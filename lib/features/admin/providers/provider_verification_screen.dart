import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/phone.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_pill.dart';
import '../admin_repository.dart';
import '../shell/admin_community_context.dart';

const _addProviderCategories = [
  'electrician', 'plumber', 'ac', 'cleaning', 'pest', 'carpenter',
  'painter', 'appliance', 'movers', 'cook', 'maid', 'driver', 'tutor',
];

final verificationQueueProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref.watch(adminRepositoryProvider).providerVerificationQueue());

class ProviderVerificationScreen extends ConsumerWidget {
  const ProviderVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(verificationQueueProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Provider verification')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProviderSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add provider'),
      ),
      body: queueAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(verificationQueueProvider)),
        data: (providers) {
          if (providers.isEmpty) return const EmptyState(icon: Icons.verified_user_outlined, title: 'Nothing to review', message: 'New provider applications will show up here.');
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(TnnSpacing.lg, TnnSpacing.lg, TnnSpacing.lg, 88),
            itemCount: providers.length,
            itemBuilder: (context, i) => _ProviderCard(provider: providers[i]),
          );
        },
      ),
    );
  }
}

void _showAddProviderSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddProviderSheet(),
  );
}

class _AddProviderSheet extends ConsumerStatefulWidget {
  const _AddProviderSheet();

  @override
  ConsumerState<_AddProviderSheet> createState() => _AddProviderSheetState();
}

class _AddProviderSheetState extends ConsumerState<_AddProviderSheet> {
  final _phone = TextEditingController();
  final _businessName = TextEditingController();
  final Set<String> _categories = {};
  bool _autoVerify = true;
  bool _loading = false;

  @override
  void dispose() {
    _phone.dispose();
    _businessName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_phone.text.trim().isEmpty || _businessName.text.trim().isEmpty || _categories.isEmpty) {
      showTnnSnackBar(context, 'Phone, business name, and at least one category are required', isError: true);
      return;
    }
    final communityId = ref.read(selectedCommunityIdProvider);
    if (communityId == null) {
      showTnnSnackBar(context, 'Could not determine your community', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(adminRepositoryProvider).createProvider(
            phone: toStoredPhone(_phone.text),
            businessName: _businessName.text.trim(),
            categories: _categories.toList(),
            communityId: communityId,
            autoVerify: _autoVerify,
          );
      ref.invalidate(verificationQueueProvider);
      if (mounted) {
        showTnnSnackBar(context, 'Provider added${_autoVerify ? ' and verified' : ' — pending review'}');
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: TnnColors.paper, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add a provider directly', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              const Text(
                "Use this for a business that won't self-register — e.g. an in-house vendor you already know.",
                style: TextStyle(color: TnnColors.inkSoft, fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              const Text('Phone *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: TnnColors.inkSoft)),
              const SizedBox(height: 6),
              TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '98480 XXXXX')),
              const SizedBox(height: 14),
              const Text('Business name *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: TnnColors.inkSoft)),
              const SizedBox(height: 6),
              TextField(controller: _businessName, decoration: const InputDecoration(hintText: 'e.g. Ravi Electricals')),
              const SizedBox(height: 14),
              const Text('Categories *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: TnnColors.inkSoft)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _addProviderCategories.map((c) {
                  final selected = _categories.contains(c);
                  return FilterChip(
                    label: Text(c, style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (v) => setState(() => v ? _categories.add(c) : _categories.remove(c)),
                    selectedColor: TnnColors.ink,
                    labelStyle: TextStyle(color: selected ? Colors.white : TnnColors.ink),
                    backgroundColor: TnnColors.card,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mark as verified immediately', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Off leaves it in the review queue like a self-submitted application.', style: TextStyle(fontSize: 11.5)),
                value: _autoVerify,
                activeThumbColor: TnnColors.gold,
                onChanged: (v) => setState(() => _autoVerify = v),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add provider'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderCard extends ConsumerWidget {
  final Map<String, dynamic> provider;
  const _ProviderCard({required this.provider});

  Future<void> _decide(BuildContext context, WidgetRef ref, String state) async {
    String? reason;
    if (state == 'Rejected') {
      reason = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Reason for rejection'),
            content: TextField(controller: controller, autofocus: true),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Confirm')),
            ],
          );
        },
      );
      if (reason == null) return;
    }
    try {
      await ref.read(adminRepositoryProvider).updateProviderVerification(provider['id'] as int, state, reason: reason);
      ref.invalidate(verificationQueueProvider);
      if (context.mounted) showTnnSnackBar(context, 'Marked as $state');
    } catch (e) {
      if (context.mounted) showTnnSnackBar(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = (provider['documents'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(provider['business_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
            StatusPill(status: provider['verification_state'] as String),
          ]),
          const SizedBox(height: 4),
          Wrap(spacing: 6, children: (provider['categories'] as List).map((c) => Chip(label: Text(c.toString(), style: const TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact)).toList()),
          const SizedBox(height: 8),
          Text(documents.isEmpty ? 'No documents submitted yet' : '${documents.length} document(s) submitted', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: TnnColors.brick), onPressed: () => _decide(context, ref, 'Rejected'), child: const Text('Reject'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: () => _decide(context, ref, 'UnderReview'), child: const Text('Request more info'))),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton(onPressed: () => _decide(context, ref, 'Verified'), child: const Text('Verify'))),
          ]),
        ],
      ),
    );
  }
}
