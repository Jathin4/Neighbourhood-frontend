import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import '../../core/api/api_exception.dart';
import '../../core/utils/phone.dart';
import '../../core/widgets/states.dart';
import 'auth_repository.dart';
import 'session_controller.dart';
import 'widgets/auth_scaffold.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String? devOtp;
  const OtpScreen({super.key, required this.phone, this.devOtp});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _digits = List.generate(4, (_) => TextEditingController());
  final _focusNodes = List.generate(4, (_) => FocusNode());
  bool _loading = false;
  bool _otpError = false;
  int _cooldown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.devOtp != null) {
      for (var i = 0; i < 4 && i < widget.devOtp!.length; i++) {
        _digits[i].text = widget.devOtp![i];
      }
    }
    _startCooldown();
  }

  void _startCooldown() {
    _cooldown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown == 0) {
        t.cancel();
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _digits) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    try {
      await ref.read(authRepositoryProvider).sendOtp(widget.phone);
      _startCooldown();
      if (mounted) showTnnSnackBar(context, 'A new OTP has been sent');
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    }
  }

  Future<void> _verify() async {
    final otp = _digits.map((c) => c.text).join();
    if (otp.length != 4) {
      setState(() => _otpError = true);
      showTnnSnackBar(context, 'Enter the 4-digit code', isError: true);
      return;
    }
    setState(() {
      _otpError = false;
      _loading = true;
    });
    try {
      final user = await ref.read(authRepositoryProvider).verifyOtp(widget.phone, otp);
      await ref.read(sessionControllerProvider.notifier).onVerified(user);
      if (!mounted) return;
      context.go('/auth/route');
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _otpError = true);
        showTnnSnackBar(context, e.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _otpError = true);
        showTnnSnackBar(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(3, (i) => Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(color: i < 2 ? TnnColors.gold : Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(3)),
              ),
            )),
          ),
          const SizedBox(height: 24),
          Text('Enter the code we sent', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontSize: 22)),
          const SizedBox(height: 6),
          Text('Sent by SMS to ${displayPhone(widget.phone)}', style: const TextStyle(color: Color(0xFFB9C4DA), fontSize: 13.5)),
          const SizedBox(height: 20),
          Row(
            children: List.generate(4, (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 3 ? 0 : 9),
                child: TextField(
                  controller: _digits[i],
                  focusNode: _focusNodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(color: Colors.white, fontSize: 19),
                  decoration: authFieldDecoration('', errorText: _otpError ? '' : null).copyWith(counterText: ''),
                  onChanged: (v) {
                    if (_otpError) setState(() => _otpError = false);
                    if (v.isNotEmpty && i < 3) _focusNodes[i + 1].requestFocus();
                    if (v.isEmpty && i > 0) _focusNodes[i - 1].requestFocus();
                  },
                ),
              ),
            )),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _resend,
            child: Text(
              _cooldown > 0 ? "Didn't get it? Resend in ${_cooldown}s" : "Didn't get it? Resend",
              style: TextStyle(color: _cooldown > 0 ? const Color(0xFF8493AE) : TnnColors.gold, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _verify,
              style: ElevatedButton.styleFrom(backgroundColor: TnnColors.gold, foregroundColor: TnnColors.ink),
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: TnnColors.ink))
                  : const Text('Verify & continue'),
            ),
          ),
        ],
      ),
    );
  }
}
