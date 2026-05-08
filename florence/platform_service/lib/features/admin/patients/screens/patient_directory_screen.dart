import 'package:flutter/material.dart';
import 'package:florence/config/admin_theme.dart';

class PatientDirectoryScreen extends StatelessWidget {
  const PatientDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // const AdminSidebar(),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header (Same as Dashboard)
                  // _buildHeader(context),
                  // const SizedBox(height: 48),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Patient Directory', style: Theme.of(context).textTheme.displaySmall),
                          const SizedBox(height: 8),
                          Text('Manage and monitor patient health records and risk levels.', 
                            style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Register New Patient'),
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
                          decoration: InputDecoration(
                            hintText: 'Search by name, ID, or condition...',
                            prefixIcon: const Icon(Icons.search, color: AdminTheme.outline),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AdminTheme.outlineVariant),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AdminTheme.outlineVariant),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.filter_list, color: AdminTheme.outline, size: 20),
                            SizedBox(width: 8),
                            Text('Filter by Risk Level', style: TextStyle(color: AdminTheme.onSurfaceVariant)),
                            SizedBox(width: 16),
                            Icon(Icons.keyboard_arrow_down, color: AdminTheme.outline, size: 20),
                          ],
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
                        DataTable(
                          headingTextStyle: Theme.of(context).textTheme.labelSmall,
                          dataTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AdminTheme.onSurface),
                          headingRowColor: MaterialStateProperty.all(AdminTheme.surface),
                          dividerThickness: 1,
                          columns: const [
                            DataColumn(label: Text('Patient ID')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Assigned Clinician')),
                            DataColumn(label: Text('Risk Level')),
                            DataColumn(label: Text('Last Sync Date')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: [
                            _buildDataRow('#PT-8842', 'Eleanor Vance', 'Dr. H. Montague', 'High Risk', true, 'Oct 24, 2023 · 09:41 AM'),
                            _buildDataRow('#PT-8901', 'Jameson Locke', 'NP S. Carter', 'Low Risk', false, 'Oct 23, 2023 · 14:22 PM'),
                            _buildDataRow('#PT-9112', 'Sarah Connor', 'Dr. H. Montague', 'Medium Risk', false, 'Oct 23, 2023 · 11:05 AM', isMedium: true),
                            _buildDataRow('#PT-9155', 'Marcus Fenix', 'PA R. Santiago', 'Low Risk', false, 'Oct 22, 2023 · 08:30 AM'),
                          ],
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Showing 1 to 4 of 128 patients', style: TextStyle(color: AdminTheme.outline)),
                              Row(
                                children: [
                                  OutlinedButton(
                                    onPressed: null, 
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                    child: const Icon(Icons.chevron_left, size: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () {}, 
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                    child: const Icon(Icons.chevron_right, size: 20),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
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

  DataRow _buildDataRow(String id, String name, String doctor, String riskLabel, bool isHighRisk, String syncDate, {bool isMedium = false}) {
    Color badgeColor = isHighRisk ? AdminTheme.errorContainer : (isMedium ? AdminTheme.surfaceContainerHighest : AdminTheme.primaryFixed);
    Color textColor = isHighRisk ? AdminTheme.onErrorContainer : (isMedium ? AdminTheme.onSurfaceVariant : AdminTheme.onPrimaryFixed);
    
    return DataRow(
      cells: [
        DataCell(Text(id, style: const TextStyle(color: AdminTheme.outline))),
        DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(
          Row(
            children: [
              const CircleAvatar(radius: 12, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=3')),
              const SizedBox(width: 8),
              Text(doctor),
            ],
          )
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: textColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(riskLabel, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ),
        DataCell(Text(syncDate, style: const TextStyle(color: AdminTheme.outline))),
        DataCell(IconButton(icon: const Icon(Icons.more_vert, color: AdminTheme.outline), onPressed: () {})),
      ],
    );
  }
}