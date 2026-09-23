import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../../auth/session_controller.dart';
import '../admin_repository.dart';
import '../shell/admin_community_context.dart';

class CommunitySetupScreen extends ConsumerStatefulWidget {
  const CommunitySetupScreen({super.key});

  @override
  ConsumerState<CommunitySetupScreen> createState() => _CommunitySetupScreenState();
}

class _CommunitySetupScreenState extends ConsumerState<CommunitySetupScreen> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _towerController = TextEditingController();
  final _unitController = TextEditingController();
  int? _selectedTowerId;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _towerController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _createCommunity() async {
    if (_nameController.text.trim().isEmpty || _cityController.text.trim().isEmpty) return;
    try {
      final row = await ref.read(adminRepositoryProvider).createCommunity(name: _nameController.text.trim(), city: _cityController.text.trim());
      ref.invalidate(adminCommunitiesProvider);
      ref.read(selectedCommunityIdProvider.notifier).state = row['id'] as int;
      _nameController.clear();
      _cityController.clear();
      if (mounted) showTnnSnackBar(context, 'Community created');
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    }
  }

  Future<void> _editCommunity(int communityId, Map<String, dynamic> current) async {
    final nameController = TextEditingController(text: current['name'] as String?);
    final cityController = TextEditingController(text: current['city'] as String?);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit community'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Community name'), autofocus: true),
            const SizedBox(height: 12),
            TextField(controller: cityController, decoration: const InputDecoration(labelText: 'City')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true) return;
    if (nameController.text.trim().isEmpty || cityController.text.trim().isEmpty) {
      if (mounted) showTnnSnackBar(context, 'Name and city cannot be empty', isError: true);
      return;
    }
    try {
      await ref.read(adminRepositoryProvider).updateCommunity(communityId, name: nameController.text.trim(), city: cityController.text.trim());
      ref.invalidate(adminCommunitiesProvider);
      if (mounted) showTnnSnackBar(context, 'Community updated');
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlatformAdmin = ref.watch(sessionControllerProvider).role == 'platform_admin';
    final communityId = ref.watch(selectedCommunityIdProvider);
    final towersAsync = communityId == null ? null : ref.watch(towersProvider(communityId));

    return Scaffold(
      appBar: AppBar(title: const Text('Community setup')),
      body: ListView(
        padding: const EdgeInsets.all(TnnSpacing.lg),
        children: [
          if (isPlatformAdmin) ...[
            Text('Create a new community', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Community name')),
            const SizedBox(height: 10),
            TextField(controller: _cityController, decoration: const InputDecoration(hintText: 'City')),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _createCommunity, child: const Text('Create community')),
            const SizedBox(height: 28),
          ],
          if (communityId != null) ...[
            ref.watch(adminCommunitiesProvider).when(
                  loading: () => const LoadingSkeleton(lines: 2),
                  error: (e, _) => Text(e.toString()),
                  data: (communities) {
                    final match = communities.cast<Map<String, dynamic>?>().firstWhere((c) => c?['id'] == communityId, orElse: () => null);
                    if (match == null) return const SizedBox.shrink();
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.lg), border: Border.all(color: TnnColors.lineSoft)),
                      child: Row(
                        children: [
                          const Icon(Icons.location_city_outlined, size: 22, color: TnnColors.ink),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${match['name']}', style: Theme.of(context).textTheme.headlineSmall),
                                Text('${match['city']}', style: const TextStyle(color: TnnColors.inkSoft, fontSize: 12.5)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _editCommunity(communityId, match),
                            icon: const Icon(Icons.edit_outlined, size: 19, color: TnnColors.inkSoft),
                            tooltip: 'Edit community',
                          ),
                        ],
                      ),
                    );
                  },
                ),
            Text('Towers / blocks', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: _towerController, decoration: const InputDecoration(hintText: 'e.g. Tower 5'))),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  if (_towerController.text.trim().isEmpty) return;
                  try {
                    await ref.read(adminRepositoryProvider).createTower(communityId, _towerController.text.trim());
                    ref.invalidate(towersProvider(communityId));
                    _towerController.clear();
                  } catch (e) {
                    if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
                  }
                },
                child: const Text('Add'),
              ),
            ]),
            const SizedBox(height: 16),
            if (towersAsync != null)
              towersAsync.when(
                loading: () => const LoadingSkeleton(lines: 2),
                error: (e, _) => Text(e.toString()),
                data: (towers) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: towers.map((t) => ChoiceChip(
                        label: Text(t['name']),
                        selected: _selectedTowerId == t['id'],
                        onSelected: (_) => setState(() => _selectedTowerId = t['id'] as int),
                      )).toList(),
                ),
              ),
            const SizedBox(height: 24),
            Text('Units', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            const Text('Select a tower above, then add or view its units.', style: TextStyle(color: TnnColors.inkSoft, fontSize: 12.5)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: _unitController, decoration: const InputDecoration(hintText: 'e.g. Unit 502'))),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _selectedTowerId == null
                    ? null
                    : () async {
                        if (_unitController.text.trim().isEmpty) return;
                        try {
                          await ref.read(adminRepositoryProvider).createUnit(_selectedTowerId!, _unitController.text.trim());
                          ref.invalidate(unitsProvider(_selectedTowerId!));
                          _unitController.clear();
                          if (mounted) showTnnSnackBar(context, 'Unit added');
                        } catch (e) {
                          if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
                        }
                      },
                child: const Text('Add'),
              ),
            ]),
            const SizedBox(height: 16),
            if (_selectedTowerId != null)
              ref.watch(unitsProvider(_selectedTowerId!)).when(
                    loading: () => const LoadingSkeleton(lines: 2),
                    error: (e, _) => Text(e.toString()),
                    data: (units) => units.isEmpty
                        ? const Text('No units yet in this tower.', style: TextStyle(color: TnnColors.inkSoft, fontSize: 12.5))
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: units.map((u) => Chip(label: Text(u['name']))).toList(),
                          ),
                  ),
          ],
        ],
      ),
    );
  }
}
