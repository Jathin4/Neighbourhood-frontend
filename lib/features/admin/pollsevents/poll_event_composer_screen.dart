import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../admin_repository.dart';
import '../shell/admin_community_context.dart';

class PollEventComposerScreen extends ConsumerStatefulWidget {
  const PollEventComposerScreen({super.key});

  @override
  ConsumerState<PollEventComposerScreen> createState() => _PollEventComposerScreenState();
}

class _PollEventComposerScreenState extends ConsumerState<PollEventComposerScreen> with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create poll or event'),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Poll'), Tab(text: 'Event')], labelColor: Colors.white, indicatorColor: TnnColors.gold),
      ),
      body: TabBarView(controller: _tabController, children: const [_PollForm(), _EventForm()]),
    );
  }
}

class _PollForm extends ConsumerStatefulWidget {
  const _PollForm();

  @override
  ConsumerState<_PollForm> createState() => _PollFormState();
}

class _PollFormState extends ConsumerState<_PollForm> {
  final _question = TextEditingController();
  final List<TextEditingController> _options = [TextEditingController(), TextEditingController()];
  DateTime? _endAt;
  bool _anonymous = false;
  bool _loading = false;

  Future<void> _submit() async {
    final communityId = ref.read(selectedCommunityIdProvider);
    final options = _options.where((c) => c.text.trim().isNotEmpty).toList();
    if (communityId == null || _question.text.trim().isEmpty || options.length < 2 || _endAt == null) {
      showTnnSnackBar(context, 'Fill in a question, at least 2 options, and an end date', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(adminRepositoryProvider).createPoll(
            communityId: communityId,
            question: _question.text.trim(),
            options: options.asMap().entries.map((e) => {'id': 'opt${e.key}', 'label': e.value.text.trim()}).toList(),
            endAt: _endAt!.toUtc().toIso8601String(),
            isAnonymous: _anonymous,
          );
      if (mounted) {
        showTnnSnackBar(context, 'Poll created');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(TnnSpacing.lg),
      children: [
        TextField(controller: _question, decoration: const InputDecoration(hintText: 'Poll question')),
        const SizedBox(height: 12),
        ..._options.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(controller: e.value, decoration: InputDecoration(hintText: 'Option ${e.key + 1}')),
            )),
        TextButton.icon(onPressed: () => setState(() => _options.add(TextEditingController())), icon: const Icon(Icons.add, size: 16), label: const Text('Add option')),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Anonymous voting'),
          value: _anonymous,
          activeThumbColor: TnnColors.gold,
          onChanged: (v) => setState(() => _anonymous = v),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_endAt == null ? 'Pick an end date' : 'Ends ${DateFormat('d MMM yyyy, h:mm a').format(_endAt!)}'),
          trailing: const Icon(Icons.calendar_today, size: 16),
          onTap: () async {
            final date = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 3)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
            if (date != null) setState(() => _endAt = date);
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create poll'),
        ),
      ],
    );
  }
}

class _EventForm extends ConsumerStatefulWidget {
  const _EventForm();

  @override
  ConsumerState<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends ConsumerState<_EventForm> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _capacity = TextEditingController();
  DateTime? _dateTime;
  bool _loading = false;

  Future<void> _submit() async {
    final communityId = ref.read(selectedCommunityIdProvider);
    if (communityId == null || _title.text.trim().isEmpty || _dateTime == null) {
      showTnnSnackBar(context, 'Fill in a title and date/time', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(adminRepositoryProvider).createEvent(
            communityId: communityId,
            title: _title.text.trim(),
            dateTime: _dateTime!.toUtc().toIso8601String(),
            location: _location.text.trim(),
            capacity: int.tryParse(_capacity.text.trim()),
          );
      if (mounted) {
        showTnnSnackBar(context, 'Event created');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(TnnSpacing.lg),
      children: [
        TextField(controller: _title, decoration: const InputDecoration(hintText: 'Event title')),
        const SizedBox(height: 10),
        TextField(controller: _location, decoration: const InputDecoration(hintText: 'Location')),
        const SizedBox(height: 10),
        TextField(controller: _capacity, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Capacity (optional)')),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_dateTime == null ? 'Pick date & time' : DateFormat('d MMM yyyy, h:mm a').format(_dateTime!)),
          trailing: const Icon(Icons.calendar_today, size: 16),
          onTap: () async {
            final date = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
            if (date == null) return;
            final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
            if (time == null) return;
            setState(() => _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create event'),
        ),
      ],
    );
  }
}
