import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../resident_repository.dart';

final noticesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref.watch(residentRepositoryProvider).listNotices());

class NoticesScreen extends ConsumerWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(noticesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notices')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(noticesProvider.future),
        child: noticesAsync.when(
          loading: () => ListView(children: const [LoadingSkeleton()]),
          error: (e, _) => ListView(children: [ErrorState(message: e.toString(), onRetry: () => ref.invalidate(noticesProvider))]),
          data: (notices) {
            if (notices.isEmpty) {
              return ListView(children: const [
                EmptyState(icon: Icons.description_outlined, title: 'No notices yet', message: 'Community announcements will show up here.'),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(TnnSpacing.lg),
              itemCount: notices.length,
              itemBuilder: (context, i) => _NoticeCard(notice: notices[i]),
            );
          },
        ),
      ),
    );
  }
}

class _NoticeCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> notice;
  const _NoticeCard({required this.notice});

  @override
  ConsumerState<_NoticeCard> createState() => _NoticeCardState();
}

class _NoticeCardState extends ConsumerState<_NoticeCard> {
  bool _open = false;
  bool _locallyRead = false;

  // Derived fresh on every build instead of captured once — notices tabs live
  // inside an IndexedStack that never disposes, so a `late`-initialized copy
  // of is_read would go stale after the first fetch and never update again
  // (e.g. after a pull-to-refresh, or once the list is refetched elsewhere).
  bool get _isRead => widget.notice['is_read'] == true || _locallyRead;

  Future<void> _toggle() async {
    setState(() => _open = !_open);
    if (_open && !_isRead) {
      setState(() => _locallyRead = true);
      try {
        await ref.read(residentRepositoryProvider).markNoticeRead(widget.notice['id'] as int);
      } catch (_) {
        // Non-critical — a failed read-receipt shouldn't disrupt reading the notice.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notice;
    final isCritical = n['priority'] == 'critical';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TnnColors.card,
        borderRadius: BorderRadius.circular(TnnRadius.md),
        border: Border.all(color: TnnColors.lineSoft),
      ),
      child: InkWell(
        onTap: _toggle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCritical ? TnnColors.statusCriticalBg : TnnColors.statusNeutralBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isCritical ? 'CRITICAL' : 'NOTICE',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: isCritical ? TnnColors.brick : TnnColors.inkSoft),
                  ),
                ),
                const Spacer(),
                if (!_isRead) Container(width: 7, height: 7, decoration: const BoxDecoration(color: TnnColors.goldDeep, shape: BoxShape.circle)),
              ],
            ),
            const SizedBox(height: 8),
            Text(n['title'] ?? '', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              n['content'] ?? '',
              maxLines: _open ? null : 2,
              overflow: _open ? TextOverflow.visible : TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_open) ...[
              const SizedBox(height: 10),
              Text('Posted by ${n['posted_by'] ?? 'Community Admin'}', style: const TextStyle(fontSize: 11, color: TnnColors.inkSoft, fontStyle: FontStyle.italic)),
              const SizedBox(height: 6),
              const Text('✓ Marked as read', style: TextStyle(fontSize: 11, color: TnnColors.leaf, fontWeight: FontWeight.w600)),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Read more', style: TextStyle(fontSize: 11.5, color: TnnColors.goldDeep, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }
}
