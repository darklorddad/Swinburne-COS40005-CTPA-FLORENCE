import 'package:florence/config/routes.dart';
import 'package:florence/config/theme.dart';
import 'package:florence/core/utils/formatters.dart';
import 'package:florence/core/utils/helpers.dart';
import 'package:florence/core/utils/validators.dart';
import 'package:florence/features/patient/core/providers/monitor_data_providers.dart';
import 'package:florence/features/patient/core/providers/threshold_providers.dart';
import 'package:florence/features/patient/core/repositories/monitor_data_repository.dart';
import 'package:florence/shared/widgets/button_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Log Blood Pressure Screen
class LogBloodPressureScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSwitchToHistory;
  const LogBloodPressureScreen({super.key, this.onSwitchToHistory});

  @override
  ConsumerState<LogBloodPressureScreen> createState() => _LogBloodPressureScreenState();
}

class _LogBloodPressureScreenState extends ConsumerState<LogBloodPressureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _systolicFocusNode = FocusNode();
  final _diastolicFocusNode = FocusNode();

  bool _forcePop = false;
  String _initialSystolic = '';
  String _initialDiastolic = '';
  late DateTime _initialDateTime;
  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initialDateTime = _selectedDateTime;
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _systolicFocusNode.dispose();
    _diastolicFocusNode.dispose();
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
        AppRoutes.pushAndRemoveUntil(context, AppRoutes.dashboard);
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
      _systolicController.text = _initialSystolic;
      _diastolicController.text = _initialDiastolic;
      _selectedDateTime = _initialDateTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sysValue = double.tryParse(_systolicController.text);
    final diaValue = double.tryParse(_diastolicController.text);

    // Fetch thresholds from the NEW provider
    final thresholdsAsync = ref.watch(patientThresholdsProvider);
    PatientThreshold? sysThreshold;
    PatientThreshold? diaThreshold;

    if (thresholdsAsync.hasValue && thresholdsAsync.value != null) {
      try {
        sysThreshold = thresholdsAsync.value!.firstWhere(
          (t) => t.dataType == 'BLOOD_PRESSURE_SYSTOLIC',
        );
        diaThreshold = thresholdsAsync.value!.firstWhere(
          (t) => t.dataType == 'BLOOD_PRESSURE_DIASTOLIC',
        );
      } catch (_) {}
    }

    final bpColor = _getBPColor(sysValue, diaValue, sysThreshold, diaThreshold);

    final bool hasChanges = !_forcePop && 
        (_systolicController.text != _initialSystolic || 
         _diastolicController.text != _initialDiastolic ||
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
                onPressed: () async {
                  if (hasChanges) {
                    final shouldDiscard = await _showDiscardDialog();
                    if (!shouldDiscard) return;
                    _resetForm();
                  }
                  if (widget.onSwitchToHistory != null) {
                    widget.onSwitchToHistory!();
                  } else {
                    AppRoutes.pushReplacement(context, AppRoutes.bloodPressureDetail);
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
      ),
    );
  }

  Widget _buildInfoCard(PatientThreshold? sysT, PatientThreshold? diaT) {

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
            color: Colors.black.withValues(alpha: 0.03),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Regularly logging your blood pressure helps monitor cardiovascular health.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.infoColor,
                          ),
                    ),
                  ],
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
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
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
                              color: AppTheme.primaryGreen.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppTheme.primaryGreen.withValues(alpha: 0.5),
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
        Text(label, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildInputSection(
      Color? bpColor, PatientThreshold? sysT, PatientThreshold? diaT) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = bpColor != null 
        ? bpColor.withValues(alpha: 0.05) 
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
            color: Colors.black.withValues(alpha: 0.03),
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
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
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
                  SizedBox(
                    width: 110,
                    child: TextFormField(
                      controller: _systolicController,
                      focusNode: _systolicFocusNode,
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
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor,
                        hintText: '---',
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Systolic',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                  ),
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                child: Text(
                  '/',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
                      ),
                ),
              ),

              // Diastolic
              Column(
                children: [
                  SizedBox(
                    width: 110,
                    child: TextFormField(
                      controller: _diastolicController,
                      focusNode: _diastolicFocusNode,
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
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor,
                        hintText: '---',
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Diastolic',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                  ),
                ],
              ),
              
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
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

                  return InkWell(
                    onTap: () => _systolicFocusNode.requestFocus(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 140, // Fixed width
                      height: 32, // Fixed height
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bpColor == null
                            ? (isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor)
                            : displayColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: displayColor.withValues(alpha: 0.3)),
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
            color: Colors.black.withValues(alpha: 0.03),
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
                  color: titleIconColor.withValues(alpha: 0.1),
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
              color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.borderColor,
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
                Divider(height: 1, color: AppTheme.borderColor.withValues(alpha: 0.5)),
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

  Color? _getBPColor(
      double? sys, double? dia, PatientThreshold? sysT, PatientThreshold? diaT) {
    if (sys == null || dia == null) return null;
    
    final sMin = sysT?.minValue ?? 90;
    final sMax = sysT?.maxValue ?? 120;
    final dMin = diaT?.minValue ?? 60;
    final dMax = diaT?.maxValue ?? 80;

    if (sys > sMax || dia > dMax) return AppTheme.errorColor;
    if (sys < sMin || dia < dMin) return AppTheme.warningColor;
    return AppTheme.primaryGreen;
  }

  String _getBPStatus(
      double? sys, double? dia, PatientThreshold? sysT, PatientThreshold? diaT) {
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
