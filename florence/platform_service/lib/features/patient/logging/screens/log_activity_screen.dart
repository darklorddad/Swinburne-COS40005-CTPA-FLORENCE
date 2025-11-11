import 'package:flutter/material.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/button_widgets.dart';
import '../../../../shared/widgets/input_widgets.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';

/// Log Activity Screen
/// Allows users to record physical activities and exercise
class LogActivityScreen extends StatefulWidget {
  const LogActivityScreen({super.key});

  @override
  State<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends State<LogActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _activityNameController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  
  // State
  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();
  String _selectedActivityType = 'Walking';
  String _selectedIntensity = 'Moderate';
  
  // Activity type options with icons and colors
  final List<Map<String, dynamic>> _activityTypes = [
    {
      'name': 'Walking',
      'icon': Icons.directions_walk,
      'color': const Color(0xFF4CAF50)
    },
    {'name': 'Running', 'icon': Icons.directions_run, 'color': const Color(0xFFFF5722)},
    {'name': 'Cycling', 'icon': Icons.pedal_bike, 'color': const Color(0xFF2196F3)},
    {'name': 'Swimming', 'icon': Icons.pool, 'color': const Color(0xFF00BCD4)},
    {'name': 'Gym', 'icon': Icons.fitness_center, 'color': const Color(0xFF9C27B0)},
    {'name': 'Yoga', 'icon': Icons.self_improvement, 'color': const Color(0xFFE91E63)},
    {'name': 'Sports', 'icon': Icons.sports_soccer, 'color': const Color(0xFFFF9800)},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': const Color(0xFF607D8B)},
  ];
  
  // Intensity options
  final List<String> _intensityOptions = ['Light', 'Moderate', 'Vigorous'];
  
  @override
  void dispose() {
    _activityNameController.dispose();
    _durationController.dispose();
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
      // TODO: Save to Supabase
      // await activityService.saveActivity({
      //   'name': _activityNameController.text.trim(),
      //   'type': _selectedActivityType,
      //   'duration': int.parse(_durationController.text),
      //   'intensity': _selectedIntensity,
      //   'timestamp': _selectedDateTime.toIso8601String(),
      //   'notes': _notesController.text.trim(),
      // });
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Helpers.showSuccess(context, 'Activity logged successfully!');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to log activity');
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
  
  /// Get estimated calories burned
  int _estimateCalories() {
    final duration = int.tryParse(_durationController.text) ?? 0;
    if (duration == 0) return 0;
    
    // Simple estimation based on activity and intensity
    double multiplier = 5.0; // Base calories per minute
    
    // Adjust by intensity
    switch (_selectedIntensity) {
      case 'Light':
        multiplier = 3.0;
        break;
      case 'Moderate':
        multiplier = 5.0;
        break;
      case 'Vigorous':
        multiplier = 8.0;
        break;
    }
    
    return (duration * multiplier).round();
  }
  
  @override
  Widget build(BuildContext context) {
    final estimatedCalories = _estimateCalories();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Helpers.showInfo(context, 'Activity history coming soon');
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
              
              // Activity type selection
              _buildActivityTypeSection(),
              const SizedBox(height: 24),
              
              // Activity name
              _buildActivityNameSection(),
              const SizedBox(height: 24),
              
              // Duration
              _buildDurationSection(estimatedCalories),
              const SizedBox(height: 24),
              
              // Intensity
              _buildIntensitySection(),
              const SizedBox(height: 24),
              
              // Date and time
              _buildDateTimeSection(),
              const SizedBox(height: 24),
              
              // Notes
              _buildNotesSection(),
              const SizedBox(height: 32),
              
              // Save button
              PrimaryButton(
                text: 'Save Activity',
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
      // backgroundColor: AppTheme.activityColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            Icons.directions_run,
            color: AppTheme.activityColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Track your physical activities to see how they affect your glucose',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.activityColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build activity type section
  Widget _buildActivityTypeSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Type',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: _activityTypes.length,
            itemBuilder: (context, index) {
              final activity = _activityTypes[index];
              final isSelected = activity['name'] == _selectedActivityType;
              
              return InkWell(
                onTap: () {
                  setState(() => _selectedActivityType = activity['name']);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activity['color'].withOpacity(0.1)
                        : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? activity['color']
                          : AppTheme.borderColor,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        activity['icon'],
                        color: isSelected
                            ? activity['color']
                            : AppTheme.textSecondaryColor,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activity['name'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? activity['color']
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
  
  /// Build activity name section
  Widget _buildActivityNameSection() {
    return CustomTextField(
      label: 'Activity Name (Optional)',
      hint: 'e.g., Morning jog, Gym workout',
      controller: _activityNameController,
      textCapitalization: TextCapitalization.sentences,
      prefixIcon: const Icon(Icons.label_outline),
    );
  }
  
  /// Build duration section
  Widget _buildDurationSection(int estimatedCalories) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Duration',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (estimatedCalories > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.activityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: AppTheme.activityColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '~$estimatedCalories kcal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.activityColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _durationController,
            validator: Validators.activityDuration,
            keyboardType: TextInputType.number,
            hint: 'Duration in minutes',
            // suffix: 'minutes',
            prefixIcon: const Icon(Icons.timer),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
  
  /// Build intensity section
  Widget _buildIntensitySection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Intensity',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: _intensityOptions.map((intensity) {
              final isSelected = intensity == _selectedIntensity;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIntensity = intensity;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.activityColor
                            : AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.activityColor
                              : AppTheme.borderColor,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        intensity,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimaryColor,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
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
                  Icon(Icons.access_time, color: AppTheme.activityColor),
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
      hint: 'How did you feel during the activity?',
      controller: _notesController,
      maxLines: 3,
      textInputAction: TextInputAction.done,
    );
  }
}