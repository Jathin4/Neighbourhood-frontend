import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/phone.dart';
import '../../../core/widgets/states.dart';
import '../admin_repository.dart';
import '../shell/admin_community_context.dart';

const _expectedColumns = ['phone', 'full_name', 'tower_name', 'unit_name', 'household_relationship'];
const _relationshipOptions = ['Owner', 'Tenant', 'Family member'];

/// One editable resident row backing a card in the preview list. Holds its own
/// controllers so rows loaded from a file and rows added manually work the same way.
class _ResidentRow {
  final phone = TextEditingController();
  final fullName = TextEditingController();
  final tower = TextEditingController();
  final unit = TextEditingController();
  final relationship = TextEditingController();

  _ResidentRow({String phone = '', String fullName = '', String tower = '', String unit = '', String relationship = ''}) {
    this.phone.text = phone;
    this.fullName.text = fullName;
    this.tower.text = tower;
    this.unit.text = unit;
    this.relationship.text = relationship;
  }

  void dispose() {
    phone.dispose();
    fullName.dispose();
    tower.dispose();
    unit.dispose();
    relationship.dispose();
  }

  Map<String, dynamic> toJson() => {
        'phone': toStoredPhone(phone.text),
        if (fullName.text.trim().isNotEmpty) 'full_name': fullName.text.trim(),
        if (tower.text.trim().isNotEmpty) 'tower_name': tower.text.trim(),
        if (unit.text.trim().isNotEmpty) 'unit_name': unit.text.trim(),
        if (relationship.text.trim().isNotEmpty) 'household_relationship': relationship.text.trim(),
      };
}

class BulkImportScreen extends ConsumerStatefulWidget {
  const BulkImportScreen({super.key});

