import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../../resident/marketplace_repository.dart';
import '../../resident/services/services_screen.dart' show categoriesProvider;
import '../admin_repository.dart';
import '../shell/admin_community_context.dart';

final curatedProvidersProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
  (ref, communityId) => ref.watch(adminRepositoryProvider).listCuratedProviders(communityId),
);

class CuratedProvidersScreen extends ConsumerStatefulWidget {
  const CuratedProvidersScreen({super.key});

  @override
  ConsumerState<CuratedProvidersScreen> createState() => _CuratedProvidersScreenState();
}

class _CuratedProvidersScreenState extends ConsumerState<CuratedProvidersScreen> {
  String? _category;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  Widget build(BuildContext context) {
    final communityId = ref.watch(selectedCommunityIdProvider);
    if (communityId == null) return const Scaffold(body: Center(child: Text('Select a community first')));

    final curatedAsync = ref.watch(curatedProvidersProvider(communityId));
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Curated providers')),
      body: ListView(
        padding: const EdgeInsets.all(TnnSpacing.lg),
        children: [
          Text('Currently curated', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          curatedAsync.when(
            loading: () => const LoadingSkeleton(lines: 2),
            error: (e, _) => Text(e.toString()),
            data: (list) {
              if (list.isEmpty) return const Text('No curated providers yet.', style: TextStyle(color: TnnColors.inkSoft, fontSize: 12.5));
              return Column(
                children: list.map((c) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c['business_name'] ?? ''),
                      subtitle: Text(c['label'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () async {
                          await ref.read(adminRepositoryProvider).removeCuratedProvider(c['id'] as int);
                          ref.invalidate(curatedProvidersProvider(communityId));
                        },
                      ),
                    )).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Add a provider', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          categoriesAsync.when(
            loading: () => const LoadingSkeleton(lines: 1),
            error: (e, _) => Text(e.toString()),
            data: (categories) => DropdownButtonFormField<String>(
              initialValue: _category,
              hint: const Text('Choose a category'),
              items: categories.map((c) => DropdownMenuItem(value: c['key'] as String, child: Text(c['name']))).toList(),
              onChanged: (v) async {
                setState(() => _category = v);
                if (v == null) return;
                final results = await ref.read(marketplaceRepositoryProvider).searchProviders(category: v, communityId: communityId);
                setState(() => _searchResults = results);
              },
            ),
          ),
          const SizedBox(height: 10),
          ..._searchResults.map((p) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(p['business_name'] ?? ''),
                subtitle: Text('★ ${p['rating_avg']} · ${p['jobs_completed']} jobs'),
                trailing: OutlinedButton(
                  onPressed: () async {
                    await ref.read(adminRepositoryProvider).curateProvider(communityId, p['provider_id'] as int);
                    ref.invalidate(curatedProvidersProvider(communityId));
                    if (context.mounted) showTnnSnackBar(context, 'Added to curated list');
                  },
                  child: const Text('Curate'),
                ),
              )),
        ],
      ),
    );
  }
}
