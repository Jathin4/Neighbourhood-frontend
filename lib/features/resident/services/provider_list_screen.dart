import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_pill.dart';
import '../../auth/session_controller.dart';
import '../marketplace_repository.dart';

final providersForCategoryProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, category) {
  final communityId = ref.watch(sessionControllerProvider).profile?['community']?['id'] as int?;
  return ref.watch(marketplaceRepositoryProvider).searchProviders(category: category, communityId: communityId);
});

class ProviderListScreen extends ConsumerWidget {
  final String categoryKey;
  final String label;
  const ProviderListScreen({super.key, required this.categoryKey, required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(providersForCategoryProvider(categoryKey));

    return Scaffold(
      appBar: AppBar(title: Text('Verified ${label.toLowerCase()}s')),
      body: providersAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(providersForCategoryProvider(categoryKey))),
        data: (providers) {
          if (providers.isEmpty) {
            return const EmptyState(icon: Icons.handyman_outlined, title: 'No providers yet in this category', message: 'Check back soon — we are onboarding local providers.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(TnnSpacing.lg),
            itemCount: providers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final p = providers[i];
              return InkWell(
                onTap: () => context.push('/providers/${p['provider_id']}'),
                borderRadius: BorderRadius.circular(TnnRadius.md),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 22, backgroundColor: TnnColors.ink, child: Text((p['business_name'] as String)[0], style: const TextStyle(color: Colors.white))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Flexible(child: Text(p['business_name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5), overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 6),
                              VerifiedBadge(verified: p['verification_state'] == 'Verified'),
                              if (p['is_promoted'] == true) ...[const SizedBox(width: 6), const PromotedLabel()],
                            ]),
                            const SizedBox(height: 4),
                            Text('★ ${p['rating_avg']} · ${p['jobs_completed']} jobs completed', style: const TextStyle(color: TnnColors.goldDeep, fontWeight: FontWeight.w600, fontSize: 11.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