  @override
  ConsumerState<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends ConsumerState<BulkImportScreen> {
  final List<_ResidentRow> _rows = [];
  String? _fileName;
  bool _loading = false;
  bool _submitAttempted = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      List<List<dynamic>> table;
      if (file.name.toLowerCase().endsWith('.xlsx')) {
        final book = xls.Excel.decodeBytes(bytes);
        final sheet = book.tables[book.tables.keys.first]!;
        table = sheet.rows.map((row) => row.map((c) => c?.value?.toString() ?? '').toList()).toList();
      } else {
        table = const CsvToListConverter(eol: '\n').convert(utf8.decode(bytes));
      }
      if (table.isEmpty) {
        if (mounted) showTnnSnackBar(context, 'That file has no rows', isError: true);
        return;
      }

      // Match columns by header name when present, so column order in the file doesn't matter;
      // otherwise assume the fixed phone,full_name,tower_name,unit_name,household_relationship order.
      final header = table.first.map((h) => h.toString().trim().toLowerCase()).toList();
      final looksLikeHeader = header.any(_expectedColumns.contains);
      final dataRows = looksLikeHeader ? table.skip(1) : table;
      int colIndex(String name) => looksLikeHeader ? header.indexOf(name) : _expectedColumns.indexOf(name);

      final parsed = <_ResidentRow>[];
      for (final row in dataRows) {
        String cell(int i) => (i >= 0 && i < row.length) ? row[i].toString().trim() : '';
        final phone = cell(colIndex('phone'));
        if (phone.isEmpty) continue;
        parsed.add(_ResidentRow(
          phone: displayPhone(phone),
          fullName: cell(colIndex('full_name')),
          tower: cell(colIndex('tower_name')),
          unit: cell(colIndex('unit_name')),
          relationship: cell(colIndex('household_relationship')),
        ));
      }

      if (parsed.isEmpty) {
        if (mounted) showTnnSnackBar(context, 'No valid rows found — a phone number is required in each row', isError: true);
        return;
      }

      setState(() {
        for (final r in _rows) {
          r.dispose();
        }
        _rows
          ..clear()
          ..addAll(parsed);
        _fileName = file.name;
        _result = null;
      });
      if (mounted) showTnnSnackBar(context, '${parsed.length} row${parsed.length == 1 ? '' : 's'} loaded from ${file.name}');
    } catch (e) {
      if (mounted) showTnnSnackBar(context, 'Could not read that file: $e', isError: true);
    }
  }

  void _addRow() => setState(() => _rows.add(_ResidentRow()));

  void _removeRow(int i) => setState(() {
        _rows[i].dispose();
        _rows.removeAt(i);
      });

  bool _rowIsValid(_ResidentRow r) =>
      toStoredPhone(r.phone.text).isNotEmpty &&
      r.tower.text.trim().isNotEmpty &&
      r.unit.text.trim().isNotEmpty &&
      r.relationship.text.trim().isNotEmpty;

  Future<void> _import() async {
    final communityId = ref.read(selectedCommunityIdProvider);
    if (communityId == null) return;
    if (_rows.isEmpty) {
      showTnnSnackBar(context, 'Add at least one resident row', isError: true);
      return;
    }
    if (_rows.any((r) => !_rowIsValid(r))) {
      setState(() => _submitAttempted = true);
      showTnnSnackBar(context, 'Fill in phone, tower, unit and relationship for every resident', isError: true);
      return;
    }
    final rows = _rows.map((r) => r.toJson()).toList();
    setState(() => _loading = true);
    try {
      final result = await ref.read(adminRepositoryProvider).bulkImportResidents(communityId, rows);
      setState(() => _result = result);
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rowResults = (_result?['row_results'] as List?)?.cast<Map<String, dynamic>>();
    final okCount = rowResults?.where((r) => r['status'] == 'ok').length ?? 0;
    final errorRows = rowResults?.where((r) => r['status'] == 'error').toList() ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Bulk import residents')),
      body: ListView(
        padding: const EdgeInsets.all(TnnSpacing.lg),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: TnnColors.card,
              borderRadius: BorderRadius.circular(TnnRadius.lg),
              border: Border.all(color: TnnColors.line),
            ),
            child: Column(
              children: [
                Icon(_fileName == null ? Icons.upload_file_outlined : Icons.description_outlined, size: 32, color: TnnColors.gold),
                const SizedBox(height: 10),
                Text(
                  _fileName ?? 'Upload a CSV or Excel (.xlsx) file',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Columns (any order, matched by header): phone*, full_name, tower_name, unit_name, household_relationship',
                  style: TextStyle(color: TnnColors.inkSoft, fontSize: 11.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.folder_open_outlined, size: 18),
                  label: Text(_fileName == null ? 'Browse file' : 'Choose a different file'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Residents to import (${_rows.length})', style: Theme.of(context).textTheme.headlineSmall),
              TextButton.icon(onPressed: _addRow, icon: const Icon(Icons.add, size: 18), label: const Text('Add row')),
            ],
          ),
          const SizedBox(height: 10),
          if (_rows.isEmpty)
            const Text('No residents added yet — upload a file above or tap "Add row" to enter one by hand.', style: TextStyle(color: TnnColors.inkSoft, fontSize: 12.5)),
          ..._rows.asMap().entries.map(
                (entry) => _RowCard(
                  key: ValueKey(entry.value),
                  index: entry.key,
                  row: entry.value,
                  showErrors: _submitAttempted,
                  onRemove: () => _removeRow(entry.key),
                ),
              ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _import,
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Import ${_rows.length} resident${_rows.length == 1 ? '' : 's'}'),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: TnnColors.statusSuccessBg, borderRadius: BorderRadius.circular(TnnRadius.md)),
              child: Row(children: [
                const Icon(Icons.check_circle_outline, color: TnnColors.statusSuccessFg, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$okCount imported successfully, ${errorRows.length} rejected',
                    style: const TextStyle(color: TnnColors.statusSuccessFg, fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),
            if (errorRows.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Rejected rows', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...errorRows.map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: TnnColors.statusCriticalBg, borderRadius: BorderRadius.circular(TnnRadius.md)),
                    child: Text('Row ${r['row']}: ${r['message']}', style: const TextStyle(color: TnnColors.statusCriticalFg, fontSize: 12.5)),
                  )),
            ],
          ],
        ],
      ),
    );
  }
}

class _RowCard extends ConsumerStatefulWidget {
  final int index;
  final _ResidentRow row;
  final bool showErrors;
  final VoidCallback? onRemove;
  const _RowCard({super.key, required this.index, required this.row, required this.showErrors, required this.onRemove});

  @override
  ConsumerState<_RowCard> createState() => _RowCardState();
}

