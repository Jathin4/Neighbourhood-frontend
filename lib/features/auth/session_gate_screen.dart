import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import 'session_controller.dart';

/// A brief transitional screen that inspects session state and routes the user
/// to the right place: phone entry, profile setup, community match / pending,
/// or the resident home shell. Used as the initial route and again right after
/// OTP verification.
class SessionGateScreen extends ConsumerWidget {
  const SessionGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionControllerProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      switch (state.status) {
        case SessionStatus.loading:
          return;
        case SessionStatus.unauthenticated:
          context.go('/auth/phone');
          return;
        case SessionStatus.authenticated:
          if (state.role == 'provider' || state.role == 'provider_staff') {
            context.go('/provider/home');
            return;
          }
          if (state.role == 'community_admin' || state.role == 'platform_admin') {
            context.go('/admin/home');
            return;
          }
          if (!state.hasProfile) {
            context.go('/auth/account-type');
          } else if (state.accountState == 'Active') {
            context.go('/home');
          } else {
            context.go('/auth/pending');
          }
      }
    });

    return const Scaffold(
      backgroundColor: TnnColors.ink,
      body: Center(child: CircularProgressIndicator(color: TnnColors.gold)),
    );
  }
}
