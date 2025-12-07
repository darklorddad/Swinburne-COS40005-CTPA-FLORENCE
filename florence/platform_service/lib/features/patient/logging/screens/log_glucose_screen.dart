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
import '../../../../core/layout/responsive_layout_system.dart';
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
          timestamp: _selectedDateTime.toUtc(),
          value: glucoseValue,
          context: _selectedTiming,
        ));
      } 
      else {
        final isBefore = _selectedTiming == 'Before Meal';
        // Delegate complex logic to repository
        await repo.addMeal(
          _selectedMealType,
          _selectedDateTime.toUtc(), // Date only used for day
          (!isBefore && _notesController.text.trim().isNotEmpty) ? _notesController.text.trim() : null,
          isBefore ? glucoseValue : null,
          isBefore ? _selectedDateTime.toUtc() : null,
          !isBefore ? glucoseValue : null,
          !isBefore ? _selectedDateTime.toUtc() : null,
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
          Helpers.showError(context, 'You have already logged $_selectedMealType for this date.');
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
    
    // Fetch thresholds
    final healthData = ref.watch(monitorDataProvider).asData?.value;
    HealthThreshold? glucoseThreshold;
    try {
      glucoseThreshold = healthData?.healthThresholds.firstWhere(
        (t) => t.dataType == MonitorDataType.GLUCOSE
      );
    } catch (_) {}

    final glucoseColor = _getGlucoseColor(glucoseValue, glucoseThreshold);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Glucose'),
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppTheme.getBorderColor(context),
            height: 1.0,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.5),
            child: IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                AppRoutes.push(context, AppRoutes.trendsDetail);
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
                      // Info & Target card
                      _buildInfoCard(glucoseThreshold),
                      const SizedBox(height: 20),

                      // Glucose value input (large and prominent)
                      _buildGlucoseInput(glucoseColor, glucoseThreshold),
                      const SizedBox(height: 20),

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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build info card with target range
  Widget _buildInfoCard(HealthThreshold? threshold) {
    final min = threshold?.minValue ?? 70;
    final max = threshold?.maxValue ?? 180;
    
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
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.infoColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Record your blood glucose reading to track your health trends.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.infoColor,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Target Range Box (Matching Analytics Overview Style)
          InkWell(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.track_changes,
                            size: 18,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Target Range',
                            style: TextStyle(
                              color: AppTheme.primaryGreen.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppTheme.primaryGreen.withOpacity(0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Glucose', 
                        style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen.withOpacity(0.8))
                      ),
                      Text(
                        '${min.toInt()} - ${max.toInt()} mg/dL',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
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

  /// Build glucose input
  Widget _buildGlucoseInput(Color? glucoseColor, HealthThreshold? threshold) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Tint the whole card background based on status
    final containerColor = glucoseColor != null 
        ? glucoseColor.withOpacity(0.05) 
        : (isDark ? AppTheme.midnightSurface : Colors.white);
        
    final borderColor = glucoseColor ?? AppTheme.getBorderColor(context);
    final hasInput = glucoseColor != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: 1.0, // Fixed width to prevent displacement
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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

          const SizedBox(height: 16),

          // Status indicator (Always visible)
          SizedBox(
            height: 32,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(minWidth: 100),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: (glucoseColor ?? AppTheme.textSecondaryColor)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (glucoseColor ?? AppTheme.textSecondaryColor)
                        .withOpacity(0.3),
                  ),
                ),
                child: Text(
                  glucoseColor != null
                      ? _getGlucoseStatus(
                              double.tryParse(_glucoseController.text),
                              threshold)
                          .toUpperCase()
                      : 'ENTER VALUE',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: glucoseColor ?? AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
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

  /// Get glucose color based on value and user thresholds
  Color? _getGlucoseColor(double? value, HealthThreshold? threshold) {
    if (value == null) return null;
    
    final min = threshold?.minValue ?? 70;
    final max = threshold?.maxValue ?? 180;

    if (value < min) {
      return AppTheme.warningColor; // Low (Amber)
    } else if (value > max) {
      return AppTheme.errorColor; // High (Red)
    } else {
      return AppTheme.primaryGreen; // Normal (Green)
    }
  }

  /// Get glucose status text
  String _getGlucoseStatus(double? value, HealthThreshold? threshold) {
    if (value == null) return '';
    
    final min = threshold?.minValue ?? 70;
    final max = threshold?.maxValue ?? 180;

    if (value < min) {
      return 'Low';
    } else if (value > max) {
      return 'High';
    } else {
      return 'Normal';
    }
  }
}
