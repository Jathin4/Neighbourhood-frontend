import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_pill.dart';
import '../resident_repository.dart';
import 'report_issue_sheet.dart';

final myIssuesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref.watch(residentRepositoryProvider).listMyIssues());

class IssuesScreen extends ConsumerWidget {
  const IssuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issuesAsync = ref.watch(myIssuesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My issues')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TnnColors.gold,
        foregroundColor: TnnColors.ink,
        onPressed: () async {
          final created = await showReportIssueSheet(context);
          if (created == true) ref.invalidate(myIssuesProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myIssuesProvider.future),
        child: issuesAsync.when(
          loading: () => ListView(children: const [LoadingSkeleton()]),
          error: (e, _) => ListView(children: [ErrorState(message: e.toString(), onRetry: () => ref.invalidate(myIssuesProvider))]),
          data: (issues) {
            if (issues.isEmpty) {
              return ListView(children: const [
                EmptyState(icon: Icons.checklist_outlined, title: 'No issues yet', message: 'Report a maintenance or community issue and track it here.'),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(TnnSpacing.lg, TnnSpacing.lg, TnnSpacing.lg, 90),
              itemCount: issues.length,
              itemBuilder: (context, i) {
                final issue = issues[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(TnnRadius.md),
                    onTap: () async {
                      await context.push('/issues/${issue['ticket_no']}');
                      ref.invalidate(myIssuesProvider);
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 62,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: const BoxDecoration(color: TnnColors.ink, borderRadius: BorderRadius.only(topLeft: Radius.circular(TnnRadius.md), bottomLeft: Radius.circular(TnnRadius.md))),
                          child: Column(
                            children: [
                              const Text('TICKET', style: TextStyle(color: Colors.white54, fontSize: 8, letterSpacing: 0.5)),
                              const SizedBox(height: 3),
                              Text('#${(issue['ticket_no'] as String).split('-').last}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(issue['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                const SizedBox(height: 3),
                                Text('${issue['category']}', style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 8),
                                StatusPill(status: issue['status'] as String),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
