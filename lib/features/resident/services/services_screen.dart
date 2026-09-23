import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../marketplace_repository.dart';

final categoriesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref.watch(marketplaceRepositoryProvider).listCategories());
final myBookingsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref.watch(marketplaceRepositoryProvider).listMyBookings());

const _categoryIcons = {
  'electrician': Icons.bolt,
  'plumber': Icons.plumbing,
  'ac': Icons.ac_unit,
  'cleaning': Icons.cleaning_services_outlined,
  'pest': Icons.pest_control_outlined,
  'carpenter': Icons.carpenter_outlined,
  'painter': Icons.format_paint_outlined,
  'appliance': Icons.kitchen_outlined,
  'movers': Icons.local_shipping_outlined,
  'cook': Icons.soup_kitchen_outlined,
  'maid': Icons.auto_awesome_outlined,
  'driver': Icons.directions_car_outlined,
  'tutor': Icons.menu_book_outlined,
};

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(TnnSpacing.lg),
            child: Row(children: [
              _Pill(label: 'Browse', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
              const SizedBox(width: 8),
              _Pill(label: 'My bookings', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
            ]),
          ),
          Expanded(child: _tab == 0 ? const _BrowseTab() : const _MyBookingsTab()),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TnnRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? TnnColors.ink : TnnColors.card,
          border: Border.all(color: selected ? TnnColors.ink : TnnColors.line),
          borderRadius: BorderRadius.circular(TnnRadius.pill),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : TnnColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 12.5)),
      ),
    );
  }
}

class _BrowseTab extends ConsumerWidget {
  const _BrowseTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return categoriesAsync.when(
      loading: () => const LoadingSkeleton(),
      error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(categoriesProvider)),
      data: (categories) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(TnnSpacing.lg, 0, TnnSpacing.lg, TnnSpacing.lg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.95),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final c = categories[i];
          return InkWell(
            borderRadius: BorderRadius.circular(TnnRadius.lg),
            onTap: () => context.push('/services/${c['key']}?label=${Uri.encodeComponent(c['name'])}'),
            child: Container(
              decoration: BoxDecoration(color: TnnColors.card, border: Border.all(color: TnnColors.lineSoft), borderRadius: BorderRadius.circular(TnnRadius.lg)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_categoryIcons[c['key']] ?? Icons.build_outlined, size: 24, color: TnnColors.ink),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(c['name'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MyBookingsTab extends ConsumerWidget {
  const _MyBookingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);
    return bookingsAsync.when(
      loading: () => const LoadingSkeleton(),
      error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(myBookingsProvider)),
      data: (bookings) {
        if (bookings.isEmpty) {
          return const EmptyState(icon: Icons.calendar_month_outlined, title: 'No bookings yet', message: 'Book a verified provider from Browse to see it here.');
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(myBookingsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(TnnSpacing.lg, 0, TnnSpacing.lg, TnnSpacing.lg),
            itemCount: bookings.length,
            itemBuilder: (context, i) {
              final b = bookings[i];
              return InkWell(
                borderRadius: BorderRadius.circular(TnnRadius.md),
                onTap: () => context.push('/bookings/${b['id']}'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b['provider_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                            const SizedBox(height: 3),
                            Text('${b['category']} · ${b['preferred_time'] ?? b['proposed_time'] ?? ''}', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      _StatusChip(status: b['status'] as String),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: TnnColors.statusPendingBg, borderRadius: BorderRadius.circular(TnnRadius.pill)),
      child: Text(status.toUpperCase(), style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: TnnColors.goldDeep)),
    );
  }
}
