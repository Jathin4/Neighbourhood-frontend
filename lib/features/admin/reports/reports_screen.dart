import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../admin_repository.dart';
import '../shell/admin_community_context.dart';

const _reportTypes = {
  'service_usage': 'Service usage',
  'ratings': 'Ratings',
  'sla_compliance': 'SLA compliance',
  'engagement': 'Resident engagement',
};

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _reportType = 'service_usage';
  Map<String, dynamic>? _report;
  bool _loading = false;

  Future<void> _load() async {
    final communityId = ref.read(selectedCommunityIdProvider);
    if (communityId == null) return;
    setState(() => _loading = true);
    try {
      final result = await ref.read(adminRepositoryProvider).generateReport(communityId, _reportType);
      setState(() => _report = result);
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final data = _report?['data'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(TnnSpacing.lg),
        children: [
          Wrap(
            spacing: 8,
            children: _reportTypes.entries.map((e) => ChoiceChip(
                  label: Text(e.value),
                  selected: _reportType == e.key,
                  onSelected: (_) {
                    setState(() => _reportType = e.key);
                    _load();
                  },
                )).toList(),
          ),
          const SizedBox(height: 20),
          if (_loading) const LoadingSkeleton(lines: 3),
          if (!_loading && data != null) ..._buildStats(context, data),
        ],
      ),
    );
  }

  List<Widget> _buildStats(BuildContext context, Map<String, dynamic> data) {
    return data.entries.map((e) {
      final isMap = e.value is Map;
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_prettify(e.key), style: const TextStyle(fontSize: 11.5, color: TnnColors.inkSoft, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            if (isMap)
              ...((e.value as Map).entries.map((sub) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${sub.key}'), Text('${sub.value}', style: const TextStyle(fontWeight: FontWeight.w700))]),
                  )))
            else
              Text('${e.value}', style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      );
    }).toList();
  }

  String _prettify(String key) => key.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
}
