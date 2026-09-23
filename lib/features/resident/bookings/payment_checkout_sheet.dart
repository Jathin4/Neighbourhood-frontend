import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../marketplace_repository.dart';

/// Amount breakdown -> method selection -> either a gateway checkout hand-off,
/// or a "pay with cash" record for jobs settled hand-to-hand with the provider
/// (tracked via fn_record_off_platform_payment, not run through the gateway —
/// visible to admins in reporting so cash jobs aren't silently invisible).
Future<void> showPaymentCheckoutSheet(BuildContext context, {required int bookingId, int? budgetMinor, required VoidCallback onDone}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaymentCheckoutSheet(bookingId: bookingId, budgetMinor: budgetMinor, onDone: onDone),
  );
}

class _PaymentCheckoutSheet extends ConsumerStatefulWidget {
  final int bookingId;
  final int? budgetMinor;
  final VoidCallback onDone;
  const _PaymentCheckoutSheet({required this.bookingId, this.budgetMinor, required this.onDone});

  @override
  ConsumerState<_PaymentCheckoutSheet> createState() => _PaymentCheckoutSheetState();
}

class _PaymentCheckoutSheetState extends ConsumerState<_PaymentCheckoutSheet> {
  late final _amountController = TextEditingController(text: widget.budgetMinor != null ? (widget.budgetMinor! / 100).toStringAsFixed(0) : '');
  String _method = 'gateway';
  bool _loading = false;
  Map<String, dynamic>? _result;
  bool _cashResult = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int get _platformFeeMinor => ((int.tryParse(_amountController.text) ?? 0) * 100 * 0.15).round();
  int get _amountMinor => (int.tryParse(_amountController.text) ?? 0) * 100;

  Future<void> _pay() async {
    if (_amountMinor <= 0) {
      showTnnSnackBar(context, 'Enter a valid amount', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      if (_method == 'cash') {
        await ref.read(marketplaceRepositoryProvider).recordOffPlatformPayment(
              widget.bookingId,
              'Paid in cash — ₹${_amountController.text}',
            );
        setState(() {
          _cashResult = true;
          _result = const {};
        });
      } else {
        final result = await ref.read(marketplaceRepositoryProvider).initiatePayment(widget.bookingId, _amountMinor);
        setState(() => _result = result);
      }
      widget.onDone();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _result == null ? _buildForm(context) : _buildResult(context),
        ),
      ),
    );
  }

  List<Widget> _buildForm(BuildContext context) {
    return [
      Text('Pay for this service', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 16),
      const Text('Amount (₹)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: TnnColors.inkSoft)),
      const SizedBox(height: 6),
      TextField(controller: _amountController, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixText: '₹ ')),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
        child: Column(
          children: [
            _row('Amount', '₹${_amountController.text.isEmpty ? '0' : _amountController.text}'),
            const SizedBox(height: 6),
            _row('Platform fee (included)', '₹${(_platformFeeMinor / 100).toStringAsFixed(0)}', muted: true),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Text('Payment method', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: TnnColors.inkSoft)),
      const SizedBox(height: 8),
      _methodOption(value: 'gateway', icon: Icons.credit_card, label: 'Card / UPI / Netbanking (Razorpay)'),
      const SizedBox(height: 8),
      _methodOption(value: 'cash', icon: Icons.payments_outlined, label: 'Pay with cash', subtitle: 'Settle directly with the provider — we just keep a record.'),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _pay,
          child: _loading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_method == 'cash' ? 'Confirm cash payment' : 'Proceed to pay'),
        ),
      ),
    ];
  }

  Widget _methodOption({required String value, required IconData icon, required String label, String? subtitle}) {
    final selected = _method == value;
    return InkWell(
      onTap: () => setState(() => _method = value),
      borderRadius: BorderRadius.circular(TnnRadius.md),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TnnColors.card,
          borderRadius: BorderRadius.circular(TnnRadius.md),
          border: Border.all(color: selected ? TnnColors.gold : TnnColors.lineSoft, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? TnnColors.goldDeep : TnnColors.ink),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12.5)),
                  if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 11, color: TnnColors.inkSoft)),
                ],
              ),
            ),
            Radio<String>(value: value, groupValue: _method, activeColor: TnnColors.gold, onChanged: (v) => setState(() => _method = v ?? _method)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResult(BuildContext context) {
    if (_cashResult) {
      return [
        const Icon(Icons.payments_outlined, size: 40, color: TnnColors.leaf),
        const SizedBox(height: 14),
        Text('Marked as paid in cash', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          "We've recorded that this job was settled directly with the provider. This doesn't go through the platform gateway, so it won't count toward the provider's platform earnings — just a transparent record for both sides.",
          style: TextStyle(color: TnnColors.inkSoft, fontSize: 12.5, height: 1.5),
        ),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))),
      ];
    }

    final checkout = _result!['checkout'] as Map<String, dynamic>?;
    final gatewayConfigured = checkout == null || checkout['error'] != 'gateway_not_configured';

    return [
      Icon(gatewayConfigured ? Icons.check_circle_outline : Icons.info_outline, size: 40, color: gatewayConfigured ? TnnColors.leaf : TnnColors.goldDeep),
      const SizedBox(height: 14),
      Text(gatewayConfigured ? 'Redirecting to checkout…' : 'Payment request created', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text(
        gatewayConfigured
            ? 'Complete the payment in the gateway window that opens.'
            : "The payment record was created (Pending) but the live payment gateway isn't configured in this environment yet — this is expected in dev/demo, not an error.",
        style: const TextStyle(color: TnnColors.inkSoft, fontSize: 12.5, height: 1.5),
      ),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))),
    ];
  }

  Widget _row(String label, String value, {bool muted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: muted ? TnnColors.inkSoft : TnnColors.ink)),
        Text(value, style: TextStyle(fontSize: 12.5, fontWeight: muted ? FontWeight.w400 : FontWeight.w700, color: muted ? TnnColors.inkSoft : TnnColors.ink)),
      ],
    );
  }
}
