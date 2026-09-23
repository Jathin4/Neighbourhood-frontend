import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_pill.dart';
import '../provider_repository.dart';
import '../dashboard/provider_dashboard_screen.dart';

Future<void> showJobDetailSheet(BuildContext context, {required Map<String, dynamic> booking, required int providerId}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _JobDetailSheet(booking: booking, providerId: providerId),
  );
}

class _JobDetailSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> booking;
  final int providerId;
  const _JobDetailSheet({required this.booking, required this.providerId});

  @override
  ConsumerState<_JobDetailSheet> createState() => _JobDetailSheetState();
}

class _JobDetailSheetState extends ConsumerState<_JobDetailSheet> {
  bool _busy = false;

  Future<void> _complete() async {
    setState(() => _busy = true);
    try {
      await ref.read(providerRepositoryProvider).completeBooking(widget.booking['id'] as int);
      ref.invalidate(providerDashboardProvider(widget.providerId));
      if (mounted) {
        showTnnSnackBar(context, 'Marked complete');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Cancel this job'),
          content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Reason for cancelling'), autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
            FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Cancel job')),
          ],
        );
      },
    );
    if (reason == null || reason.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(providerRepositoryProvider).cancelBooking(widget.booking['id'] as int, reason);
      ref.invalidate(providerDashboardProvider(widget.providerId));
      if (mounted) {
        showTnnSnackBar(context, 'Job cancelled');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final status = b['status'] as String;
    final canComplete = status == 'Confirmed' || status == 'InProgress';
    final canCancel = !['Completed', 'Cancelled', 'Rejected'].contains(status);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: TnnColors.paper, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(b['booking_ref'] ?? '', style: Theme.of(context).textTheme.headlineMedium)),
              StatusPill(status: status),
            ]),
            const SizedBox(height: 10),
            Text(b['description'] ?? '', style: const TextStyle(fontSize: 13.5)),
            const SizedBox(height: 12),
            _DetailRow(icon: Icons.person_outline, label: 'Resident', value: (b['resident_name'] as String?)?.isNotEmpty == true ? b['resident_name'] : 'Not provided'),
            _DetailRow(icon: Icons.location_city_outlined, label: 'Address', value: _jobAddress(b)),
            if ((b['location'] as String?)?.isNotEmpty == true) _DetailRow(icon: Icons.pin_drop_outlined, label: 'Landmark', value: b['location']),
            if ((b['proposed_time'] ?? b['preferred_time']) != null)
              _DetailRow(icon: Icons.schedule_outlined, label: 'Slot', value: b['proposed_time'] ?? b['preferred_time']),
            if (b['budget_minor'] != null) _DetailRow(icon: Icons.currency_rupee, label: 'Budget', value: '₹${(b['budget_minor'] / 100).toStringAsFixed(0)}'),
            const SizedBox(height: 20),
            if (canComplete)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _complete,
                  child: _busy ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Mark complete'),
                ),
              ),
            if (canCancel) ...[
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _busy ? null : _cancel, child: const Text('Cancel job'))),
            ],
          ],
        ),
      ),
    );
  }
}

String _jobAddress(Map<String, dynamic> b) {
  final parts = [b['community_name'], b['tower_name'], b['unit_name']].whereType<String>().where((s) => s.isNotEmpty).toList();
  return parts.isEmpty ? 'Not provided' : parts.join(' · ');
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: TnnColors.inkSoft),
          const SizedBox(width: 8),
          SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 12, color: TnnColors.inkSoft))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
