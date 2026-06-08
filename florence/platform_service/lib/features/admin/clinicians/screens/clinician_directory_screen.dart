import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/config/admin_theme.dart';
import 'package:florence/features/admin/core/widgets/admin_sidebar.dart';
import 'package:florence/features/admin/core/providers/admin_providers.dart';
import 'package:florence/features/admin/core/models/admin_models.dart';
import 'package:florence/config/routes.dart';
import 'package:florence/features/admin/clinicians/widgets/add_clinician_dialog.dart';

class ClinicianDirectoryScreen extends ConsumerStatefulWidget {
  const ClinicianDirectoryScreen({super.key});

  @override
  ConsumerState<ClinicianDirectoryScreen> createState() => _ClinicianDirectoryScreenState();
}

class _ClinicianDirectoryScreenState extends ConsumerState<ClinicianDirectoryScreen> {
  String _searchQuery = '';
  int? _filterOrgId; // null means 'All Organisations'

  @override
  Widget build(BuildContext context) {
    final cliniciansAsync = ref.watch(adminCliniciansProvider);
    final orgsAsync = ref.watch(adminOrganizationsProvider);

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Clinician Directory', style: Theme.of(context).textTheme.displaySmall),
                          const SizedBox(height: 8),
                          Text('Manage healthcare professionals and their assignments.', style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const AddClinicianDialog(),
                          );
                        },
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Register New Clinician'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AdminTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Search & Filter Row
                  Row(
                    children: [
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
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AdminTheme.outlineVariant),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: _filterOrgId,
                            icon: const Icon(Icons.filter_list, color: AdminTheme.outline, size: 20),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('All Organisations')),
                              if (orgsAsync.hasValue)
                                ...orgsAsync.value!.map((org) => DropdownMenuItem<int?>(
                                      value: org.id,
                                      child: Text(org.name),
                                    )),
                            ],
                            onChanged: (value) => setState(() => _filterOrgId = value),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Data Table Card
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        cliniciansAsync.when(
                          data: (clinicians) {
                            final filteredClinicians = clinicians.where((c) {
                              final matchesSearch = c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                  c.id.toString().contains(_searchQuery);
                              final matchesOrg = _filterOrgId == null || c.organisationId == _filterOrgId;
                              return matchesSearch && matchesOrg;
                            }).toList();

                            if (filteredClinicians.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(48.0),
                                child: Center(
                                    child: Text('No clinicians found matching your criteria.',
                                        style: TextStyle(color: AdminTheme.outline))),
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
                              rows: filteredClinicians.map((c) => _buildDataRow(c)).toList(),
                            );
                          },
                          loading: () => const Padding(
                              padding: EdgeInsets.all(48.0),
                              child: Center(child: CircularProgressIndicator(color: AdminTheme.primary))),
                          error: (err, _) => Padding(
                              padding: const EdgeInsets.all(48.0),
                              child: Center(child: Text('Error: $err', style: const TextStyle(color: AdminTheme.error)))),
                        ),
                      ],
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
        DataCell(Text(c.organisationName ?? 'Unassigned', style: const TextStyle(fontWeight: FontWeight.w500))),
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
