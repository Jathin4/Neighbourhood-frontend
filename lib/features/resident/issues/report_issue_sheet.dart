import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../../auth/session_controller.dart';
import '../resident_repository.dart';

const _categories = ['Maintenance', 'Electrical', 'Plumbing', 'Sanitation', 'Security', 'Other'];
const _urgencies = ['Normal', 'High', 'Critical'];

Future<bool?> showReportIssueSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ReportIssueSheet(),
  );
}

class _ReportIssueSheet extends ConsumerStatefulWidget {
  const _ReportIssueSheet();

  @override
  ConsumerState<_ReportIssueSheet> createState() => _ReportIssueSheetState();
}

class _ReportIssueSheetState extends ConsumerState<_ReportIssueSheet> {
  String _category = _categories.first;
  String _urgency = _urgencies.first;
  final _location = TextEditingController();
  final _description = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_description.text.trim().isEmpty) {
      showTnnSnackBar(context, "Describe what's happening", isError: true);
      return;
    }
    final communityId = ref.read(sessionControllerProvider).profile?['community']?['id'] as int?;
    if (communityId == null) {
      showTnnSnackBar(context, 'Could not determine your community', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final issue = await ref.read(residentRepositoryProvider).createIssue(
            communityId: communityId,
            category: _category,
            description: _description.text.trim(),
            location: _location.text.trim(),
            urgency: _urgency,
          );
      if (mounted) {
        showTnnSnackBar(context, 'Issue #${issue['ticket_no']} submitted');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: TnnColors.paper, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: TnnColors.line, borderRadius: BorderRadius.circular(99)))),
              const SizedBox(height: 16),
              Text('Report an issue', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Admin will assign an owner and SLA once submitted.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 18),
              _label('Category'),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 14),
              _label('Location'),
              TextField(controller: _location, decoration: const InputDecoration(hintText: 'e.g. Tower 4, near lift')),
              const SizedBox(height: 14),
              _label('Describe the issue'),
              TextField(controller: _description, maxLines: 3, decoration: const InputDecoration(hintText: "What's happening?")),
              const SizedBox(height: 14),
              _label('Urgency'),
              DropdownButtonFormField<String>(
                initialValue: _urgency,
                items: _urgencies.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setState(() => _urgency = v ?? _urgency),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit issue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: TnnColors.inkSoft)),
      );
}
