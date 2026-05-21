import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/core/utils/validators.dart';
import 'package:florence/core/utils/formatters.dart';
import 'package:florence/core/utils/helpers.dart';
import 'package:florence/shared/widgets/button_widgets.dart';
import 'package:florence/config/theme.dart';
import 'package:florence/config/routes.dart';
import 'package:florence/features/patient/core/models/health_data_models.dart'; // Added
import 'package:florence/features/patient/core/providers/monitor_data_providers.dart'; // Added
import 'package:florence/core/services/notifications/notification_service.dart';
import 'package:florence/features/patient/core/repositories/monitor_data_repository.dart';
import 'package:florence/features/patient/profile/providers/user_profile_provider.dart';

/// Log Activity Screen
/// Allows users to record physical activities and exercise
class LogActivityScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSwitchToHistory;
  const LogActivityScreen({super.key, this.onSwitchToHistory});

  @override
  ConsumerState<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends ConsumerState<LogActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _activeDurationController = TextEditingController();
  final _caloriesController = TextEditingController();
  
  // State
  bool _forcePop = false;
  String _initialDescription = '';
  String _initialDuration = '';
  String _initialCalories = '';
  
  // Default to a 30-min workout ending now
  DateTime _endDateTime = DateTime.now();
  late DateTime _selectedDateTime; 
  
  late DateTime _initialDateTime;
  late DateTime _initialEndDateTime;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    // Grab the current time but force seconds and milliseconds to 0
    final now = DateTime.now();
    _endDateTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    
    _selectedDateTime = _endDateTime.subtract(const Duration(minutes: 30));
    _initialDateTime = _selectedDateTime;
    _initialEndDateTime = _endDateTime;
    
    // Automatically suggest active time based on start/end if empty
    // We do this after initialising late variables to avoid LateInitializationError
    _updateSuggestedDuration(isInitial: true);
  }

  void _validateAndAdjustTimeline({required bool isStart}) {
    final now = DateTime.now();
    // Strip seconds and milliseconds for perfectly clean math
    final cleanNow = DateTime(now.year, now.month, now.day, now.hour, now.minute);

    if (isStart) {
      // 1. Clamp Start to Now if they picked a future time
      if (_selectedDateTime.isAfter(cleanNow)) {
        _selectedDateTime = cleanNow.subtract(const Duration(minutes: 1));
        Helpers.showWarning(context, 'Start time cannot be in the future.');
      }

      // 2. If Start overtakes End, dynamically push End forward by 30 mins
      if (_selectedDateTime.isAfter(_endDateTime) ||
          _selectedDateTime.isAtSameMomentAs(_endDateTime)) {
        DateTime proposedEnd = _selectedDateTime.add(const Duration(minutes: 30));
        // Ensure the pushed End Time doesn't accidentally go into the future
        _endDateTime = proposedEnd.isAfter(cleanNow) ? cleanNow : proposedEnd;

        // Ultimate fallback if squeezed against the exact current minute
        if (_endDateTime.isBefore(_selectedDateTime) ||
            _endDateTime.isAtSameMomentAs(_selectedDateTime)) {
          _selectedDateTime = _endDateTime.subtract(const Duration(minutes: 1));
        }
      }
    } else {
      // 1. Clamp End to Now
      if (_endDateTime.isAfter(cleanNow)) {
        _endDateTime = cleanNow;
        Helpers.showWarning(context, 'End time cannot be in the future.');
      }

      // 2. If End is pulled before Start, dynamically pull Start backwards
      if (_endDateTime.isBefore(_selectedDateTime) ||
          _endDateTime.isAtSameMomentAs(_selectedDateTime)) {
        _selectedDateTime = _endDateTime.subtract(const Duration(minutes: 30));
      }
    }

    // 3. Automatically clamp the Active Duration input if the timeline window shrank
    int totalElapsed = _endDateTime.difference(_selectedDateTime).inMinutes;
    int currentActive = int.tryParse(_activeDurationController.text) ?? 0;
    if (currentActive > totalElapsed) {
      _activeDurationController.text = totalElapsed.toString();
    }
  }

  void _updateSuggestedDuration({bool isInitial = false}) {
    final diff = _endDateTime.difference(_selectedDateTime).inMinutes;
    if (diff > 0 && _activeDurationController.text.isEmpty) {
      _activeDurationController.text = diff.toString();

      // Keep track of the prefilled value so it doesn't immediately count as a "change"
      if (isInitial) {
        _initialDuration = diff.toString();
      }
    }
    // Don't call setState during initState
    if (!isInitial && mounted) setState(() {});
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _activeDurationController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _estimateCalories() async {
    if (_descriptionController.text.isEmpty || _activeDurationController.text.isEmpty) {
      Helpers.showError(context, 'Please enter activity details and duration first.');
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final profile = ref.read(userProfileProvider).value;
      
      final calories = await ref.read(monitorDataRepositoryProvider).estimateActivityCalories(
        durationMinutes: int.parse(_activeDurationController.text),
        description: _descriptionController.text,
        weightKg: profile?['weight'] != null ? (profile!['weight'] as num).toDouble() : null,
        heightCm: profile?['height'] != null ? (profile!['height'] as num).toDouble() : null,
        age: profile?['age'] != null ? profile!['age'] as int : null,
        gender: profile?['gender'] as String?,
      );
      
      setState(() {
        _caloriesController.text = calories.toString();
      });
      Helpers.showSuccess(context, 'Calories estimated successfully!');
    } catch (e) {
      Helpers.showError(context, 'Failed to estimate calories.');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  /// Handle save
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDateTime.isAfter(DateTime.now())) {
      Helpers.showError(context, 'Cannot log activity in the future.');
      return;
    }
    
    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);
    
    try {
      // Use the repository to add activity
      await ref.read(monitorDataRepositoryProvider).addActivity(
        ActivityLog(
          id: '', // ID generated by backend
          startTime: _selectedDateTime.toUtc(),
          endTime: _endDateTime.toUtc(),
          type: _descriptionController.text.trim(),
          activeDurationMinutes: int.parse(_activeDurationController.text.trim()),
          intensity: 'Moderate', // Default
          caloriesBurned: int.tryParse(_caloriesController.text.trim()),
        )
      );
      
      // Invalidate to refresh dashboard
      ref.invalidate(monitorDataProvider);
      ref.read(notificationProvider.notifier).checkAfterActivityLog(
        int.tryParse(_activeDurationController.text.trim()),
      );

      if (mounted) {
        Helpers.showSuccess(context, 'Activity logged successfully!');
        AppRoutes.pushAndRemoveUntil(context, AppRoutes.dashboard);
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
          _validateAndAdjustTimeline(isStart: true);
        });
      }
    }
  }
  
  Future<bool> _showDiscardDialog() async {
    return await showDialog<bool>(
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
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Discard'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _resetForm() {
    setState(() {
      _forcePop = false;
      _descriptionController.text = _initialDescription;
      _activeDurationController.text = _initialDuration;
      _caloriesController.text = _initialCalories;
      _selectedDateTime = _initialDateTime;
      _endDateTime = _initialEndDateTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasChanges = !_forcePop && 
        (_descriptionController.text != _initialDescription || 
         _activeDurationController.text != _initialDuration ||
         _caloriesController.text != _initialCalories ||
         _selectedDateTime != _initialDateTime ||
         _endDateTime != _initialEndDateTime);

    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldDiscard = await _showDiscardDialog();

        if (shouldDiscard && context.mounted) {
          setState(() => _forcePop = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Log Activity'),
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
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: const Icon(Icons.history),
                onPressed: () async {
                  if (hasChanges) {
                    final shouldDiscard = await _showDiscardDialog();
                    if (!shouldDiscard) return;
                    _resetForm();
                  }
                  if (widget.onSwitchToHistory != null) {
                    widget.onSwitchToHistory!();
                  } else {
                    AppRoutes.pushReplacement(context, AppRoutes.activityDetail);
                  }
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

                        // Session Timeline (Start and End)
                        _buildTimeSection(),
                        const SizedBox(height: 20),

                        // Active Duration
                        _buildActiveDurationSection(),
                        const SizedBox(height: 20),

                        // Activity Details
                        _buildActivityDetailsSection(),
                        const SizedBox(height: 32),

                        // Save button
                        PrimaryButton(
                          text: 'Save Activity',
                          onPressed: _isLoading ? null : _handleSave,
                          isLoading: _isLoading,
                          width: double.infinity,
                        ),
                        const SizedBox(height: 24),
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

  /// Build info card
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
              'Track your physical activities to see how they affect your glucose.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.infoColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityDetailsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);
    final titleIconColor = isDark ? Colors.blue.shade200 : AppTheme.primaryBlue;

    final List<Map<String, dynamic>> commonActivities = [
      {'name': 'Walking', 'icon': Icons.directions_walk},
      {'name': 'Running', 'icon': Icons.directions_run},
      {'name': 'Cycling', 'icon': Icons.directions_bike},
      {'name': 'Gym', 'icon': Icons.fitness_center},
      {'name': 'Yoga', 'icon': Icons.self_improvement},
      {'name': 'Chores', 'icon': Icons.cleaning_services},
    ];

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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: titleIconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_run,
                  color: titleIconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Activity Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Select Grid
          Text(
            'Quick Select',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final spacing = 8.0;
              final itemWidth = (constraints.maxWidth - (spacing * 2)) / 3;
              final itemHeight = itemWidth / 2.5;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: commonActivities.map((activity) {
                  final isSelected = _descriptionController.text.toLowerCase() ==
                      activity['name'].toString().toLowerCase();
                  return SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _descriptionController.clear();
                          } else {
                            _descriptionController.text = activity['name'];
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : AppTheme.backgroundColor),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : AppTheme.borderColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              activity['icon'],
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                activity['name'],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimaryColor,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // Description Input Title
          Text(
            'Activity Description',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
          ),
          const SizedBox(height: 12),

          // Description Input
          TextFormField(
            controller: _descriptionController,
            validator: Validators.required,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
            minLines: 3,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g. playing tennis with 30 minutes break in between',
              hintStyle: const TextStyle(color: AppTheme.textSecondaryColor),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.edit_note, color: AppTheme.textSecondaryColor),
            ),
          ),
          const SizedBox(height: 20),

          // Calories Section
          Row(
            children: [
              Text(
                'Calories Burned (kcal)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                'Optional',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. 500',
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.local_fire_department_outlined, color: AppTheme.textSecondaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: _isLoading ? null : _estimateCalories,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: AppTheme.primaryBlue,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Auto',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection() {
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
                  Icons.schedule,
                  color: titleIconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Session Timeline',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Start Time
          Text(
            'Started At',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.borderColor),
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
                        _selectedDateTime = DateTime(picked.year, picked.month, picked.day, _selectedDateTime.hour, _selectedDateTime.minute);
                        _validateAndAdjustTimeline(isStart: true);
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
                        _selectedDateTime = DateTime(_selectedDateTime.year, _selectedDateTime.month, _selectedDateTime.day, picked.hour, picked.minute);
                        _validateAndAdjustTimeline(isStart: true);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // End Time
          Text(
            'Ended At',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.borderColor),
            ),
            child: Column(
              children: [
                _buildCompactPickerItem(
                  label: 'Date',
                  value: Formatters.date(_endDateTime),
                  icon: Icons.calendar_today_outlined,
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDateTime,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _endDateTime = DateTime(picked.year, picked.month, picked.day, _endDateTime.hour, _endDateTime.minute);
                        _validateAndAdjustTimeline(isStart: false);
                      });
                    }
                  },
                ),
                Divider(height: 1, color: AppTheme.borderColor.withValues(alpha: 0.5)),
                _buildCompactPickerItem(
                  label: 'Time',
                  value: TimeOfDay.fromDateTime(_endDateTime).format(context),
                  icon: Icons.access_time_outlined,
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_endDateTime),
                    );
                    if (picked != null) {
                      setState(() {
                        _endDateTime = DateTime(_endDateTime.year, _endDateTime.month, _endDateTime.day, picked.hour, picked.minute);
                        _validateAndAdjustTimeline(isStart: false);
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

  Widget _buildActiveDurationSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);
    final titleIconColor = isDark ? Colors.blue.shade200 : AppTheme.primaryBlue;

    int totalElapsed = _endDateTime.difference(_selectedDateTime).inMinutes;
    int maxDuration = totalElapsed > 0 ? totalElapsed : 1; 
    
    int currentActive = int.tryParse(_activeDurationController.text) ?? 0;
    double sliderValue = currentActive.clamp(0, maxDuration).toDouble();

    int full = totalElapsed;
    int threeQuarters = (totalElapsed * 0.75).round();
    int half = (totalElapsed * 0.5).round();
    int quarter = (totalElapsed * 0.25).round();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
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
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: titleIconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_fire_department,
                    color: titleIconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Duration',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text.rich(
                        TextSpan(
                          text: 'Total session duration: ',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                          children: [
                            TextSpan(
                              text: '$totalElapsed mins',
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Big Number Display with Input Clamping
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SizedBox(
                    width: 140, 
                    child: TextFormField(
                      controller: _activeDurationController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8), 
                      ),
                      onChanged: (val) {
                        int? parsed = int.tryParse(val);
                        if (parsed != null && parsed > totalElapsed) {
                          _activeDurationController.text = totalElapsed.toString();
                          _activeDurationController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _activeDurationController.text.length),
                          );
                        }
                        setState(() {}); 
                      }, 
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'mins',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryColor, 
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Full-Width Custom Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primaryBlue,
              inactiveTrackColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
              thumbColor: AppTheme.primaryBlue,
              overlayColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            ),
            child: Slider(
              value: sliderValue,
              min: 0,
              max: maxDuration.toDouble(),
              divisions: maxDuration > 0 ? maxDuration : 1,
              onChanged: (val) {
                setState(() {
                  _activeDurationController.text = val.toInt().toString();
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Quick Adjust Chips (Fractions!)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildDurationChip(
                    label: 'Full',
                    onTap: () => setState(() => _activeDurationController.text = full.toString()),
                    isSelected: currentActive == full,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDurationChip(
                    label: '3/4',
                    onTap: () => setState(() => _activeDurationController.text = threeQuarters.toString()),
                    isSelected: currentActive == threeQuarters,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDurationChip(
                    label: '1/2',
                    onTap: () => setState(() => _activeDurationController.text = half.toString()),
                    isSelected: currentActive == half,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDurationChip(
                    label: '1/4',
                    onTap: () => setState(() => _activeDurationController.text = quarter.toString()),
                    isSelected: currentActive == quarter,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Note (Default font!)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: Text(
                'Note: Adjust this down if you took breaks',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Updated to match the standard Quick Select aesthetic
  Widget _buildDurationChip({
    required String label,
    required VoidCallback onTap,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryBlue 
              : (isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.getBorderColor(context),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
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
}
