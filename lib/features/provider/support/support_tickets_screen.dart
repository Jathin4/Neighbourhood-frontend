import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_pill.dart';
import '../provider_repository.dart';

final supportTicketsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
  (ref, providerId) => ref.watch(providerRepositoryProvider).listSupportTickets(providerId),
);

class SupportTicketsScreen extends ConsumerWidget {
  final int providerId;
  const SupportTicketsScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(supportTicketsProvider(providerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TnnColors.gold,
        foregroundColor: TnnColors.ink,
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: ticketsAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(supportTicketsProvider(providerId))),
        data: (tickets) {
          if (tickets.isEmpty) return const EmptyState(icon: Icons.support_agent_outlined, title: 'No support tickets', message: 'Raise a dispute or support request here.');
          return ListView.builder(
            padding: const EdgeInsets.all(TnnSpacing.lg),
            itemCount: tickets.length,
            itemBuilder: (context, i) {
              final t = tickets[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(t['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5))),
                      StatusPill(status: t['status'] as String),
                    ]),
                    const SizedBox(height: 4),
                    Text(t['description'] ?? '', style: Theme.of(context).textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final subjectController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New support ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: subjectController, decoration: const InputDecoration(hintText: 'Subject')),
            const SizedBox(height: 10),
            TextField(controller: descController, maxLines: 3, decoration: const InputDecoration(hintText: 'Describe the issue')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(providerRepositoryProvider).createSupportTicket(providerId: providerId, subject: subjectController.text.trim(), description: descController.text.trim());
                ref.invalidate(supportTicketsProvider(providerId));
              } catch (e) {
                if (context.mounted) showTnnSnackBar(context, e.toString(), isError: true);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
