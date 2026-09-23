import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';

/// Full-bleed navy auth screen chrome, matching the resident-app prototype's
/// sign-in / OTP / community-match screens exactly.
class AuthScaffold extends StatelessWidget {
  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;

  const AuthScaffold({super.key, required this.child, this.showBack = false, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TnnColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBack)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: onBack,
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back, size: 16, color: Color(0xFF8493AE)),
                        SizedBox(width: 6),
                        Text('Back', style: TextStyle(color: Color(0xFF8493AE), fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthMark extends StatelessWidget {
  const AuthMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(color: TnnColors.gold, borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: Text('TN', style: GoogleFonts.fraunces(fontWeight: FontWeight.w700, fontSize: 19, color: TnnColors.ink)),
    );
  }
}

class AuthHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  const AuthHeading({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.fraunces(fontSize: 24, height: 1.25, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: Color(0xFFB9C4DA), fontSize: 13.5, height: 1.5)),
      ],
    );
  }
}

InputDecoration authFieldDecoration(String label, {String? errorText}) {
  return InputDecoration(
    label: Text(label, style: const TextStyle(color: Color(0xFFB9C4DA))),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TnnColors.gold, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TnnColors.brick, width: 1.5)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TnnColors.brick, width: 1.5)),
    errorText: errorText,
    errorStyle: const TextStyle(color: TnnColors.brick, fontSize: 11.5),
  );
}

/// Field label with a red "*" appended when the field is mandatory.
class AuthFieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const AuthFieldLabel(this.text, {super.key, this.required = true});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11.5, fontWeight: FontWeight.w600),
        children: [
          TextSpan(text: text),
          if (required) const TextSpan(text: ' *', style: TextStyle(color: TnnColors.brick)),
        ],
      ),
    );
  }
}
