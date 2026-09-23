import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../provider_repository.dart';

final ledgerProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>(
  (ref, providerId) => ref.watch(providerRepositoryProvider).getSettlementLedger(providerId),
);

class LedgerScreen extends ConsumerWidget {
  final int providerId;
  const LedgerScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(ledgerProvider(providerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Payout history')),
      body: ledgerAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(ledgerProvider(providerId))),
        data: (data) {
          final items = (data['items'] as List).cast<Map<String, dynamic>>();
          final totals = data['totals'] as Map<String, dynamic>;
          final df = DateFormat('d MMM yyyy');

          return ListView(
            padding: const EdgeInsets.all(TnnSpacing.lg),
            children: [
              Row(
                children: [
                  _TotalCard(label: 'Gross', value: totals['gross']),
                  const SizedBox(width: 10),
                  _TotalCard(label: 'Platform fee', value: totals['fee']),
                  const SizedBox(width: 10),
                  _TotalCard(label: 'Net payable', value: totals['net'], highlight: true),
                ],
              ),
              const SizedBox(height: 20),
              Text('Settlements', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              if (items.isEmpty) const EmptyState(icon: Icons.receipt_long_outlined, title: 'No settlements yet', message: 'Completed, paid bookings will appear here.'),
              ...items.map((entry) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('₹${(entry['net_payable'] / 100).toStringAsFixed(0)} net', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                            Text(entry['settled_at'] != null ? df.format(DateTime.parse(entry['settled_at'] as String).toLocal()) : '—', style: const TextStyle(fontSize: 11, color: TnnColors.inkSoft)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Gross ₹${(entry['gross_amount'] / 100).toStringAsFixed(0)} · Fee ₹${(entry['platform_fee'] / 100).toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final String label;
  final int value;
  final bool highlight;
  const _TotalCard({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlight ? TnnColors.ink : TnnColors.card,
          borderRadius: BorderRadius.circular(TnnRadius.md),
          border: Border.all(color: TnnColors.lineSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('₹${(value / 100).toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: highlight ? Colors.white : TnnColors.ink)),
            Text(label, style: TextStyle(fontSize: 10.5, color: highlight ? const Color(0xFFB9C4DA) : TnnColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}
