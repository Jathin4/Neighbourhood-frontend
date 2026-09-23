import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/phone.dart';
import '../../../core/widgets/states.dart';
import '../admin_repository.dart';
import '../shell/admin_community_context.dart';

const _capabilities = [
  'can_create_notice',
  'can_assign_issue',
  'can_create_poll',
  'can_create_event',
  'can_manage_structure',
];

const _capabilityLabels = {
  'can_create_notice': 'Post community notices',
  'can_assign_issue': 'Assign and manage issues',
  'can_create_poll': 'Create polls',
  'can_create_event': 'Create events',
  'can_manage_structure': 'Manage towers and units',
};

class CommitteeRolesScreen extends ConsumerStatefulWidget {
  const CommitteeRolesScreen({super.key});

  @override
  ConsumerState<CommitteeRolesScreen> createState() => _CommitteeRolesScreenState();
}

class _CommitteeRolesScreenState extends ConsumerState<CommitteeRolesScreen> {
  final _query = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _selected;
  final Set<String> _selectedCapabilities = {};
  bool _searching = false;
  bool _saving = false;

  Future<void> _search() async {
    final communityId = ref.read(selectedCommunityIdProvider);
    if (communityId == null || _query.text.trim().isEmpty) return;
    setState(() => _searching = true);
    try {
      final results = await ref.read(adminRepositoryProvider).searchResidents(communityId, query: _query.text.trim());
      setState(() => _results = results);
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _assign() async {
    final communityId = ref.read(selectedCommunityIdProvider);
    if (communityId == null || _selected == null || _selectedCapabilities.isEmpty) {
      showTnnSnackBar(context, 'Pick a resident and at least one capability', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).assignCommitteeRole(communityId, _selected!['user_id'] as int, _selectedCapabilities.toList());
      if (mounted) showTnnSnackBar(context, 'Capabilities granted to ${_selected!['full_name']}');
      setState(() {
        _selected = null;
        _selectedCapabilities.clear();
      });
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Committee roles')),
      body: ListView(
        padding: const EdgeInsets.all(TnnSpacing.lg),
        children: [
          const Text('Search for a resident to assign committee responsibilities to.', style: TextStyle(color: TnnColors.inkSoft, fontSize: 12.5)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: _query, decoration: const InputDecoration(hintText: 'Name or phone'), onSubmitted: (_) => _search())),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _searching ? null : _search, child: const Text('Search')),
          ]),
          const SizedBox(height: 12),
          ..._results.map((r) => RadioListTile<int>(
                value: r['user_id'] as int,
                groupValue: _selected?['user_id'] as int?,
                title: Text(r['full_name'] ?? ''),
                subtitle: Text('${displayPhone(r['phone'] as String?)} · ${r['tower_name'] ?? ''} ${r['unit_name'] ?? ''}'),
                activeColor: TnnColors.gold,
                onChanged: (_) => setState(() => _selected = r),
              )),
          if (_selected != null) ...[
            const SizedBox(height: 20),
            Text('Assign responsibilities to ${_selected!['full_name']}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            ..._capabilities.map((c) => CheckboxListTile(
                  value: _selectedCapabilities.contains(c),
                  title: Text(_capabilityLabels[c] ?? c),
                  activeColor: TnnColors.gold,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => v == true ? _selectedCapabilities.add(c) : _selectedCapabilities.remove(c)),
                )),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saving ? null : _assign,
              child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Grant capabilities'),
            ),
          ],
        ],
      ),
    );
  }
}
