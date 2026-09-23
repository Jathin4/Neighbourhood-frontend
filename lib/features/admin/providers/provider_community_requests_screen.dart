import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../admin_repository.dart';
import '../shell/admin_community_context.dart';

/// Providers that have asked to serve THIS community (fn_request_serve_community)
/// and are waiting for the admin to approve — separate from platform-level
/// verification, which only checks the business itself, not which communities
/// it's allowed to appear in.
final communityProviderRequestsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final communityId = ref.watch(selectedCommunityIdProvider);
  if (communityId == null) return Future.value([]);
  return ref.watch(adminRepositoryProvider).listCommunityProviderRequests(communityId);
});

class ProviderCommunityRequestsScreen extends ConsumerWidget {
  const ProviderCommunityRequestsScreen({super.key});

  Future<void> _decide(BuildContext context, WidgetRef ref, int requestId, String status) async {
    try {
      await ref.read(adminRepositoryProvider).decideCommunityProviderRequest(requestId, status);
      ref.invalidate(communityProviderRequestsProvider);
      if (context.mounted) showTnnSnackBar(context, status == 'Approved' ? 'Approved — now visible to residents' : 'Request rejected');
    } catch (e) {
      if (context.mounted) showTnnSnackBar(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(communityProviderRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Provider requests')),
      body: requestsAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(communityProviderRequestsProvider)),
        data: (requests) {
          if (requests.isEmpty) {
            return const EmptyState(
              icon: Icons.storefront_outlined,
              title: 'No pending requests',
              message: 'When a verified provider asks to serve your community, it shows up here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(TnnSpacing.lg),
            itemCount: requests.length,
            itemBuilder: (context, i) {
              final r = requests[i];
              final categories = (r['categories'] as List).cast<String>();
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['business_name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, children: categories.map((c) => Chip(label: Text(c, style: const TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact)).toList()),
                    const SizedBox(height: 6),
                    Text('★ ${r['rating_avg']} · ${r['jobs_completed']} jobs completed platform-wide', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: TnnColors.brick),
                          onPressed: () => _decide(context, ref, r['id'] as int, 'Rejected'),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _decide(context, ref, r['id'] as int, 'Approved'),
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
}
