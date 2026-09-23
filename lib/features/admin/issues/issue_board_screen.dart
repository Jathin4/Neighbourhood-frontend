import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_pill.dart';
import '../../auth/session_controller.dart';
import '../admin_repository.dart';
import '../shell/admin_community_context.dart';

final adminIssuesProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
  (ref, communityId) => ref.watch(adminRepositoryProvider).listIssues(communityId),
);

const _statuses = ['Submitted', 'Acknowledged', 'Assigned', 'InProgress', 'Resolved', 'Closed'];

class IssueBoardScreen extends ConsumerWidget {
  const IssueBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityId = ref.watch(selectedCommunityIdProvider);
    if (communityId == null) return const Scaffold(body: Center(child: Text('Select a community first')));

    final issuesAsync = ref.watch(adminIssuesProvider(communityId));

    return Scaffold(
      appBar: AppBar(title: const Text('Issue board')),
      body: issuesAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(adminIssuesProvider(communityId))),
        data: (issues) {
          if (issues.isEmpty) return const EmptyState(icon: Icons.checklist_outlined, title: 'No issues', message: 'Resident-reported issues will show up here.');
          return ListView.builder(
            padding: const EdgeInsets.all(TnnSpacing.lg),
            itemCount: issues.length,
            itemBuilder: (context, i) => _IssueCard(issue: issues[i], communityId: communityId),
          );
        },
      ),
    );
  }
}

class _IssueCard extends ConsumerWidget {
  final Map<String, dynamic> issue;
  final int communityId;
  const _IssueCard({required this.issue, required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overdue = issue['is_overdue'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: TnnColors.card,
        borderRadius: BorderRadius.circular(TnnRadius.md),
        border: Border.all(color: overdue ? TnnColors.brick : TnnColors.lineSoft, width: overdue ? 1.4 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('#${(issue['ticket_no'] as String).split('-').last}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(width: 8),
            if (overdue) const Text('OVERDUE', style: TextStyle(color: TnnColors.brick, fontSize: 10, fontWeight: FontWeight.w700)),
            const Spacer(),
            StatusPill(status: issue['status'] as String),
          ]),
          const SizedBox(height: 6),
          Text(issue['description'] ?? '', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text('${issue['category']} · ${issue['resident_name'] ?? ''}', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _assign(context, ref),
                child: const Text('Assign'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _changeStatus(context, ref),
                child: const Text('Update status'),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _assign(BuildContext context, WidgetRef ref) async {
    final selfId = ref.read(sessionControllerProvider).profile?['user_id'] as int?;
    if (selfId == null) return;
    try {
      await ref.read(adminRepositoryProvider).assignIssue(issue['id'] as int, selfId);
      ref.invalidate(adminIssuesProvider(communityId));
      if (context.mounted) showTnnSnackBar(context, 'Assigned to you');
    } catch (e) {
      if (context.mounted) showTnnSnackBar(context, e.toString(), isError: true);
    }
  }

  Future<void> _changeStatus(BuildContext context, WidgetRef ref) async {
    final current = issue['status'] as String;
    final currentIdx = _statuses.indexOf(current);
    final forwardStatuses = currentIdx >= 0 ? _statuses.sublist(currentIdx + 1) : _statuses;
    if (forwardStatuses.isEmpty) return;

    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Move to status'),
        children: forwardStatuses.map((s) => SimpleDialogOption(onPressed: () => Navigator.pop(context, s), child: Text(s))).toList(),
      ),
    );
    if (chosen == null) return;
    try {
      await ref.read(adminRepositoryProvider).transitionIssueStatus(issue['id'] as int, chosen);
      ref.invalidate(adminIssuesProvider(communityId));
      if (context.mounted) showTnnSnackBar(context, 'Status updated to $chosen');
    } catch (e) {
      if (context.mounted) showTnnSnackBar(context, e.toString(), isError: true);
    }
  }
}
