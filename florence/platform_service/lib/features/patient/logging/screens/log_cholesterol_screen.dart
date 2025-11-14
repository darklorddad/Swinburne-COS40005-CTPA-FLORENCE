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

/// Log Cholesterol Screen
class LogCholesterolScreen extends StatefulWidget {
  const LogCholesterolScreen({super.key});

  @override
  State<LogCholesterolScreen> createState() => _LogCholesterolScreenState();
}

class _LogCholesterolScreenState extends State<LogCholesterolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cholesterolController = TextEditingController();
  final _notesController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();

  @override
  void dispose() {
    _cholesterolController.dispose();
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
      await _apiService.post('/patients/me/monitor-data', {
        'data_type': 'CHOLESTEROL',
        'value': double.parse(_cholesterolController.text),
        'measured_at': _selectedDateTime.toIso8601String(),
      });

      if (mounted) {
        Helpers.showSuccess(context, 'Cholesterol logged successfully!');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to log cholesterol: ${e.toString()}');
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
        title: const Text('Log Cholesterol'),
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
          Icon(Icons.bloodtype, color: AppTheme.accentPurple, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Keep track of your cholesterol levels for a healthy heart.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return BaseCard(
      child: CustomTextField(
        label: 'Total Cholesterol (mg/dL)',
        hint: 'e.g., 190',
        controller: _cholesterolController,
        validator: Validators.required,
        keyboardType: TextInputType.number,
        prefixIcon: const Icon(Icons.bloodtype_outlined),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Date',
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
                  const Icon(Icons.calendar_today, color: AppTheme.accentPurple),
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

  Widget _buildNotesSection() {
    return CustomTextField(
      label: 'Notes (Optional)',
      hint: 'e.g., Fasting test',
      controller: _notesController,
      maxLines: 3,
      textInputAction: TextInputAction.done,
    );
  }
}
