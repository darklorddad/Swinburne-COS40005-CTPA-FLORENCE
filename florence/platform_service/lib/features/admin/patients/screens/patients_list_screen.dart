import 'package:flutter/material.dart';
import 'package:florence/config/admin_theme.dart';
import 'package:florence/features/admin/core/widgets/admin_scaffold.dart';
import 'package:florence/features/admin/core/services/permission_service.dart';
import 'package:florence/config/admin_routes.dart';
import 'package:florence/core/services/api_service.dart'; // Import your ApiService

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  final _permissionService = PermissionService();
  final _apiService = ApiService(); // Initialize API Service
  
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterRisk = 'all'; 

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);

    try {
      // Call your FastAPI endpoint
      final response = await _apiService.get('/admin/patients');
      
      setState(() {
        // Parse response into a List of Maps
        _patients = List<Map<String, dynamic>>.from(response);
        _filterPatients();
      });
    } catch (e) {
      debugPrint("Error fetching patients: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load patients: $e'), backgroundColor: AdminTheme.errorColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterPatients() {
    setState(() {
      _filteredPatients = _patients.where((patient) {
        final name = (patient['Name'] ?? '').toString().toLowerCase();
        final phone = (patient['Phone Number'] ?? '').toString().toLowerCase();
        final searchLower = _searchQuery.toLowerCase();
        
        final matchesSearch = _searchQuery.isEmpty || 
                              name.contains(searchLower) || 
                              phone.contains(searchLower);

        final risk = (patient['Risk Level'] ?? '').toString().toLowerCase();
        final matchesRisk = _filterRisk == 'all' || risk == _filterRisk.toLowerCase();

        return matchesSearch && matchesRisk;
      }).toList();
    });
  }

  Future<void> _deletePatient(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text('Are you sure you want to delete $name? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.errorColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _apiService.delete('/admin/patients/$id');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient deleted successfully.'), backgroundColor: AdminTheme.successColor),
        );
        _loadPatients(); // Reload the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete patient: $e'), backgroundColor: AdminTheme.errorColor),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Patients',
      currentRoute: AdminRoutes.patients,
      body: AdminPageLayout(
        title: 'Patients Directory',
        subtitle: 'Manage all patient records in the system',
        actions: [
          ElevatedButton.icon(
            onPressed: _loadPatients,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
        showCard: false,
        child: Column(
          children: [
            _buildSearchAndFilter(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
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
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search patients by name or phone...',
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) {
                  _searchQuery = value;
                  _filterPatients();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                initialValue: _filterRisk,
                decoration: const InputDecoration(labelText: 'Risk Level'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Risk Levels')),
                  DropdownMenuItem(value: 'low', child: Text('Low Risk')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium Risk')),
                  DropdownMenuItem(value: 'high', child: Text('High Risk')),
                ],
                onChanged: (value) {
                  _filterRisk = value ?? 'all';
                  _filterPatients();
                },
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
          headingRowColor: WidgetStateProperty.all(AdminTheme.backgroundColor),
          columns: const [
            DataColumn(label: Text('Patient Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Gender', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Organisation', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Clinician', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Risk Level', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _filteredPatients.map((patient) {
            final id = patient['id'] as int?;
            final risk = patient['Risk Level'] ?? 'UNKNOWN';

            return DataRow(
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(patient['Name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(patient['Phone Number'] ?? 'No Phone', style: TextStyle(fontSize: 12, color: AdminTheme.textSecondaryColor)),
                    ],
                  ),
                ),
                DataCell(Text(patient['Gender'] ?? 'N/A')),
                DataCell(Text(patient['Organisation Name'] ?? 'Unassigned')),
                DataCell(Text(patient['Clinician Name'] ?? 'Unassigned')),
                DataCell(AdminTheme.getStatusBadge(risk)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // View/Edit Action -> Navigates to Patient Detail Screen
                      IconButton(
                        icon: const Icon(Icons.edit, color: AdminTheme.primaryIndigo),
                        tooltip: 'Manage Patient',
                        onPressed: id != null ? () {
                          // Pass the patient data map to the detail screen
                          Navigator.pushNamed(
                            context, 
                            AdminRoutes.patientDetail.replaceAll(':id', id.toString()),
                            arguments: patient, 
                          ).then((_) => _loadPatients()); // Refresh when returning
                        } : null,
                      ),
                      // Delete Action
                      IconButton(
                        icon: const Icon(Icons.delete, color: AdminTheme.errorColor),
                        tooltip: 'Delete Patient',
                        onPressed: id != null ? () => _deletePatient(id, patient['Name'] ?? 'Unknown') : null,
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

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Center(
        child: Text('No patients match your search criteria.', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}