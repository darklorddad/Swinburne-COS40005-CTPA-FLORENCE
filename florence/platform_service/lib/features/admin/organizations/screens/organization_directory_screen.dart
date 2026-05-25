import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/config/admin_theme.dart';
import 'package:florence/config/routes.dart';
import 'package:florence/features/admin/core/widgets/admin_sidebar.dart';
import 'package:florence/features/admin/core/providers/admin_providers.dart';
import 'package:florence/features/admin/core/models/admin_models.dart';
import 'package:florence/features/admin/organizations/widgets/organization_form_dialog.dart';

class OrganizationDirectoryScreen extends ConsumerStatefulWidget {
  const OrganizationDirectoryScreen({super.key});

  @override
  ConsumerState<OrganizationDirectoryScreen> createState() => _OrganizationDirectoryScreenState();
}

class _OrganizationDirectoryScreenState extends ConsumerState<OrganizationDirectoryScreen> {
  String _searchQuery = '';
  String _sectorFilter = 'All';
  String _typeFilter = 'All';
  String _stateFilter = 'All';

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
                  
                  // Filters
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: 300,
                        child: TextField(
                          onChanged: (value) => setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Search by name, email, or state...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      _buildDropdown('Sector', ['All', 'Public', 'Private', 'NGO', 'Other'], _sectorFilter, (val) => setState(() => _sectorFilter = val!)),
                      _buildDropdown('Facility Type', ['All', 'Hospital', 'Clinic', 'Health Centre', 'Lab', 'Other'], _typeFilter, (val) => setState(() => _typeFilter = val!)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Card(
                    child: orgsAsync.when(
                      loading: () => const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator())),
                      error: (err, _) => Padding(padding: const EdgeInsets.all(48), child: Center(child: Text('Error: $err'))),
                      data: (orgs) {
                        final filtered = orgs.where((o) {
                          final matchesSearch = o.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                                (o.email ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                                (o.state ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
                          final matchesSector = _sectorFilter == 'All' || o.sector == _sectorFilter;
                          final matchesType = _typeFilter == 'All' || o.facilityType == _typeFilter;
                          return matchesSearch && matchesSector && matchesType;
                        }).toList();

                        if (filtered.isEmpty) return const Padding(padding: EdgeInsets.all(48), child: Center(child: Text('No organizations found.')));

                        return DataTable(
                          headingTextStyle: Theme.of(context).textTheme.labelSmall,
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
                              DataCell(Text(org.sector ?? '-')),
                              DataCell(Text(org.facilityType ?? '-')),
                              DataCell(Text(org.state ?? '-')),
                              DataCell(Text(org.patientCount.toString())),
                              DataCell(Text(org.clinicianCount.toString())),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility_outlined, color: AdminTheme.primary),
                                      onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.organizationDetail, arguments: org),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AdminTheme.outline),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AdminTheme.outlineVariant), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
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