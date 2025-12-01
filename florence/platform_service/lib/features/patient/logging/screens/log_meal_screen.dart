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

/// Log Meal Screen
/// Allows users to record meals and food intake
class LogMealScreen extends ConsumerStatefulWidget {
  const LogMealScreen({super.key});

  @override
  ConsumerState<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends ConsumerState<LogMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mealNameController = TextEditingController();
  final _notesController = TextEditingController();
  
  // State
  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();
  late String _selectedMealType;

  @override
  void initState() {
    super.initState();
    _selectedMealType = _getMealTypeFromTime(DateTime.now());
  }

  String _getMealTypeFromTime(DateTime time) {
    final hour = time.hour;
    if (hour >= 4 && hour < 11) return 'Breakfast';
    if (hour >= 11 && hour < 16) return 'Lunch';
    return 'Dinner';
  }
  
  // Meal type options
  final List<Map<String, dynamic>> _mealTypeOptions = [
    {'name': 'Breakfast', 'icon': Icons.wb_sunny},
    {'name': 'Lunch', 'icon': Icons.wb_cloudy},
    {'name': 'Dinner', 'icon': Icons.nightlight},
    // REMOVED 'Snack' to match backend MealTime enum (BREAKFAST, LUNCH, DINNER)
  ];
  
  @override
  void dispose() {
    _mealNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  /// Handle save
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check only date part for future validation
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(_selectedDateTime.year, _selectedDateTime.month, _selectedDateTime.day);

    if (selectedDate.isAfter(today)) {
      Helpers.showError(context, 'Cannot log meals in the future.');
      return;
    }
    
    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);
    
    try {
      // Combine Name and Notes for the description
      String description = _mealNameController.text.trim();
      if (_notesController.text.isNotEmpty) {
        description += ' - ${_notesController.text.trim()}';
      }

      // Use the repository logic
      await ref.read(monitorDataRepositoryProvider).addMeal(
        _selectedMealType.toUpperCase(),
        _selectedDateTime,
        description,
        null, // Glucose before
        null, // Time before
        null, // Glucose after
        null, // Time after
      );
      
      ref.invalidate(monitorDataProvider);
      
      if (mounted) {
        Helpers.showSuccess(context, 'Meal logged successfully!');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to log meal: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  /// Show date picker (Time is not needed for meals as per backend schema)
  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date != null && mounted) {
      setState(() {
        _selectedDateTime = date;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Meal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Helpers.showInfo(context, 'Meal history coming soon');
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
              
              // Meal type selection
              _buildMealTypeSection(),
              const SizedBox(height: 24),
              
              // Meal name
              _buildMealNameSection(),
              const SizedBox(height: 24),
              
              // Date and time
              _buildDateTimeSection(),
              const SizedBox(height: 24),
              
              // Notes
              _buildNotesSection(),
              const SizedBox(height: 32),
              
              // Save button
              PrimaryButton(
                text: 'Save Meal',
                onPressed: _isLoading ? null : _handleSave,
                isLoading: _isLoading,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build info card
  Widget _buildInfoCard() {
    return BaseCard(
      // backgroundColor: AppTheme.mealColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            Icons.restaurant,
            color: AppTheme.mealColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Log your meals to understand how food affects your glucose',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mealColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build meal type section
  Widget _buildMealTypeSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meal Type',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: _mealTypeOptions.map((option) {
              final isSelected = option['name'] == _selectedMealType;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedMealType = option['name']);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.mealColor
                            : AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.mealColor
                              : AppTheme.borderColor,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            option['icon'],
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondaryColor,
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            option['name'],
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimaryColor,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  /// Build meal name section
  Widget _buildMealNameSection() {
    return CustomTextField(
      label: 'Meal Name',
      hint: 'e.g., Chicken rice, Oatmeal with fruits',
      controller: _mealNameController,
      validator: (value) => Validators.required(value, fieldName: 'Meal name'),
      textCapitalization: TextCapitalization.sentences,
      prefixIcon: const Icon(Icons.restaurant_menu),
    );
  }
  
  /// Build date section (Time removed)
  Widget _buildDateTimeSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date',
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
                  Icon(Icons.calendar_today, color: AppTheme.mealColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      Formatters.date(_selectedDateTime),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
      hint: 'How did you feel? Any reactions?',
      controller: _notesController,
      maxLines: 3,
      textInputAction: TextInputAction.done,
    );
  }
}
