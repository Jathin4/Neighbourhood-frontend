import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_pill.dart';
import '../marketplace_repository.dart';
import 'booking_sheet.dart';

final providerProfileProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>(
  (ref, id) => ref.watch(marketplaceRepositoryProvider).getProviderProfile(id),
);

class ProviderProfileScreen extends ConsumerWidget {
  final int providerId;
  const ProviderProfileScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(providerProfileProvider(providerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Provider profile')),
      body: profileAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(providerProfileProvider(providerId))),
        data: (p) {
          final reviews = (p['reviews'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          return ListView(
            padding: const EdgeInsets.all(TnnSpacing.lg),
            children: [
              Row(children: [
                Expanded(child: Text(p['business_name'] ?? '', style: Theme.of(context).textTheme.headlineMedium)),
                VerifiedBadge(verified: p['verification_state'] == 'Verified'),
              ]),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Stat(label: 'Rating', value: '★ ${p['rating']?.toString() ?? p['rating_avg'] ?? '—'}'),
                  _Stat(label: 'Jobs done', value: '${p['jobs_completed'] ?? p['jobs'] ?? '—'}'),
                  _Stat(label: 'Verified', value: p['verification_state'] == 'Verified' ? 'Yes' : 'Pending'),
                ],
              ),
              const SizedBox(height: 22),
              Text('About', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              const Text(
                'Handles residential jobs across your community and nearby. Reviews are only shown from completed, verified bookings.',
                style: TextStyle(color: TnnColors.inkSoft, fontSize: 12.5, height: 1.5),
              ),
              const SizedBox(height: 22),
              Text('Reviews', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (reviews.isEmpty) const Text('No reviews yet.', style: TextStyle(color: TnnColors.inkSoft, fontSize: 12.5)),
              ...reviews.map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.sm), border: Border.all(color: TnnColors.lineSoft)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('★ ${r['rating']}', style: const TextStyle(color: TnnColors.goldDeep, fontWeight: FontWeight.w700)),
                        if (r['text'] != null) Text(r['text'], style: const TextStyle(fontSize: 12.5)),
                        if (r['provider_response'] != null) ...[
                          const SizedBox(height: 4),
                          Text('Response: ${r['provider_response']}', style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: TnnColors.inkSoft)),
                        ],
                      ],
                    ),
                  )),
              const SizedBox(height: 90),
            ],
          );
        },
      ),
      bottomNavigationBar: profileAsync.maybeWhen(
        data: (p) => Padding(
          padding: const EdgeInsets.all(TnnSpacing.lg),
          child: ElevatedButton(
            onPressed: () => showBookingSheet(
              context,
              providerId: providerId,
              providerName: p['business_name'] ?? '',
              categoryKey: (p['categories'] as List?)?.isNotEmpty == true ? (p['categories'] as List).first as String : null,
            ),
            child: const Text('Request a booking'),
          ),
        ),
        orElse: () => null,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
