import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../marketplace_repository.dart';
import 'services_screen.dart';

const _slots = ['Today, 4–6 PM', 'Tomorrow, 10–12 AM', 'Tomorrow, 3–5 PM'];

Future<void> showBookingSheet(BuildContext context, {required int providerId, required String providerName, String? categoryKey}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BookingSheet(providerId: providerId, providerName: providerName, categoryKey: categoryKey),
  );
}

class _BookingSheet extends ConsumerStatefulWidget {
  final int providerId;
  final String providerName;
  final String? categoryKey;
  const _BookingSheet({required this.providerId, required this.providerName, this.categoryKey});

  @override
  ConsumerState<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<_BookingSheet> {
  final _description = TextEditingController();
  final _budget = TextEditingController();
  String? _slot;
  bool _loading = false;

  @override
  void dispose() {
    _description.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_description.text.trim().isEmpty) {
      showTnnSnackBar(context, 'Describe what you need', isError: true);
      return;
    }
    if (_slot == null) {
      showTnnSnackBar(context, 'Pick a preferred time slot', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final categories = await ref.read(marketplaceRepositoryProvider).listCategories();
      final match = widget.categoryKey == null
          ? null
          : categories.cast<Map<String, dynamic>?>().firstWhere((c) => c?['key'] == widget.categoryKey, orElse: () => null);
      final categoryId = (match ?? (categories.isNotEmpty ? categories.first : null))?['id'] as int?;
      if (categoryId == null) throw Exception('No service categories configured');

      await ref.read(marketplaceRepositoryProvider).createBooking(
            providerId: widget.providerId,
            categoryId: categoryId,
            description: _description.text.trim(),
            preferredTime: _slot,
            budgetMinor: int.tryParse(_budget.text.trim()) != null ? int.parse(_budget.text.trim()) * 100 : null,
          );
      if (mounted) {
        showTnnSnackBar(context, 'Request sent to ${widget.providerName}');
        Navigator.of(context).pop();
        ref.invalidate(myBookingsProvider);
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: TnnColors.line, borderRadius: BorderRadius.circular(99)))),
              const SizedBox(height: 16),
              Text('Book ${widget.providerName}', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('They can accept, decline, or propose another time.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              const Text('Describe what you need', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: TnnColors.inkSoft)),
              const SizedBox(height: 6),
              TextField(controller: _description, maxLines: 3, decoration: const InputDecoration(hintText: 'e.g. Kitchen tap is leaking')),
              const SizedBox(height: 14),
              const Text('Preferred time', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: TnnColors.inkSoft)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _slots.map((s) {
                  final selected = _slot == s;
                  return ChoiceChip(
                    label: Text(s, style: const TextStyle(fontSize: 11.5)),
                    selected: selected,
                    onSelected: (_) => setState(() => _slot = s),
                    selectedColor: TnnColors.ink,
                    labelStyle: TextStyle(color: selected ? Colors.white : TnnColors.ink),
                    backgroundColor: TnnColors.card,
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const Text('Budget (optional, ₹)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: TnnColors.inkSoft)),
              const SizedBox(height: 6),
              TextField(controller: _budget, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'e.g. 500-800')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _send,
                  child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
