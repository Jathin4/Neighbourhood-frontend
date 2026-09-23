import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../provider_repository.dart';

/// Lets a Verified provider ask specific communities' admins for permission to
/// serve their residents — fn_rank_providers only surfaces a provider in a
/// community's marketplace once that community's admin has approved this.
final myCommunityRequestsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref.watch(providerRepositoryProvider).myCommunityRequests());

class CoverageAreasScreen extends ConsumerStatefulWidget {
  const CoverageAreasScreen({super.key});

  @override
  ConsumerState<CoverageAreasScreen> createState() => _CoverageAreasScreenState();
}

class _CoverageAreasScreenState extends ConsumerState<CoverageAreasScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>>? _results;
  bool _searching = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    setState(() => _searching = true);
    try {
      final results = await ref.read(providerRepositoryProvider).browseCommunities(search: _search.text.trim());
      setState(() => _results = results);
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _request(Map<String, dynamic> community) async {
    try {
      await ref.read(providerRepositoryProvider).requestServeCommunity(community['id'] as int);
      ref.invalidate(myCommunityRequestsProvider);
      if (mounted) showTnnSnackBar(context, 'Request sent to ${community['name']}');
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(myCommunityRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Coverage areas')),
      body: ListView(
        padding: const EdgeInsets.all(TnnSpacing.lg),
        children: [
          Text('Your requests', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text("Communities you've asked to serve, and their status.", style: TextStyle(color: TnnColors.inkSoft, fontSize: 12.5)),
          const SizedBox(height: 10),
          requestsAsync.when(
            loading: () => const LoadingSkeleton(lines: 2),
            error: (e, _) => Text(e.toString()),
            data: (requests) => requests.isEmpty
                ? const Text('No requests yet — search below to find a community.', style: TextStyle(color: TnnColors.inkSoft, fontSize: 12.5))
                : Column(
                    children: requests.map((r) {
                      final status = r['status'] as String;
                      final color = switch (status) {
                        'Approved' => TnnColors.statusSuccessFg,
                        'Rejected' => TnnColors.statusCriticalFg,
                        _ => TnnColors.statusPendingFg,
                      };
                      final bg = switch (status) {
                        'Approved' => TnnColors.statusSuccessBg,
                        'Rejected' => TnnColors.statusCriticalBg,
                        _ => TnnColors.statusPendingBg,
                      };
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${r['community_name']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                  Text('${r['city']}', style: const TextStyle(color: TnnColors.inkSoft, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(TnnRadius.pill)),
                              child: Text(status, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 26),
          Text('Find a community to serve', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: _search, decoration: const InputDecoration(hintText: 'Search by community or city'), onSubmitted: (_) => _runSearch())),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _searching ? null : _runSearch, child: const Text('Search')),
          ]),
          const SizedBox(height: 14),
          if (_searching) const LoadingSkeleton(lines: 2),
          if (!_searching && _results != null)
            _results!.isEmpty
                ? const Text('No communities match that search.', style: TextStyle(color: TnnColors.inkSoft, fontSize: 12.5))
                : Column(
                    children: _results!.map((c) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${c['name']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                    Text('${c['city']}', style: const TextStyle(color: TnnColors.inkSoft, fontSize: 12)),
                                  ],
                                ),
                              ),
                              OutlinedButton(onPressed: () => _request(c), child: const Text('Request')),
                            ],
                          ),
                        )).toList(),
                  ),
        ],
      ),
    );
  }
}
