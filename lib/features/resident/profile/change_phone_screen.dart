import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/phone.dart';
import '../../../core/widgets/states.dart';
import '../../auth/auth_repository.dart';
import '../../auth/session_controller.dart';

/// Changing the login number requires proving ownership of the new one via
/// the same OTP flow as login — it's a credential, not a plain profile field.
class ChangePhoneScreen extends ConsumerStatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  ConsumerState<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends ConsumerState<ChangePhoneScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _newPhone;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final typed = _phoneController.text.replaceAll(' ', '').trim();
    if (typed.length != 10) {
      showTnnSnackBar(context, 'Enter a valid 10-digit mobile number', isError: true);
      return;
    }
    final phone = toStoredPhone(typed);
    setState(() => _loading = true);
    try {
      final devOtp = await ref.read(authRepositoryProvider).sendOtp(phone);
      setState(() {
        _otpSent = true;
        _newPhone = phone;
      });
      if (devOtp != null && mounted) showTnnSnackBar(context, 'Dev OTP: $devOtp');
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      showTnnSnackBar(context, 'Enter the code', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).changePhone(_newPhone!, otp);
      await ref.read(sessionControllerProvider.notifier).refreshProfile();
      if (mounted) {
        showTnnSnackBar(context, 'Mobile number updated');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change mobile number')),
      body: ListView(
        padding: const EdgeInsets.all(TnnSpacing.lg),
        children: _otpSent
            ? [
                Text("Enter the code sent to ${displayPhone(_newPhone)}", style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(border: OutlineInputBorder(), counterText: '', hintText: '4-digit code'),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _confirm,
                    style: ElevatedButton.styleFrom(backgroundColor: TnnColors.gold, foregroundColor: TnnColors.ink),
                    child: _loading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: TnnColors.ink))
                        : const Text('Confirm change'),
                  ),
                ),
                const SizedBox(height: 10),
                Center(child: TextButton(onPressed: () => setState(() => _otpSent = false), child: const Text('Use a different number'))),
              ]
            : [
                const Text('New mobile number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(border: OutlineInputBorder(), counterText: '', hintText: 'e.g. 9848012345'),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(backgroundColor: TnnColors.gold, foregroundColor: TnnColors.ink),
                    child: _loading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: TnnColors.ink))
                        : const Text('Send code'),
                  ),
                ),
              ],
      ),
    );
  }
}
