import 'package:flutter/material.dart';
import '../../../../config/admin_theme.dart';
import '../../core/widgets/admin_scaffold.dart';
import '../../../../core/services/api_service.dart';

class PatientDetailScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;

  const PatientDetailScreen({super.key, required this.patientData});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final _apiService = ApiService();
  bool _isLoading = false;
  
  late String _currentRisk;
  final TextEditingController _clinicianIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentRisk = widget.patientData['Risk Level'] ?? 'LOW';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patientData;

    return AdminScaffold(
      title: 'Patient Details',
      currentRoute: '/admin/patients',
      showBackButton: true,
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: AdminPageLayout(
          title: p['Name'] ?? 'Unknown Patient',
          subtitle: 'ID: ${p['id']} | Org: ${p['Organisation Name'] ?? 'N/A'}',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Patient Read-Only Info
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('General Information', style: Theme.of(context).textTheme.titleLarge),
                    const Divider(),
                    _buildInfoRow('Gender', p['Gender']),
                    _buildInfoRow('Date of Birth', p['Date of Birth']),
                    _buildInfoRow('Phone', p['Phone Number']),
                    const SizedBox(height: 24),
                    
                    Text('Emergency Contact', style: Theme.of(context).textTheme.titleLarge),
                    const Divider(),
                    _buildInfoRow('Name', p['Emergency Contact Name']),
                    _buildInfoRow('Relationship', p['Emergency Contact Relationship']),
                    _buildInfoRow('Phone', p['Emergency Contact Phone Number']),
                  ],
                ),
              ),
              
              const SizedBox(width: 32),

              // Right Column: Admin Actions
              Expanded(
                flex: 1,
                child: Card(
                  color: AdminTheme.backgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin Controls', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        
                        // Risk Level Update
                        const Text('Risk Level', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _currentRisk,
                          decoration: const InputDecoration(filled: true, fillColor: Colors.white),
                          items: const [
                            DropdownMenuItem(value: 'LOW', child: Text('Low Risk')),
                            DropdownMenuItem(value: 'MEDIUM', child: Text('Medium Risk')),
                            DropdownMenuItem(value: 'HIGH', child: Text('High Risk')),
                          ],
                          onChanged: (val) {
                            if (val != null) _updateRiskLevel(val);
                          },
                        ),
                        
                        const SizedBox(height: 24),

                        // Clinician Assignment
                        const Text('Assign Clinician (Enter ID)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _clinicianIdController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: p['Clinician Name'] ?? 'Enter Clinician ID',
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _assignClinician,
                              child: const Text('Assign'),
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
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.textSecondaryColor))),
          Expanded(child: Text(value?.toString() ?? 'N/A', style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}