import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../provider_repository.dart';

final availabilityProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>(
  (ref, providerId) => ref.watch(providerRepositoryProvider).getAvailability(providerId),
);

const _days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
const _dayLabels = {'mon': 'Monday', 'tue': 'Tuesday', 'wed': 'Wednesday', 'thu': 'Thursday', 'fri': 'Friday', 'sat': 'Saturday', 'sun': 'Sunday'};

class AvailabilityScreen extends ConsumerWidget {
  final int providerId;
  const AvailabilityScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availabilityAsync = ref.watch(availabilityProvider(providerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Availability')),
      body: availabilityAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(availabilityProvider(providerId))),
        data: (data) => _AvailabilityBody(providerId: providerId, initial: data),
      ),
    );
  }
}

class _AvailabilityBody extends ConsumerStatefulWidget {
  final int providerId;
  final Map<String, dynamic> initial;
  const _AvailabilityBody({required this.providerId, required this.initial});

  @override
  ConsumerState<_AvailabilityBody> createState() => _AvailabilityBodyState();
}

class _AvailabilityBodyState extends ConsumerState<_AvailabilityBody> {
  late Map<String, bool> _dayEnabled = {
    for (final d in _days) d: ((widget.initial['weekly_schedule'] as Map?)?[d] as List?)?.isNotEmpty == true,
  };
  late List<DateTime> _blackoutDates = ((widget.initial['blackout_dates'] as List?) ?? [])
      .map((d) => DateTime.tryParse(d.toString()))
      .whereType<DateTime>()
      .toList();
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final schedule = {for (final d in _days) d: _dayEnabled[d] == true ? [['09:00', '18:00']] : []};
      await ref.read(providerRepositoryProvider).updateAvailability(
            widget.providerId,
            weeklySchedule: schedule,
            blackoutDates: _blackoutDates.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList(),
          );
      ref.invalidate(availabilityProvider(widget.providerId));
      if (mounted) showTnnSnackBar(context, 'Availability updated');
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addBlackoutDate() async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (picked != null) setState(() => _blackoutDates.add(picked));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(TnnSpacing.lg),
      children: [
        Text('Weekly schedule', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        const Text('Toggle the days you take bookings (9 AM – 6 PM).', style: TextStyle(color: TnnColors.inkSoft, fontSize: 12.5)),
        const SizedBox(height: 10),
        ..._days.map((d) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(_dayLabels[d]!),
              value: _dayEnabled[d] ?? false,
              activeThumbColor: TnnColors.gold,
              onChanged: (v) => setState(() => _dayEnabled[d] = v),
            )),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Blackout dates', style: Theme.of(context).textTheme.headlineSmall),
            TextButton.icon(onPressed: _addBlackoutDate, icon: const Icon(Icons.add, size: 16), label: const Text('Add')),
          ],
        ),
        if (_blackoutDates.isEmpty) const Text('No blackout dates set.', style: TextStyle(color: TnnColors.inkSoft, fontSize: 12.5)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _blackoutDates.map((d) => Chip(
                label: Text(DateFormat('d MMM yyyy').format(d)),
                onDeleted: () => setState(() => _blackoutDates.remove(d)),
              )).toList(),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save availability'),
        ),
      ],
    );
  }
}
