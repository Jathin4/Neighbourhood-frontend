import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../admin_repository.dart';
import '../shell/admin_community_context.dart';

class NoticeComposerScreen extends ConsumerStatefulWidget {
  const NoticeComposerScreen({super.key});

  @override
  ConsumerState<NoticeComposerScreen> createState() => _NoticeComposerScreenState();
}

class _NoticeComposerScreenState extends ConsumerState<NoticeComposerScreen> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  String _priority = 'normal';
  String _audience = 'all';
  bool _preview = false;
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final communityId = ref.read(selectedCommunityIdProvider);
    if (communityId == null || _title.text.trim().isEmpty || _content.text.trim().isEmpty) {
      showTnnSnackBar(context, 'Fill in a title and content', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(adminRepositoryProvider).createNotice(
            communityId: communityId,
            title: _title.text.trim(),
            content: _content.text.trim(),
            priority: _priority,
            audienceType: _audience,
          );
      if (mounted) {
        showTnnSnackBar(context, 'Notice published');
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
      appBar: AppBar(title: const Text('Compose notice'), actions: [
        TextButton(onPressed: () => setState(() => _preview = !_preview), child: Text(_preview ? 'Edit' : 'Preview', style: const TextStyle(color: Colors.white))),
      ]),
      body: _preview ? _buildPreview(context) : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(TnnSpacing.lg),
      children: [
        const Text('Title', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: TnnColors.inkSoft)),
        const SizedBox(height: 6),
        TextField(controller: _title),
        const SizedBox(height: 14),
        const Text('Content', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: TnnColors.inkSoft)),
        const SizedBox(height: 6),
        TextField(controller: _content, maxLines: 5),
        const SizedBox(height: 14),
        const Text('Priority', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: TnnColors.inkSoft)),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: const [ButtonSegment(value: 'normal', label: Text('Normal')), ButtonSegment(value: 'critical', label: Text('Critical'))],
          selected: {_priority},
          onSelectionChanged: (s) => setState(() => _priority = s.first),
        ),
        const SizedBox(height: 14),
        const Text('Audience', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: TnnColors.inkSoft)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _audience,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All residents')),
            DropdownMenuItem(value: 'tower', child: Text('Specific tower')),
            DropdownMenuItem(value: 'committee', child: Text('Committee only')),
          ],
          onChanged: (v) => setState(() => _audience = v ?? _audience),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loading ? null : _publish,
          child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Publish notice'),
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    final isCritical = _priority == 'critical';
    return Padding(
      padding: const EdgeInsets.all(TnnSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: isCritical ? TnnColors.statusCriticalBg : TnnColors.statusNeutralBg, borderRadius: BorderRadius.circular(4)),
              child: Text(isCritical ? 'CRITICAL' : 'NOTICE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: isCritical ? TnnColors.brick : TnnColors.inkSoft)),
            ),
            const SizedBox(height: 8),
            Text(_title.text.isEmpty ? '(title)' : _title.text, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(_content.text.isEmpty ? '(content)' : _content.text, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
