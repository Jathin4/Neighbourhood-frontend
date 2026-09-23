import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Maps every lifecycle status string (issues, bookings, provider verification,
/// payments) used across the app to one consistent visual language, so the same
/// status always reads the same way wherever it appears.
class StatusPill extends StatelessWidget {
  final String status;
  const StatusPill({super.key, required this.status});

  static const _success = {
    'resolved', 'verified', 'completed', 'confirmed', 'accepted', 'active', 'paid', 'approved', 'going'
  };
  static const _pending = {
    'acknowledged', 'assigned', 'inprogress', 'in progress', 'requested', 'pending', 'submitted',
    'proposed', 'underreview', 'under review', 'draft'
  };
  static const _critical = {
    'critical', 'rejected', 'suspended', 'failed', 'cancelled', 'reopened', 'overdue'
  };

  @override
  Widget build(BuildContext context) {
    final key = status.toLowerCase();
    Color bg, fg;
    if (_success.contains(key)) {
      bg = TnnColors.statusSuccessBg;
      fg = TnnColors.statusSuccessFg;
    } else if (_pending.contains(key)) {
      bg = TnnColors.statusPendingBg;
      fg = TnnColors.statusPendingFg;
    } else if (_critical.contains(key)) {
      bg = TnnColors.statusCriticalBg;
      fg = TnnColors.statusCriticalFg;
    } else {
      bg = TnnColors.statusNeutralBg;
      fg = TnnColors.statusNeutralFg;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(TnnRadius.pill)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.3),
      ),
    );
  }
}

/// A consistent "✓ Verified" badge for providers — appears identically in search
/// results, profile, and booking confirmation per the trust-signal requirement.
class VerifiedBadge extends StatelessWidget {
  final bool verified;
  const VerifiedBadge({super.key, this.verified = true});

  @override
  Widget build(BuildContext context) {
    if (!verified) return const SizedBox.shrink();
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, size: 13, color: TnnColors.leaf),
        SizedBox(width: 3),
        Text('Verified', style: TextStyle(color: TnnColors.leaf, fontSize: 11.5, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

/// Labels a promoted/paid provider listing — never silent, per the no-dark-patterns rule.
class PromotedLabel extends StatelessWidget {
  const PromotedLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: TnnColors.lineSoft,
        borderRadius: BorderRadius.circular(TnnRadius.sm),
      ),
      child: const Text('PROMOTED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: TnnColors.inkSoft, letterSpacing: 0.4)),
    );
  }
}
