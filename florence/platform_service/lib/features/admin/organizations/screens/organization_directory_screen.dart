import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/config/admin_theme.dart';
import 'package:florence/config/routes.dart';
import 'package:florence/features/admin/core/widgets/admin_sidebar.dart';
import '../../core/providers/admin_providers.dart';
import '../../core/models/admin_models.dart';
import '../widgets/organization_form_dialog.dart';

class OrganizationDirectoryScreen extends ConsumerStatefulWidget {
  const OrganizationDirectoryScreen({super.key});

  @override
  ConsumerState<OrganizationDirectoryScreen> createState() => _OrganizationDirectoryScreenState();
}

class _OrganizationDirectoryScreenState extends ConsumerState<OrganizationDirectoryScreen> {
  String _searchQuery = '';
  String _sectorFilter = 'All';
  String _typeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final orgsAsync = ref.watch(adminOrganizationsProvider);

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSidebar(currentRoute: AppRoutes.organizations),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Organizations', style: Theme.of(context).textTheme.displaySmall),
                          const SizedBox(height: 8),
                          Text('Manage healthcare facilities, clinics, and hospitals.', 
                            style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: () => _openFormDialog(context),
                        icon: const Icon(Icons.add_business_rounded),
                        label: const Text('Add Organization'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AdminTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // --- SEARCH & FILTERS ROW ---
                  Row(
                    children: [
                      SizedBox(
                        width: 400, // Matched Patient Directory search width
                        child: TextField(
                          onChanged: (value) => setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Search by name, email, or state...',
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
                      _buildDropdown(
                        ['All', 'Public', 'Private', 'NGO', 'Other'], 
                        _sectorFilter, 
                        (val) => setState(() => _sectorFilter = val!)
                      ),
                      const SizedBox(width: 16),
                      _buildDropdown(
                        ['All', 'Hospital', 'Clinic', 'Health Centre', 'Lab', 'Other'], 
                        _typeFilter, 
                        (val) => setState(() => _typeFilter = val!)
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // --- DATA TABLE CARD ---
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        orgsAsync.when(
                          loading: () => const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator())),
                          error: (err, _) => Padding(padding: const EdgeInsets.all(48), child: Center(child: Text('Error: $err', style: const TextStyle(color: AdminTheme.error)))),
                          data: (orgs) {
                            final filtered = orgs.where((o) {
                              final matchesSearch = o.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                                    (o.email ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                                    (o.state ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
                              final matchesSector = _sectorFilter == 'All' || o.sector == _sectorFilter;
                              final matchesType = _typeFilter == 'All' || o.facilityType == _typeFilter;
                              return matchesSearch && matchesSector && matchesType;
                            }).toList();

                            if (filtered.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(48), 
                                child: Center(child: Text('No organizations found matching your criteria.', style: TextStyle(color: AdminTheme.outline)))
                              );
                            }

                            return DataTable(
                              headingTextStyle: Theme.of(context).textTheme.labelSmall,
                              dataTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AdminTheme.onSurface),
                              headingRowColor: WidgetStateProperty.all(AdminTheme.surface),
                              dividerThickness: 1,
                              columns: const [
                                DataColumn(label: Text('Organisation')),
                                DataColumn(label: Text('Sector')),
                                DataColumn(label: Text('Facility Type')),
                                DataColumn(label: Text('State')),
                                DataColumn(label: Text('Patients')),
                                DataColumn(label: Text('Clinicians')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: filtered.map((org) => DataRow(
                                cells: [
                                  DataCell(Text(org.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                  DataCell(Text(org.sector ?? '-', style: const TextStyle(color: AdminTheme.outline))),
                                  DataCell(Text(org.facilityType ?? '-', style: const TextStyle(color: AdminTheme.outline))),
                                  DataCell(Text(org.state ?? '-', style: const TextStyle(color: AdminTheme.outline))),
                                  DataCell(Text(org.patientCount.toString(), style: const TextStyle(color: AdminTheme.outline))),
                                  DataCell(Text(org.clinicianCount.toString(), style: const TextStyle(color: AdminTheme.outline))),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility_outlined, color: AdminTheme.outline),
                                          tooltip: 'View Details',
                                          onPressed: () => Navigator.pushNamed(context, AppRoutes.organizationDetail, arguments: org),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: AdminTheme.outline),
                                          tooltip: 'Edit',
                                          onPressed: () => _openFormDialog(context, org: org),
                                        ),
                                      ],
                                    )
                                  ),
                                ]
                              )).toList(),
                            );
                          },
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

  // Styled exactly like the Patient Directory Dropdown
  Widget _buildDropdown(List<String> items, String value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AdminTheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.expand_more, color: AdminTheme.outline, size: 20),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _openFormDialog(BuildContext context, {AdminOrganization? org}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OrganizationFormDialog(organization: org),
    );
  }
}