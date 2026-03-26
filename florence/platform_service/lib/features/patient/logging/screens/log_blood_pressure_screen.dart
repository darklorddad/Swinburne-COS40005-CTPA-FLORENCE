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
import '../../../../core/layout/responsive_layout_system.dart';
import '../../core/models/health_data_models.dart';
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
        _selectedDateTime.toUtc(),
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
    final sysValue = double.tryParse(_systolicController.text);
    final diaValue = double.tryParse(_diastolicController.text);

    // Fetch thresholds
    final healthData = ref.watch(monitorDataProvider).asData?.value;
    HealthThreshold? sysThreshold;
    HealthThreshold? diaThreshold;
    try {
      sysThreshold = healthData?.healthThresholds.firstWhere(
        (t) => t.dataType == MonitorDataType.BLOOD_PRESSURE_SYSTOLIC
      );
      diaThreshold = healthData?.healthThresholds.firstWhere(
        (t) => t.dataType == MonitorDataType.BLOOD_PRESSURE_DIASTOLIC
      );
    } catch (_) {}

    final bpColor = _getBPColor(sysValue, diaValue, sysThreshold, diaThreshold);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Blood Pressure'),
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
                AppRoutes.push(context, AppRoutes.bloodPressureDetail);
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
                      _buildInfoCard(sysThreshold, diaThreshold),
                      const SizedBox(height: 20),

                      // Input Section
                      _buildInputSection(bpColor, sysThreshold, diaThreshold),
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

  Widget _buildInfoCard(HealthThreshold? sysT, HealthThreshold? diaT) {
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
                  'Regularly logging your blood pressure helps monitor cardiovascular health.',
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
                            'Target Ranges',
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
                  _buildMiniTargetRow(
                    'Systolic',
                    sysT != null ? '${sysT.minValue.toInt()} - ${sysT.maxValue.toInt()} mmHg' : 'Not Set',
                    sysT != null ? AppTheme.primaryGreen : AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(height: 4),
                  _buildMiniTargetRow(
                    'Diastolic',
                    diaT != null ? '${diaT.minValue.toInt()} - ${diaT.maxValue.toInt()} mmHg' : 'Not Set',
                    diaT != null ? AppTheme.primaryGreen : AppTheme.textSecondaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTargetRow(String label, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildInputSection(Color? bpColor, HealthThreshold? sysT, HealthThreshold? diaT) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = bpColor != null 
        ? bpColor.withOpacity(0.05) 
        : (isDark ? AppTheme.midnightSurface : Colors.white);
    final borderColor = bpColor ?? AppTheme.getBorderColor(context);

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
            'Blood Pressure Level',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),

          // Large BP input
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Systolic
              Column(
                children: [
                  Text(
                    'SYS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 130,
                    child: TextFormField(
                      controller: _systolicController,
                      validator: (value) => Validators.range(value, 50, 300, fieldName: 'Systolic'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: bpColor ?? AppTheme.textPrimaryColor,
                          ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.05) : AppTheme.backgroundColor,
                        hintText: '---',
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 24, 8, 0),
                child: Text(
                  '/',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.textSecondaryColor.withOpacity(0.5),
                      ),
                ),
              ),

              // Diastolic
              Column(
                children: [
                  Text(
                    'DIA',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 130,
                    child: TextFormField(
                      controller: _diastolicController,
                      validator: (value) => Validators.range(value, 30, 200, fieldName: 'Diastolic'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: bpColor ?? AppTheme.textPrimaryColor,
                          ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.05) : AppTheme.backgroundColor,
                        hintText: '---',
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  'mmHg',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Status indicator (Always visible, fixed size)
          SizedBox(
            height: 32,
            child: Center(
              child: Builder(
                builder: (context) {
                  final sysValue = double.tryParse(_systolicController.text);
                  final diaValue = double.tryParse(_diastolicController.text);
                  final statusText = bpColor != null
                      ? _getBPStatus(sysValue, diaValue, sysT, diaT).toUpperCase()
                      : 'ENTER READING';

                  IconData statusIcon;
                  if (bpColor == null) {
                    statusIcon = Icons.edit;
                  } else if (statusText == 'LOW') {
                    statusIcon = Icons.arrow_downward;
                  } else if (statusText == 'ELEVATED') {
                    statusIcon = Icons.arrow_upward;
                  } else {
                    statusIcon = Icons.check;
                  }

                  final displayColor = bpColor ?? AppTheme.textSecondaryColor;

                  return Container(
                    width: 140, // Fixed width
                    height: 32, // Fixed height
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bpColor == null
                          ? (isDark ? Colors.white.withOpacity(0.05) : AppTheme.backgroundColor)
                          : displayColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: displayColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: displayColor),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: displayColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
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

  Color? _getBPColor(double? sys, double? dia, HealthThreshold? sysT, HealthThreshold? diaT) {
    if (sys == null || dia == null) return null;
    
    final sMin = sysT?.minValue ?? 90;
    final sMax = sysT?.maxValue ?? 120;
    final dMin = diaT?.minValue ?? 60;
    final dMax = diaT?.maxValue ?? 80;

    if (sys > sMax || dia > dMax) return AppTheme.errorColor;
    if (sys < sMin || dia < dMin) return AppTheme.warningColor;
    return AppTheme.primaryGreen;
  }

  String _getBPStatus(double? sys, double? dia, HealthThreshold? sysT, HealthThreshold? diaT) {
    if (sys == null || dia == null) return '';
    
    final sMin = sysT?.minValue ?? 90;
    final sMax = sysT?.maxValue ?? 120;
    final dMin = diaT?.minValue ?? 60;
    final dMax = diaT?.maxValue ?? 80;

    if (sys > sMax || dia > dMax) return 'Elevated';
    if (sys < sMin || dia < dMin) return 'Low';
    return 'Normal';
  }
}
