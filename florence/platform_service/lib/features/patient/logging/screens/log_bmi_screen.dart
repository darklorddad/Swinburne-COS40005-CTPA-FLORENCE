import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/button_widgets.dart';
import '../../../../shared/widgets/input_widgets.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';

/// Log BMI Screen
class LogBmiScreen extends StatefulWidget {
  const LogBmiScreen({super.key});

  @override
  State<LogBmiScreen> createState() => _LogBmiScreenState();
}

class _LogBmiScreenState extends State<LogBmiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final ApiService _apiService = ApiService();

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
    final heightCm = double.tryParse(_heightController.text);
    final weightKg = double.tryParse(_weightController.text);

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

    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);

    try {
      await _apiService.post('/patients/me/monitor-data', {
        'data_type': 'BMI',
        'value': _calculatedBmi,
        'measured_at': _selectedDateTime.toIso8601String(),
      });

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
      setState(() {
        _selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log BMI'),
      ),
      body: SingleChildScrollView(
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
                      Validators.minLength(value, 1, fieldName: 'Height'),
                  keyboardType: TextInputType.number,
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
                      Validators.minLength(value, 1, fieldName: 'Weight'),
                  keyboardType: TextInputType.number,
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
    final bmiCategory = Helpers.getBMICategory(_calculatedBmi!);
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
                    child: Text(
                      Formatters.date(_selectedDateTime),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
