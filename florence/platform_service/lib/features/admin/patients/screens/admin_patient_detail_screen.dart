import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/config/admin_theme.dart';
import 'package:florence/features/admin/core/models/admin_models.dart';
import 'package:florence/features/admin/core/providers/admin_providers.dart';
import 'package:florence/features/admin/core/widgets/admin_sidebar.dart';
import 'package:florence/config/routes.dart';

class AdminPatientDetailScreen extends ConsumerStatefulWidget {
  final AdminPatient patient;

  const AdminPatientDetailScreen({super.key, required this.patient});

  @override
  ConsumerState<AdminPatientDetailScreen> createState() => _AdminPatientDetailScreenState();
}

class _AdminPatientDetailScreenState extends ConsumerState<AdminPatientDetailScreen> {
  bool _isLoading = false;
  late String _currentRisk;
  final TextEditingController _clinicianIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentRisk = widget.patient.riskLevel.toUpperCase();
  }

  @override
  void dispose() {
    _clinicianIdController.dispose();
    super.dispose();
  }

  Future<void> _updateRiskLevel(String newRisk) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.updatePatientRiskLevel(widget.patient.id, newRisk);
      
      setState(() => _currentRisk = newRisk);
      ref.invalidate(adminPatientsProvider); // Refresh dashboard/lists

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Risk Level updated successfully.'), backgroundColor: AdminTheme.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AdminTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _assignClinician() async {
    if (_clinicianIdController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final clinicianId = int.tryParse(_clinicianIdController.text.trim());
      
      await repo.assignClinicianToPatient(widget.patient.id, clinicianId);
      ref.invalidate(adminPatientsProvider); // Refresh dashboard/lists
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clinician assigned successfully.'), backgroundColor: AdminTheme.primary),
        );
        Navigator.pop(context); // Go back to directory
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AdminTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSidebar(currentRoute: '/admin/patients'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumb Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AdminTheme.outline),
                        onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.adminPatientList),
                      ),
                      const SizedBox(width: 8),
                      Text('Patients', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AdminTheme.outline)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.chevron_right, color: AdminTheme.outline, size: 20),
                      ),
                      Text(p.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT COLUMN: Patient Info
                      Expanded(
                        flex: 7,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundColor: AdminTheme.primaryContainer,
                                      backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${p.id}'),
                                    ),
                                    const SizedBox(width: 24),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name, style: Theme.of(context).textTheme.headlineMedium),
                                        const SizedBox(height: 4),
                                        Text('Patient ID: #PT-${p.id.toString().padLeft(4, '0')}', style: const TextStyle(color: AdminTheme.outline)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                const Divider(height: 1, color: AdminTheme.outlineVariant),
                                const SizedBox(height: 32),
                                Text('General Information', style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 16),
                                _buildInfoRow(Icons.phone_outlined, 'Phone', p.phoneNumber ?? 'Not provided'),
                                _buildInfoRow(Icons.cake_outlined, 'Date of Birth', p.dateOfBirth ?? 'Not provided'),
                                _buildInfoRow(Icons.person_outline, 'Gender', p.gender ?? 'Not provided'),
                                _buildInfoRow(Icons.business_outlined, 'Organization', p.organisationName ?? 'Florence Platform'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),

                      // RIGHT COLUMN: Admin Oversight Controls
                      Expanded(
                        flex: 4,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.admin_panel_settings_outlined, color: AdminTheme.primary),
                                    const SizedBox(width: 12),
                                    Text('Admin Oversight', style: Theme.of(context).textTheme.titleLarge),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                
                                // Risk Level Controller
                                const Text('Oversight Risk Level', style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.onSurfaceVariant)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _currentRisk,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AdminTheme.surface,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminTheme.outlineVariant)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminTheme.outlineVariant)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'LOW', child: Text('Low Risk')),
                                    DropdownMenuItem(value: 'MEDIUM', child: Text('Medium Risk')),
                                    DropdownMenuItem(value: 'HIGH', child: Text('High Risk (Action Required)')),
                                  ],
                                  onChanged: _isLoading ? null : (val) {
                                    if (val != null && val != _currentRisk) _updateRiskLevel(val);
                                  },
                                ),
                                
                                const SizedBox(height: 32),
                                const Divider(height: 1, color: AdminTheme.outlineVariant),
                                const SizedBox(height: 32),

                                // Clinician Assignment Controller
                                const Text('Assigned Clinician', style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.onSurfaceVariant)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AdminTheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AdminTheme.outlineVariant),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.medical_information_outlined, color: AdminTheme.outline, size: 20),
                                      const SizedBox(width: 12),
                                      Text(p.clinicianName ?? 'Unassigned', style: const TextStyle(fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _clinicianIdController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: 'Enter Clinician ID',
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminTheme.outlineVariant)),
                                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminTheme.outlineVariant)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton(
                                      onPressed: _isLoading ? null : _assignClinician,
                                      child: _isLoading 
                                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                          : const Text('Assign'),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AdminTheme.outline),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AdminTheme.outline, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: AdminTheme.onSurface)),
          ),
        ],
      ),
    );
  }
}