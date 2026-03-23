import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/button_widgets.dart';
import '../../../../shared/widgets/input_widgets.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../core/providers/medication_providers.dart';
import '../../core/repositories/medication_repository.dart';

/// Add Medication Screen
/// Allows users to add a new medication to their cabinet
class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  ConsumerState<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  // State
  bool _isLoading = false;
  int? _selectedMedicationId;
  int? _selectedFrequencyId;
  String? _selectedType;
  String? _selectedTiming;
  
  // Options based on database requirements
  final List<Map<String, dynamic>> _medications = [
    {'id': 1, 'name': 'Metformin (Diabetes)'},
    {'id': 7, 'name': 'Lipitor (Cholesterol)'},
    {'id': 10, 'name': 'Panadol (Pain/Fever)'},
  ];

  final List<Map<String, dynamic>> _frequencies = [
    {'id': 1, 'name': 'Once a day'},
    {'id': 2, 'name': 'Twice a day'},
    {'id': 5, 'name': 'As needed'},
  ];

  final List<String> _types = ['TABLET', 'CAPSULE', 'LIQUID', 'INHALER'];
  
  final List<String> _timings = [
    'BEFORE_MEAL',
    'AFTER_MEAL',
    'AS_NEEDED',
    'ANYTIME',
  ];
  
  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
  
  /// Handle save
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedMedicationId == null || 
        _selectedFrequencyId == null || 
        _selectedType == null || 
        _selectedTiming == null) {
      Helpers.showError(context, 'Please fill in all required fields');
      return;
    }

    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);
    
    try {
      final Map<String, dynamic> data = {
        'medication_id': _selectedMedicationId,
        'frequency_id': _selectedFrequencyId,
        'amount': _amountController.text.trim(),
        'medication_type': _selectedType,
        'timing_instruction': _selectedTiming,
      };

      await ref.read(medicationRepositoryProvider).addPatientMedication(data);
      
      // Invalidate providers to refresh data
      ref.invalidate(patientMedicationsProvider);
      ref.invalidate(dailyMedicationScheduleProvider);
      
      if (mounted) {
        Helpers.showSuccess(context, 'Medication added successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to add medication: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 24),
                    
                    // Medication Dropdown
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Medication',
                        prefixIcon: Icon(Icons.medical_services),
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedMedicationId,
                      items: _medications.map((med) {
                        return DropdownMenuItem<int>(
                          value: med['id'] as int,
                          child: Text(med['name'] as String),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedMedicationId = val),
                      validator: (val) => val == null ? 'Please select a medication' : null,
                    ),
                    const SizedBox(height: 16),

                    // Frequency Dropdown
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        prefixIcon: Icon(Icons.repeat),
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedFrequencyId,
                      items: _frequencies.map((freq) {
                        return DropdownMenuItem<int>(
                          value: freq['id'] as int,
                          child: Text(freq['name'] as String),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedFrequencyId = val),
                      validator: (val) => val == null ? 'Please select frequency' : null,
                    ),
                    const SizedBox(height: 16),

                    // Amount Text Field
                    CustomTextField(
                      label: 'Amount',
                      hint: 'e.g., 1 or 2',
                      controller: _amountController,
                      keyboardType: TextInputType.text,
                      validator: (value) => Validators.minLength(value, 1, fieldName: 'Amount'),
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                    const SizedBox(height: 16),

                    // Type Dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedType,
                      items: _types.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedType = val),
                      validator: (val) => val == null ? 'Please select type' : null,
                    ),
                    const SizedBox(height: 16),

                    // Timing Dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Timing',
                        prefixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedTiming,
                      items: _timings.map((timing) {
                        return DropdownMenuItem<String>(
                          value: timing,
                          child: Text(timing.replaceAll('_', ' ')),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedTiming = val),
                      validator: (val) => val == null ? 'Please select timing' : null,
                    ),
                    const SizedBox(height: 32),
                    
                    // Save button
                    PrimaryButton(
                      text: 'Add to Cabinet',
                      onPressed: _isLoading ? null : _handleSave,
                      isLoading: _isLoading,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 24),
                    _buildWarningCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return BaseCard(
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Add your prescribed medications here to track your daily intake.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWarningCard() {
    return BaseCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.primaryRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ensure the details match your prescription. Consult your doctor if you are unsure.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.primaryRed),
            ),
          ),
        ],
      ),
    );
  }
}
