import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';

class CommunityRepository {
  final ApiClient api;
  CommunityRepository(this.api);

  Future<List<Map<String, dynamic>>> listPolls() async {
    final data = await api.get('/polls');
    return (data['items'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> pollResults(int pollId) async => await api.get('/polls/$pollId/results') as Map<String, dynamic>;

  Future<void> vote(int pollId, List<String> optionIds) async => api.post('/polls/$pollId/vote', data: {'option_ids': optionIds});

  Future<List<Map<String, dynamic>>> listEvents() async {
    final data = await api.get('/events');
    return (data['items'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> rsvp(int eventId, String status) async => api.post('/events/$eventId/rsvp', data: {'status': status});
}

final communityRepositoryProvider = Provider<CommunityRepository>((ref) => CommunityRepository(ref.watch(apiClientProvider)));
final pollsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref.watch(communityRepositoryProvider).listPolls());
final eventsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref.watch(communityRepositoryProvider).listEvents());

class PollsEventsScreen extends StatefulWidget {
  final int initialTab;
  const PollsEventsScreen({super.key, this.initialTab = 0});

  @override
  State<PollsEventsScreen> createState() => _PollsEventsScreenState();
}

class _PollsEventsScreenState extends State<PollsEventsScreen> with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Polls & Events'),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Polls'), Tab(text: 'Events')], labelColor: Colors.white, indicatorColor: TnnColors.gold),
      ),
      body: TabBarView(controller: _tabController, children: const [_PollsTab(), _EventsTab()]),
    );
  }
}

class _PollsTab extends ConsumerWidget {
  const _PollsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pollsAsync = ref.watch(pollsProvider);
    return pollsAsync.when(
      loading: () => const LoadingSkeleton(),
      error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(pollsProvider)),
      data: (polls) {
        if (polls.isEmpty) return const EmptyState(icon: Icons.poll_outlined, title: 'No polls right now', message: 'Community polls will show up here.');
        return ListView.builder(
          padding: const EdgeInsets.all(TnnSpacing.lg),
          itemCount: polls.length,
          itemBuilder: (context, i) => _PollCard(poll: polls[i]),
        );
      },
    );
  }
}

class _PollCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> poll;
  const _PollCard({required this.poll});

  @override
  ConsumerState<_PollCard> createState() => _PollCardState();
}

class _PollCardState extends ConsumerState<_PollCard> {
  bool _locallyVoted = false;
  Map<String, dynamic>? _results;
  bool _resultsLoading = false;
  String? _selected;
  bool _loading = false;

  bool get _closed => DateTime.tryParse(widget.poll['end_at'] as String? ?? '')?.isBefore(DateTime.now()) ?? false;
  // Derived from the fetched poll every build, not captured once — same staleness
  // bug class as the notices read-state: this tab's screen never gets disposed
  // while logged in, so a one-time-initialized flag would never reflect a vote
  // that was actually cast in an earlier session.
  bool get _hasVoted => widget.poll['has_voted'] == true || _locallyVoted;

  @override
  void initState() {
    super.initState();
    if (_hasVoted || _closed) _loadResults();
  }

  Future<void> _loadResults() async {
    if (_resultsLoading || _results != null) return;
    setState(() => _resultsLoading = true);
    try {
      final results = await ref.read(communityRepositoryProvider).pollResults(widget.poll['id'] as int);
      if (mounted) setState(() => _results = results);
    } catch (_) {
      // Non-critical — the card still shows the question even if results fail to load.
    } finally {
      if (mounted) setState(() => _resultsLoading = false);
    }
  }

  Future<void> _vote() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(communityRepositoryProvider).vote(widget.poll['id'] as int, [_selected!]);
      final results = await ref.read(communityRepositoryProvider).pollResults(widget.poll['id'] as int);
      setState(() {
        _locallyVoted = true;
        _results = results;
      });
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = (widget.poll['options'] as List).cast<Map<String, dynamic>>();
    final showResults = _hasVoted || _closed;
    if (showResults && _results == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.poll['question'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 10),
            const Center(child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))),
          ],
        ),
      );
    }
    final totalVotes = _results?.values.fold<int>(0, (sum, v) => sum + (v as int)) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.poll['question'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          if (_closed) const Padding(padding: EdgeInsets.only(top: 4), child: Text('Poll closed', style: TextStyle(fontSize: 11, color: TnnColors.inkSoft))),
          const SizedBox(height: 10),
          ...options.map((o) {
            final count = _results?[o['id']] as int? ?? 0;
            final pct = totalVotes > 0 ? count / totalVotes : 0.0;
            if (showResults) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(o['label'], style: const TextStyle(fontSize: 12.5)), Text('$count', style: const TextStyle(fontSize: 11, color: TnnColors.inkSoft))]),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: TnnColors.lineSoft, color: TnnColors.gold),
                    ),
                  ],
                ),
              );
            }
            return RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(o['label'], style: const TextStyle(fontSize: 12.5)),
              value: o['id'],
              groupValue: _selected,
              activeColor: TnnColors.gold,
              onChanged: (v) => setState(() => _selected = v),
            );
          }),
          if (!showResults) ...[
            const SizedBox(height: 6),
            ElevatedButton(
              onPressed: _loading ? null : _vote,
              child: _loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Vote'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EventsTab extends ConsumerWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    return eventsAsync.when(
      loading: () => const LoadingSkeleton(),
      error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(eventsProvider)),
      data: (events) {
        if (events.isEmpty) return const EmptyState(icon: Icons.event_outlined, title: 'No upcoming events', message: 'Community events will show up here.');
        final df = DateFormat('EEE, d MMM · h:mm a');
        return ListView.builder(
          padding: const EdgeInsets.all(TnnSpacing.lg),
          itemCount: events.length,
          itemBuilder: (context, i) {
            final e = events[i];
            final going = e['going_count'] as int? ?? 0;
            final capacity = e['capacity'] as int?;
            final myRsvp = e['my_rsvp'] as String?;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(df.format(DateTime.parse(e['date_time'] as String).toLocal()), style: Theme.of(context).textTheme.bodyMedium),
                  if (e['location'] != null) Text('${e['location']}', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Text(capacity != null ? '$going/$capacity going' : '$going going', style: const TextStyle(fontSize: 11.5, color: TnnColors.goldDeep, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await ref.read(communityRepositoryProvider).rsvp(e['id'] as int, myRsvp == 'Going' ? 'NotGoing' : 'Going');
                            ref.invalidate(eventsProvider);
                          },
                          child: Text(myRsvp == 'Going' ? "You're going ✓" : 'RSVP'),
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
    );
  }
}
