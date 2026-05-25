import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:florence/config/admin_theme.dart';
import 'package:florence/config/routes.dart';
import 'package:florence/features/admin/core/widgets/admin_sidebar.dart';
import 'package:florence/features/admin/core/providers/admin_providers.dart';
import 'package:florence/features/admin/core/models/admin_models.dart';
import 'package:florence/features/admin/patients/widgets/add_patient_dialog.dart';

class PatientDirectoryScreen extends ConsumerStatefulWidget {
  const PatientDirectoryScreen({super.key});

  @override
  ConsumerState<PatientDirectoryScreen> createState() =>
      _PatientDirectoryScreenState();
}

class _PatientDirectoryScreenState
    extends ConsumerState<PatientDirectoryScreen> {
  String _searchQuery = '';
  String _filterRisk = 'all';

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(adminPatientsProvider);

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSidebar(currentRoute: AppRoutes.adminPatientList),
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
                          Text('Patient Directory',
                              style: Theme.of(context).textTheme.displaySmall),
                          const SizedBox(height: 8),
                          Text(
                              'Manage and monitor patient health records and risk levels.',
                              style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible:
                                false, // Prevents closing by tapping outside
                            builder: (context) => const AddPatientDialog(),
                          );
                        },
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Register New Patient'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AdminTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
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
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Search by name or ID...',
                            prefixIcon: const Icon(Icons.search,
                                color: AdminTheme.outline),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: AdminTheme.outlineVariant),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AdminTheme.primary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AdminTheme.outlineVariant),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _filterRisk,
                            icon: const Icon(Icons.filter_list,
                                color: AdminTheme.outline, size: 20),
                            items: const [
                              DropdownMenuItem(
                                  value: 'all', child: Text('All Risk Levels')),
                              DropdownMenuItem(
                                  value: 'low', child: Text('Low Risk')),
                              DropdownMenuItem(
                                  value: 'medium', child: Text('Medium Risk')),
                              DropdownMenuItem(
                                  value: 'high', child: Text('High Risk')),
                            ],
                            onChanged: (value) =>
                                setState(() => _filterRisk = value ?? 'all'),
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
                        patientsAsync.when(
                          data: (patients) {
                            // Apply Search & Risk Filters
                            final filteredPatients = patients.where((p) {
                              final matchesSearch = p.name
                                      .toLowerCase()
                                      .contains(_searchQuery.toLowerCase()) ||
                                  p.id.toString().contains(_searchQuery);
                              final matchesRisk = _filterRisk == 'all' ||
                                  p.riskLevel.toLowerCase() == _filterRisk;
                              return matchesSearch && matchesRisk;
                            }).toList();

                            if (filteredPatients.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(48.0),
                                child: Center(
                                    child: Text(
                                        'No patients found matching your criteria.',
                                        style: TextStyle(
                                            color: AdminTheme.outline))),
                              );
                            }

                            return DataTable(
                              headingTextStyle:
                                  Theme.of(context).textTheme.labelSmall,
                              dataTextStyle: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: AdminTheme.onSurface),
                              headingRowColor:
                                  WidgetStateProperty.all(AdminTheme.surface),
                              dividerThickness: 1,
                              columns: const [
                                DataColumn(label: Text('Patient ID')),
                                DataColumn(label: Text('Name')),
                                DataColumn(label: Text('Assigned Clinician')),
                                DataColumn(label: Text('Risk Level')),
                                DataColumn(label: Text('Last Assessment')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: filteredPatients
                                  .map((patient) => _buildDataRow(patient))
                                  .toList(),
                            );
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.all(48.0),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: AdminTheme.primary)),
                          ),
                          error: (error, stack) => Padding(
                            padding: const EdgeInsets.all(48.0),
                            child: Center(
                                child: Text('Error loading patients: $error',
                                    style: const TextStyle(
                                        color: AdminTheme.error))),
                          ),
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

  DataRow _buildDataRow(AdminPatient patient) {
    Color badgeColor = patient.isHighRisk
        ? AdminTheme.errorContainer
        : (patient.isMediumRisk
            ? AdminTheme.surfaceContainerHighest
            : AdminTheme.primaryFixed);
    Color textColor = patient.isHighRisk
        ? AdminTheme.onErrorContainer
        : (patient.isMediumRisk
            ? AdminTheme.onSurfaceVariant
            : AdminTheme.onPrimaryFixed);

    // Format the date if it exists
    final formattedDate = patient.lastRiskAssessment != null
        ? DateFormat('MMM dd, yyyy · hh:mm a')
            .format(DateTime.parse(patient.lastRiskAssessment!).toLocal())
        : 'Never Assessed';

    return DataRow(
      cells: [
        DataCell(Text('#PT-${patient.id.toString().padLeft(4, '0')}',
            style: const TextStyle(color: AdminTheme.outline))),
        DataCell(Text(patient.name,
            style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Row(
          children: [
            CircleAvatar(
                radius: 12,
                backgroundImage:
                    NetworkImage('https://picsum.photos/id/128/200/300')),
            const SizedBox(width: 8),
            Text(patient.clinicianName ?? 'Unassigned'),
          ],
        )),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
              color: badgeColor, borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: textColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(patient.riskLevel,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        )),
        DataCell(Text(formattedDate,
            style: const TextStyle(color: AdminTheme.outline))),
        DataCell(IconButton(
            icon: const Icon(Icons.edit_outlined, color: AdminTheme.outline),
            onPressed: () {
              // Navigate to the detail screen, passing the actual patient model
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.adminPatientDetail,
                arguments: patient,
              );
            })),
      ],
    );
  }
}
