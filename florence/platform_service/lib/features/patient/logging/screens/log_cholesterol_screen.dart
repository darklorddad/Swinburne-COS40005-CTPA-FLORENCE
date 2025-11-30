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
import '../../core/providers/monitor_data_providers.dart';

/// Log Cholesterol Screen
class LogCholesterolScreen extends ConsumerStatefulWidget {
  const LogCholesterolScreen({super.key});

  @override
  ConsumerState<LogCholesterolScreen> createState() => _LogCholesterolScreenState();
}

class _LogCholesterolScreenState extends ConsumerState<LogCholesterolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalController = TextEditingController(); 
  final _ldlController = TextEditingController();
  final _hdlController = TextEditingController();
  final _triglyceridesController = TextEditingController();
  // final ApiService _apiService = ApiService(); // Removed

  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();

  @override
  void dispose() {
    _totalController.dispose();
    _ldlController.dispose();
    _hdlController.dispose();
    _triglyceridesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(monitorDataRepositoryProvider);
      final List<Future> tasks = [];

      // Helper
      void addCallIfNotEmpty(TextEditingController controller, String type) {
        if (controller.text.trim().isNotEmpty) {
          tasks.add(repo.addMonitorData(type, double.parse(controller.text.trim()), _selectedDateTime));
        }
      }

      addCallIfNotEmpty(_totalController, 'CHOLESTEROL_TOTAL');
      addCallIfNotEmpty(_ldlController, 'CHOLESTEROL_LDL');
      addCallIfNotEmpty(_hdlController, 'CHOLESTEROL_HDL');
      addCallIfNotEmpty(_triglyceridesController, 'CHOLESTEROL_TRIGLYCERIDES');

      if (tasks.isEmpty) {
        throw Exception("Please enter at least one value.");
      }

      await Future.wait(tasks);
      
      ref.invalidate(monitorDataProvider);

      if (mounted) {
        Helpers.showSuccess(context, 'Cholesterol data logged successfully!');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to log data: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

class _LogCholesterolScreenState extends ConsumerState<LogCholesterolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalController = TextEditingController(); 
  final _ldlController = TextEditingController();
  final _hdlController = TextEditingController();
  final _triglyceridesController = TextEditingController();
  // final ApiService _apiService = ApiService(); // Removed

  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();

  @override
  void dispose() {
    _totalController.dispose();
    _ldlController.dispose();
    _hdlController.dispose();
    _triglyceridesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(monitorDataRepositoryProvider);
      final List<Future> tasks = [];

      // Helper
      void addCallIfNotEmpty(TextEditingController controller, Function(DateTime, double) operation) {
        if (controller.text.trim().isNotEmpty) {
          tasks.add(operation(_selectedDateTime, double.parse(controller.text.trim())));
        }
      }

      // Queue up requests
      // Note: We need dedicated repo methods for each if we want repo to encapsulate logic
      // Or we can create a generic addCholesterolReading in the repo.
      // For now, I will add a generic 'addMonitorData' to the repo or specific ones if available.
      // Since I added addCholesterol (which does total), I might need addLDL, etc or make it more generic.
      // But wait, the implementation plan said: "Move Write logic ... into MonitorDataRepository".
      // I implemented 'addCholesterol' for TOTAL only in the previous step.
      // I should probably update the repo to handle all types or expose a generic write.
      // To be architecturally strict, I should add specific methods.
      
      // Let's assume I'll update the repo again to support these or use a generic method if I had one.
      // Actually, to save time and be cleaner, I should probably just add a flexible 'addMonitorData' to the repo.
      // But the instruction was "Create mutation providers... that call the repository".
      // Let's start with what I have. I have addCholesterol (Total). I need others.
      
      // Re-reading the repo file I edited... I added addCholesterol(DateTime timestamp, double value) for CHOLESTEROL_TOTAL.
      // I should probably make that method more flexible or add others.
      // I will edit the repo to add 'addMonitorData' which is generic enough for all.
      
      // Actually, let's just use the repo's generic nature if possible.
      // I'll queue them using a new Generic method I'll add to repo next.
      
      // Wait, I can't edit the repo method signature inside this file edit.
      // I will pause this edit and update the repo first.
      throw Exception("Repo update needed first"); 

    } catch (e) {
      // ...
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
      child: Column(
        children: [
          CustomTextField(
            label: 'Total Cholesterol (mg/dL)',
            hint: 'e.g., 190',
            controller: _totalController,
            // Keep Total as required, or remove validator to make it optional
            validator: (value) =>
                Validators.minLength(value, 1, fieldName: 'Total Cholesterol'),
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.bloodtype_outlined),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'LDL Cholesterol (mg/dL)',
            hint: 'e.g., 100',
            controller: _ldlController,
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.arrow_downward),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'HDL Cholesterol (mg/dL)',
            hint: 'e.g., 60',
            controller: _hdlController,
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.arrow_upward),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Triglycerides (mg/dL)',
            hint: 'e.g., 150',
            controller: _triglyceridesController,
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.water_drop_outlined),
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
}
