import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/button_widgets.dart';
import '../../../../shared/widgets/input_widgets.dart';
import '../../core/models/health_data_models.dart';
import '../../core/providers/monitor_data_providers.dart' as core_providers;
import '../../core/providers/threshold_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../profile/providers/user_profile_provider.dart';

/// Log BMI Screen
class LogBmiScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSwitchToHistory;
  const LogBmiScreen({super.key, this.onSwitchToHistory});

  @override
  ConsumerState<LogBmiScreen> createState() => _LogBmiScreenState();
}

class _LogBmiScreenState extends ConsumerState<LogBmiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  // final ApiService _apiService = ApiService(); // Removed

  bool _forcePop = false;
  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();
  late DateTime _initialDateTime;
  double? _calculatedBmi;

  // Track pre-filled data to prevent false "hasChanges" triggers
  String _initialHeight = '';
  String _initialWeight = '';

  @override
  void initState() {
    super.initState();
    _initialDateTime = _selectedDateTime;
    _heightController.addListener(_calculateBmi);
    _weightController.addListener(_calculateBmi);
    
    // Pre-fill from profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider).value;
      if (profile != null) {
        if (profile['height'] != null) {
          _initialHeight = profile['height'].toString();
          _heightController.text = _initialHeight;
        }
        if (profile['weight'] != null) {
          _initialWeight = profile['weight'].toString();
          _weightController.text = _initialWeight;
        }
      }
    });
  }

  @override
  void dispose() {
    _heightController.removeListener(_calculateBmi);
    _weightController.removeListener(_calculateBmi);
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _calculateBmi() {
    // Handle commas for international users
    final hText = _heightController.text.replaceAll(',', '.');
    final wText = _weightController.text.replaceAll(',', '.');

    final heightCm = double.tryParse(hText);
    final weightKg = double.tryParse(wText);

    if (heightCm != null && heightCm > 0 && weightKg != null && weightKg > 0) {
      final heightM = heightCm / 100;
      setState(() {
        _calculatedBmi = weightKg / (heightM * heightM);
      });
    } else {
      setState(() {
        _calculatedBmi = null;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _calculatedBmi == null) {
      if (_calculatedBmi == null) {
        Helpers.showError(context, 'Please enter valid height and weight to calculate BMI.');
      }
      return;
    }

    if (_selectedDateTime.isAfter(DateTime.now())) {
      Helpers.showError(context, 'Cannot log measurements in the future.');
      return;
    }

    // Foolproof: Check for duplicate entries at the same time
    final existingData = ref.read(monitorDataProvider).asData?.value ?? [];
    final isDuplicate = existingData.any((d) {
      if (d.dataType != MonitorDataType.BMI) return false;
      
      // Convert to local to match user selection
      final localDate = d.measuredAt.toLocal();
      
      return localDate.year == _selectedDateTime.year &&
             localDate.month == _selectedDateTime.month &&
             localDate.day == _selectedDateTime.day &&
             localDate.hour == _selectedDateTime.hour &&
             localDate.minute == _selectedDateTime.minute;
    });

    if (isDuplicate) {
      Helpers.showError(context, 'A BMI reading for this time already exists.');
      return;
    }

    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      
      // Update profile - backend will auto-log the BMI entry
      await apiService.put('/patients/me', {
        'height': double.tryParse(_heightController.text.replaceAll(',', '.')),
        'weight': double.tryParse(_weightController.text.replaceAll(',', '.')),
      });
      
      // Refresh providers
      ref.invalidate(userProfileProvider);
      ref.invalidate(core_providers.monitorDataProvider);

      if (mounted) {
        Helpers.showSuccess(context, 'BMI logged and profile updated!');
        AppRoutes.pushAndRemoveUntil(context, AppRoutes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to log BMI: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Get BMI color based on value and user thresholds
  Color? _getBmiColor(double? value, HealthThreshold? threshold) {
    if (value == null) return null;
    final minNormal = threshold?.minValue ?? 18.5;
    final maxNormal = threshold?.maxValue ?? 24.9;
    final obeseCutoff = maxNormal + 5.0;

    if (value < minNormal) return AppTheme.primaryBlue;
    if (value <= maxNormal) return AppTheme.primaryGreen;
    if (value <= obeseCutoff) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  /// Get BMI status text
  String _getBmiStatus(double? value, HealthThreshold? threshold) {
    if (value == null) return '';
    final minNormal = threshold?.minValue ?? 18.5;
    final maxNormal = threshold?.maxValue ?? 24.9;
    final obeseCutoff = maxNormal + 5.0;

    if (value < minNormal) return 'Underweight';
    if (value <= maxNormal) return 'Normal';
    if (value <= obeseCutoff) return 'Overweight';
    return 'Obese';
  }

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
      _heightController.text = _initialHeight;
      _weightController.text = _initialWeight;
      _selectedDateTime = _initialDateTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    final thresholdsAsync = ref.watch(patientThresholdsProvider);

    String targetText = "Target: Loading...";
    if (thresholdsAsync.hasValue && thresholdsAsync.value != null) {
      try {
        final bmiTarget =
            thresholdsAsync.value!.firstWhere((t) => t.dataType == 'BMI');
        targetText =
            "Target: ${bmiTarget.minValue.toStringAsFixed(1)} - ${bmiTarget.maxValue.toStringAsFixed(1)}";
      } catch (e) {
        targetText = "Target: Not set";
      }
    }

    // Fetch thresholds
    final healthData =
        ref.watch(core_providers.monitorDataProvider).asData?.value;
    HealthThreshold? bmiThreshold;
    try {
      bmiThreshold = healthData?.healthThresholds.firstWhere(
          (t) => t.dataType == MonitorDataType.BMI);
    } catch (_) {}

    final bool hasChanges = !_forcePop &&
        (_heightController.text != _initialHeight || 
         _weightController.text != _initialWeight ||
         _selectedDateTime != _initialDateTime);

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
          title: const Text('Log BMI'),
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
                    AppRoutes.pushReplacement(context, AppRoutes.bmiDetail);
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
                        // Info & Target card
                        _buildInfoCard(bmiThreshold),
                        const SizedBox(height: 20),

                        // Calculated BMI Section
                        _buildCalculatedBmiSection(bmiThreshold),
                        const SizedBox(height: 20),

                        // Input Section
                        _buildInputSection(),
                        const SizedBox(height: 20),

                        // Date and time
                        _buildDateTimeSection(),
                        const SizedBox(height: 32),

                        // Save button
                        PrimaryButton(
                          text: 'Save Reading',
                          onPressed: (_isLoading || _calculatedBmi == null) ? null : _handleSave,
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

  Widget _buildInfoCard(HealthThreshold? threshold) {
    final thresholdsAsync = ref.watch(patientThresholdsProvider);

    String targetText = "Target: Loading...";
    if (thresholdsAsync.hasValue && thresholdsAsync.value != null) {
      try {
        final bmiTarget =
            thresholdsAsync.value!.firstWhere((t) => t.dataType == 'BMI');
        targetText =
            "Target: ${bmiTarget.minValue.toStringAsFixed(1)} - ${bmiTarget.maxValue.toStringAsFixed(1)}";
      } catch (e) {
        targetText = "Target: Not set";
      }
    }

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
                  'Body Mass Index (BMI) is a measure of body fat based on height and weight.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.infoColor,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Target Range Box
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
                      Text('BMI',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryGreen.withOpacity(0.8))),
                      Text(
                        targetText,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen),
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

  Widget _buildCalculatedBmiSection(HealthThreshold? threshold) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bmiColor = _getBmiColor(_calculatedBmi, threshold);
    
    final containerColor = bmiColor != null 
        ? bmiColor.withOpacity(0.05) 
        : (isDark ? AppTheme.midnightSurface : Colors.white);
        
    final borderColor = bmiColor ?? AppTheme.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: 1.0,
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
            'Calculated BMI Level',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _calculatedBmi?.toStringAsFixed(1) ?? '---',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: bmiColor ?? AppTheme.textPrimaryColor,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                'kg/m²',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildBmiStatusBadge(threshold),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);
    final titleIconColor = isDark ? Colors.blue.shade200 : AppTheme.primaryBlue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: 1.0,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: titleIconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.monitor_weight_outlined,
                  color: titleIconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Measurements',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Height (cm)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _heightController,
                      validator: (value) =>
                          Validators.range(value, 50, 300, fieldName: 'Height'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'e.g., 175',
                        hintStyle: const TextStyle(color: AppTheme.textSecondaryColor),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.05) : AppTheme.backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(Icons.height, color: AppTheme.textSecondaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weight (kg)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _weightController,
                      validator: (value) =>
                          Validators.range(value, 20, 500, fieldName: 'Weight'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'e.g., 70',
                        hintStyle: const TextStyle(color: AppTheme.textSecondaryColor),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.05) : AppTheme.backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(Icons.scale, color: AppTheme.textSecondaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBmiStatusBadge(HealthThreshold? threshold) {
    final statusText = _calculatedBmi != null
        ? _getBmiStatus(_calculatedBmi, threshold).toUpperCase()
        : 'ENTER DETAILS';

    final bmiColor = _getBmiColor(_calculatedBmi, threshold);
    final displayColor = bmiColor ?? AppTheme.textSecondaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isPending = _calculatedBmi == null;

    IconData statusIcon;
    if (isPending) {
      statusIcon = Icons.edit;
    } else if (statusText == 'UNDERWEIGHT') {
      statusIcon = Icons.arrow_downward;
    } else if (statusText == 'NORMAL') {
      statusIcon = Icons.check;
    } else {
      statusIcon = Icons.arrow_upward;
    }

    return Container(
      width: 140, // Fixed width matching Log Glucose
      height: 32, // Fixed height matching Log Glucose
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isPending
            ? (isDark ? Colors.white.withOpacity(0.05) : AppTheme.backgroundColor)
            : displayColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: displayColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 14,
            color: isPending ? displayColor.withOpacity(0.5) : displayColor,
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: isPending ? displayColor.withOpacity(0.5) : displayColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
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
            color: Colors.black.withOpacity(0.03),
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
                  color: titleIconColor.withOpacity(0.1),
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
              color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : AppTheme.borderColor,
              ),
            ),
            child: Column(
              children: [
                _buildCompactPickerItem(
                  label: 'Date',
                  value: Formatters.date(_selectedDateTime),
                  icon: Icons.calendar_today_outlined,
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
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
                Divider(height: 1, color: AppTheme.borderColor.withOpacity(0.5)),
                _buildCompactPickerItem(
                  label: 'Time',
                  value: TimeOfDay.fromDateTime(_selectedDateTime).format(context),
                  icon: Icons.access_time_outlined,
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            // Override tertiary colors so AM/PM selector is Blue, not Red
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                              tertiary: AppTheme.primaryBlue,
                              onTertiary: Colors.white,
                              tertiaryContainer: AppTheme.primaryBlue.withOpacity(0.2),
                              onTertiaryContainer: AppTheme.primaryBlue,
                            ),
                            // Fix input field background to make cursor visible
                            timePickerTheme: TimePickerThemeData(
                              hourMinuteColor: MaterialStateColor.resolveWith((states) {
                                return states.contains(MaterialState.selected)
                                    ? AppTheme.primaryBlue.withOpacity(0.1)
                                    : Colors.grey.shade100;
                              }),
                              hourMinuteTextColor: MaterialStateColor.resolveWith((states) {
                                return states.contains(MaterialState.selected)
                                    ? AppTheme.primaryBlue
                                    : AppTheme.textPrimaryColor;
                              }),
                            ),
                            textSelectionTheme: TextSelectionThemeData(
                              cursorColor: AppTheme.primaryBlue,
                              selectionColor: AppTheme.primaryBlue.withOpacity(0.3),
                              selectionHandleColor: AppTheme.primaryBlue,
                            ),
                          ),
                          child: child!,
                        );
                      },
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
}