class _RowCardState extends ConsumerState<_RowCard> {
  @override
  Widget build(BuildContext context) {
    final communityId = ref.watch(selectedCommunityIdProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: TnnColors.card, borderRadius: BorderRadius.circular(TnnRadius.md), border: Border.all(color: TnnColors.lineSoft)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Row ${widget.index + 1}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: TnnColors.inkSoft)),
              if (widget.onRemove != null)
                InkWell(
                  onTap: widget.onRemove,
                  borderRadius: BorderRadius.circular(TnnRadius.pill),
                  child: const Padding(padding: EdgeInsets.all(2), child: Icon(Icons.close, size: 18, color: TnnColors.inkSoft)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: widget.row.phone,
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Phone *',
              hintText: '98480 XXXXX',
              isDense: true,
              errorText: widget.showErrors && toStoredPhone(widget.row.phone.text).isEmpty ? 'Required' : null,
            ),
          ),
          const SizedBox(height: 8),
          TextField(controller: widget.row.fullName, decoration: const InputDecoration(labelText: 'Full name', isDense: true)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(width: 150, child: communityId == null ? const SizedBox.shrink() : _towerDropdown(communityId)),
              SizedBox(width: 150, child: communityId == null ? const SizedBox.shrink() : _unitDropdown(communityId)),
              SizedBox(width: 150, child: _relationshipDropdown()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _relationshipDropdown() {
    final currentValue = _relationshipOptions.contains(widget.row.relationship.text) ? widget.row.relationship.text : null;
    return DropdownButtonFormField<String>(
      key: ValueKey('relationship-${widget.row}-$currentValue'),
      initialValue: currentValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Relationship *',
        isDense: true,
        errorText: widget.showErrors && currentValue == null ? 'Required' : null,
      ),
      hint: const Text('Select', style: TextStyle(fontSize: 12.5)),
      items: _relationshipOptions.map((r) => DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: (v) => setState(() => widget.row.relationship.text = v ?? ''),
    );
  }

  Widget _towerDropdown(int communityId) {
    return ref.watch(towersProvider(communityId)).when(
          loading: () => const _DropdownSkeleton(),
          error: (e, _) => const Text('Could not load towers', style: TextStyle(fontSize: 11, color: TnnColors.brick)),
          data: (towers) {
            final names = towers.map((t) => t['name'] as String).toList();
            final currentValue = names.contains(widget.row.tower.text) ? widget.row.tower.text : null;
            return DropdownButtonFormField<String>(
              key: ValueKey('tower-${widget.row}-$currentValue'),
              initialValue: currentValue,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Tower *',
                isDense: true,
                errorText: widget.showErrors && currentValue == null ? 'Required' : null,
              ),
              hint: const Text('Select', style: TextStyle(fontSize: 12.5)),
              items: names.map((n) => DropdownMenuItem(value: n, child: Text(n, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => setState(() {
                widget.row.tower.text = v ?? '';
                widget.row.unit.text = ''; // a new tower means the previously picked unit no longer applies
              }),
            );
          },
        );
  }

  Widget _unitDropdown(int communityId) {
    return ref.watch(towersProvider(communityId)).when(
          loading: () => const _DropdownSkeleton(),
          error: (e, _) => const SizedBox.shrink(),
          data: (towers) {
            final match = towers.cast<Map<String, dynamic>?>().firstWhere((t) => t?['name'] == widget.row.tower.text, orElse: () => null);
            if (match == null) {
              return Text(
                'Pick a tower first',
                style: TextStyle(fontSize: 11.5, color: widget.showErrors ? TnnColors.brick : TnnColors.inkSoft, fontWeight: widget.showErrors ? FontWeight.w600 : FontWeight.w400),
              );
            }
            final towerId = match['id'] as int;
            return ref.watch(unitsProvider(towerId)).when(
                  loading: () => const _DropdownSkeleton(),
                  error: (e, _) => const Text('Could not load units', style: TextStyle(fontSize: 11, color: TnnColors.brick)),
                  data: (units) {
                    final names = units.map((u) => u['name'] as String).toList();
                    final currentValue = names.contains(widget.row.unit.text) ? widget.row.unit.text : null;
                    return DropdownButtonFormField<String>(
                      key: ValueKey('unit-${widget.row}-$towerId-$currentValue'),
                      initialValue: currentValue,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Unit *',
                        isDense: true,
                        errorText: widget.showErrors && currentValue == null ? 'Required' : null,
                      ),
                      hint: const Text('Select', style: TextStyle(fontSize: 12.5)),
                      items: names.map((n) => DropdownMenuItem(value: n, child: Text(n, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => widget.row.unit.text = v ?? ''),
                    );
                  },
                );
          },
        );
  }
}

class _DropdownSkeleton extends StatelessWidget {
  const _DropdownSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2));
  }
}
