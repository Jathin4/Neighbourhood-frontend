import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/phone.dart';
import '../../../core/widgets/states.dart';
import '../provider_repository.dart';

final staffProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
  (ref, providerId) => ref.watch(providerRepositoryProvider).listStaff(providerId),
);

class StaffScreen extends ConsumerWidget {
  final int providerId;
  const StaffScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffProvider(providerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TnnColors.gold,
        foregroundColor: TnnColors.ink,
        onPressed: () => _showAddStaffDialog(context, ref),
        child: const Icon(Icons.person_add),
      ),
      body: staffAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(staffProvider(providerId))),
        data: (staff) {
          if (staff.isEmpty) {
            return const EmptyState(icon: Icons.groups_2_outlined, title: 'No technicians added yet', message: 'Add a technician by phone number to assign them jobs.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(TnnSpacing.lg),
            itemCount: staff.length,
            separatorBuilder: (context, i) => const Divider(),
            itemBuilder: (context, i) {
              final s = staff[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(backgroundColor: TnnColors.ink, child: Text((s['role'] as String)[0].toUpperCase(), style: const TextStyle(color: Colors.white))),
                title: Text(displayPhone(s['phone'] as String?), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: Text(s['role'] ?? ''),
                trailing: Switch(
                  value: s['active'] == true,
                  activeThumbColor: TnnColors.gold,
                  onChanged: (v) async {
                    try {
                      await ref.read(providerRepositoryProvider).updateStaff(providerId, s['id'] as int, active: v);
                      ref.invalidate(staffProvider(providerId));
                    } catch (e) {
                      if (context.mounted) showTnnSnackBar(context, e.toString(), isError: true);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context, WidgetRef ref) {
    final phoneController = TextEditingController();
    String role = 'technician';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add technician'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: phoneController, decoration: const InputDecoration(hintText: '98480 XXXXX'), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                items: ['technician', 'supervisor'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => role = v ?? role),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref.read(providerRepositoryProvider).addStaff(providerId, phone: toStoredPhone(phoneController.text), role: role);
                  ref.invalidate(staffProvider(providerId));
                } catch (e) {
                  if (context.mounted) showTnnSnackBar(context, e.toString(), isError: true);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
