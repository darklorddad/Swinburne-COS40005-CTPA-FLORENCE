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
import '../../core/models/health_data_models.dart';
import '../../core/providers/monitor_data_providers.dart';
import '../../core/repositories/monitor_data_repository.dart';

/// Log Glucose Screen
/// Allows users to record blood glucose readings
class LogGlucoseScreen extends ConsumerStatefulWidget {
  const LogGlucoseScreen({super.key});

  @override
  ConsumerState<LogGlucoseScreen> createState() => _LogGlucoseScreenState();
}

class _LogGlucoseScreenState extends ConsumerState<LogGlucoseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _glucoseController = TextEditingController();
  final _notesController = TextEditingController();

  // State
  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();
  String _selectedTiming = 'No Meal';
  String _selectedMealType = 'BREAKFAST';

  final List<String> _timingOptions = [
    'No Meal',
    'Before Meal',
    'After Meal',
  ];

  final List<String> _mealTypeOptions = [
    'BREAKFAST',
    'LUNCH',
    'DINNER',
  ];

  @override
  void dispose() {
    _glucoseController.dispose();
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
      final glucoseValue = double.parse(_glucoseController.text);
      // Use the repository provider
      final repo = ref.read(monitorDataRepositoryProvider);

      if (_selectedTiming == 'No Meal') {
        await repo.addGlucoseReading(GlucoseReading(
          id: '', // Backend generates ID
          timestamp: _selectedDateTime,
          value: glucoseValue,
          context: _selectedTiming,
        ));
      } 
      else {
        final isBefore = _selectedTiming == 'Before Meal';
        // Delegate complex logic to repository
        await repo.addMeal(
          _selectedMealType,
          _selectedDateTime, // Date only used for day
          (!isBefore && _notesController.text.trim().isNotEmpty) ? _notesController.text.trim() : null,
          isBefore ? glucoseValue : null,
          isBefore ? _selectedDateTime : null,
          !isBefore ? glucoseValue : null,
          !isBefore ? _selectedDateTime : null,
        );
      }
      
      // Invalidate provider to refresh dashboard
      ref.invalidate(monitorDataProvider);

      if (mounted) {
        Helpers.showSuccess(context, 'Glucose reading saved successfully!');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('409')) {
          Helpers.showError(context, 'A log for this meal already exists today.');
        } else {
          Helpers.showError(context, 'Failed to save glucose reading: ${e.toString()}');
        }
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
    final glucoseValue = double.tryParse(_glucoseController.text);
    final glucoseColor = _getGlucoseColor(glucoseValue);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Glucose'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Show glucose history
              Helpers.showInfo(context, 'History feature coming soon');
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

              // Glucose value input (large and prominent)
              _buildGlucoseInput(glucoseColor),
              const SizedBox(height: 24),

              // Date and time
              _buildDateTimeSection(),
              const SizedBox(height: 24),

              // Context selection
              _buildContextSection(),
              const SizedBox(height: 24),

              // Notes (optional)
              _buildNotesSection(),
              const SizedBox(height: 32),

              // Save button
              PrimaryButton(
                text: 'Save Reading',
                onPressed: _isLoading ? null : _handleSave,
                isLoading: _isLoading,
                width: double.infinity,
              ),
              const SizedBox(height: 16),

              // Reference ranges
              _buildReferenceRanges(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build info card
  Widget _buildInfoCard() {
    return BaseCard(
      // backgroundColor: AppTheme.infoColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppTheme.infoColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Record your blood glucose reading to track your health trends',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.infoColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build glucose input
  Widget _buildGlucoseInput(Color? glucoseColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: glucoseColor?.withOpacity(0.1) ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: glucoseColor?.withOpacity(0.3) ?? Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Blood Glucose Level',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),

          // Large glucose input
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: 150,
                child: TextFormField(
                  controller: _glucoseController,
                  validator: Validators.glucose,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: glucoseColor ?? AppTheme.textPrimaryColor,
                      ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '---',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'mg/dL',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),

          // Status indicator
          if (glucoseColor != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: glucoseColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getGlucoseStatus(double.tryParse(_glucoseController.text)),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
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
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 20,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Date & Time',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
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
                border: Border.all(
                  color: AppTheme.borderColor,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.date(_selectedDateTime),
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          Formatters.time(_selectedDateTime),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build context section
  Widget _buildContextSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant, size: 20, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Context',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Timing Selection (No Meal, Before, After)
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
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),

          // 2. Meal Type Selection (Only if Before/After is selected)
          if (_selectedTiming != 'No Meal') ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Select Meal',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _mealTypeOptions.map((meal) {
                final isSelected = meal == _selectedMealType;
                final displayLabel = meal[0] + meal.substring(1).toLowerCase();

                return ChoiceChip(
                  label: Text(displayLabel),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedMealType = meal),
                  selectedColor:
                      AppTheme.primaryBlue,
                  labelStyle: TextStyle(
                    color:
                        isSelected ? Colors.white : AppTheme.textPrimaryColor,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Build notes section
  Widget _buildNotesSection() {
    // Only show notes if "After Meal" is selected
    if (_selectedTiming != 'After Meal') return const SizedBox.shrink();

    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book,
                size: 20,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Meal Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _notesController,
            hint: 'What did you eat? (e.g. Rice, Chicken, Salad)',
            maxLines: 3,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  /// Build reference ranges
  Widget _buildReferenceRanges() {
    return BaseCard(
      // backgroundColor: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reference Ranges',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildRangeItem(
            'Normal',
            '70-180 mg/dL',
            AppTheme.glucoseNormal,
          ),
          const SizedBox(height: 8),
          _buildRangeItem(
            'Low',
            'Below 70 mg/dL',
            AppTheme.glucoseLow,
          ),
          const SizedBox(height: 8),
          _buildRangeItem(
            'High',
            'Above 180 mg/dL',
            AppTheme.glucoseHigh,
          ),
        ],
      ),
    );
  }

  /// Build single range item
  Widget _buildRangeItem(String label, String range, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        Text(
          range,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
        ),
      ],
    );
  }

  /// Get glucose color based on value
  Color? _getGlucoseColor(double? value) {
    if (value == null) return null;

    if (value < 70) {
      return AppTheme.glucoseLow;
    } else if (value > 180) {
      return AppTheme.glucoseHigh;
    } else {
      return AppTheme.glucoseNormal;
    }
  }

  /// Get glucose status text
  String _getGlucoseStatus(double? value) {
    if (value == null) return '';

    if (value < 70) {
      return 'Low - Eat something!';
    } else if (value > 180) {
      return 'High - Consider activity';
    } else {
      return 'Normal - Great job!';
    }
  }
}
