import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:florence/config/routes.dart';
import 'package:florence/core/config/environment.dart';
import 'package:florence/core/services/api_service.dart';
import 'package:florence/features/patient/core/providers/settings_providers.dart';
import 'package:florence/config/theme.dart';
import 'package:florence/core/utils/formatters.dart';
import 'package:florence/core/utils/helpers.dart';
import 'package:florence/shared/widgets/button_widgets.dart';
import 'package:florence/features/patient/core/models/health_data_models.dart';
import 'package:florence/features/patient/core/providers/monitor_data_providers.dart';
import 'package:florence/features/patient/core/providers/threshold_providers.dart';
import 'package:florence/features/patient/core/repositories/monitor_data_repository.dart';

/// Log Cholesterol Screen
class LogCholesterolScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSwitchToHistory;
  const LogCholesterolScreen({super.key, this.onSwitchToHistory});

  @override
  ConsumerState<LogCholesterolScreen> createState() => _LogCholesterolScreenState();
}

class _LogCholesterolScreenState extends ConsumerState<LogCholesterolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _totalController = TextEditingController();
  final _ldlController = TextEditingController();
  final _hdlController = TextEditingController();
  final _triglyceridesController = TextEditingController();

  bool _isScanning = false;
  final ImagePicker _picker = ImagePicker();
  bool _forcePop = false;
  String _initialTotal = '';
  String _initialLdl = '';
  String _initialHdl = '';
  String _initialTri = '';
  late DateTime _initialDateTime;
  bool _isLoading = false;
  // Initialize with seconds stripped for clean database grouping
  DateTime _selectedDateTime = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    DateTime.now().hour,
    DateTime.now().minute,
  );

  @override
  void initState() {
    super.initState();
    _initialDateTime = _selectedDateTime;
  }

  Future<void> _scanLabReport() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() => _isScanning = true);

      final bytes = await pickedFile.readAsBytes();

      final result = await _apiService.uploadFile(
        '/biometrics/parse-lab-report',
        'file',
        bytes,
        pickedFile.name,
        baseUrlOverride: Environment.llmEngineServiceUrl,
        additionalFields: {'report_type': 'lipid_panel'},
      );

      if (mounted && result != null) {
        setState(() {
          if (result['total_cholesterol'] != null) {
            _totalController.text = result['total_cholesterol'].toString();
          }
          if (result['hdl'] != null) {
            _hdlController.text = result['hdl'].toString();
          }
          if (result['ldl'] != null) {
            _ldlController.text = result['ldl'].toString();
          }
          if (result['triglycerides'] != null) {
            _triglyceridesController.text = result['triglycerides'].toString();
          }
        });
        Helpers.showSuccess(context, 'Lab report parsed! Please verify the values before saving.');
      }
    } catch (e) {
      if (mounted) Helpers.showError(context, 'Failed to parse report: $e');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

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
        // Fix: Handle comma inputs (e.g. 190,5 -> 190.5) to prevent crashes
        final text = controller.text.trim().replaceAll(',', '.');
        if (text.isNotEmpty) {
          // Fix: Send UTC time to ensure consistency across timezones
          tasks.add(repo.addMonitorData(
            type, 
            double.parse(text), 
            _selectedDateTime.toUtc(),
          ));
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
        AppRoutes.pushAndRemoveUntil(context, AppRoutes.dashboard);
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

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      // Fix: Add TimePicker to allow accurate back-logging of lab results
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
      _totalController.text = _initialTotal;
      _ldlController.text = _initialLdl;
      _hdlController.text = _initialHdl;
      _triglyceridesController.text = _initialTri;
      _selectedDateTime = _initialDateTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Fetch thresholds
    final healthData = ref.watch(monitorDataProvider).asData?.value;
    HealthThreshold? totalThreshold;
    HealthThreshold? ldlThreshold;
    HealthThreshold? hdlThreshold;
    HealthThreshold? triThreshold;
    try {
      totalThreshold = healthData?.healthThresholds.firstWhere(
        (t) => t.dataType == MonitorDataType.CHOLESTEROL_TOTAL
      );
      ldlThreshold = healthData?.healthThresholds.firstWhere(
        (t) => t.dataType == MonitorDataType.CHOLESTEROL_LDL
      );
      hdlThreshold = healthData?.healthThresholds.firstWhere(
        (t) => t.dataType == MonitorDataType.CHOLESTEROL_HDL
      );
      triThreshold = healthData?.healthThresholds.firstWhere(
        (t) => t.dataType == MonitorDataType.CHOLESTEROL_TRIGLYCERIDES
      );
    } catch (_) {}

    final bool hasChanges = !_forcePop && 
        (_totalController.text != _initialTotal || 
         _ldlController.text != _initialLdl || 
         _hdlController.text != _initialHdl || 
         _triglyceridesController.text != _initialTri ||
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
          title: const Text('Log Cholesterol'),
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
                    AppRoutes.pushReplacement(context, AppRoutes.cholesterolDetail);
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
                        _buildInfoCard(totalThreshold, ldlThreshold,
                            hdlThreshold, triThreshold),
                        const SizedBox(height: 20),

                        // The new unified Lipid Panel Card
                        _buildLipidPanelSection(),
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

  Widget _buildInfoCard(HealthThreshold? totalT, HealthThreshold? ldlT,
      HealthThreshold? hdlT, HealthThreshold? triT) {
    final settings = ref.watch(patientSettingsProvider);
    final currentUnit = settings.cholesterolUnit;

    final thresholdsAsync = ref.watch(patientThresholdsProvider);
    String targetText = "Loading target...";
    if (thresholdsAsync.hasValue && thresholdsAsync.value != null) {
      try {
        final totalTarget = thresholdsAsync.value!
            .firstWhere((t) => t.dataType == 'CHOLESTEROL_TOTAL');
        targetText =
            "Total Target: ${totalTarget.minValue} - ${totalTarget.maxValue} $currentUnit";
      } catch (e) {
        targetText = "Target: Not set";
      }
    }

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
                      'Keep track of your cholesterol levels for a healthy heart.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.infoColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      targetText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.infoColor.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
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
                  _buildMiniTargetRow('Total', totalT != null ? '${totalT.minValue.toInt()} - ${totalT.maxValue.toInt()} mg/dL' : 'Not Set', AppTheme.primaryGreen),
                  const SizedBox(height: 4),
                  _buildMiniTargetRow('LDL', ldlT != null ? '${ldlT.minValue.toInt()} - ${ldlT.maxValue.toInt()} mg/dL' : 'Not Set', AppTheme.primaryGreen),
                  const SizedBox(height: 4),
                  _buildMiniTargetRow('HDL', hdlT != null ? '${hdlT.minValue.toInt()} - ${hdlT.maxValue.toInt()} mg/dL' : 'Not Set', AppTheme.primaryGreen),
                  const SizedBox(height: 4),
                  _buildMiniTargetRow('Triglycerides', triT != null ? '${triT.minValue.toInt()} - ${triT.maxValue.toInt()} mg/dL' : 'Not Set', AppTheme.primaryGreen),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLipidPanelSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);
    final titleIconColor = isDark ? Colors.blue.shade200 : AppTheme.primaryBlue;

    final settings = ref.watch(patientSettingsProvider);
    final currentUnit = settings.cholesterolUnit;

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
          // 1. Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: titleIconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.science_outlined,
                  size: 24,
                  color: titleIconColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Lipid Panel ($currentUnit)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 2. The Photo Button
          InkWell(
            onTap: _isScanning ? null : _scanLabReport,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: _isScanning
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          'Analyzing Report...',
                          style: TextStyle(
                            color:
                                isDark ? Colors.white : AppTheme.textPrimaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 28,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add Lab Report',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // 3. The 2x2 Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _buildGridLabField(
                      'Total',
                      _totalController,
                      currentUnit,
                      Icons.bloodtype_outlined,
                      '5.0',
                      '150')),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildGridLabField('LDL', _ldlController, currentUnit,
                      Icons.arrow_downward, '2.5', '100')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _buildGridLabField('HDL', _hdlController, currentUnit,
                      Icons.arrow_upward, '1.5', '50')),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildGridLabField(
                      'Triglycerides',
                      _triglyceridesController,
                      currentUnit,
                      Icons.water_drop_outlined,
                      '1.7',
                      '150')),
            ],
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

  Widget _buildGridLabField(String label, TextEditingController controller, String unit, IconData icon, String placeholderMmol, String placeholderMgdl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMmol = unit == 'mmol/L';
    final double minValid = isMmol ? 0.1 : 5.0;
    final double maxValid = isMmol ? 50.0 : 1000.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          validator: (val) {
            if (val != null && val.isNotEmpty) {
              final num = double.tryParse(val.replaceAll(',', '.'));
              if (num == null) return 'Invalid';
              if (num < minValid || num > maxValid) return 'Range:\n$minValid - $maxValid';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: isMmol ? 'e.g. $placeholderMmol' : 'e.g. $placeholderMgdl',
            prefixIcon: Icon(icon, color: AppTheme.textSecondaryColor, size: 20),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryBlue,
                width: 2,
              ),
            ),
          ),
        ),
      ],
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
