import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/core/utils/validators.dart';
import 'package:florence/core/utils/formatters.dart';
import 'package:florence/core/utils/helpers.dart';
import 'package:florence/shared/widgets/button_widgets.dart';
import 'package:florence/shared/widgets/input_widgets.dart';
import 'package:florence/shared/widgets/card_widgets.dart';
import 'package:florence/config/theme.dart';
import 'package:florence/config/routes.dart';
import 'package:florence/features/patient/core/providers/monitor_data_providers.dart';
import 'package:florence/features/patient/core/repositories/monitor_data_repository.dart';
import 'package:florence/features/patient/recommendations/services/recommendation_engine.dart';
import 'package:florence/features/patient/dashboard/providers/insight_provider.dart';

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
  bool _forcePop = false;
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
      
      await ref.refresh(monitorDataProvider.future);

      ref.read(recommendationProvider.notifier).generateRecommendations(
        timeframe: 'daily',
      );

      if (mounted) {
        AppRoutes.pushAndRemoveUntil(
          context, 
          AppRoutes.dashboard,
          arguments: {'message': 'Medication logged successfully!'},
        );
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
    final bool hasChanges = !_forcePop && 
        (_medicationNameController.text.isNotEmpty || 
         _dosageController.text.isNotEmpty || 
         _notesController.text.isNotEmpty);

    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final bool shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text('You have entered data. Are you sure you want to go back without saving?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep Editing'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _forcePop = true);
                  Navigator.pop(context, true);
                },
                style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ?? false;

        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Log Medication'),
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: AppTheme.getBorderColor(context), height: 1.0),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: const Icon(Icons.history),
                onPressed: () {
                  Helpers.showInfo(context, 'Medication history coming soon');
                },
                tooltip: 'View History',
              ),
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Info card
                        _buildInfoCard(),
                        const SizedBox(height: 20),
                        
                        // Medication name
                        _buildMedicationNameSection(),
                        const SizedBox(height: 20),
                        
                        // Medication type
                        _buildMedicationTypeSection(),
                        const SizedBox(height: 20),
                        
                        // Dosage
                        _buildDosageSection(),
                        const SizedBox(height: 20),
                        
                        // Timing
                        _buildTimingSection(),
                        const SizedBox(height: 20),
                        
                        // Date and time
                        _buildDateTimeSection(),
                        const SizedBox(height: 20),
                        
                        // Notes
                        _buildNotesSection(),
                        const SizedBox(height: 32),
                        
                        // Save button
                        PrimaryButton(
                          text: 'Save Medication',
                          onPressed: (_isLoading || _medicationNameController.text.trim().isEmpty || _dosageController.text.trim().isEmpty) ? null : _handleSave,
                          isLoading: _isLoading,
                          width: double.infinity,
                          padding: Helpers.isDesktop(context)
                              ? const EdgeInsets.symmetric(horizontal: 24, vertical: 20)
                              : null,
                        ),
                        const SizedBox(height: 20),
                        
                        // Warning card
                        _buildWarningCard(),
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);
    final titleIconColor = isDark ? Colors.blue.shade200 : AppTheme.primaryBlue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: titleIconColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Track your medications to stay on schedule and monitor effects.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.infoColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationNameSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);
    final titleIconColor = isDark ? Colors.blue.shade200 : AppTheme.primaryBlue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: titleIconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medical_services_outlined,
                  color: titleIconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Medication Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Medication Name',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _medicationNameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            validator: (value) => Validators.name(value, fieldName: 'Medication name'),
            decoration: InputDecoration(
              hintText: 'e.g., Metformin, Insulin',
              hintStyle: const TextStyle(color: AppTheme.textSecondaryColor),
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
              ),
              prefixIcon: const Icon(Icons.medical_services, color: AppTheme.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationTypeSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medication Type',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
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
                        ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryBlue : AppTheme.getBorderColor(context),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        type['icon'],
                        color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondaryColor,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type['name'],
                        style: TextStyle(
                          color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimaryColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
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

  Widget _buildDosageSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dosage',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _dosageController,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            validator: (value) => Validators.minLength(value, 1, fieldName: 'Dosage'),
            decoration: InputDecoration(
              hintText: 'e.g., 500mg, 10 units',
              hintStyle: const TextStyle(color: AppTheme.textSecondaryColor),
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
              ),
              prefixIcon: const Icon(Icons.numbers, color: AppTheme.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timing',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
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
                onSelected: (_) => setState(() => _selectedTiming = timing),
                selectedColor: AppTheme.primaryBlue,
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.getBorderColor(context),
                  ),
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);
    final titleIconColor = isDark ? Colors.blue.shade200 : AppTheme.primaryBlue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: titleIconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: titleIconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Date and Time',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.borderColor,
              ),
            ),
            child: Column(
              children: [
                _buildCompactPickerItem(
                  label: 'Date',
                  value: Formatters.date(_selectedDateTime),
                  icon: Icons.calendar_today_outlined,
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDateTime,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDateTime = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          _selectedDateTime.hour,
                          _selectedDateTime.minute,
                        );
                      });
                    }
                  },
                ),
                Divider(height: 1, color: AppTheme.borderColor.withValues(alpha: 0.5)),
                _buildCompactPickerItem(
                  label: 'Time',
                  value: TimeOfDay.fromDateTime(_selectedDateTime).format(context),
                  icon: Icons.access_time_outlined,
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDateTime = DateTime(
                          _selectedDateTime.year,
                          _selectedDateTime.month,
                          _selectedDateTime.day,
                          picked.hour,
                          picked.minute,
                        );
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPickerItem({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondaryColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Text(
                    '$label:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: AppTheme.textSecondaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes (Optional)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            textInputAction: TextInputAction.done,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Any side effects or observations?',
              hintStyle: const TextStyle(color: AppTheme.textSecondaryColor),
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
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
