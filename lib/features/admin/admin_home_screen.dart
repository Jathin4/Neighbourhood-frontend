import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/states.dart';
import '../auth/session_controller.dart';
import 'shell/admin_community_context.dart';

/// Admin dashboard home — community switcher + every admin section, grouped
/// under section headers with each section rendered as a grid of compact tiles.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final isPlatformAdmin = session.role == 'platform_admin';
    final communitiesAsync = ref.watch(adminCommunitiesProvider);
    final selectedCommunityId = ref.watch(selectedCommunityIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin dashboard'),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(sessionControllerProvider.notifier).logout();
              if (context.mounted) context.go('/');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: communitiesAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(adminCommunitiesProvider)),
        data: (communities) {
          if (communities.isEmpty) {
            return isPlatformAdmin
                ? Padding(
                    padding: const EdgeInsets.all(TnnSpacing.lg),
                    child: EmptyState(
                      icon: Icons.location_city_outlined,
                      title: 'No communities yet',
                      message: 'Create your first community to get started.',
                      actionLabel: 'Create community',
                      onAction: () => context.push('/admin/community-setup'),
                    ),
                  )
                : const EmptyState(icon: Icons.location_city_outlined, title: 'No community assigned', message: 'Ask a platform admin to grant you committee access.');
          }

          return ListView(
            padding: const EdgeInsets.all(TnnSpacing.lg),
            children: [
              const Text('Managing community', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: TnnColors.inkSoft)),
              const SizedBox(height: 6),
              if (communities.length > 1)
                DropdownButtonFormField<int>(
                  initialValue: selectedCommunityId,
                  items: communities.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text('${c['name']} · ${c['city']}'))).toList(),
                  onChanged: (v) => ref.read(selectedCommunityIdProvider.notifier).state = v,
                )
              else
                Builder(builder: (context) {
                  final c = communities.first;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.lg), border: Border.all(color: TnnColors.lineSoft)),
                    child: Row(
                      children: [
                        const Icon(Icons.location_city_outlined, size: 22, color: TnnColors.ink),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${c['name']}', style: Theme.of(context).textTheme.headlineSmall),
                            Text('${c['city']}', style: const TextStyle(color: TnnColors.inkSoft, fontSize: 12.5)),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 22),
              _TileSection(title: 'Community', items: [
                _NavItem(icon: Icons.location_city_outlined, label: 'Community setup', onTap: () => context.push('/admin/community-setup')),
                _NavItem(icon: Icons.upload_file_outlined, label: 'Bulk import', onTap: () => context.push('/admin/bulk-import')),
                _NavItem(icon: Icons.people_outline, label: 'Residents', onTap: () => context.push('/admin/residents')),
                _NavItem(icon: Icons.how_to_reg_outlined, label: 'Membership requests', onTap: () => context.push('/admin/membership-requests')),
                _NavItem(icon: Icons.badge_outlined, label: 'Committee roles', onTap: () => context.push('/admin/committee-roles')),
              ]),
              const SizedBox(height: 18),
              _TileSection(title: 'Content & engagement', items: [
                _NavItem(icon: Icons.campaign_outlined, label: 'Notice composer', onTap: () => context.push('/admin/notices/new')),
                _NavItem(icon: Icons.assignment_outlined, label: 'Issue board', onTap: () => context.push('/admin/issues')),
                _NavItem(icon: Icons.poll_outlined, label: 'Polls & events', onTap: () => context.push('/admin/polls-events/new')),
              ]),
              const SizedBox(height: 18),
              _TileSection(title: 'Marketplace', items: [
                _NavItem(icon: Icons.verified_user_outlined, label: 'Provider verification', onTap: () => context.push('/admin/providers/verification')),
                _NavItem(icon: Icons.storefront_outlined, label: 'Provider requests', onTap: () => context.push('/admin/providers/community-requests')),
                _NavItem(icon: Icons.star_outline, label: 'Curated providers', onTap: () => context.push('/admin/providers/curated')),
              ]),
              const SizedBox(height: 18),
              _TileSection(title: 'Insights & safety', items: [
                _NavItem(icon: Icons.bar_chart_outlined, label: 'Reports', onTap: () => context.push('/admin/reports')),
                _NavItem(icon: Icons.flag_outlined, label: 'Moderation', onTap: () => context.push('/admin/moderation')),
              ]),
              if (isPlatformAdmin) ...[
                const SizedBox(height: 18),
                _TileSection(title: 'Platform', items: [
                  _NavItem(icon: Icons.settings_suggest_outlined, label: 'Platform admin', onTap: () => context.push('/admin/platform')),
                ]),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.onTap});
}

/// Section header + its items laid out as a wrapping grid of compact square
/// tiles (3 per row), same tile style used everywhere in this dashboard.
class _TileSection extends StatelessWidget {
  final String title;
  final List<_NavItem> items;
  const _TileSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: TnnColors.inkSoft)),
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
          children: items.map((item) => _QuickTile(icon: item.icon, label: item.label, onTap: item.onTap)).toList(),
        ),
      ],
    );
  }
}

/// A compact square tile — the single tile style used for every dashboard action.
class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TnnRadius.lg),
      child: Container(
        decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.lg), border: Border.all(color: TnnColors.lineSoft)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: TnnColors.ink),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
