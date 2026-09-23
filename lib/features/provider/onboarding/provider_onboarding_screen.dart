import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../provider_repository.dart';

const _availableCategories = [
  'electrician', 'plumber', 'ac', 'cleaning', 'pest', 'carpenter',
  'painter', 'appliance', 'movers', 'cook', 'maid', 'driver', 'tutor',
];

/// Onboarding wizard step 1 (business details + categories). Service area,
/// operating hours, pricing model and document upload are configurable after
/// submission via /providers/me/profile, /providers/me/availability etc. —
/// this screen gets a provider from Draft to Submitted so verification can begin.
class ProviderOnboardingScreen extends ConsumerStatefulWidget {
  const ProviderOnboardingScreen({super.key});

  @override
  ConsumerState<ProviderOnboardingScreen> createState() => _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState extends ConsumerState<ProviderOnboardingScreen> {
  final _businessName = TextEditingController();
  final Set<String> _categories = {};
  bool _loading = false;

  Future<void> _submit() async {
    if (_businessName.text.trim().isEmpty) {
      showTnnSnackBar(context, 'Enter your business name', isError: true);
      return;
    }
    if (_categories.isEmpty) {
      showTnnSnackBar(context, 'Select at least one category you serve', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(providerRepositoryProvider).submitApplication(businessName: _businessName.text.trim(), categories: _categories.toList());
      ref.invalidate(myProviderProvider);
      if (mounted) showTnnSnackBar(context, 'Application submitted — under review');
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider onboarding')),
      body: ListView(
        padding: const EdgeInsets.all(TnnSpacing.lg),
        children: [
          Text('Business details', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text('Tell residents who you are — you can add documents and pricing after this step.', style: TextStyle(color: TnnColors.inkSoft, fontSize: 12.5)),
          const SizedBox(height: 16),
          const Text('Business name', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: TnnColors.inkSoft)),
          const SizedBox(height: 6),
          TextField(controller: _businessName, decoration: const InputDecoration(hintText: 'e.g. Ravi Electricals')),
          const SizedBox(height: 18),
          const Text('Categories you serve', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: TnnColors.inkSoft)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableCategories.map((c) {
              final selected = _categories.contains(c);
              return FilterChip(
                label: Text(c),
                selected: selected,
                onSelected: (v) => setState(() => v ? _categories.add(c) : _categories.remove(c)),
                selectedColor: TnnColors.ink,
                labelStyle: TextStyle(color: selected ? Colors.white : TnnColors.ink, fontSize: 12),
                backgroundColor: TnnColors.card,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit application'),
          ),
        ],
      ),
    );
  }
}
