import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart'; // For ApiService (if needed, but repo used)
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/button_widgets.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';
import '../../../../core/layout/responsive_layout_system.dart';
import '../../core/models/health_data_models.dart';
import '../../core/providers/monitor_data_providers.dart'; // Added
import '../../core/repositories/monitor_data_repository.dart';

/// Log HbA1c Screen
/// Allows users to record Hemoglobin A1c readings
class LogHba1cScreen extends ConsumerStatefulWidget {
  const LogHba1cScreen({super.key});

  @override
  ConsumerState<LogHba1cScreen> createState() => _LogHba1cScreenState();
}

class _LogHba1cScreenState extends ConsumerState<LogHba1cScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hba1cController = TextEditingController();
  
  // State
  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();
  
  @override
  void dispose() {
    _hba1cController.dispose();
    super.dispose();
  }
  
  /// Handle save
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Foolproof 1: Prevent logging in the future
    if (_selectedDateTime.isAfter(DateTime.now())) {
      Helpers.showError(context, 'Cannot log readings in the future.');
      return;
    }

    // Foolproof 2: Prevent duplicate logs
    final existingData = ref.read(monitorDataProvider).asData?.value.allMonitorData ?? [];
    final isDuplicate = existingData.any((d) {
      if (d.dataType != MonitorDataType.HBA1C) return false;
      
      // Convert DB time to local to match user selection
      final localDate = d.measuredAt.toLocal();
      
      return localDate.year == _selectedDateTime.year &&
             localDate.month == _selectedDateTime.month &&
             localDate.day == _selectedDateTime.day &&
             localDate.hour == _selectedDateTime.hour &&
             localDate.minute == _selectedDateTime.minute;
    });

    if (isDuplicate) {
      Helpers.showError(context, 'An HbA1c reading for this time already exists.');
      return;
    }
    
    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);
    
    try {
      // Foolproof 3: Handle comma vs dot and use tryParse for crash safety
      final normalizedText = _hba1cController.text.replaceAll(',', '.');
      final value = double.tryParse(normalizedText);

      if (value == null) {
        throw const FormatException('Invalid number format');
      }

      // Use repository to add data
      // Convert to UTC to ensure global consistency
      await ref.read(monitorDataRepositoryProvider).addMonitorData(
        'HBA1C',
        value,
        _selectedDateTime.toUtc(),
      );
      
      // Invalidate provider to refresh dashboard
      ref.invalidate(monitorDataProvider);
      
      if (mounted) {
        Helpers.showSuccess(context, 'HbA1c reading saved successfully!');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to save HbA1c reading: ${e.toString()}');
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
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time?.hour ?? _selectedDateTime.hour,
            time?.minute ?? _selectedDateTime.minute,
          );
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final hba1cValue = double.tryParse(_hba1cController.text.replaceAll(',', '.'));

    // Fetch thresholds
    final healthData = ref.watch(monitorDataProvider).asData?.value;
    HealthThreshold? hba1cThreshold;
    try {
      hba1cThreshold = healthData?.healthThresholds.firstWhere(
        (t) => t.dataType == MonitorDataType.HBA1C
      );
    } catch (_) {}

    final hba1cColor = _getHba1cColor(hba1cValue, hba1cThreshold);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log HbA1c'),
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
                AppRoutes.push(context, AppRoutes.hba1cDetail);
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
                      _buildInfoCard(hba1cThreshold),
                      const SizedBox(height: 20),

                      // Input Section
                      _buildInputSection(hba1cColor, hba1cThreshold),
                      const SizedBox(height: 20),

                      // Date and time
                      _buildDateTimeSection(),
                      const SizedBox(height: 32),

                      // Save button
                      PrimaryButton(
                        text: 'Save Reading',
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
                  'HbA1c reflects your average blood sugar level over the past 2-3 months.',
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
                        'HbA1c', 
                        style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen.withOpacity(0.8))
                      ),
                      Text(
                        threshold != null 
                          ? '${threshold.minValue.toStringAsFixed(1)} - ${threshold.maxValue.toStringAsFixed(1)}%'
                          : '4.0 - 7.0%',
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

  Widget _buildInputSection(Color? hba1cColor, HealthThreshold? threshold) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = hba1cColor != null 
        ? hba1cColor.withOpacity(0.05) 
        : (isDark ? AppTheme.midnightSurface : Colors.white);
    final borderColor = hba1cColor ?? AppTheme.getBorderColor(context);
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
                  Icons.pie_chart_outline,
                  color: titleIconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'HbA1c Level (%)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _hba1cController,
                  validator: Validators.hba1c,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: hba1cColor ?? AppTheme.textPrimaryColor,
                      ),
                  decoration: InputDecoration(
                    hintText: '---',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : AppTheme.backgroundColor,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
          if (hba1cColor != null) ...[
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: hba1cColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: hba1cColor.withOpacity(0.2)),
                ),
                child: Text(
                  _getHba1cStatus(
                    double.tryParse(_hba1cController.text.replaceAll(',', '.')),
                    threshold,
                  ).toUpperCase(),
                  style: TextStyle(
                    color: hba1cColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
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
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
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

  Color? _getHba1cColor(double? value, HealthThreshold? threshold) {
    if (value == null) return null;
    final min = threshold?.minValue ?? 4.0;
    final max = threshold?.maxValue ?? 7.0;

    if (value > max) return AppTheme.errorColor;
    if (value < min) return AppTheme.warningColor;
    return AppTheme.primaryGreen;
  }

  String _getHba1cStatus(double? value, HealthThreshold? threshold) {
    if (value == null) return '';
    final min = threshold?.minValue ?? 4.0;
    final max = threshold?.maxValue ?? 7.0;

    if (value > max) return 'High';
    if (value < min) return 'Low';
    return 'Normal';
  }
}
