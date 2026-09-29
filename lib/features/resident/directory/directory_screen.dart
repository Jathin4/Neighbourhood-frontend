import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../chat/chat_repository.dart';
import '../resident_repository.dart';

final directoryProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, query) => ref.watch(residentRepositoryProvider).searchDirectory(query: query),
);

final directoryUnreadProvider = FutureProvider.autoDispose<Map<int, int>>((ref) async {
  final conversations = await ref.watch(chatRepositoryProvider).listConversations();
  return {for (final c in conversations) c['other_user_id'] as int: c['unread_count'] as int};
});

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
    final unreadByUser = ref.watch(directoryUnreadProvider).valueOrNull ?? const {};

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
                    final phone = r['phone'] as String?;
                    final userId = r['user_id'] as int;
                    final unread = unreadByUser[userId] ?? 0;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(backgroundColor: TnnColors.ink, child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 13))),
                      title: Text(r['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      subtitle: Text('${r['tower_name'] ?? ''} · ${r['unit_name'] ?? ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: phone != null ? 'Call' : 'Number is private',
                            onPressed: phone == null ? null : () => launchUrl(Uri(scheme: 'tel', path: phone)),
                            icon: const Icon(Icons.call_outlined, size: 20),
                            color: TnnColors.ink,
                            disabledColor: TnnColors.inkSoft,
                          ),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                tooltip: 'Chat in-app',
                                onPressed: () async {
                                  await context.push('/chat/$userId?name=${Uri.encodeComponent(r['full_name'] ?? '')}');
                                  ref.invalidate(directoryUnreadProvider);
                                },
                                icon: const Icon(Icons.chat_bubble_outline, size: 19),
                                color: TnnColors.ink,
                              ),
                              if (unread > 0)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    constraints: const BoxConstraints(minWidth: 16),
                                    decoration: const BoxDecoration(color: TnnColors.brick, shape: BoxShape.circle),
                                    child: Text(
                                      '$unread',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
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
