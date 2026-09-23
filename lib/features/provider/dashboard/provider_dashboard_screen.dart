import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_pill.dart';
import '../../auth/session_controller.dart';
import '../provider_repository.dart';
import '../jobs/job_detail_sheet.dart';

final providerDashboardProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>(
  (ref, providerId) => ref.watch(providerRepositoryProvider).getDashboard(providerId),
);

class ProviderDashboardScreen extends ConsumerWidget {
  final Map<String, dynamic> provider;
  const ProviderDashboardScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerId = provider['id'] as int;
    final dashboardAsync = ref.watch(providerDashboardProvider(providerId));

    return Scaffold(
      appBar: AppBar(
        title: Text(provider['business_name'] ?? 'Dashboard'),
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: TnnColors.ink),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(provider['business_name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ),
            ListTile(leading: const Icon(Icons.dashboard_outlined), title: const Text('Dashboard'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.groups_2_outlined), title: const Text('Staff'), onTap: () => context.push('/provider/staff?provider_id=$providerId')),
            ListTile(leading: const Icon(Icons.calendar_month_outlined), title: const Text('Availability'), onTap: () => context.push('/provider/availability?provider_id=$providerId')),
            ListTile(leading: const Icon(Icons.receipt_long_outlined), title: const Text('Payout history'), onTap: () => context.push('/provider/ledger?provider_id=$providerId')),
            ListTile(leading: const Icon(Icons.star_border), title: const Text('Reviews'), onTap: () => context.push('/provider/reviews?provider_id=$providerId')),
            ListTile(leading: const Icon(Icons.support_agent_outlined), title: const Text('Support'), onTap: () => context.push('/provider/support?provider_id=$providerId')),
            ListTile(leading: const Icon(Icons.map_outlined), title: const Text('Coverage areas'), onTap: () => context.push('/provider/coverage')),
            const Divider(),
            ListTile(leading: const Icon(Icons.storefront_outlined), title: const Text('Edit profile & catalogue'), onTap: () => context.push('/provider/profile?provider_id=$providerId')),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(providerDashboardProvider(providerId).future),
        child: dashboardAsync.when(
          loading: () => ListView(children: const [LoadingSkeleton()]),
          error: (e, _) => ListView(children: [ErrorState(message: e.toString(), onRetry: () => ref.invalidate(providerDashboardProvider(providerId)))]),
          data: (data) {
            final p = data['provider'] as Map<String, dynamic>;
            final leads = (data['leads'] as List?)?.cast<Map<String, dynamic>>() ?? [];
            final upcoming = (data['upcoming_jobs'] as List?)?.cast<Map<String, dynamic>>() ?? [];

            return ListView(
              padding: const EdgeInsets.all(TnnSpacing.lg),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.7,
                  children: [
                    _StatCard(label: 'Leads', value: '${leads.length}'),
                    _StatCard(label: 'Upcoming jobs', value: '${upcoming.length}'),
                    _StatCard(label: 'Completed jobs', value: '${data['completed_jobs_count']}'),
                    _StatCard(label: 'Avg rating', value: '★ ${p['rating_avg']}'),
                    _StatCard(label: 'Earnings (net)', value: '₹${((data['earnings_net_minor'] as int? ?? 0) / 100).toStringAsFixed(0)}'),
                    _StatCard(label: 'Verification', value: p['verification_state'], isStatus: true),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Lead inbox', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                if (leads.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No new leads right now.', style: TextStyle(color: TnnColors.inkSoft, fontSize: 12.5)))
                else
                  ...leads.map((b) => _LeadCard(booking: b, providerId: providerId)),
                const SizedBox(height: 24),
                Text('Upcoming jobs', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                if (upcoming.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Nothing scheduled.', style: TextStyle(color: TnnColors.inkSoft, fontSize: 12.5)))
                else
                  ...upcoming.map((b) => _JobCard(booking: b, providerId: providerId)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isStatus;
  const _StatCard({required this.label, required this.value, this.isStatus = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          isStatus ? StatusPill(status: value) : Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _LeadCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> booking;
  final int providerId;
  const _LeadCard({required this.booking, required this.providerId});

  @override
  ConsumerState<_LeadCard> createState() => _LeadCardState();
}

class _LeadCardState extends ConsumerState<_LeadCard> {
  bool _busy = false;

  Future<void> _respond(String action) async {
    setState(() => _busy = true);
    try {
      await ref.read(providerRepositoryProvider).respondBooking(widget.booking['id'] as int, action: action);
      ref.invalidate(providerDashboardProvider(widget.providerId));
      if (mounted) showTnnSnackBar(context, action == 'accept' ? 'Booking accepted' : 'Booking declined');
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(b['description'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              Text(b['booking_ref'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          _BookingInfoRow(icon: Icons.person_outline, text: (b['resident_name'] as String?)?.isNotEmpty == true ? b['resident_name'] : 'Resident'),
          _BookingInfoRow(icon: Icons.location_on_outlined, text: _addressLine(b)),
          if ((b['preferred_time'] as String?)?.isNotEmpty == true) _BookingInfoRow(icon: Icons.schedule_outlined, text: b['preferred_time']),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: _busy ? null : () => _respond('reject'), child: const Text('Decline'))),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : () => _respond('accept'),
                  child: _busy ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final int providerId;
  const _JobCard({required this.booking, required this.providerId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
      child: ListTile(
        title: Text(
          (booking['resident_name'] as String?)?.isNotEmpty == true ? booking['resident_name'] : (booking['booking_ref'] ?? ''),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          [
            _addressLine(booking),
            (booking['proposed_time'] ?? booking['preferred_time'] ?? '') as String,
          ].where((s) => s.isNotEmpty).join(' · '),
        ),
        trailing: StatusPill(status: booking['status'] as String),
        onTap: () => showJobDetailSheet(context, booking: booking, providerId: providerId),
      ),
    );
  }
}

/// Community · Tower · Unit, skipping any piece that's missing — this is the
/// address a provider actually needs to know where to physically go.
String _addressLine(Map<String, dynamic> b) {
  return [b['community_name'], b['tower_name'], b['unit_name']]
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .join(' · ');
}

class _BookingInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BookingInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: TnnColors.inkSoft),
          const SizedBox(width: 5),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: TnnColors.inkSoft))),
        ],
      ),
    );
  }
}
