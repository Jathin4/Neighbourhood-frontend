import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/phone.dart';
import '../../../core/widgets/states.dart';
import '../admin_repository.dart';
import '../shell/admin_community_context.dart';

final membershipRequestsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
  (ref, communityId) => ref.watch(adminRepositoryProvider).listMembershipRequests(communityId, status: 'Pending'),
);

class MembershipRequestsScreen extends ConsumerWidget {
  const MembershipRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityId = ref.watch(selectedCommunityIdProvider);
    if (communityId == null) return const Scaffold(body: Center(child: Text('Select a community first')));

    final requestsAsync = ref.watch(membershipRequestsProvider(communityId));

    return Scaffold(
      appBar: AppBar(title: const Text('Membership requests')),
      body: requestsAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(membershipRequestsProvider(communityId))),
        data: (requests) {
          if (requests.isEmpty) return const EmptyState(icon: Icons.how_to_reg_outlined, title: 'No pending requests', message: 'New membership requests will show up here.');
          return ListView.builder(
            padding: const EdgeInsets.all(TnnSpacing.lg),
            itemCount: requests.length,
            itemBuilder: (context, i) {
              final r = requests[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['full_name'] ?? displayPhone(r['phone'] as String?), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    Text('${displayPhone(r['phone'] as String?)} · ${r['method']}', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: TnnColors.brick),
                          onPressed: () async {
                            final reason = await _askReason(context, 'Reason for rejecting');
                            if (reason == null) return;
                            try {
                              await ref.read(adminRepositoryProvider).decideMembershipRequest(r['id'] as int, status: 'Rejected', reason: reason);
                              ref.invalidate(membershipRequestsProvider(communityId));
                            } catch (e) {
                              if (context.mounted) showTnnSnackBar(context, e.toString(), isError: true);
                            }
                          },
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await ref.read(adminRepositoryProvider).decideMembershipRequest(r['id'] as int, status: 'Approved');
                              ref.invalidate(membershipRequestsProvider(communityId));
                            } catch (e) {
                              if (context.mounted) showTnnSnackBar(context, e.toString(), isError: true);
                            }
                          },
                          child: const Text('Approve'),
                        ),
                      ),
                    ]),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<String?> _askReason(BuildContext context, String hint) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(hint),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Confirm')),
        ],
      ),
    );
  }
}
