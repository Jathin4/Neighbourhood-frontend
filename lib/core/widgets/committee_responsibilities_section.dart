import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/shell/admin_community_context.dart';
import '../theme/tokens.dart';
import '../utils/capabilities.dart';

/// Shown on both the resident dashboard and the profile screen for anyone
/// holding committee capabilities — reused so the two stay in sync instead of
/// duplicating the tile-building logic.
class CommitteeResponsibilitiesSection extends ConsumerWidget {
  final List<String> capabilities;
  final int? communityId;
  const CommitteeResponsibilitiesSection({super.key, required this.capabilities, required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (capabilities.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Committee responsibilities', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        ...capabilities.map((cap) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
              child: ListTile(
                title: Text(committeeCapabilityLabels[cap] ?? cap, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: const Text('Granted by your community admin'),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () {
                  if (communityId != null) ref.read(selectedCommunityIdProvider.notifier).state = communityId;
                  final route = committeeCapabilityRoutes[cap];
                  if (route != null) context.push(route);
                },
              ),
            )),
      ],
    );
  }
}
