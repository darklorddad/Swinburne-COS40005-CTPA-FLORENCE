import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/button_widgets.dart';
import '../../../../shared/widgets/input_widgets.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';
import '../../core/providers/monitor_data_providers.dart';
import '../../core/repositories/monitor_data_repository.dart';

/// Log Medication Screen
/// Allows users to record medication intake
class LogMedicationScreen extends ConsumerStatefulWidget {
  const LogMedicationScreen({super.key});

  @override
  ConsumerState<LogMedicationScreen> createState() => _LogMedicationScreenState();
}

class _LogMedicationScreenState extends ConsumerState<LogMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicationNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  
  // State
  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();
  String _selectedMedicationType = 'Tablet';
  String _selectedTiming = 'Before Meal';
  
  // Medication type options
  final List<Map<String, dynamic>> _medicationTypes = [
    {'name': 'Tablet', 'icon': Icons.medication},
    {'name': 'Capsule', 'icon': Icons.medication_liquid},
    {'name': 'Injection', 'icon': Icons.vaccines},
    {'name': 'Liquid', 'icon': Icons.water_drop},
    {'name': 'Inhaler', 'icon': Icons.air},
    {'name': 'Other', 'icon': Icons.more_horiz},
  ];
  
  // Timing options
  final List<String> _timingOptions = [
    'Before Meal',
    'After Meal',
    'With Meal',
    'Empty Stomach',
    'Before Bed',
    'As Needed',
  ];
  
  @override
  void dispose() {
    _medicationNameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  /// Handle save
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);
    
    try {
      await ref.read(monitorDataRepositoryProvider).addMedication(
        _medicationNameController.text.trim(),
        _selectedMedicationType,
        _dosageController.text.trim(),
        _selectedTiming,
        _selectedDateTime.toUtc(),
        _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
      
      ref.invalidate(monitorDataProvider);
      
      if (mounted) {
        Helpers.showSuccess(context, 'Medication logged successfully!');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to log medication: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  /// Show date time picker
  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      
      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Medication'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Helpers.showInfo(context, 'Medication history coming soon');
            },
            tooltip: 'View History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              _buildInfoCard(),
              const SizedBox(height: 24),
              
              // Medication name
              _buildMedicationNameSection(),
              const SizedBox(height: 24),
              
              // Medication type
              _buildMedicationTypeSection(),
              const SizedBox(height: 24),
              
              // Dosage
              _buildDosageSection(),
              const SizedBox(height: 24),
              
              // Timing
              _buildTimingSection(),
              const SizedBox(height: 24),
              
              // Date and time
              _buildDateTimeSection(),
              const SizedBox(height: 24),
              
              // Notes
              _buildNotesSection(),
              const SizedBox(height: 32),
              
              // Save button
              PrimaryButton(
                text: 'Save Medication',
                onPressed: _isLoading ? null : _handleSave,
                isLoading: _isLoading,
                width: double.infinity,
              ),
              const SizedBox(height: 16),
              
              // Warning card
              _buildWarningCard(),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build info card
  Widget _buildInfoCard() {
    return BaseCard(
      // backgroundColor: AppTheme.medicationColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            Icons.medication,
            color: AppTheme.medicationColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Track your medications to stay on schedule and monitor effects',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.medicationColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build medication name section
  Widget _buildMedicationNameSection() {
    return CustomTextField(
      label: 'Medication Name',
      hint: 'e.g., Metformin, Insulin',
      controller: _medicationNameController,
      validator: (value) => Validators.name(value, fieldName: 'Medication name'),
      textCapitalization: TextCapitalization.words,
      prefixIcon: const Icon(Icons.medical_services),
    );
  }
  
  /// Build medication type section
  Widget _buildMedicationTypeSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medication Type',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _medicationTypes.length,
            itemBuilder: (context, index) {
              final type = _medicationTypes[index];
              final isSelected = type['name'] == _selectedMedicationType;
              
              return InkWell(
                onTap: () {
                  setState(() => _selectedMedicationType = type['name']);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.medicationColor.withOpacity(0.1)
                        : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.medicationColor
                          : AppTheme.borderColor,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        type['icon'],
                        color: isSelected
                            ? AppTheme.medicationColor
                            : AppTheme.textSecondaryColor,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type['name'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? AppTheme.medicationColor
                                  : AppTheme.textPrimaryColor,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  /// Build dosage section
  Widget _buildDosageSection() {
    return CustomTextField(
      label: 'Dosage',
      hint: 'e.g., 500mg, 10 units',
      controller: _dosageController,
      validator: (value) =>
          Validators.minLength(value, 1, fieldName: 'Dosage'),
      prefixIcon: const Icon(Icons.numbers),
    );
  }
  
  /// Build timing section
  Widget _buildTimingSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timing',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _timingOptions.map((timing) {
              final isSelected = timing == _selectedTiming;
              return ChoiceChip(
                label: Text(timing),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedTiming = timing);
                },
                selectedColor: AppTheme.medicationColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  /// Build date time section
  Widget _buildDateTimeSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date & Time',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          InkWell(
            onTap: _selectDateTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: AppTheme.medicationColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.date(_selectedDateTime),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          Formatters.time(_selectedDateTime),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build notes section
  Widget _buildNotesSection() {
    return CustomTextField(
      label: 'Notes (Optional)',
      hint: 'Any side effects or observations?',
      controller: _notesController,
      maxLines: 3,
      textInputAction: TextInputAction.done,
    );
  }
  
  /// Build warning card
  Widget _buildWarningCard() {
    return BaseCard(
      // backgroundColor: AppTheme.warningColor.withOpacity(0.1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.warningColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Always consult your healthcare provider before starting, stopping, or changing medications.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.warningColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
