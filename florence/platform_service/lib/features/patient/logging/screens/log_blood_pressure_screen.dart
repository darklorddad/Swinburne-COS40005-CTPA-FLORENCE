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

/// Log Blood Pressure Screen
class LogBloodPressureScreen extends StatefulWidget {
  const LogBloodPressureScreen({super.key});

  @override
  State<LogBloodPressureScreen> createState() => _LogBloodPressureScreenState();
}

class _LogBloodPressureScreenState extends State<LogBloodPressureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _notesController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);

    try {
      final now = _selectedDateTime.toIso8601String();
      
      // Post Systolic
      await _apiService.post('/patients/me/monitor-data', {
        'data_type': 'BLOOD_PRESSURE_SYSTOLIC',
        'value': double.parse(_systolicController.text),
        'measured_at': now,
      });

      // Post Diastolic
      await _apiService.post('/patients/me/monitor-data', {
        'data_type': 'BLOOD_PRESSURE_DIASTOLIC',
        'value': double.parse(_diastolicController.text),
        'measured_at': now,
      });

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
              _buildNotesSection(),
              const SizedBox(height: 32),
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
                  validator: Validators.required,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.arrow_upward),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Diastolic',
                  hint: 'e.g., 80',
                  controller: _diastolicController,
                  validator: Validators.required,
                  keyboardType: TextInputType.number,
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

  Widget _buildNotesSection() {
    return CustomTextField(
      label: 'Notes (Optional)',
      hint: 'Any symptoms or observations?',
      controller: _notesController,
      maxLines: 3,
      textInputAction: TextInputAction.done,
    );
  }
}
