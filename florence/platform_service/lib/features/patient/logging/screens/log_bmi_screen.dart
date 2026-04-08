import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
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
import '../../core/providers/monitor_data_providers.dart' as core_providers;
import '../../core/repositories/monitor_data_repository.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../profile/providers/user_profile_provider.dart';

/// Log BMI Screen
class LogBmiScreen extends ConsumerStatefulWidget {
  const LogBmiScreen({super.key});

  @override
  ConsumerState<LogBmiScreen> createState() => _LogBmiScreenState();
}

class _LogBmiScreenState extends ConsumerState<LogBmiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  // final ApiService _apiService = ApiService(); // Removed

  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();
  double? _calculatedBmi;

  @override
  void initState() {
    super.initState();
    _heightController.addListener(_calculateBmi);
    _weightController.addListener(_calculateBmi);
    
    // Pre-fill from profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider).value;
      if (profile != null) {
        if (profile['height'] != null) {
          _heightController.text = profile['height'].toString();
        }
        if (profile['weight'] != null) {
          _weightController.text = profile['weight'].toString();
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
        AppRoutes.pop(context);
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
    // Fetch thresholds
    final healthData = ref.watch(core_providers.monitorDataProvider).asData?.value;
    HealthThreshold? bmiThreshold;
    try {
      bmiThreshold = healthData?.healthThresholds.firstWhere(
        (t) => t.dataType == MonitorDataType.BMI
      );
    } catch (_) {}

    return Scaffold(
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
              onPressed: () {
                AppRoutes.push(context, AppRoutes.bmiDetail);
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

                      // Input Section
                      _buildInputSection(bmiThreshold),
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
    );
  }

  Widget _buildInfoCard(HealthThreshold? threshold) {
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
                      Text(
                        'BMI', 
                        style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen.withOpacity(0.8))
                      ),
                      Text(
                        threshold != null 
                          ? '${threshold.minValue.toStringAsFixed(1)} - ${threshold.maxValue.toStringAsFixed(1)} kg/m²'
                          : '18.5 - 24.9 kg/m²',
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

  Widget _buildInputSection(HealthThreshold? threshold) {
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
          if (_calculatedBmi != null) ...[
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    'Calculated BMI',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _calculatedBmi!.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildBmiStatusBadge(threshold),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Height (cm)',
                  hint: 'e.g., 175',
                  controller: _heightController,
                  validator: (value) =>
                      Validators.range(value, 50, 300, fieldName: 'Height'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: const Icon(Icons.height),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Weight (kg)',
                  hint: 'e.g., 70',
                  controller: _weightController,
                  validator: (value) =>
                      Validators.range(value, 20, 500, fieldName: 'Weight'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: const Icon(Icons.scale),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBmiStatusBadge(HealthThreshold? threshold) {
    String category;
    Color color;

    final minNormal = threshold?.minValue ?? 18.5;
    final maxNormal = threshold?.maxValue ?? 24.9;
    final obeseCutoff = maxNormal + 5.0;

    if (_calculatedBmi! < minNormal) {
      category = 'Underweight';
      color = AppTheme.primaryBlue;
    } else if (_calculatedBmi! <= maxNormal) {
      category = 'Normal';
      color = AppTheme.primaryGreen;
    } else if (_calculatedBmi! <= obeseCutoff) {
      category = 'Overweight';
      color = AppTheme.warningColor;
    } else {
      category = 'Obese';
      color = AppTheme.errorColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
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
