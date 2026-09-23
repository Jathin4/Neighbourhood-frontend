import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/phone.dart';
import '../../core/widgets/states.dart';
import 'auth_repository.dart';
import 'widgets/auth_scaffold.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _phoneError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final typed = _controller.text.replaceAll(' ', '').trim();
    if (typed.length < 10) {
      setState(() => _phoneError = 'Enter a valid mobile number');
      showTnnSnackBar(context, 'Enter a valid mobile number', isError: true);
      return;
    }
    final phone = toStoredPhone(typed);
    setState(() {
      _phoneError = null;
      _loading = true;
    });
    try {
      final devOtp = await ref.read(authRepositoryProvider).sendOtp(phone);
      if (!mounted) return;
      context.push('/auth/otp', extra: {'phone': phone, 'dev_otp': devOtp});
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
          const AuthHeading(
            title: 'Your society,\nonline and trusted.',
            subtitle: 'Notices, local issues and verified home services for your community — in one place.',
          ),
          const SizedBox(height: 30),
          const AuthFieldLabel('Mobile number'),
          const SizedBox(height: 6),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            onChanged: (_) {
              if (_phoneError != null) setState(() => _phoneError = null);
            },
            decoration: authFieldDecoration('', errorText: _phoneError)
                .copyWith(label: null, hintText: '98480 XXXXX', hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _sendOtp,
              style: ElevatedButton.styleFrom(backgroundColor: TnnColors.gold, foregroundColor: TnnColors.ink),
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: TnnColors.ink))
                  : const Text('Send OTP'),
            ),
          ),
        ],
      ),
    );
  }
}
