import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Consistent empty state with a helpful CTA — never a bare "no data".
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 34, color: TnnColors.inkSoft),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Consistent error state with retry — never a silent failure.
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 34, color: TnnColors.brick),
          const SizedBox(height: 12),
          Text('Something went wrong', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: TnnColors.gold, foregroundColor: TnnColors.ink),
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Simple shimmer-free loading skeleton (a set of pulsing bars) for list/detail screens.
class LoadingSkeleton extends StatelessWidget {
  final int lines;
  const LoadingSkeleton({super.key, this.lines = 4});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TnnSpacing.lg),
      child: Column(
        children: List.generate(
          lines,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: TnnSpacing.md),
            child: _Bar(height: i == 0 ? 60 : 44),
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatefulWidget {
  final double height;
  const _Bar({required this.height});

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(TnnColors.lineSoft, TnnColors.line, _controller.value),
          borderRadius: BorderRadius.circular(TnnRadius.md),
        ),
      ),
    );
  }
}

/// Offline/connectivity banner — shown above content, never blocking it.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: TnnColors.statusCriticalBg,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: TnnSpacing.lg),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, size: 15, color: TnnColors.brick),
          SizedBox(width: 8),
          Text("You're offline — showing the last loaded data", style: TextStyle(color: TnnColors.brick, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

void showTnnSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? TnnColors.brick : TnnColors.ink,
    ),
  );
}
