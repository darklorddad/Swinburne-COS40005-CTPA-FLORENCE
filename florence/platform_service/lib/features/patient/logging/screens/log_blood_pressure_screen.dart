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

/// Log Blood Pressure Screen
class LogBloodPressureScreen extends ConsumerStatefulWidget {
  const LogBloodPressureScreen({super.key});

  @override
  ConsumerState<LogBloodPressureScreen> createState() => _LogBloodPressureScreenState();
}

class _LogBloodPressureScreenState extends ConsumerState<LogBloodPressureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();

  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Foolproof 2: Logic check prevents impossible medical data
    final sys = double.tryParse(_systolicController.text);
    final dia = double.tryParse(_diastolicController.text);

    if (sys == null || dia == null) {
      Helpers.showError(context, 'Please enter valid numbers.');
      return;
    }

    if (dia >= sys) {
      Helpers.showError(context, 'Diastolic (bottom) must be lower than Systolic (top).');
      return;
    }

    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);

    try {
      await ref.read(monitorDataRepositoryProvider).addBloodPressure(
        _selectedDateTime,
        sys,
        dia,
      );
      
      ref.invalidate(monitorDataProvider);

      if (mounted) {
        Helpers.showSuccess(context, 'Blood pressure logged successfully!');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to log blood pressure: ${e.toString()}');
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
        title: const Text('Log Blood Pressure'),
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
              _buildDateTimeSection(),
              const SizedBox(height: 24),
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
    );
  }

  Widget _buildInfoCard() {
    return const BaseCard(
      child: Row(
        children: [
          Icon(Icons.monitor_heart, color: AppTheme.primaryRed, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Regularly logging your blood pressure helps monitor cardiovascular health.',
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
            'Blood Pressure (mmHg)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Systolic',
                  hint: 'e.g., 120',
                  controller: _systolicController,
                  // Foolproof 1: Range validator prevents non-numbers crashing the app
                  validator: (value) => Validators.range(value, 50, 300, fieldName: 'Systolic'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: const Icon(Icons.arrow_upward),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Diastolic',
                  hint: 'e.g., 80',
                  controller: _diastolicController,
                  // Foolproof 1: Range validator prevents non-numbers crashing the app
                  validator: (value) => Validators.range(value, 30, 200, fieldName: 'Diastolic'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: const Icon(Icons.arrow_downward),
                ),
              ),
            ],
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
                  const Icon(Icons.access_time, color: AppTheme.primaryRed),
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
