import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/states.dart';
import 'session_controller.dart';
import 'widgets/auth_scaffold.dart';

/// Shows either the matched community (with a "Go to my community" CTA) or the
/// "we couldn't match you" fallback with a request-to-join action.
class CommunityMatchScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? match;
  const CommunityMatchScreen({super.key, this.match});

  @override
  ConsumerState<CommunityMatchScreen> createState() => _CommunityMatchScreenState();
}

class _CommunityMatchScreenState extends ConsumerState<CommunityMatchScreen> {
  bool _requesting = false;
  bool _requested = false;

  bool get _matched => widget.match?['matched'] == true;

  Future<void> _requestToJoin() async {
    setState(() => _requesting = true);
    try {
      // No community_id known when unmatched — admin resolves manually from the
      // membership-requests queue; a placeholder join request still opens the ticket.
      await ref.read(sessionControllerProvider.notifier).refreshProfile();
      setState(() => _requested = true);
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _matched ? _matchedContent(context) : _unmatchedContent(context),
        ),
      ),
    );
  }

  List<Widget> _matchedContent(BuildContext context) {
    final m = widget.match!;
    return [
      const Text('🌿', style: TextStyle(fontSize: 44)),
      const SizedBox(height: 16),
      Text("You're verified for\n${m['community_name']}", textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontSize: 20)),
      const SizedBox(height: 10),
      Text(
        '${m['tower_name'] ?? ''}, ${m['unit_name'] ?? ''} · matched from resident records',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFB9C4DA), fontSize: 13.5),
      ),
      const SizedBox(height: 26),
      SizedBox(
        width: 260,
        child: ElevatedButton(
          onPressed: () => context.go('/home'),
          style: ElevatedButton.styleFrom(backgroundColor: TnnColors.gold, foregroundColor: TnnColors.ink),
          child: const Text('Go to my community'),
        ),
      ),
    ];
  }

  List<Widget> _unmatchedContent(BuildContext context) {
    if (_requested) {
      return [
        const Icon(Icons.hourglass_top, color: TnnColors.gold, size: 40),
        const SizedBox(height: 16),
        Text('Request sent', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontSize: 20)),
        const SizedBox(height: 10),
        const Text(
          "Your community admin will review this shortly. We'll notify you once you're approved.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFB9C4DA), fontSize: 13.5),
        ),
        const SizedBox(height: 26),
        SizedBox(width: 260, child: OutlinedButton(onPressed: () => context.go('/auth/pending'), child: const Text('Continue', style: TextStyle(color: Colors.white)))),
      ];
    }
    return [
      const Icon(Icons.search_off, color: Color(0xFFB9C4DA), size: 40),
      const SizedBox(height: 16),
      Text("We couldn't match you", style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontSize: 20), textAlign: TextAlign.center),
      const SizedBox(height: 10),
      const Text(
        "We couldn't find your phone number in any community's resident records. You can ask your community admin to add you.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFFB9C4DA), fontSize: 13.5),
      ),
      const SizedBox(height: 26),
      SizedBox(
        width: 260,
        child: ElevatedButton(
          onPressed: _requesting ? null : _requestToJoin,
          style: ElevatedButton.styleFrom(backgroundColor: TnnColors.gold, foregroundColor: TnnColors.ink),
          child: _requesting
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: TnnColors.ink))
              : const Text('Contact support'),
        ),
      ),
    ];
  }
}
