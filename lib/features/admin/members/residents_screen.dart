import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/phone.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_pill.dart';
import '../admin_repository.dart';
import '../shell/admin_community_context.dart';

/// Full resident directory for the selected community — every resident, not
/// just the ones matching a committee-role search.
final residentsListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final communityId = ref.watch(selectedCommunityIdProvider);
  if (communityId == null) return Future.value([]);
  return ref.watch(adminRepositoryProvider).searchResidents(communityId);
});

class ResidentsScreen extends ConsumerStatefulWidget {
  const ResidentsScreen({super.key});

  @override
  ConsumerState<ResidentsScreen> createState() => _ResidentsScreenState();
}

class _ResidentsScreenState extends ConsumerState<ResidentsScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final residentsAsync = ref.watch(residentsListProvider);
    final q = _query.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Residents')),
      body: residentsAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(residentsListProvider)),
        data: (residents) {
          final filtered = q.isEmpty
              ? residents
              : residents.where((r) {
                  final name = (r['full_name'] as String? ?? '').toLowerCase();
                  final phone = (r['phone'] as String? ?? '').toLowerCase();
                  return name.contains(q) || phone.contains(q);
                }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(TnnSpacing.lg, TnnSpacing.lg, TnnSpacing.lg, 0),
                child: TextField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: q.isEmpty ? null : IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(_query.clear)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(TnnSpacing.lg, 10, TnnSpacing.lg, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${filtered.length} resident${filtered.length == 1 ? '' : 's'}', style: const TextStyle(color: TnnColors.inkSoft, fontSize: 12.5)),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(icon: Icons.people_outline, title: 'No residents found', message: 'Try a different search, or check back once bulk import / self sign-ups land.')
                    : ListView.builder(
                        padding: const EdgeInsets.all(TnnSpacing.lg),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => _ResidentCard(resident: filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResidentCard extends StatelessWidget {
  final Map<String, dynamic> resident;
  const _ResidentCard({required this.resident});

  @override
  Widget build(BuildContext context) {
    final name = resident['full_name'] as String? ?? '';
    final phone = displayPhone(resident['phone'] as String?);
    final tower = resident['tower_name'] as String?;
    final unit = resident['unit_name'] as String?;
    final relationship = resident['household_relationship'] as String?;
    final email = resident['email'] as String?;
    final createdAt = DateTime.tryParse(resident['created_at']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 20, backgroundColor: TnnColors.ink, child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(phone, style: const TextStyle(color: TnnColors.inkSoft, fontSize: 12.5)),
                  ],
                ),
              ),
              StatusPill(status: (resident['account_state'] as String?) ?? 'Pending'),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              if (tower != null || unit != null) _detail(Icons.location_city_outlined, '$tower${unit != null ? ' · $unit' : ''}'),
              if (relationship != null) _detail(Icons.home_outlined, relationship),
              if (email != null && email.isNotEmpty) _detail(Icons.mail_outline, email),
              if (createdAt != null) _detail(Icons.event_outlined, 'Joined ${DateFormat('d MMM yyyy').format(createdAt)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: TnnColors.inkSoft),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: TnnColors.inkSoft)),
      ],
    );
  }
}
