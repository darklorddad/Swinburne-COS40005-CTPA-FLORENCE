import 'package:flutter/material.dart';
import '../../../../config/admin_theme.dart';
import '../../core/widgets/admin_scaffold.dart';
import '../../core/services/permission_service.dart';
import '../../../../config/admin_routes.dart';

/// Patients List Screen
/// View and manage patients (scoped by permissions)
class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  final _permissionService = PermissionService();
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, inactive
  String _filterRisk = 'all'; // all, low, moderate, high

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call

    // Mock patient data
    final currentUser = _permissionService.currentUser;
    final orgId = currentUser?.organizationId;

    // Generate mock patients based on organization
    final mockPatients = _generateMockPatients(orgId);

    setState(() {
      _patients = mockPatients;
      _filteredPatients = mockPatients;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _generateMockPatients(String? orgId) {
    // Mock data - would come from API in real app
    return [
      {
        'id': '1',
        'name': 'John Doe',
        'mrn': 'MRN-001234',
        'age': 45,
        'gender': 'Male',
        'diabetesType': 'Type 2',
        'status': 'active',
        'risk': 'moderate',
        'lastVisit': DateTime.now().subtract(const Duration(days: 7)),
        'nextAppointment': DateTime.now().add(const Duration(days: 14)),
        'phone': '+60 12-3456789',
        'email': 'john.doe@example.com',
      },
      {
        'id': '2',
        'name': 'Jane Smith',
        'mrn': 'MRN-001235',
        'age': 52,
        'gender': 'Female',
        'diabetesType': 'Type 1',
        'status': 'active',
        'risk': 'high',
        'lastVisit': DateTime.now().subtract(const Duration(days: 2)),
        'nextAppointment': DateTime.now().add(const Duration(days: 7)),
        'phone': '+60 12-9876543',
        'email': 'jane.smith@example.com',
      },
      {
        'id': '3',
        'name': 'Robert Brown',
        'mrn': 'MRN-001236',
        'age': 38,
        'gender': 'Male',
        'diabetesType': 'Type 2',
        'status': 'active',
        'risk': 'low',
        'lastVisit': DateTime.now().subtract(const Duration(days: 30)),
        'nextAppointment': DateTime.now().add(const Duration(days: 30)),
        'phone': '+60 12-5551234',
        'email': 'robert.brown@example.com',
      },
      {
        'id': '4',
        'name': 'Emily Wilson',
        'mrn': 'MRN-001237',
        'age': 61,
        'gender': 'Female',
        'diabetesType': 'Type 2',
        'status': 'active',
        'risk': 'high',
        'lastVisit': DateTime.now().subtract(const Duration(days: 5)),
        'nextAppointment': DateTime.now().add(const Duration(days: 10)),
        'phone': '+60 12-7778888',
        'email': 'emily.wilson@example.com',
      },
      {
        'id': '5',
        'name': 'Michael Chen',
        'mrn': 'MRN-001238',
        'age': 29,
        'gender': 'Male',
        'diabetesType': 'Type 1',
        'status': 'active',
        'risk': 'moderate',
        'lastVisit': DateTime.now().subtract(const Duration(days: 14)),
        'nextAppointment': DateTime.now().add(const Duration(days: 21)),
        'phone': '+60 12-3334444',
        'email': 'michael.chen@example.com',
      },
    ];
  }

  void _filterPatients() {
    setState(() {
      _filteredPatients = _patients.where((patient) {
        // Search filter
        final matchesSearch = _searchQuery.isEmpty ||
            patient['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
            patient['mrn'].toLowerCase().contains(_searchQuery.toLowerCase());

        // Status filter
        final matchesStatus = _filterStatus == 'all' ||
            patient['status'].toLowerCase() == _filterStatus.toLowerCase();

        // Risk filter
        final matchesRisk = _filterRisk == 'all' ||
            patient['risk'].toLowerCase() == _filterRisk.toLowerCase();

        return matchesSearch && matchesStatus && matchesRisk;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = _permissionService.canCreatePatient;

    return AdminScaffold(
      title: 'Patients',
      currentRoute: AdminRoutes.patients,
      body: AdminPageLayout(
        title: 'Patients',
        subtitle: _permissionService.isSuperAdmin
            ? 'Manage all patients in the system'
            : 'Manage patients in your organization',
        actions: canCreate
            ? [
                ElevatedButton.icon(
                  onPressed: () {
                    AdminRoutes.push(context, AdminRoutes.createPatient);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Patient'),
                ),
              ]
            : null,
        showCard: false,
        child: Column(
          children: [
            // Search and Filter Bar
            _buildSearchAndFilter(),

            const SizedBox(height: 16),

            // Patients Table
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_filteredPatients.isEmpty)
              _buildEmptyState()
            else
              _buildPatientsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Search Field
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search patients by name or MRN...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _filterPatients();
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // Risk Filter
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: _filterRisk,
                    decoration: InputDecoration(
                      labelText: 'Risk Level',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Risk')),
                      DropdownMenuItem(value: 'low', child: Text('Low Risk')),
                      DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                      DropdownMenuItem(value: 'high', child: Text('High Risk')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterRisk = value ?? 'all';
                      });
                      _filterPatients();
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // Status Filter
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    initialValue: _filterStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Status')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterStatus = value ?? 'all';
                      });
                      _filterPatients();
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // Refresh Button
                IconButton(
                  onPressed: _loadPatients,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Results count
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Showing ${_filteredPatients.length} of ${_patients.length} patients',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AdminTheme.textSecondaryColor,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientsTable() {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 48,
          horizontalMargin: 24,
          headingRowColor: WidgetStateProperty.all(
            AdminTheme.backgroundColor,
          ),
          columns: const [
            DataColumn(label: Text('Patient', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('MRN', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Age/Gender', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Risk', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Last Visit', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Next Appointment', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w700))),
          ],
          rows: _filteredPatients.map((patient) {
            return DataRow(
              cells: [
                // Patient
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: _getRiskColor(patient['risk']).withOpacity(0.2),
                        child: Icon(
                          Icons.person,
                          color: _getRiskColor(patient['risk']),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            patient['name'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            patient['email'],
                            style: TextStyle(
                              fontSize: 12,
                              color: AdminTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // MRN
                DataCell(
                  Text(
                    patient['mrn'],
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                // Age/Gender
                DataCell(
                  Text('${patient['age']}/${patient['gender'][0]}'),
                ),
                // Type
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AdminTheme.infoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      patient['diabetesType'],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AdminTheme.infoColor,
                      ),
                    ),
                  ),
                ),
                // Risk
                DataCell(_buildRiskBadge(patient['risk'])),
                // Last Visit
                DataCell(
                  Text(_formatDate(patient['lastVisit'])),
                ),
                // Next Appointment
                DataCell(
                  Text(_formatDate(patient['nextAppointment'])),
                ),
                // Actions
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 18),
                        onPressed: () => _showPatientDetail(patient),
                        tooltip: 'View',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      if (_permissionService.canEditPatient)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Edit feature coming soon')),
                            );
                          },
                          tooltip: 'Edit',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.event_note, size: 18),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('View logbook feature coming soon')),
                          );
                        },
                        tooltip: 'Logbook',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRiskBadge(String risk) {
    final color = _getRiskColor(risk);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        risk.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return AdminTheme.successColor;
      case 'moderate':
        return AdminTheme.warningColor;
      case 'high':
        return AdminTheme.errorColor;
      default:
        return AdminTheme.textSecondaryColor;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) {
      // Past date
      final daysDiff = difference.inDays.abs();
      if (daysDiff == 0) return 'Today';
      if (daysDiff == 1) return 'Yesterday';
      if (daysDiff < 7) return '$daysDiff days ago';
      if (daysDiff < 30) return '${(daysDiff / 7).floor()} weeks ago';
      return '${date.day}/${date.month}/${date.year}';
    } else {
      // Future date
      if (difference.inDays == 0) return 'Today';
      if (difference.inDays == 1) return 'Tomorrow';
      if (difference.inDays < 7) return 'In ${difference.inDays} days';
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.personal_injury_outlined,
                size: 64,
                color: AdminTheme.textLightColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No patients found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty || _filterRisk != 'all' || _filterStatus != 'all'
                    ? 'Try adjusting your search or filters'
                    : 'Get started by adding your first patient',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AdminTheme.textSecondaryColor,
                    ),
              ),
              if (_permissionService.canCreatePatient) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    AdminRoutes.push(context, AdminRoutes.createPatient);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Patient'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPatientDetail(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _getRiskColor(patient['risk']).withOpacity(0.2),
              child: Icon(
                Icons.person,
                color: _getRiskColor(patient['risk']),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                patient['name'],
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('MRN', patient['mrn']),
              const SizedBox(height: 12),
              _buildInfoRow('Age', patient['age'].toString()),
              const SizedBox(height: 12),
              _buildInfoRow('Gender', patient['gender']),
              const SizedBox(height: 12),
              _buildInfoRow('Diabetes Type', patient['diabetesType']),
              const SizedBox(height: 12),
              _buildInfoRow('Risk Level', patient['risk']),
              const SizedBox(height: 12),
              _buildInfoRow('Phone', patient['phone']),
              const SizedBox(height: 12),
              _buildInfoRow('Email', patient['email']),
              const SizedBox(height: 12),
              _buildInfoRow('Last Visit', _formatDate(patient['lastVisit'])),
              const SizedBox(height: 12),
              _buildInfoRow('Next Appointment', _formatDate(patient['nextAppointment'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (_permissionService.canEditPatient)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit feature coming soon')),
                );
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit'),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AdminTheme.textSecondaryColor,
                ),
          ),
        ),
      ],
    );
  }
}