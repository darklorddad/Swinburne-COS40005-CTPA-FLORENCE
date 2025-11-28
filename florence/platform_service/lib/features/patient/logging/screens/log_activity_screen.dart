import 'package:flutter/material.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/button_widgets.dart';
import '../../../../shared/widgets/input_widgets.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';
import '../../../../core/services/api_service.dart';

/// Log Activity Screen
/// Allows users to record physical activities and exercise
class LogActivityScreen extends StatefulWidget {
  const LogActivityScreen({super.key});

  @override
  State<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends State<LogActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _apiService = ApiService();
  
  // State
  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();
  
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
    _descriptionController.dispose();
    _durationController.dispose();
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
      final payload = {
        'activity_description': _descriptionController.text.trim(),
        'duration_minutes': int.parse(_durationController.text),
        'performed_at': _selectedDateTime.toIso8601String(),
      };

      await _apiService.post('/patients/me/activity-logs', payload);
      
      if (mounted) {
        Helpers.showSuccess(context, 'Activity logged successfully!');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to log activity: ${e.toString()}');
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
              
              // Activity Description
              _buildDescriptionSection(),
              const SizedBox(height: 24),
              
              // Duration
              _buildDurationSection(),
              const SizedBox(height: 24),
              
              // Date and time
              _buildDateTimeSection(),
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
  
  /// Build activity name section
  Widget _buildDescriptionSection() {
    return CustomTextField(
      label: 'Activity Description',
      hint: 'e.g., Morning jog, Gym workout, Cleaning',
      controller: _descriptionController,
      validator: Validators.required,
      textCapitalization: TextCapitalization.sentences,
      prefixIcon: const Icon(Icons.description_outlined),
    );
  }
  
  /// Build duration section
  Widget _buildDurationSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Duration',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _durationController,
            validator: Validators.activityDuration,
            keyboardType: TextInputType.number,
            hint: 'Duration in minutes',
            prefixIcon: const Icon(Icons.timer),
            onChanged: (_) => setState(() {}),
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
}