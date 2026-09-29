import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/committee_responsibilities_section.dart';
import '../../../core/widgets/states.dart';
import '../../auth/session_controller.dart';
import '../home_shell.dart';
import '../resident_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(sessionControllerProvider).profile;
    final name = profile?['full_name'] as String? ?? '';
    final community = profile?['community'] as Map<String, dynamic>?;
    final capabilities = (profile?['committee_capabilities'] as List?)?.cast<String>() ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(TnnSpacing.lg),
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(TnnRadius.md),
            onTap: () => context.push('/profile/edit'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(radius: 26, backgroundColor: TnnColors.ink, child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white, fontSize: 18))),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: Theme.of(context).textTheme.headlineSmall),
                        Text('${community?['name'] ?? ''} · ${community?['tower'] ?? ''}, ${community?['unit'] ?? ''}', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (capabilities.isNotEmpty) ...[
            CommitteeResponsibilitiesSection(capabilities: capabilities, communityId: community?['id'] as int?),
            const SizedBox(height: 14),
          ],
          _Tile(title: 'My bookings', subtitle: 'View booking history', onTap: () => ref.read(residentTabIndexProvider.notifier).state = 3),
          _Tile(title: 'Notification preferences', subtitle: 'Push, SMS, WhatsApp', onTap: () => context.push('/profile/notification-preferences')),
          _Tile(title: 'Language', subtitle: 'English · Telugu & Hindi coming soon', onTap: () => showTnnSnackBar(context, 'Telugu and Hindi are on the roadmap')),
          _Tile(title: 'List your business', subtitle: 'Become a verified service provider on TNN', onTap: () => context.push('/provider/home')),
          _PrivacyTile(),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              await ref.read(sessionControllerProvider.notifier).logout();
              if (context.mounted) context.go('/');
            },
            style: OutlinedButton.styleFrom(foregroundColor: TnnColors.brick),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Tile({required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
      ),
    );
  }
}

class _PrivacyTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PrivacyTile> createState() => _PrivacyTileState();
}

class _PrivacyTileState extends ConsumerState<_PrivacyTile> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(sessionControllerProvider).profile;
    final phoneVisible = profile?['phone_visible'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
      child: SwitchListTile(
        title: const Text('Show my phone in directory', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
        subtitle: const Text('Hidden by default — in-app contact always works either way.'),
        value: phoneVisible,
        activeThumbColor: TnnColors.gold,
        onChanged: _updating
            ? null
            : (v) async {
                setState(() => _updating = true);
                try {
                  await ref.read(residentRepositoryProvider).updatePrivacy(phoneVisible: v);
                  await ref.read(sessionControllerProvider.notifier).refreshProfile();
                } catch (e) {
                  if (context.mounted) showTnnSnackBar(context, e.toString(), isError: true);
                } finally {
                  if (mounted) setState(() => _updating = false);
                }
              },
      ),
    );
  }
}
