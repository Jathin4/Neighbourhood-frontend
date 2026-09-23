import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../provider_repository.dart';

final providerReviewsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
  (ref, providerId) => ref.watch(providerRepositoryProvider).listReviews(providerId),
);

class ProviderReviewsScreen extends ConsumerWidget {
  final int providerId;
  const ProviderReviewsScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(providerReviewsProvider(providerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: reviewsAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(providerReviewsProvider(providerId))),
        data: (reviews) {
          if (reviews.isEmpty) return const EmptyState(icon: Icons.star_border, title: 'No reviews yet', message: 'Reviews from completed bookings will show up here.');
          return ListView.builder(
            padding: const EdgeInsets.all(TnnSpacing.lg),
            itemCount: reviews.length,
            itemBuilder: (context, i) => _ReviewCard(review: reviews[i], providerId: providerId),
          );
        },
      ),
    );
  }
}

class _ReviewCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> review;
  final int providerId;
  const _ReviewCard({required this.review, required this.providerId});

  @override
  ConsumerState<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<_ReviewCard> {
  bool _responding = false;
  final _responseController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _submitResponse() async {
    if (_responseController.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(providerRepositoryProvider).respondToReview(widget.review['id'] as int, _responseController.text.trim());
      ref.invalidate(providerReviewsProvider(widget.providerId));
      if (mounted) showTnnSnackBar(context, 'Response posted');
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() { _busy = false; _responding = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: List.generate(5, (i) => Icon(i < (r['rating'] as int) ? Icons.star : Icons.star_border, size: 16, color: TnnColors.gold))),
          if (r['text'] != null) ...[const SizedBox(height: 6), Text(r['text'], style: const TextStyle(fontSize: 13))],
          if (r['provider_response'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: TnnColors.paper, borderRadius: BorderRadius.circular(TnnRadius.sm)),
              child: Text('Your response: ${r['provider_response']}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: TnnColors.inkSoft)),
            ),
          ] else if (_responding) ...[
            const SizedBox(height: 8),
            TextField(controller: _responseController, decoration: const InputDecoration(hintText: 'Write a response')),
            const SizedBox(height: 6),
            Row(children: [
              TextButton(onPressed: () => setState(() => _responding = false), child: const Text('Cancel')),
              const Spacer(),
              FilledButton(onPressed: _busy ? null : _submitResponse, child: const Text('Post response')),
            ]),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextButton(onPressed: () => setState(() => _responding = true), child: const Text('Respond')),
            ),
        ],
      ),
    );
  }
}
