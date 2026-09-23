import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../resident_repository.dart';

final directoryProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, query) => ref.watch(residentRepositoryProvider).searchDirectory(query: query),
);

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final directoryAsync = ref.watch(directoryProvider(_query));

    return Scaffold(
      appBar: AppBar(title: const Text('Resident directory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(TnnSpacing.lg),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: 'Search by name or tower'),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: directoryAsync.when(
              loading: () => const LoadingSkeleton(),
              error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(directoryProvider(_query))),
              data: (residents) {
                if (residents.isEmpty) {
                  return const EmptyState(icon: Icons.search_off, title: 'No residents found', message: 'Try a different name or tower/block.');
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: TnnSpacing.lg),
                  itemCount: residents.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final r = residents[i];
                    final initials = (r['full_name'] as String? ?? '?').split(' ').where((s) => s.isNotEmpty).take(2).map((s) => s[0]).join();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(backgroundColor: TnnColors.ink, child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 13))),
                      title: Text(r['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      subtitle: Text('${r['tower_name'] ?? ''} · ${r['unit_name'] ?? ''}'),
                      trailing: OutlinedButton(
                        onPressed: () => showTnnSnackBar(context, 'Opens in-app chat — number stays private'),
                        child: const Text('Contact'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
