import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_pill.dart';
import '../resident_repository.dart';

final issueDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, ticketNo) => ref.watch(residentRepositoryProvider).getIssueDetail(ticketNo),
);

class IssueDetailScreen extends ConsumerWidget {
  final String ticketNo;
  const IssueDetailScreen({super.key, required this.ticketNo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(issueDetailProvider(ticketNo));

    return Scaffold(
      appBar: AppBar(title: Text(ticketNo)),
      body: detailAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(issueDetailProvider(ticketNo))),
        data: (issue) => _IssueDetailBody(issue: issue, ticketNo: ticketNo),
      ),
    );
  }
}

class _IssueDetailBody extends ConsumerStatefulWidget {
  final Map<String, dynamic> issue;
  final String ticketNo;
  const _IssueDetailBody({required this.issue, required this.ticketNo});

  @override
  ConsumerState<_IssueDetailBody> createState() => _IssueDetailBodyState();
}

class _IssueDetailBodyState extends ConsumerState<_IssueDetailBody> {
  final _comment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  bool get _canReopen => ['Resolved', 'Closed'].contains(widget.issue['status']);

  Future<void> _reopen() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Reopen this issue'),
          content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'What went wrong?'), autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Reopen')),
          ],
        );
      },
    );
    if (reason == null || reason.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(residentRepositoryProvider).reopenIssue(widget.issue['id'] as int, reason);
      ref.invalidate(issueDetailProvider(widget.ticketNo));
      if (mounted) showTnnSnackBar(context, 'Issue reopened');
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addComment() async {
    if (_comment.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(residentRepositoryProvider).addIssueComment(widget.issue['id'] as int, _comment.text.trim());
      _comment.clear();
      ref.invalidate(issueDetailProvider(widget.ticketNo));
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    final history = (issue['status_history'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final comments = (issue['comments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final df = DateFormat('d MMM, h:mm a');

    return ListView(
      padding: const EdgeInsets.all(TnnSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(child: Text(issue['description'] ?? '', style: Theme.of(context).textTheme.headlineSmall)),
            StatusPill(status: issue['status'] as String),
          ],
        ),
        const SizedBox(height: 6),
        Text('${issue['category']} · ${issue['urgency']} urgency', style: Theme.of(context).textTheme.bodyMedium),
        if (issue['location'] != null) Text('${issue['location']}', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),
        Text('Status history', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        ...history.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(children: const [Icon(Icons.circle, size: 9, color: TnnColors.goldDeep)]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${h['to_status']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        if (h['note'] != null) Text('${h['note']}', style: Theme.of(context).textTheme.bodyMedium),
                        Text(df.format(DateTime.parse(h['created_at'] as String).toLocal()), style: const TextStyle(fontSize: 10.5, color: TnnColors.inkSoft)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
        if (_canReopen) ...[
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _busy ? null : _reopen, child: const Text('Reopen issue')),
        ],
        const SizedBox(height: 24),
        Text('Comments', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (comments.isEmpty) const Text('No comments yet.', style: TextStyle(color: TnnColors.inkSoft, fontSize: 12.5)),
        ...comments.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.sm), border: Border.all(color: TnnColors.lineSoft)),
              child: Text('${c['comment']}', style: const TextStyle(fontSize: 13)),
            )),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: TextField(controller: _comment, decoration: const InputDecoration(hintText: 'Add a comment'))),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: _busy ? null : _addComment, icon: const Icon(Icons.send, size: 18)),
          ],
        ),
      ],
    );
  }
}
