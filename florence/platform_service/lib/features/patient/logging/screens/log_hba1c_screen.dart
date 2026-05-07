import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:florence/config/routes.dart';
import 'package:florence/config/theme.dart';
import 'package:florence/core/utils/formatters.dart';
import 'package:image_picker/image_picker.dart';
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
  
  bool _isScanning = false;
  final ImagePicker _picker = ImagePicker();
  bool _useAiAutofill = true;
  Uint8List? _fileBytes;
  String? _selectedFileName;
  bool _isPdf = false;
  bool _isAnalyzing = false;
  bool _forcePop = false;
  String _initialHba1c = '';
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
          'When enabled, selecting a lab report will automatically trigger our AI engine to extract your HbA1c value.\n\n'
          'Note: Analysis only happens when the image is first selected.',
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Add Lab Report',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),

                // 1. Camera
                _buildPhotoOption(
                  context,
                  title: 'Take Photo',
                  icon: Icons.camera_alt_rounded,
                  color: AppTheme.primaryBlue,
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await _picker.pickImage(
                        source: ImageSource.camera, maxWidth: 800);
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      _processFile(bytes, image.name, false);
                    }
                  },
                ),
                const SizedBox(height: 12),

                // 2. Photo Gallery
                _buildPhotoOption(
                  context,
                  title: 'Choose Photo',
                  icon: Icons.photo_library_rounded,
                  color: AppTheme.accentPurple,
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await _picker.pickImage(
                        source: ImageSource.gallery, maxWidth: 800);
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      _processFile(bytes, image.name, false);
                    }
                  },
                ),
                const SizedBox(height: 12),

                // 3. Document / PDF Picker
                _buildPhotoOption(
                  context,
                  title: 'Upload Document (PDF)',
                  icon: Icons.picture_as_pdf_rounded,
                  color: Colors.redAccent,
                  onTap: () async {
                    Navigator.pop(context);
                    FilePickerResult? result = await FilePicker.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                      withData: true,
                    );
                    if (result != null && result.files.single.bytes != null) {
                      final file = result.files.single;
                      final isPdf = file.extension?.toLowerCase() == 'pdf';
                      _processFile(file.bytes!, file.name, isPdf);
                    }
                  },
                ),
              ],
            ),
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
            borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24)),
            const SizedBox(width: 16),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16))),
            Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
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

    if (!_useAiAutofill) {
      setState(() => _isAnalyzing = false);
      return;
    }

    try {
      // 1. Send the BYTES directly to LLM Engine for analysis (Stateless)
      // We use the baseUrlOverride to hit the LLM Engine instead of Data Service
      final result = await _apiService.uploadFile(
        '/biometrics/parse-lab-report',
        'file',
        bytes,
        filename,
        baseUrlOverride: Environment.llmEngineServiceUrl,
        additionalFields: {
          'report_type': 'hba1c',
          'target_unit': '%',
        },
      );

      if (mounted && result != null) {
        setState(() {
          if (result['hba1c'] != null && result['hba1c']['value'] != null) {
            _hba1cController.text = result['hba1c']['value'].toString();
          } else if (result['hba1c'] != null) {
            _hba1cController.text = result['hba1c'].toString();
          }
        });
        Helpers.showSuccess(
            context, 'Report parsed successfully! Please verify the values.');
      }
    } catch (e) {
      if (mounted) Helpers.showError(context, 'Failed to parse report: $e');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(monitorDataRepositoryProvider);
      int? documentId;

      // STEP 1: If a file was selected, upload it to Data Service to persist in Storage
      if (_fileBytes != null && _selectedFileName != null) {
        final uploadRes = await _apiService.uploadFile(
          '/patients/me/clinical-documents/upload',
          'file',
          _fileBytes!,
          _selectedFileName!,
          additionalFields: {'document_type': 'HBA1C_REPORT'},
        );

        documentId = uploadRes['id'];
      }

      // STEP 2: Save the actual biometrics, linking them to the document record
      final text = _hba1cController.text.trim().replaceAll(',', '.');
      if (text.isNotEmpty) {
        await repo.addMonitorData(
          'HBA1C',
          double.parse(text),
          _selectedDateTime.toUtc(),
          documentId: documentId,
        );
      } else {
        throw Exception("Please enter a value.");
      }

      ref.invalidate(monitorDataProvider);

      if (mounted) {
        Helpers.showSuccess(
            context, 'HbA1c data and lab report saved successfully!');
        AppRoutes.pushAndRemoveUntil(context, AppRoutes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to save data: ${e.toString()}');
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
    // Fetch thresholds
    final healthData = ref.watch(monitorDataProvider).asData?.value;
    HealthThreshold? hba1cThreshold;
    try {
      hba1cThreshold = healthData?.healthThresholds.firstWhere(
        (t) => t.dataType == MonitorDataType.HBA1C
      );
    } catch (_) {}

    final bool hasChanges = !_forcePop &&
        (_hba1cController.text != _initialHba1c ||
            _selectedDateTime != _initialDateTime ||
            _fileBytes != null);

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

                        // The new unified HbA1c Panel Card
                        _buildHba1cPanelSection(),
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

  Widget _buildHba1cPanelSection() {
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
          // Header with AI Toggle
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
                'HbA1c Panel',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),

              // AI Toggle Switch Group
              Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _useAiAutofill = !_useAiAutofill),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _useAiAutofill
                              ? AppTheme.primaryBlue
                              : AppTheme.borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: _useAiAutofill
                                ? AppTheme.primaryBlue
                                : AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Auto',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _useAiAutofill
                                  ? AppTheme.primaryBlue
                                  : AppTheme.textSecondaryColor,
                              fontSize: 14,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 28,
                            width: 44,
                            child: Transform.scale(
                              scale: 0.9,
                              child: Switch(
                                value: _useAiAutofill,
                                activeThumbColor: Colors.white,
                                activeTrackColor: AppTheme.primaryBlue,
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: Colors.grey.shade300,
                                trackOutlineColor:
                                    WidgetStateProperty.all(Colors.transparent),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (val) =>
                                    setState(() => _useAiAutofill = val),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.info_outline,
                        size: 22, color: AppTheme.textSecondaryColor),
                    onPressed: _showAiInfoDialog,
                    visualDensity: VisualDensity.compact,
                    constraints:
                        const BoxConstraints.tightFor(width: 40, height: 40),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Image Picker Box
          InkWell(
            onTap: _isAnalyzing ? null : _showImageSourcePicker,
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
              child: _fileBytes != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        if (!_isPdf)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(_fileBytes!, fit: BoxFit.cover),
                          )
                        else
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.picture_as_pdf,
                                  size: 48, color: Colors.redAccent),
                              const SizedBox(height: 12),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  _selectedFileName ?? 'Document.pdf',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _fileBytes = null;
                                _selectedFileName = null;
                                _isPdf = false;
                              });
                            },
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                        if (_isAnalyzing)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              color: Colors.black45,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                      color: Colors.white),
                                  const SizedBox(height: 12),
                                  Text(
                                    _useAiAutofill
                                        ? 'Analyzing...'
                                        : 'Processing...',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      shadows: [
                                        Shadow(
                                            blurRadius: 4,
                                            color: Colors.black54),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
                        if (_useAiAutofill) ...[
                          const SizedBox(height: 4),
                          const Text(
                            'Analysis runs on selection',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // The Input Field contained in a distinct box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // A subtle inner background colour to differentiate from the main card
              color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.borderColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Subtitle Group
                Row(
                  children: [
                    Text(
                      'Value (%)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                    ),
                    if (_useAiAutofill) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'Leave blank for auto-extract',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // The Input Field
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _buildGridLabField(
                            'HbA1c',
                            _hba1cController,
                            '%',
                            Icons.bloodtype_outlined,
                            '5.5')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(HealthThreshold? hba1cT) {
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
                      'HbA1c reflects your average blood sugar level over the past 2-3 months.',
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
                  _buildMiniTargetRow('HbA1c', hba1cT != null ? '${hba1cT.minValue.toStringAsFixed(1)} - ${hba1cT.maxValue.toStringAsFixed(1)} %' : 'Not Set', AppTheme.primaryGreen),
                ],
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

  Widget _buildGridLabField(String label, TextEditingController controller, String unit, IconData icon, String placeholder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double minValid = 3.0;
    final double maxValid = 20.0;

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
            if (val == null || val.isEmpty) return 'Required';
            final num = double.tryParse(val.replaceAll(',', '.'));
            if (num == null) return 'Invalid';
            if (num < minValid || num > maxValid) return 'Range:\n$minValid - $maxValid';
            return null;
          },
          decoration: InputDecoration(
            hintText: 'e.g. $placeholder',
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

  Widget _buildMiniTargetRow(String label, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
