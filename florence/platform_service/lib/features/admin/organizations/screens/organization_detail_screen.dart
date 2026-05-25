import 'package:flutter/material.dart';
import 'package:florence/config/admin_theme.dart';
import 'package:florence/features/admin/core/models/admin_models.dart';
import 'package:florence/features/admin/core/widgets/admin_sidebar.dart';
import 'package:florence/features/admin/organizations/widgets/organization_form_dialog.dart';

class OrganizationDetailScreen extends StatelessWidget {
  final AdminOrganization organization;
  const OrganizationDetailScreen({super.key, required this.organization});

  @override
  Widget build(BuildContext context) {
    final o = organization;
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSidebar(currentRoute: '/admin/organizations'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                      const SizedBox(width: 8),
                      Text(o.name, style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT CARD
                      Expanded(
                        flex: 7,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Facility Details', style: Theme.of(context).textTheme.titleLarge),
                                const Divider(height: 32),
                                _RowItem('Sector', o.sector),
                                _RowItem('Type', o.facilityType),
                                _RowItem('State', o.state),
                                _RowItem('Address', o.fullAddress),
                                _RowItem('Phone', o.phoneNumber),
                                _RowItem('Email', o.email),
                                _RowItem('Website', o.website),
                                _RowItem('Hours', o.is24Hours ? '24 Hours' : o.operatingHours),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // RIGHT CARD
                      Expanded(
                        flex: 4,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('System Usage', style: Theme.of(context).textTheme.titleLarge),
                                const Divider(height: 32),
                                _StatRow(Icons.people, 'Patients', o.patientCount.toString()),
                                const SizedBox(height: 16),
                                _StatRow(Icons.medical_services, 'Clinicians', o.clinicianCount.toString()),
                                const SizedBox(height: 48),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Edit Organization'),
                                    onPressed: () => showDialog(context: context, builder: (c) => OrganizationFormDialog(organization: o)),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String? value; // Changed to String? to accept nulls

  const _RowItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    // Safely check if the value is null, empty, or literally the word 'null'
    final displayValue = (value == null || value!.isEmpty || value == 'null') 
        ? '-' 
        : value!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, 
            child: Text(label, style: const TextStyle(color: AdminTheme.outline))
          ),
          Expanded(
            child: Text(
              displayValue, 
              style: const TextStyle(fontWeight: FontWeight.w500, color: AdminTheme.onSurface)
            )
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _StatRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AdminTheme.primary),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(fontSize: 16, color: AdminTheme.outline)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }
}