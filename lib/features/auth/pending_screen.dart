import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import 'session_controller.dart';
import 'widgets/auth_scaffold.dart';

/// Membership pending / rejected / suspended states — clear messaging + support contact.
class MembershipStatusScreen extends ConsumerWidget {
  const MembershipStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionControllerProvider);
    final accountState = state.accountState;

    final config = switch (accountState) {
      'Rejected' => (
          icon: Icons.block,
          title: 'Membership not approved',
          message: 'Your community admin was unable to verify your membership. Contact your community admin for details.',
        ),
      'Suspended' => (
          icon: Icons.pause_circle_outline,
          title: 'Account suspended',
          message: 'Your account has been temporarily suspended. Contact your community admin to resolve this.',
        ),
      'Deactivated' => (
          icon: Icons.person_off_outlined,
          title: 'Account deactivated',
          message: "This account is deactivated. If this wasn't you, contact support.",
        ),
      _ => (
          icon: Icons.hourglass_top,
          title: 'Verification pending',
          message: "Your community admin is reviewing your request. This usually takes less than a day — we'll notify you once approved.",
        ),
    };

    return AuthScaffold(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, color: TnnColors.gold, size: 42),
            const SizedBox(height: 16),
            Text(config.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontSize: 20), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(config.message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFB9C4DA), fontSize: 13.5, height: 1.5)),
            const SizedBox(height: 26),
            OutlinedButton(
              onPressed: () async {
                await ref.read(sessionControllerProvider.notifier).refreshProfile();
              },
              child: const Text('Check status', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(sessionControllerProvider.notifier).logout();
                if (context.mounted) context.go('/');
              },
              child: const Text('Log out', style: TextStyle(color: Color(0xFF8493AE))),
            ),
          ],
        ),
      ),
    );
  }
}
