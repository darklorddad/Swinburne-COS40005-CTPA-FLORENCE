import 'package:florence/config/routes.dart';
import 'package:florence/config/theme.dart';
import 'package:florence/core/utils/formatters.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:florence/core/config/environment.dart';
import 'package:florence/core/services/api_service.dart';
import 'package:florence/core/utils/helpers.dart';
import 'package:florence/core/utils/validators.dart';
import 'package:florence/features/patient/core/models/health_data_models.dart';
import 'package:florence/features/patient/core/providers/monitor_data_providers.dart';
import 'package:florence/features/patient/core/providers/threshold_providers.dart';
import 'package:florence/features/patient/core/repositories/monitor_data_repository.dart';
import 'package:florence/shared/widgets/button_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Log HbA1c Screen
/// Allows users to record Hemoglobin A1c readings
class LogHba1cScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSwitchToHistory;
  const LogHba1cScreen({super.key, this.onSwitchToHistory});

  @override
  ConsumerState<LogHba1cScreen> createState() => _LogHba1cScreenState();
}

class _LogHba1cScreenState extends ConsumerState<LogHba1cScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _hba1cController = TextEditingController();
  
  // State
  bool _forcePop = false;
  String _initialHba1c = '';
  late DateTime _initialDateTime;
  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();

  // AI Auto-Fill State
  bool _isAnalyzing = false;
  Uint8List? _fileBytes;
  String? _selectedFileName;
  bool _isPdf = false;
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _initialDateTime = _selectedDateTime;
  }

  @override
  void dispose() {
    _hba1cController.dispose();
    super.dispose();
  }
  
  void _showAiInfoDialog() {
    FocusScope.of(context).requestFocus(FocusNode());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text('AI Auto-Fill'),
          ],
        ),
        content: const Text(
          'Upload a photo or PDF of your lab report, and our AI will automatically extract your HbA1c reading for you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImageSourcePicker() async {
    FocusScope.of(context).requestFocus(FocusNode());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.midnightSurface : Colors.white;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upload Lab Report',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                    onPressed: _showAiInfoDialog,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPhotoOption(
                    context,
                    title: 'Camera',
                    icon: Icons.camera_alt_outlined,
                    color: AppTheme.primaryBlue,
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
                      if (photo != null) {
                        final bytes = await photo.readAsBytes();
                        _processFile(bytes, photo.name, false);
                      }
                    },
                  ),
                  _buildPhotoOption(
                    context,
                    title: 'Gallery',
                    icon: Icons.photo_library_outlined,
                    color: AppTheme.primaryGreen,
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        _processFile(bytes, image.name, false);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoOption(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.getBorderColor(context)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Future<void> _processFile(Uint8List bytes, String filename, bool isPdf) async {
    setState(() {
      _fileBytes = bytes;
      _selectedFileName = filename;
      _isPdf = isPdf;
      _isAnalyzing = true;
    });

    await _analyzeLabReport(bytes, filename, isPdf);
  }

  Future<void> _analyzeLabReport(Uint8List fileBytes, String filename, bool isPdf) async {
    try {
      final llmUrl = '${Environment.llmEngineServiceUrl}/biometrics/parse-lab-report';
      final session = Supabase.instance.client.auth.currentSession;
      
      final request = http.MultipartRequest('POST', Uri.parse(llmUrl));
      request.headers.addAll({
        'Authorization': 'Bearer ${session?.accessToken}',
      });
      
      request.fields['report_type'] = 'hba1c';
      request.fields['target_unit'] = '%';
      
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        fileBytes, 
        filename: filename,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (mounted) {
          setState(() {
            if (data['hba1c'] != null && data['hba1c']['value'] != null) {
              _hba1cController.text = data['hba1c']['value'].toString();
            }
            _isAnalyzing = false;
          });
          Helpers.showSuccess(context, 'Lab report analyzed successfully!');
        }
      } else {
        throw Exception('Failed to analyze report');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        Helpers.showError(context, 'Could not analyze report. Please enter manually.');
      }
    }
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

      int? documentId;
      if (_fileBytes != null && _selectedFileName != null) {
        try {
          final uploadRes = await _apiService.uploadFile(
            '/patients/me/clinical-documents/upload',
            'file',
            _fileBytes!,
            _selectedFileName!,
            additionalFields: {'document_type': 'LAB_REPORT'},
          );
          if (uploadRes != null && uploadRes['document'] != null) {
            documentId = uploadRes['document']['id'];
          }
        } catch (e) {
          debugPrint('Failed to upload document: $e');
        }
      }

      // Use repository to add data
      // Convert to UTC to ensure global consistency
      await ref.read(monitorDataRepositoryProvider).addMonitorData(
        'HBA1C',
        value,
        _selectedDateTime.toUtc(),
        documentId: documentId,
      );
      
      // Invalidate provider to refresh dashboard
      ref.invalidate(monitorDataProvider);
      
      if (mounted) {
        Helpers.showSuccess(context, 'HbA1c reading saved successfully!');
        AppRoutes.pushAndRemoveUntil(context, AppRoutes.dashboard);
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
      _hba1cController.text = _initialHba1c;
      _selectedDateTime = _initialDateTime;
      _fileBytes = null;
      _selectedFileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {

    final hba1cValue =
        double.tryParse(_hba1cController.text.replaceAll(',', '.'));

    final bool hasChanges = !_forcePop && 
        (_hba1cController.text != _initialHba1c ||
         _selectedDateTime != _initialDateTime ||
         _fileBytes != null);

    // Fetch thresholds
    final healthData = ref.watch(monitorDataProvider).asData?.value;
    HealthThreshold? hba1cThreshold;
    try {
      hba1cThreshold = healthData?.healthThresholds.firstWhere(
        (t) => t.dataType == MonitorDataType.HBA1C
      );
    } catch (_) {}

    final hba1cColor = _getHba1cColor(hba1cValue, hba1cThreshold);

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
                onPressed: () async {
                  if (hasChanges) {
                    final shouldDiscard = await _showDiscardDialog();
                    if (!shouldDiscard) return;
                    _resetForm();
                  }
                  if (widget.onSwitchToHistory != null) {
                    widget.onSwitchToHistory!();
                  } else {
                    AppRoutes.pushReplacement(context, AppRoutes.hba1cDetail);
                  }
                },
                tooltip: 'View History',
              ),
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              SingleChildScrollView(
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

                            // AI Auto-Fill Section
                            _buildAiToggleSection(),
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
          if (_isAnalyzing)
              Positioned.fill(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
                  child: Center(
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: const Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Analyzing lab report...', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiToggleSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome, color: AppTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Auto-Fill', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  _fileBytes != null ? 'Report attached' : 'Scan lab report',
                  style: TextStyle(
                    fontSize: 12,
                    color: _fileBytes != null ? AppTheme.primaryGreen : AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (_fileBytes != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => setState(() {
                _fileBytes = null;
                _selectedFileName = null;
              }),
            )
          else
            TextButton(
              onPressed: _showImageSourcePicker,
              child: const Text('Scan'),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(HealthThreshold? threshold) {
    final thresholdsAsync = ref.watch(patientThresholdsProvider);

    String targetText = "Target: Loading...";
    if (thresholdsAsync.hasValue && thresholdsAsync.value != null) {
      try {
        final hba1cTarget =
            thresholdsAsync.value!.firstWhere((t) => t.dataType == 'HBA1C');
        targetText =
            "${hba1cTarget.minValue.toStringAsFixed(1)} - ${hba1cTarget.maxValue.toStringAsFixed(1)} %";
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
                            'Target Range',
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('HbA1c',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryGreen.withValues(alpha: 0.8))),
                      Text(
                        targetText,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen),
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
        ? hba1cColor.withValues(alpha: 0.05) 
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
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor,
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
                  color: hba1cColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: hba1cColor.withValues(alpha: 0.2)),
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
