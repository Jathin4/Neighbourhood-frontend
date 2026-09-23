import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/states.dart';
import 'auth_repository.dart';
import 'session_controller.dart';
import 'widgets/auth_scaffold.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  String _relationship = 'Owner';
  bool _loading = false;
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = 'Enter your full name');
      showTnnSnackBar(context, 'Enter your full name', isError: true);
      return;
    }
    setState(() {
      _nameError = null;
      _loading = true;
    });
    try {
      final result = await ref.read(authRepositoryProvider).registerResident(
            fullName: _nameController.text.trim(),
            householdRelationship: _relationship,
          );
      await ref.read(sessionControllerProvider.notifier).refreshProfile();
      if (!mounted) return;
      final match = result['community_match'] as Map<String, dynamic>?;
      context.go('/auth/community-match', extra: match);
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthMark(),
          const SizedBox(height: 22),
          const AuthHeading(title: 'Tell us about you', subtitle: "We'll use this to match you to your unit and community."),
          const SizedBox(height: 26),
          const AuthFieldLabel('Full name'),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            decoration: authFieldDecoration('', errorText: _nameError)
                .copyWith(hintText: 'e.g. Ananya Reddy', hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
          ),
          const SizedBox(height: 18),
          const AuthFieldLabel('Household relationship'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _relationship,
            dropdownColor: TnnColors.ink,
            style: const TextStyle(color: Colors.white),
            decoration: authFieldDecoration(''),
            items: ['Owner', 'Tenant', 'Family member'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setState(() => _relationship = v ?? 'Owner'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: TnnColors.gold, foregroundColor: TnnColors.ink),
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: TnnColors.ink))
                  : const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
