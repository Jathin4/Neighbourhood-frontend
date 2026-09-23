import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../../auth/session_controller.dart';
import '../home_shell.dart';
import '../resident_repository.dart';

final dashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) => ref.watch(residentRepositoryProvider).getDashboard());

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final profile = ref.watch(sessionControllerProvider).profile;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: dashboardAsync.when(
          loading: () => ListView(children: const [LoadingSkeleton(lines: 5)]),
          error: (e, _) => ListView(children: [ErrorState(message: e.toString(), onRetry: () => ref.invalidate(dashboardProvider))]),
          data: (data) => _DashboardBody(data: data, profile: profile),
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic>? profile;
  const _DashboardBody({required this.data, this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final community = data['community'] as Map<String, dynamic>?;
    final critical = data['critical_notice'] as Map<String, dynamic>?;
    final unread = data['unread_notice_count'] as int? ?? 0;
    final openIssues = data['open_issue_count'] as int? ?? 0;
    final event = data['upcoming_event'] as Map<String, dynamic>?;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          decoration: const BoxDecoration(color: TnnColors.ink, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${community?['name'] ?? ''} · ${community?['tower'] ?? ''}'.toUpperCase(),
                        style: const TextStyle(color: Color(0xFFB9C4DA), fontSize: 11.5, letterSpacing: 0.3)),
                    const SizedBox(height: 3),
                    Text('$greeting, ${(data['resident_name'] as String?)?.split(' ').first ?? ''}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontSize: 20)),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: TnnColors.gold,
                child: Text(
                  ((data['resident_name'] as String?)?.isNotEmpty == true ? (data['resident_name'] as String)[0] : '?'),
                  style: const TextStyle(color: TnnColors.ink, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        if (critical != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: GestureDetector(
              onTap: () => ref.read(residentTabIndexProvider.notifier).state = 1,
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: TnnColors.statusCriticalBg,
                  border: Border.all(color: const Color(0xFFEAD0C4)),
                  borderRadius: BorderRadius.circular(TnnRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 7, height: 7, margin: const EdgeInsets.only(top: 6, right: 9), decoration: const BoxDecoration(color: TnnColors.brick, shape: BoxShape.circle)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(critical['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(critical['preview'] ?? '', style: Theme.of(context).textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
            children: [
              _QuickLink(icon: Icons.description_outlined, label: 'Notices', onTap: () => ref.read(residentTabIndexProvider.notifier).state = 1),
              _QuickLink(icon: Icons.warning_amber_outlined, label: 'Report issue', onTap: () => ref.read(residentTabIndexProvider.notifier).state = 2),
              _QuickLink(icon: Icons.build_outlined, label: 'Services', onTap: () => ref.read(residentTabIndexProvider.notifier).state = 3),
              _QuickLink(icon: Icons.groups_outlined, label: 'Directory', onTap: () => context.push('/directory')),
              _QuickLink(icon: Icons.poll_outlined, label: 'Polls & Events', onTap: () => context.push('/community/polls-events')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              _SummaryCard(
                title: 'Notices',
                subtitle: unread == 0 ? 'All caught up' : '$unread unread',
                badge: unread > 0 ? '$unread' : null,
                onTap: () => ref.read(residentTabIndexProvider.notifier).state = 1,
              ),
              const SizedBox(height: 10),
              _SummaryCard(
                title: 'My open issues',
                subtitle: openIssues == 0 ? 'Nothing open right now' : '$openIssues in progress',
                badge: openIssues > 0 ? '$openIssues' : null,
                badgeColor: TnnColors.goldDeep,
                onTap: () => ref.read(residentTabIndexProvider.notifier).state = 2,
              ),
              const SizedBox(height: 10),
              _SummaryCard(
                title: 'Upcoming event',
                subtitle: event != null ? '${event['title']}' : 'No events scheduled',
                trailing: event != null ? 'RSVP' : null,
                onTap: () => context.push('/community/polls-events?tab=events'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickLink({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TnnRadius.lg),
      child: Container(
        decoration: BoxDecoration(color: TnnColors.card, border: Border.all(color: TnnColors.lineSoft), borderRadius: BorderRadius.circular(TnnRadius.lg)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: TnnColors.ink),
            const SizedBox(height: 7),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final String? trailing;
  final Color badgeColor;
  final VoidCallback onTap;
  const _SummaryCard({required this.title, required this.subtitle, this.badge, this.trailing, this.badgeColor = TnnColors.ink, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TnnRadius.lg),
      child: Container(
        decoration: BoxDecoration(color: TnnColors.card, border: Border.all(color: TnnColors.lineSoft), borderRadius: BorderRadius.circular(TnnRadius.lg)),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(TnnRadius.pill)),
                child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            if (trailing != null) Text(trailing!, style: const TextStyle(color: TnnColors.goldDeep, fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
