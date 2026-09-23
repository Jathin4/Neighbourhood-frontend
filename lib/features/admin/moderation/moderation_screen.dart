import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/phone.dart';
import '../../../core/widgets/states.dart';
import '../admin_repository.dart';

final flaggedReviewsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref.watch(adminRepositoryProvider).flaggedReviews());

class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flaggedAsync = ref.watch(flaggedReviewsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Moderation queue')),
      body: flaggedAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(flaggedReviewsProvider)),
        data: (reviews) {
          if (reviews.isEmpty) return const EmptyState(icon: Icons.flag_outlined, title: 'Nothing flagged', message: 'Flagged reviews will show up here for moderation.');
          return ListView.builder(
            padding: const EdgeInsets.all(TnnSpacing.lg),
            itemCount: reviews.length,
            itemBuilder: (context, i) {
              final r = reviews[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.brick.withValues(alpha: 0.3))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${r['provider_name']} · ★ ${r['rating']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.person_outline, size: 13, color: TnnColors.inkSoft),
                      const SizedBox(width: 4),
                      Text(
                        '${(r['resident_name'] as String?)?.isNotEmpty == true ? r['resident_name'] : 'Unknown resident'}'
                        '${r['resident_phone'] != null ? ' · ${displayPhone(r['resident_phone'] as String?)}' : ''}',
                        style: const TextStyle(fontSize: 11.5, color: TnnColors.inkSoft),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    if (r['text'] != null) Text(r['text'], style: const TextStyle(fontSize: 12.5)),
                    if (r['flagged_reason'] != null) Text('Flagged: ${r['flagged_reason']}', style: const TextStyle(fontSize: 11.5, color: TnnColors.brick)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await ref.read(adminRepositoryProvider).moderateContent('review', r['id'] as int, 'restore');
                            ref.invalidate(flaggedReviewsProvider);
                          },
                          child: const Text('Restore'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: TnnColors.brick),
                          onPressed: () async {
                            await ref.read(adminRepositoryProvider).moderateContent('review', r['id'] as int, 'hide');
                            ref.invalidate(flaggedReviewsProvider);
                          },
                          child: const Text('Keep hidden'),
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
