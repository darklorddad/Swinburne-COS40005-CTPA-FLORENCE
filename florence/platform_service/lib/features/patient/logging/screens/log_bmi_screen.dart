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
      await ref.read(monitorDataRepositoryProvider).addMonitorData(
        'BMI',
        _calculatedBmi!,
        _selectedDateTime.toUtc(),
      );
      
      ref.invalidate(core_providers.monitorDataProvider);

      if (mounted) {
        Helpers.showSuccess(context, 'BMI logged successfully!');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log BMI'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoCard(),
              const SizedBox(height: 24),
              _buildInputSection(),
              const SizedBox(height: 24),
              if (_calculatedBmi != null) ...[
                _buildBmiResultCard(),
                const SizedBox(height: 24),
              ],
              _buildDateTimeSection(),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Save Reading',
                onPressed: (_isLoading || _calculatedBmi == null) ? null : _handleSave,
                isLoading: _isLoading,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return const BaseCard(
      child: Row(
        children: [
          Icon(Icons.height, color: AppTheme.primaryGreen, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Body Mass Index (BMI) is a measure of body fat based on height and weight.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Measurements',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
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

  Widget _buildBmiResultCard() {
    // Fetch dynamic thresholds from the provider
    final thresholdsAsync = ref.watch(patientThresholdsProvider);
    final thresholds = thresholdsAsync.value ?? [];
    
    String bmiCategory;
    
    // Try to find dynamic BMI threshold
    final t = thresholds.cast<HealthThreshold?>().firstWhere(
          (t) => t?.dataType == MonitorDataType.BMI,
          orElse: () => null,
        );

    if (t != null) {
      // Dynamic Logic
      final maxNormal = t.maxValue;
      final obeseCutoff = maxNormal + 5.0;

      if (_calculatedBmi! < t.minValue) {
        bmiCategory = 'Underweight';
      } else if (_calculatedBmi! <= maxNormal) {
        bmiCategory = 'Normal';
      } else if (_calculatedBmi! <= obeseCutoff) {
        bmiCategory = 'Overweight';
      } else {
        bmiCategory = 'Obese';
      }
    } else {
      // Fallback to static helper if no data loaded
      bmiCategory = Helpers.getBMICategory(_calculatedBmi!);
    }

    return BaseCard(
      child: Column(
        children: [
          Text(
            'Your BMI',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _calculatedBmi!.toStringAsFixed(1),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            bmiCategory,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Measurement Date',
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
                  const Icon(Icons.calendar_today, color: AppTheme.primaryGreen),
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
                  const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
