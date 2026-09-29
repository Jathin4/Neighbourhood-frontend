import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../resident_repository.dart';

final _preferencesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.watch(residentRepositoryProvider).getNotificationPreferences(),
);

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(_preferencesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notification preferences')),
      body: prefsAsync.when(
        loading: () => const LoadingSkeleton(lines: 2),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(_preferencesProvider)),
        data: (prefs) {
          final pushGeneralRow = prefs.firstWhere(
            (p) => p['channel'] == 'push' && p['category'] == 'general',
            orElse: () => const {},
          );
          final pushGeneralEnabled = pushGeneralRow['enabled'] as bool? ?? true; // no row = default on

          return ListView(
            padding: const EdgeInsets.all(TnnSpacing.lg),
            children: [
              _PrefTile(
                title: 'Push notifications',
                subtitle: 'Issue and booking status updates',
                value: pushGeneralEnabled,
                onChanged: (v) async {
                  try {
                    await ref.read(residentRepositoryProvider).updateNotificationPreference(channel: 'push', category: 'general', enabled: v);
                    ref.invalidate(_preferencesProvider);
                  } catch (e) {
                    if (context.mounted) showTnnSnackBar(context, e.toString(), isError: true);
                  }
                },
              ),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
                child: SwitchListTile(
                  title: const Text('Critical alerts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: const Text('Power cuts, safety notices — always delivered, cannot be turned off'),
                  value: true,
                  onChanged: null,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'SMS, WhatsApp and email notifications aren\'t sent yet for these updates — only push is live today.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PrefTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PrefTile({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
        subtitle: Text(subtitle),
        value: value,
        activeThumbColor: TnnColors.gold,
        onChanged: onChanged,
      ),
    );
  }
}
