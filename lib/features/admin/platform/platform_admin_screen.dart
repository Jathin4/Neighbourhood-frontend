import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../../resident/services/services_screen.dart' show categoriesProvider;
import '../admin_repository.dart';

final platformKpisProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) => ref.watch(adminRepositoryProvider).platformKpis());
final auditLogProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref.watch(adminRepositoryProvider).auditLog());

class PlatformAdminScreen extends StatefulWidget {
  const PlatformAdminScreen({super.key});

  @override
  State<PlatformAdminScreen> createState() => _PlatformAdminScreenState();
}

class _PlatformAdminScreenState extends State<PlatformAdminScreen> with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform admin'),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'KPIs'), Tab(text: 'Categories'), Tab(text: 'Audit log')], labelColor: Colors.white, indicatorColor: TnnColors.gold),
      ),
      body: TabBarView(controller: _tabController, children: const [_KpiTab(), _CategoriesTab(), _AuditLogTab()]),
    );
  }
}

class _KpiTab extends ConsumerWidget {
  const _KpiTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(platformKpisProvider);
    return kpisAsync.when(
      loading: () => const LoadingSkeleton(),
      error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(platformKpisProvider)),
      data: (kpis) => GridView.count(
        padding: const EdgeInsets.all(TnnSpacing.lg),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
        children: [
          _Kpi(label: 'Communities', value: '${kpis['total_communities']}'),
          _Kpi(label: 'Active residents', value: '${kpis['total_active_residents']}'),
          _Kpi(label: 'Verified providers', value: '${kpis['total_verified_providers']}'),
          _Kpi(label: 'Total bookings', value: '${kpis['total_bookings']}'),
          _Kpi(label: 'Completed bookings', value: '${kpis['completed_bookings']}'),
          _Kpi(label: 'GTV', value: '₹${((kpis['gross_transaction_value_minor'] as int) / 100).toStringAsFixed(0)}'),
          _Kpi(label: 'Platform revenue', value: '₹${((kpis['platform_revenue_minor'] as int) / 100).toStringAsFixed(0)}'),
          _Kpi(label: 'Take rate', value: '${((kpis['take_rate'] as num) * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  const _Kpi({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return categoriesAsync.when(
      loading: () => const LoadingSkeleton(),
      error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(categoriesProvider)),
      data: (categories) => ListView.separated(
        padding: const EdgeInsets.all(TnnSpacing.lg),
        itemCount: categories.length,
        separatorBuilder: (context, i) => const Divider(),
        itemBuilder: (context, i) {
          final c = categories[i];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(c['name'] ?? ''),
            subtitle: Text('SLA: ${c['sla_hours']}h'),
            trailing: OutlinedButton(
              onPressed: () => _editCategory(context, ref, c),
              child: const Text('Edit'),
            ),
          );
        },
      ),
    );
  }

  void _editCategory(BuildContext context, WidgetRef ref, Map<String, dynamic> category) {
    final slaController = TextEditingController(text: '${category['sla_hours']}');
    final commissionController = TextEditingController(text: '0.15');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${category['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: commissionController, decoration: const InputDecoration(labelText: 'Commission rate (0.0-1.0)'), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextField(controller: slaController, decoration: const InputDecoration(labelText: 'SLA hours'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(adminRepositoryProvider).updateCategory(
                      category['id'] as int,
                      commissionRate: double.tryParse(commissionController.text),
                      slaHours: int.tryParse(slaController.text),
                    );
                ref.invalidate(categoriesProvider);
              } catch (e) {
                if (context.mounted) showTnnSnackBar(context, e.toString(), isError: true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _AuditLogTab extends ConsumerWidget {
  const _AuditLogTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditAsync = ref.watch(auditLogProvider);
    final df = DateFormat('d MMM, h:mm a');
    return auditAsync.when(
      loading: () => const LoadingSkeleton(),
      error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(auditLogProvider)),
      data: (entries) => ListView.separated(
        padding: const EdgeInsets.all(TnnSpacing.lg),
        itemCount: entries.length,
        separatorBuilder: (context, i) => const Divider(),
        itemBuilder: (context, i) {
          final e = entries[i];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(e['action'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text('${e['entity_type']} · ${e['entity_id']}'),
            trailing: Text(df.format(DateTime.parse(e['created_at'] as String).toLocal()), style: const TextStyle(fontSize: 10.5, color: TnnColors.inkSoft)),
          );
        },
      ),
    );
  }
}
