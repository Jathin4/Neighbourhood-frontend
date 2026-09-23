import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_pill.dart';
import '../marketplace_repository.dart';
import 'payment_checkout_sheet.dart';
import 'review_sheet.dart';

final bookingDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>(
  (ref, bookingId) => ref.watch(marketplaceRepositoryProvider).getBookingDetail(bookingId),
);

class BookingDetailScreen extends ConsumerWidget {
  final int bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: detailAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(bookingDetailProvider(bookingId))),
        data: (booking) => _BookingDetailBody(booking: booking, bookingId: bookingId),
      ),
    );
  }
}

class _BookingDetailBody extends ConsumerStatefulWidget {
  final Map<String, dynamic> booking;
  final int bookingId;
  const _BookingDetailBody({required this.booking, required this.bookingId});

  @override
  ConsumerState<_BookingDetailBody> createState() => _BookingDetailBodyState();
}

class _BookingDetailBodyState extends ConsumerState<_BookingDetailBody> {
  bool _busy = false;

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      await ref.read(marketplaceRepositoryProvider).confirmBooking(widget.bookingId);
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      if (mounted) showTnnSnackBar(context, 'Confirmed');
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final category = widget.booking['category_name'] as String? ?? 'this service';
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Cancel this booking?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A cancellation fee may apply once $category has confirmed the slot, per the platform\'s cancellation policy.', style: const TextStyle(fontSize: 12.5, color: TnnColors.inkSoft)),
              const SizedBox(height: 12),
              TextField(controller: controller, decoration: const InputDecoration(hintText: 'Reason for cancelling'), autofocus: true),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: TnnColors.brick),
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Confirm cancellation'),
            ),
          ],
        );
      },
    );
    if (reason == null || reason.isEmpty) return;
    setState(() => _busy = true);
    try {
      final result = await ref.read(marketplaceRepositoryProvider).cancelBooking(widget.bookingId, reason);
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      if (mounted) {
        final fee = result['cancellation_fee_minor'] as int? ?? 0;
        showTnnSnackBar(context, fee > 0 ? 'Cancelled — a ₹${(fee / 100).toStringAsFixed(0)} fee applies' : 'Booking cancelled');
      }
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final status = b['status'] as String;
    final history = (b['status_history'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final payment = b['payment'] as Map<String, dynamic>?;
    final offPlatform = b['off_platform_payment'] as Map<String, dynamic>?;
    final review = b['review'] as Map<String, dynamic>?;
    final df = DateFormat('d MMM, h:mm a');

    final needsConfirm = status == 'Accepted' || status == 'Proposed' || (status == 'InProgress' && b['requires_resident_confirmation'] == true);
    final canCancel = !['Completed', 'Cancelled', 'Rejected'].contains(status);
    final canPay = status == 'Completed' && offPlatform == null && (payment == null || payment['state'] != 'Paid');
    final canReview = status == 'Completed' && review == null;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(bookingDetailProvider(widget.bookingId).future),
      child: ListView(
        padding: const EdgeInsets.all(TnnSpacing.lg),
        children: [
          Row(children: [
            Expanded(child: Text(b['booking_ref'] ?? '', style: Theme.of(context).textTheme.headlineMedium)),
            StatusPill(status: status),
          ]),
          const SizedBox(height: 6),
          Text('${b['provider_name']} · ${b['category_name']}', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(b['description'] ?? '', style: const TextStyle(fontSize: 13)),
          if (b['location'] != null) Text('${b['location']}', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),

          if (offPlatform != null) ...[
            _CashReceiptCard(offPlatform: offPlatform),
            const SizedBox(height: 20),
          ] else if (payment != null) ...[
            _ReceiptCard(payment: payment),
            const SizedBox(height: 20),
          ],

          Text('Status timeline', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          ...history.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.circle, size: 8, color: TnnColors.goldDeep)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${h['to_status']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          if (h['note'] != null) Text('${h['note']}', style: Theme.of(context).textTheme.bodyMedium),
                          Text(df.format(DateTime.parse(h['created_at'] as String).toLocal()), style: const TextStyle(fontSize: 10.5, color: TnnColors.inkSoft)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 12),
          if (needsConfirm)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _confirm,
                child: _busy ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Confirm'),
              ),
            ),
          if (canPay) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => showPaymentCheckoutSheet(context, bookingId: widget.bookingId, budgetMinor: b['budget_minor'] as int?, onDone: () => ref.invalidate(bookingDetailProvider(widget.bookingId))),
                child: const Text('Pay now'),
              ),
            ),
          ],
          if (canReview) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => showReviewSheet(context, bookingId: widget.bookingId, providerName: b['provider_name'] ?? '', onDone: () => ref.invalidate(bookingDetailProvider(widget.bookingId))),
                child: const Text('Rate this service'),
              ),
            ),
          ],
          if (canCancel) ...[
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _busy ? null : _cancel, style: OutlinedButton.styleFrom(foregroundColor: TnnColors.brick), child: const Text('Cancel booking'))),
          ],
        ],
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  const _ReceiptCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final paid = payment['state'] == 'Paid';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: TnnColors.statusSuccessBg, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: const Color(0xFFCBE3D2))),
      child: Row(
        children: [
          Icon(paid ? Icons.receipt_long : Icons.pending_outlined, color: TnnColors.leaf),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(paid ? 'Paid ₹${(payment['amount_minor_units'] / 100).toStringAsFixed(0)}' : 'Payment ${payment['state']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                if (payment['gateway_ref'] != null) Text('Ref: ${payment['gateway_ref']}', style: const TextStyle(fontSize: 11, color: TnnColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CashReceiptCard extends StatelessWidget {
  final Map<String, dynamic> offPlatform;
  const _CashReceiptCard({required this.offPlatform});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: TnnColors.statusSuccessBg, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: const Color(0xFFCBE3D2))),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, color: TnnColors.leaf),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Paid in cash', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                if (offPlatform['note'] != null) Text('${offPlatform['note']}', style: const TextStyle(fontSize: 11, color: TnnColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
