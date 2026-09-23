import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/status_pill.dart';
import '../auth/session_controller.dart';
import 'provider_repository.dart';
import 'onboarding/provider_onboarding_screen.dart';
import 'dashboard/provider_dashboard_screen.dart';

/// Entry point for the provider portal: routes to onboarding (Draft/no
/// provider yet), a "pending review" state (Submitted/UnderReview/Rejected/
/// Suspended), or the real dashboard (Verified).
class ProviderHomeScreen extends ConsumerWidget {
  const ProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerAsync = ref.watch(myProviderProvider);

    return providerAsync.when(
      loading: () => const Scaffold(body: LoadingSkeleton()),
      error: (e, _) => Scaffold(appBar: AppBar(title: const Text('Provider portal')), body: ErrorState(message: e.toString(), onRetry: () => ref.invalidate(myProviderProvider))),
      data: (provider) {
        if (provider == null) return const ProviderOnboardingScreen();

        final state = provider['verification_state'] as String;
        if (state != 'Verified') return _VerificationStatusScreen(state: state);

        return ProviderDashboardScreen(provider: provider);
      },
    );
  }
}

class _VerificationStatusScreen extends ConsumerWidget {
  final String state;
  const _VerificationStatusScreen({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = switch (state) {
      'Rejected' => (icon: Icons.block, title: 'Application rejected', message: 'Your provider application was not approved. Contact platform support for details, or resubmit with updated information.'),
      'Suspended' => (icon: Icons.pause_circle_outline, title: 'Account suspended', message: 'Your provider account is currently suspended. Contact platform support to resolve this.'),
      _ => (icon: Icons.hourglass_top, title: 'Verification in progress', message: 'Our team is reviewing your application and documents. This usually takes 1-2 business days.'),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Provider portal'), actions: [
        IconButton(
          onPressed: () async {
            await ref.read(sessionControllerProvider.notifier).logout();
            if (context.mounted) context.go('/');
          },
          icon: const Icon(Icons.logout),
        ),
      ]),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(config.icon, size: 40, color: TnnColors.gold),
              const SizedBox(height: 16),
              Text(config.title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(config.message, textAlign: TextAlign.center, style: const TextStyle(color: TnnColors.inkSoft, fontSize: 12.5, height: 1.5)),
              const SizedBox(height: 12),
              StatusPill(status: state),
              const SizedBox(height: 20),
              OutlinedButton(onPressed: () => ref.invalidate(myProviderProvider), child: const Text('Check status')),
            ],
          ),
        ),
      ),
    );
  }
}
