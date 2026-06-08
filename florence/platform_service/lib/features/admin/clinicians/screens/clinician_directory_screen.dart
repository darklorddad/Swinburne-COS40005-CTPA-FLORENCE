import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/config/admin_theme.dart';
import 'package:florence/features/admin/core/widgets/admin_sidebar.dart';
import 'package:florence/features/admin/core/providers/admin_providers.dart';
import 'package:florence/features/admin/core/models/admin_models.dart';
import 'package:florence/config/routes.dart';

class ClinicianDirectoryScreen extends ConsumerStatefulWidget {
  const ClinicianDirectoryScreen({super.key});

  @override
  ConsumerState<ClinicianDirectoryScreen> createState() => _ClinicianDirectoryScreenState();
}

class _ClinicianDirectoryScreenState extends ConsumerState<ClinicianDirectoryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final cliniciansAsync = ref.watch(adminCliniciansProvider);

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSidebar(currentRoute: AppRoutes.adminClinicianList),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Clinician Directory', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 8),
                  Text('Manage healthcare professionals and their assignments.', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 400,
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search by name or ID...',
                        prefixIcon: const Icon(Icons.search, color: AdminTheme.outline),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AdminTheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AdminTheme.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: cliniciansAsync.when(
                      data: (clinicians) {
                        final filtered = clinicians.where((c) {
                          return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              c.id.toString().contains(_searchQuery);
                        }).toList();

                        if (filtered.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(48.0),
                            child: Center(child: Text('No clinicians found.', style: TextStyle(color: AdminTheme.outline))),
                          );
                        }

                        return DataTable(
                          headingTextStyle: Theme.of(context).textTheme.labelSmall,
                          dataTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AdminTheme.onSurface),
                          headingRowColor: WidgetStateProperty.all(AdminTheme.surface),
                          dividerThickness: 1,
                          columns: const [
                            DataColumn(label: Text('Clinician ID')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Phone')),
                            DataColumn(label: Text('Organisation')),
                            DataColumn(label: Text('Assigned Patients')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: filtered.map((c) => _buildDataRow(c)).toList(),
                        );
                      },
                      loading: () => const Padding(padding: EdgeInsets.all(48.0), child: Center(child: CircularProgressIndicator())),
                      error: (err, _) => Padding(padding: const EdgeInsets.all(48.0), child: Center(child: Text('Error: $err', style: const TextStyle(color: AdminTheme.error)))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(AdminClinician c) {
    return DataRow(
      cells: [
        DataCell(Text('#CL-${c.id.toString().padLeft(4, '0')}', style: const TextStyle(color: AdminTheme.outline))),
        DataCell(Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(c.phoneNumber ?? '-', style: const TextStyle(color: AdminTheme.outline))),
        DataCell(Text(c.organisationName ?? 'Unassigned', style: const TextStyle(color: AdminTheme.outline))),
        DataCell(Text(c.patientCount.toString(), style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AdminTheme.outline),
                tooltip: 'Edit',
                onPressed: () => _showEditDialog(c),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AdminTheme.error),
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(c),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditDialog(AdminClinician c) {
    final nameCtrl = TextEditingController(text: c.name);
    final phoneCtrl = TextEditingController(text: c.phoneNumber ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Clinician'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(adminRepositoryProvider).updateClinician(c.id, {
                  'name': nameCtrl.text,
                  'phone_number': phoneCtrl.text,
                });
                ref.invalidate(adminCliniciansProvider);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clinician updated'), backgroundColor: AdminTheme.primary));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminTheme.error));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(AdminClinician c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Clinician'),
        content: Text('Are you sure you want to delete ${c.name}? Their assigned patients will be unassigned.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(adminRepositoryProvider).deleteClinician(c.id);
                ref.invalidate(adminCliniciansProvider);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clinician deleted'), backgroundColor: AdminTheme.primary));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminTheme.error));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
