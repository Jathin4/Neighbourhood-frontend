import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../../auth/session_controller.dart';
import '../resident_repository.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late String _relationship;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(sessionControllerProvider).profile;
    _nameController = TextEditingController(text: profile?['full_name'] as String? ?? '');
    _relationship = profile?['household_relationship'] as String? ?? 'Owner';
    if (!['Owner', 'Tenant', 'Family member'].contains(_relationship)) _relationship = 'Owner';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showTnnSnackBar(context, 'Enter your full name', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(residentRepositoryProvider).updateProfile(fullName: name, householdRelationship: _relationship);
      await ref.read(sessionControllerProvider.notifier).refreshProfile();
      if (mounted) {
        showTnnSnackBar(context, 'Profile updated');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(sessionControllerProvider).profile;
    final community = profile?['community'] as Map<String, dynamic>?;
    final phone = profile?['phone'] as String? ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(
        padding: const EdgeInsets.all(TnnSpacing.lg),
        children: [
          const Text('Mobile number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
          const SizedBox(height: 6),
          TextField(
            controller: TextEditingController(text: phone),
            enabled: false,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push('/profile/change-phone'),
              icon: const Icon(Icons.edit_outlined, size: 15),
              label: const Text('Change mobile number'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
          ),
          Text('Changing it needs a code sent to the new number, same as login.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 18),
          const Text('Full name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
          const SizedBox(height: 6),
          TextField(controller: _nameController, decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 18),
          const Text('Household relationship', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _relationship,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: ['Owner', 'Tenant', 'Family member'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setState(() => _relationship = v ?? _relationship),
          ),
          const SizedBox(height: 18),
          Text('Community: ${community?['name'] ?? '—'} · ${community?['tower'] ?? ''}, ${community?['unit'] ?? ''}',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text('Community and unit are set during onboarding and can\'t be changed here.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: TnnColors.gold, foregroundColor: TnnColors.ink),
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: TnnColors.ink))
                  : const Text('Save changes'),
            ),
          ),
        ],
      ),
    );
  }
}
