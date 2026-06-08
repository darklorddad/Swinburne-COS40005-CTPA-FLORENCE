import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/config/admin_theme.dart';
import 'package:florence/features/admin/core/models/admin_models.dart';
import 'package:florence/features/admin/core/providers/admin_providers.dart';
import 'package:florence/features/admin/core/widgets/admin_sidebar.dart';
import 'package:florence/config/routes.dart';
import 'package:florence/core/services/api_service.dart';

class AdminPatientDetailScreen extends ConsumerStatefulWidget {
  final AdminPatient patient;

  const AdminPatientDetailScreen({super.key, required this.patient});

  @override
  ConsumerState<AdminPatientDetailScreen> createState() => _AdminPatientDetailScreenState();
}

class _AdminPatientDetailScreenState extends ConsumerState<AdminPatientDetailScreen> {
  bool _isLoading = false;
  late String _currentRisk;
  late AdminPatient _patient;
  final TextEditingController _clinicianIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    _currentRisk = _patient.riskLevel.toUpperCase();
  }

  @override
  void dispose() {
    _clinicianIdController.dispose();
    super.dispose();
  }

  Future<void> _wipeDataOnly() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wipe Health Data?'),
        content: const Text('This will delete all glucose, blood pressure, meals, and activity records for this patient. The account profile will remain.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Wipe Data', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final api = ApiService();
        await api.delete('/admin/patients/${widget.patient.id}/data');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Patient health data wiped.'), backgroundColor: AdminTheme.primary),
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AdminTheme.error));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showGenerateDataDialog() async {
    final scenarios = [
      'The Perfect Patient (High Time-in-Range, regular exercise)',
      'The Rollercoaster (Frequent highs and lows, erratic eating)',
      'Dawn Phenomenon (High morning fasting glucose, normal otherwise)',
      'High-Carb Sedentary (Post-meal spikes, zero activity)'
    ];
    String selectedScenario = scenarios[0];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Generate Health Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select a clinical scenario to generate 30 days of data via LLM.'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedScenario,
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: scenarios.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) => setModalState(() => selectedScenario = val!),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton.icon(
                icon: const Icon(Icons.science),
                label: const Text('Generate'),
                style: FilledButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          );
        }
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final api = ApiService();
        await api.post('/admin/patients/${widget.patient.id}/generate-data', {
          'scenario': selectedScenario,
          'days': 30
        });
        ref.invalidate(adminPatientsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Synthetic data generated successfully!'), backgroundColor: AdminTheme.primary),
          );
          // Update local risk level text to match backend changes
          setState(() {
            _currentRisk = (selectedScenario.contains('Rollercoaster') || selectedScenario.contains('Erratic')) ? 'HIGH' : 'LOW';
          });
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AdminTheme.error));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deletePatient() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wipe Patient Account?'),
        content: const Text('This will completely delete the user from the database and Auth system. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final api = ApiService();
        await api.delete('/admin/patients/${widget.patient.id}');
        ref.invalidate(adminPatientsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Patient wiped completely.'), backgroundColor: AdminTheme.primary),
          );
          Navigator.pushReplacementNamed(context, AppRoutes.adminPatientList);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AdminTheme.error),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateRiskLevel(String newRisk) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.updatePatientRiskLevel(widget.patient.id, newRisk);
      
      setState(() => _currentRisk = newRisk);

      // Refresh both the patients list and the activity feed
      ref.invalidate(adminPatientsProvider); // Refresh dashboard/lists
      ref.invalidate(adminActivityProvider); // Refresh activity feed

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
        if (Navigator.canPop(context)) {
          // If we came from the directory normally, pop back to it
          Navigator.pop(context);
        } else {
          // If the history is empty (e.g., page refresh), force route back to directory
          Navigator.pushReplacementNamed(context, AppRoutes.adminPatientList);
        }
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

  Future<void> _unassignClinician() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      
      // Sending 'null' tells the backend to remove the clinician
      await repo.assignClinicianToPatient(widget.patient.id, null);
      
      ref.invalidate(adminPatientsProvider); // Refresh dashboard/lists
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clinician unassigned successfully.'), backgroundColor: AdminTheme.primary),
        );
        
        // Smart routing back to the directory
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.adminPatientList);
        }
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
    final p = _patient;

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
                                      child: Text(
                                        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                        style: const TextStyle(fontSize: 32, color: AdminTheme.onPrimaryContainer),
                                      ),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('General Information', style: Theme.of(context).textTheme.titleLarge),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AdminTheme.primary),
                                      tooltip: 'Edit Profile',
                                      onPressed: () => _showEditPatientDialog(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(Icons.phone_outlined, 'Phone', p.phoneNumber ?? 'Not provided'),
                                _buildInfoRow(Icons.cake_outlined, 'Date of Birth', p.dateOfBirth ?? 'Not provided'),
                                _buildInfoRow(Icons.person_outline, 'Gender', p.gender ?? 'Not provided'),
                                _buildInfoRow(Icons.business_outlined, 'Organisation', p.organisationName ?? 'Florence Platform'),
                                const SizedBox(height: 32),
                                Text('Emergency Contact', style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 16),
                                _buildInfoRow(Icons.contact_phone_outlined, 'Name', p.emergencyContactName ?? 'Not provided'),
                                _buildInfoRow(Icons.family_restroom_outlined, 'Relationship', p.emergencyContactRelationship ?? 'Not provided'),
                                _buildInfoRow(Icons.phone_outlined, 'Phone', p.emergencyContactPhone ?? 'Not provided'),
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
                                      // --- ONLY SHOW 'UNASSIGN' IF A DOCTOR IS ASSIGNED ---
                                      if (p.clinicianName != 'Unassigned') ...[
                                        const Spacer(),
                                        TextButton.icon(
                                          onPressed: _isLoading ? null : _unassignClinician,
                                          icon: const Icon(Icons.person_remove_outlined, size: 16),
                                          label: const Text('Unassign'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AdminTheme.error, // Red text for destructive action
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                      ],
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
                                ),
                                const SizedBox(height: 32),
                                const Divider(height: 1, color: AdminTheme.outlineVariant),
                                const SizedBox(height: 32),

                                // DATA MANAGEMENT
                                const Text('Data Management', style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.onSurfaceVariant)),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading ? null : _showGenerateDataDialog,
                                    icon: const Icon(Icons.science),
                                    label: const Text('Generate Simulated Data (LLM)'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.purple,
                                      side: const BorderSide(color: Colors.purple),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading ? null : _wipeDataOnly,
                                    icon: const Icon(Icons.cleaning_services),
                                    label: const Text('Wipe Health Data (Keep Account)'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange,
                                      side: const BorderSide(color: Colors.orange),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading ? null : _deletePatient,
                                    icon: const Icon(Icons.delete_forever),
                                    label: const Text('Wipe Patient Data & Account'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AdminTheme.error,
                                      side: const BorderSide(color: AdminTheme.error),
                                    ),
                                  ),
                                ),
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

  Future<void> _showEditPatientDialog() async {
    final messenger = ScaffoldMessenger.of(context);
    final nameCtrl = TextEditingController(text: _patient.name);
    final phoneCtrl = TextEditingController(text: _patient.phoneNumber ?? '');
    final dobCtrl = TextEditingController(text: _patient.dateOfBirth ?? '');
    final ecNameCtrl = TextEditingController(text: _patient.emergencyContactName ?? '');
    final ecRelCtrl = TextEditingController(text: _patient.emergencyContactRelationship ?? '');
    final ecPhoneCtrl = TextEditingController(text: _patient.emergencyContactPhone ?? '');
    String selectedGender = _patient.gender ?? 'Male';
    int? selectedOrgId = _patient.organisationId;
    
    final orgsAsync = ref.read(adminOrganizationsProvider);
    final orgs = orgsAsync.valueOrNull ?? [];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Edit Patient Profile'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                  const SizedBox(height: 12),
                  TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
                  const SizedBox(height: 12),
                  TextField(controller: dobCtrl, decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)', hintText: '1990-01-01')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: ['Male', 'Female', 'Other'].contains(selectedGender) ? selectedGender : 'Male',
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (val) => setModalState(() => selectedGender = val!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: selectedOrgId,
                    decoration: const InputDecoration(labelText: 'Organisation'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Unassigned')),
                      ...orgs.map((o) => DropdownMenuItem<int?>(value: o.id, child: Text(o.name))),
                    ],
                    onChanged: (val) => setModalState(() => selectedOrgId = val),
                  ),
                  const Divider(height: 32),
                  Text('Emergency Contact', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(controller: ecNameCtrl, decoration: const InputDecoration(labelText: 'Contact Name')),
                  const SizedBox(height: 12),
                  TextField(controller: ecRelCtrl, decoration: const InputDecoration(labelText: 'Relationship')),
                  const SizedBox(height: 12),
                  TextField(controller: ecPhoneCtrl, decoration: const InputDecoration(labelText: 'Contact Phone')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  final payload = {
                    'name': nameCtrl.text.trim(),
                    'phone_number': phoneCtrl.text.trim(),
                    'date_of_birth': dobCtrl.text.trim().isEmpty ? null : dobCtrl.text.trim(),
                    'gender': selectedGender,
                    'organisation_id': selectedOrgId,
                    'emergency_contact_name': ecNameCtrl.text.trim(),
                    'emergency_contact_relationship': ecRelCtrl.text.trim(),
                    'emergency_contact_phone': ecPhoneCtrl.text.trim(),
                  };
                  await ref.read(adminRepositoryProvider).updatePatientProfile(_patient.id, payload);
                  ref.invalidate(adminPatientsProvider);
                  
                  setState(() {
                    _patient = AdminPatient(
                      id: _patient.id,
                      name: payload['name'] as String,
                      phoneNumber: payload['phone_number'] as String?,
                      gender: payload['gender'] as String?,
                      dateOfBirth: payload['date_of_birth'] as String?,
                      organisationId: selectedOrgId,
                      organisationName: selectedOrgId != null 
                          ? (orgs.where((o) => o.id == selectedOrgId).firstOrNull?.name ?? 'Unknown') 
                          : 'Unassigned',
                      clinicianName: _patient.clinicianName,
                      riskLevel: _patient.riskLevel,
                      lastRiskAssessment: _patient.lastRiskAssessment,
                      latestAlert: _patient.latestAlert,
                      emergencyContactName: payload['emergency_contact_name'] as String?,
                      emergencyContactRelationship: payload['emergency_contact_relationship'] as String?,
                      emergencyContactPhone: payload['emergency_contact_phone'] as String?,
                    );
                  });

                  messenger.showSnackBar(const SnackBar(content: Text('Patient profile updated'), backgroundColor: AdminTheme.primary));
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminTheme.error));
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
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
