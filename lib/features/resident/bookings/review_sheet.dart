import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../marketplace_repository.dart';

Future<void> showReviewSheet(BuildContext context, {required int bookingId, required String providerName, required VoidCallback onDone}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReviewSheet(bookingId: bookingId, providerName: providerName, onDone: onDone),
  );
}

class _ReviewSheet extends ConsumerStatefulWidget {
  final int bookingId;
  final String providerName;
  final VoidCallback onDone;
  const _ReviewSheet({required this.bookingId, required this.providerName, required this.onDone});

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  int _rating = 0;
  final _text = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      showTnnSnackBar(context, 'Tap a star to rate', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(marketplaceRepositoryProvider).submitReview(widget.bookingId, rating: _rating, text: _text.text.trim());
      widget.onDone();
      if (mounted) {
        showTnnSnackBar(context, 'Thanks for your feedback!');
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rate ${widget.providerName}', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(filled ? Icons.star : Icons.star_border, color: TnnColors.gold, size: 32),
                );
              }),
            ),
            const SizedBox(height: 8),
            TextField(controller: _text, maxLines: 3, decoration: const InputDecoration(hintText: 'Tell us about the experience (optional)')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
