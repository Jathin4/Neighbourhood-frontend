import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import 'widgets/auth_scaffold.dart';

/// Shown once, right after a brand-new phone number's first OTP verification —
/// before they're locked into the resident flow. Lets someone who is NOT a
/// resident of any community (an "outsider") go straight to provider
/// onboarding instead of being forced through community matching first.
class AccountTypeScreen extends StatelessWidget {
  const AccountTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthMark(),
          const SizedBox(height: 22),
          const AuthHeading(title: 'How will you use TNN?', subtitle: "This just decides where we take you next — you can always add the other later."),
          const SizedBox(height: 30),
          _OptionCard(
            icon: Icons.home_outlined,
            title: "I'm a resident",
            subtitle: 'Notices, local issues, and services for my building or community.',
            onTap: () => context.go('/auth/profile-setup'),
          ),
          const SizedBox(height: 14),
          _OptionCard(
            icon: Icons.storefront_outlined,
            title: 'I run a business',
            subtitle: 'List my services (electrician, plumber, cleaning, etc.) and get bookings.',
            onTap: () => context.go('/provider/home'),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _OptionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: TnnColors.gold, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Color(0xFFB9C4DA), fontSize: 12, height: 1.4)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF8493AE)),
          ],
        ),
      ),
    );
  }
}
