import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/states.dart';
import 'provider_repository.dart';

/// Editable fields apply immediately (operating hours, pricing); changes to
/// business name/categories are critical fields that require admin re-approval
/// per fn_update_provider_profile — the backend flips verification_state back
/// to UnderReview automatically when those are touched.
class ProviderProfileEditScreen extends ConsumerStatefulWidget {
  final int providerId;
  const ProviderProfileEditScreen({super.key, required this.providerId});

  @override
  ConsumerState<ProviderProfileEditScreen> createState() => _ProviderProfileEditScreenState();
}

class _ProviderProfileEditScreenState extends ConsumerState<ProviderProfileEditScreen> {
  final _pricingNotes = TextEditingController();
  bool _loading = false;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      ref.read(myProviderProvider.future).then((p) {
        if (p != null && mounted) {
          setState(() => _pricingNotes.text = (p['pricing_model'] as Map?)?['notes'] as String? ?? '');
        }
      });
    }
  }

  @override
  void dispose() {
    _pricingNotes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(providerRepositoryProvider).updateServiceCatalogue(widget.providerId, {'notes': _pricingNotes.text.trim()});
      if (mounted) showTnnSnackBar(context, 'Catalogue updated');
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerAsync = ref.watch(myProviderProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & catalogue')),
      body: providerAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(myProviderProvider)),
        data: (p) {
          if (p == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(TnnSpacing.lg),
            children: [
              Text('Business name', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(p['business_name'] ?? '', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 2),
              const Text('Changing your name or categories requires admin re-approval.', style: TextStyle(fontSize: 11, color: TnnColors.inkSoft)),
              const SizedBox(height: 20),
              Text('Categories', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 6),
              Wrap(spacing: 6, children: (p['categories'] as List).map((c) => Chip(label: Text(c.toString()))).toList()),
              const SizedBox(height: 20),
              const Text('Pricing / service notes', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: TnnColors.inkSoft)),
              const SizedBox(height: 6),
              TextField(controller: _pricingNotes, maxLines: 4, decoration: const InputDecoration(hintText: 'e.g. Call-out fee ₹150, hourly rate ₹300 after first hour')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
