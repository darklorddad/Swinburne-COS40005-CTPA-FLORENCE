import 'dart:convert';
import 'dart:typed_data';

import 'package:florence/config/routes.dart';
import 'package:florence/config/theme.dart';
import 'package:florence/core/config/environment.dart';
import 'package:florence/core/services/api_service.dart';
import 'package:florence/core/utils/formatters.dart';
import 'package:florence/core/utils/helpers.dart';
import 'package:florence/core/utils/validators.dart';
import 'package:florence/features/patient/core/models/health_data_models.dart';
import 'package:florence/features/patient/core/providers/monitor_data_providers.dart';
import 'package:florence/core/services/notifications/notification_service.dart';
import 'package:florence/features/patient/core/providers/settings_providers.dart';
import 'package:florence/features/patient/core/providers/threshold_providers.dart';
import 'package:florence/features/patient/core/repositories/monitor_data_repository.dart';
import 'package:florence/features/patient/recommendations/services/recommendation_engine.dart';
import 'package:florence/features/patient/dashboard/providers/insight_provider.dart';
import 'package:florence/shared/widgets/button_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
/// Log Glucose Screen
/// Allows users to record blood glucose readings
class LogGlucoseScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSwitchToHistory;
  final VoidCallback? onKeepEditing;
  const LogGlucoseScreen({
    super.key,
    this.onSwitchToHistory,
    this.onKeepEditing,
  });

  @override
  ConsumerState<LogGlucoseScreen> createState() => _LogGlucoseScreenState();
}

class _LogGlucoseScreenState extends ConsumerState<LogGlucoseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _glucoseController = TextEditingController();
  final _notesController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _glucoseFocusNode = FocusNode();

  // State
  bool _forcePop = false;
  String _initialGlucose = '';
  String _initialNotes = '';
  String _initialCalories = '';
  late DateTime _initialDateTime;
  late String _initialTiming;
  late String _initialMealType;
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  // _uploadedImageUrl is now set ONLY after hitting Save
  bool _isAnalyzing = false;
  bool _isLoading = false;
  bool _useAiAutofill = true; // Default to enabled
  DateTime _selectedDateTime = DateTime.now();
  String _selectedTiming = 'No Meal';
  String _selectedMealType = 'BREAKFAST';

  final List<String> _timingOptions = [
    'No Meal',
    'Before Meal',
    'After Meal',
  ];

  final List<Map<String, dynamic>> _mealTypeOptions = [
    {'value': 'BREAKFAST', 'label': 'Breakfast', 'icon': Icons.wb_sunny},
    {'value': 'LUNCH', 'label': 'Lunch', 'icon': Icons.wb_cloudy},
    {'value': 'DINNER', 'label': 'Dinner', 'icon': Icons.nights_stay},
  ];

  String _getMealTypeFromTime(DateTime time) {
    final hour = time.hour;
    if (hour >= 4 && hour < 11) return 'BREAKFAST';
    if (hour >= 11 && hour < 16) return 'LUNCH';
    return 'DINNER';
  }

  @override
  void initState() {
    super.initState();
    _selectedMealType = _getMealTypeFromTime(_selectedDateTime);
    _initialDateTime = _selectedDateTime;
    _initialTiming = _selectedTiming;
    _initialMealType = _selectedMealType;
  }

  @override
  void dispose() {
    _glucoseController.dispose();
    _notesController.dispose();
    _caloriesController.dispose();
    _glucoseFocusNode.dispose();
    super.dispose();
  }

  void _showAiInfoDialog() {
    // Unfocus text fields to prevent keyboard popping up when dialog closes
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
          'When enabled, selecting a meal photo will automatically trigger our AI engine to estimate calories and generate a description.\n\n'
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
    // Unfocus text fields to prevent keyboard popping up when sheet closes
    FocusScope.of(context).requestFocus(FocusNode());

    final picker = ImagePicker();
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
                  'Add Photo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                _buildPhotoOption(
                  context,
                  title: 'Take Photo',
                  icon: Icons.camera_alt_rounded,
                  color: AppTheme.primaryBlue,
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await picker.pickImage(source: ImageSource.camera, maxWidth: 800);
                    if (image != null) _processImage(image);
                  },
                ),
                const SizedBox(height: 12),
                _buildPhotoOption(
                  context,
                  title: 'Choose from Gallery',
                  icon: Icons.photo_library_rounded,
                  color: AppTheme.accentPurple,
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
                    if (image != null) _processImage(image);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processImage(XFile image) async {
    final bytes = await image.readAsBytes();
    
    setState(() {
      _selectedImage = image;
      _imageBytes = bytes;
      _isAnalyzing = true;
    });

    // If Auto is OFF, we stop here. We upload later on Save.
    if (!_useAiAutofill) {
      setState(() => _isAnalyzing = false);
      return;
    }

    // Optimization: Skip AI if fields are full
    if (_caloriesController.text.isNotEmpty && _notesController.text.isNotEmpty) {
      Helpers.showInfo(context, 'Fields already filled. AI analysis skipped.');
      setState(() => _isAnalyzing = false);
      return;
    }

    try {
      // Send BYTES directly to LLM Service (No database upload yet)
      final analysis = await _analyzeMeal(bytes, image.name);
      
      if (mounted && analysis != null) {
        bool updated = false;

        if (analysis['calories'] != null && _caloriesController.text.isEmpty) {
          _caloriesController.text = analysis['calories'].toString();
          updated = true;
        }
        
        if (analysis['description'] != null && _notesController.text.isEmpty) {
          final desc = analysis['description'];
          _notesController.text = desc;
          updated = true;
        }
        
        if (updated) {
          Helpers.showSuccess(context, 'Meal details auto-filled!');
        } else {
          Helpers.showInfo(context, 'Could not identify meal. Please enter details manually.');
        }
      } else if (mounted) {
         Helpers.showWarning(context, 'AI analysis unavailable. Please enter details manually.');
      }
    } catch (e) {
      if (mounted) {
        Helpers.showWarning(context, 'AI analysis failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Widget _buildPhotoOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.getBorderColor(context)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
          ],
        ),
      ),
    );
  }

  /// Returns map with 'calories' and 'description'
  Future<Map<String, dynamic>?> _analyzeMeal(Uint8List imageBytes, String filename) async {
    try {
      final llmUrl = '${Environment.llmEngineServiceUrl}/nutrition/analyze';
      final session = Supabase.instance.client.auth.currentSession;
      
      final request = http.MultipartRequest('POST', Uri.parse(llmUrl));
      
      // Add Headers
      request.headers.addAll({
        'Authorization': 'Bearer ${session?.accessToken}',
      });

      // Add File
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("Analysis failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("Analysis error: $e");
    }
    return null;
  }

  /// Handle save
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedDateTime.isAfter(DateTime.now())) {
      Helpers.showError(context, 'Cannot log readings in the future.');
      return;
    }
    
    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);
    
    try {
      final glucoseValue = double.parse(_glucoseController.text.replaceAll(',', '.'));
      final repo = ref.read(monitorDataRepositoryProvider);

      // 1. Upload Image (If selected but not yet uploaded)
      String? finalImageUrl;
      if (_imageBytes != null && _selectedImage != null) {
        final apiService = ApiService();
        // Upload now!
        final uploadRes = await apiService.uploadFile(
          '/patients/me/meal-photo', 
          'file', 
          _imageBytes!, 
          _selectedImage!.name
        );
        finalImageUrl = uploadRes['url'];
      }

      if (_selectedTiming == 'No Meal') {
        await repo.addGlucoseReading(GlucoseReading(
          id: '',
          timestamp: _selectedDateTime.toUtc(),
          value: glucoseValue,
          context: _selectedTiming,
        ));
      } 
      else {
        final isBefore = _selectedTiming == 'Before Meal';
        final finalNotes = _notesController.text.trim();
        final finalCalories = int.tryParse(_caloriesController.text);
        
        await repo.addMeal(
          _selectedMealType,
          _selectedDateTime.toUtc(),
          (!isBefore && finalNotes.isNotEmpty) ? finalNotes : null,
          isBefore ? glucoseValue : null,
          isBefore ? _selectedDateTime.toUtc() : null,
          !isBefore ? glucoseValue : null,
          !isBefore ? _selectedDateTime.toUtc() : null,
          finalCalories,
          finalImageUrl, // Use the newly uploaded URL
        );
      }
      
      // AWAIT the fresh data fetch so the AI doesn't read a blank database (Race Condition Fix)
      await ref.refresh(monitorDataProvider.future);

      // LAM: fire notification if reading is out of range
      ref.read(notificationProvider.notifier).checkAfterGlucoseLog(glucoseValue);

      // Silently trigger AI to re-evaluate daily recommendations based on this new data
      ref.read(recommendationProvider.notifier).generateRecommendations(
        timeframe: 'daily',
      );

      if (mounted) {
        if (widget.onSwitchToHistory != null) {
          Helpers.showSuccess(context, 'Glucose reading saved successfully!');
          widget.onSwitchToHistory!();
        } else {
          AppRoutes.pushAndRemoveUntil(
            context, 
            AppRoutes.dashboard,
            arguments: {'message': 'Glucose reading saved successfully!'},
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('409')) {
          Helpers.showError(context, 'You have already logged $_selectedMealType for this date.');
        } else {
          Helpers.showError(context, 'Failed to save glucose reading: ${e.toString()}');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
      _glucoseController.text = _initialGlucose;
      _notesController.text = _initialNotes;
      _caloriesController.text = _initialCalories;
      _selectedDateTime = _initialDateTime;
      _selectedTiming = _initialTiming;
      _selectedMealType = _initialMealType;
      _selectedImage = null;
      _imageBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final glucoseValue = double.tryParse(_glucoseController.text.replaceAll(',', '.'));
    final bool hasChanges = !_forcePop && 
        (_glucoseController.text != _initialGlucose || 
         _notesController.text != _initialNotes || 
         _caloriesController.text != _initialCalories || 
         _imageBytes != null ||
         _selectedDateTime != _initialDateTime ||
         _selectedTiming != _initialTiming ||
         _selectedMealType != _initialMealType);

    final healthData = ref.watch(monitorDataProvider).asData?.value;
    HealthThreshold? glucoseThreshold;
    try {
      glucoseThreshold = healthData?.healthThresholds.firstWhere(
        (t) => t.dataType == MonitorDataType.GLUCOSE
      );
    } catch (_) {}

    final settings = ref.watch(patientSettingsProvider);
    final currentUnit = settings.glucoseUnit;
    final glucoseColor = _getGlucoseColor(glucoseValue, glucoseThreshold, currentUnit);

    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (!hasChanges) return;

        final shouldDiscard = await _showDiscardDialog();

        if (shouldDiscard && context.mounted) {
          setState(() => _forcePop = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
        } else {
          if (widget.onKeepEditing != null) {
            widget.onKeepEditing!();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Log Glucose'),
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
                    AppRoutes.pushReplacement(context, AppRoutes.trendsDetail);
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
                        _buildInfoCard(glucoseThreshold),
                        const SizedBox(height: 20),

                        // Glucose value input (large and prominent)
                        _buildGlucoseInput(glucoseColor, glucoseThreshold),
                        const SizedBox(height: 20),

                        // Date and time
                        _buildDateTimeSection(),
                        const SizedBox(height: 20),

                        // Context selection
                        _buildContextSection(),
                        
                        // Notes (optional) - Padding/Spacing handled internally for animation
                        _buildNotesSection(),
                        const SizedBox(height: 32),

                        // Save button
                        PrimaryButton(
                          text: 'Save Reading',
                          onPressed: _isLoading ? null : _handleSave,
                          isLoading: _isLoading,
                          width: double.infinity,
                          padding: Helpers.isDesktop(context)
                              ? const EdgeInsets.symmetric(horizontal: 24, vertical: 20)
                              : null,
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

  /// Build info card with target range
  Widget _buildInfoCard(HealthThreshold? threshold) {
    final settings = ref.watch(patientSettingsProvider);
    final currentUnit = settings.glucoseUnit;

    final thresholdsAsync = ref.watch(patientThresholdsProvider);
    String targetText = "Loading target...";
    if (thresholdsAsync.hasValue && thresholdsAsync.value != null) {
      try {
        final glucoseTarget = thresholdsAsync.value!
            .firstWhere((t) => t.dataType == 'GLUCOSE');
        targetText =
            "${glucoseTarget.minValue} - ${glucoseTarget.maxValue} $currentUnit";
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
                      'Record your blood glucose reading to track your health trends.',
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
          // Target Range Box (Matching Analytics Overview Style)
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
                      Text(
                        'Glucose',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryGreen.withValues(alpha: 0.8)),
                      ),
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

  /// Build glucose input
  Widget _buildGlucoseInput(Color? glucoseColor, HealthThreshold? threshold) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(patientSettingsProvider);
    final currentUnit = settings.glucoseUnit;
    final isMmol = currentUnit == 'mmol/L';

    // Widen absolute biological limits to prevent blocking valid readings 
    // that lie inside or slightly outside custom target ranges.
    double minValid = isMmol ? 0.1 : 10.0;
    double maxValid = isMmol ? 60.0 : 1000.0;

    // Dynamically expand if the user's custom threshold somehow exceeds even these extremes
    if (threshold != null) {
      if (threshold.minValue < minValid) minValid = threshold.minValue;
      if (threshold.maxValue > maxValid) maxValid = threshold.maxValue;
    }

    // Tint the whole card background based on status
    final containerColor = glucoseColor != null 
        ? glucoseColor.withValues(alpha: 0.05) 
        : (isDark ? AppTheme.midnightSurface : Colors.white);
        
    final borderColor = glucoseColor ?? AppTheme.getBorderColor(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: 1.0, // Fixed width to prevent displacement
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
            'Blood Glucose Level',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
          ),
          const SizedBox(height: 16),

          // Large glucose input
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 150,
                child: TextFormField(
                  controller: _glucoseController,
                  focusNode: _glucoseFocusNode,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.\,]?\d*')),
                  ],
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    final num = double.tryParse(val.replaceAll(',', '.'));
                    if (num == null) return 'Invalid';
                    if (num < minValid || num > maxValid) return 'Range:\n$minValid - $maxValid';
                    return null;
                  },
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: glucoseColor ?? AppTheme.textPrimaryColor,
                      ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor,
                    hintText: '---',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currentUnit,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Status indicator (Always visible)
          Center(
            child: Builder(
              builder: (context) {
                final statusText = glucoseColor != null
                    ? _getGlucoseStatus(
                            double.tryParse(_glucoseController.text.replaceAll(',', '.')), threshold, currentUnit)
                        .toUpperCase()
                    : 'ENTER READING';

                IconData statusIcon;
                if (glucoseColor == null) {
                  statusIcon = Icons.edit;
                } else if (statusText == 'LOW') {
                  statusIcon = Icons.arrow_downward;
                } else if (statusText == 'HIGH') {
                  statusIcon = Icons.arrow_upward;
                } else {
                  statusIcon = Icons.check;
                }

                final displayColor =
                    glucoseColor ?? AppTheme.textSecondaryColor;

                return InkWell(
                  onTap: () => _glucoseFocusNode.requestFocus(),
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 140, // Fixed width
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: glucoseColor == null
                              ? (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : AppTheme.backgroundColor)
                              : displayColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: displayColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              size: 14,
                              color: displayColor,
                            ),
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
                      if (_glucoseController.text.isNotEmpty)
                        Builder(
                          builder: (context) {
                            final val = double.tryParse(_glucoseController.text.replaceAll(',', '.'));
                            if (val != null && (val < minValid || val > maxValid)) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Enter $minValid - $maxValid $currentUnit',
                                  style: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build date time section
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
          // Header matching Dashboard Cards
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
          
          // Combined Date & Time Container
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppTheme.backgroundColor,
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
                    // Steal focus to a temporary node to prevent automatic restoration to the text field
                    FocusScope.of(context).requestFocus(FocusNode());

                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDateTime,
                      firstDate: DateTime(2000),
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
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            // Override tertiary colors so AM/PM selector is Blue, not Red
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                              tertiary: AppTheme.primaryBlue,
                              onTertiary: Colors.white,
                              tertiaryContainer: AppTheme.primaryBlue.withValues(alpha: 0.2),
                              onTertiaryContainer: AppTheme.primaryBlue,
                            ),
                            // Fix input field background to make cursor visible
                            timePickerTheme: TimePickerThemeData(
                              hourMinuteColor: WidgetStateColor.resolveWith((states) {
                                return states.contains(WidgetState.selected)
                                    ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                                    : Colors.grey.shade100;
                              }),
                              hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
                                return states.contains(WidgetState.selected)
                                    ? AppTheme.primaryBlue
                                    : AppTheme.textPrimaryColor;
                              }),
                            ),
                            textSelectionTheme: TextSelectionThemeData(
                              cursorColor: AppTheme.primaryBlue,
                              selectionColor: AppTheme.primaryBlue.withValues(alpha: 0.3),
                              selectionHandleColor: AppTheme.primaryBlue,
                            ),
                          ),
                          child: child!,
                        );
                      },
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
                        _selectedMealType = _getMealTypeFromTime(_selectedDateTime);
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

  /// Build context section
  Widget _buildContextSection() {
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
                  Icons.restaurant,
                  size: 24,
                  color: titleIconColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Context',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. Timing Selection (Merged Segmented Control)
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: _timingOptions.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = _selectedTiming == option;
                final isFirst = index == 0;
                final isLast = index == _timingOptions.length - 1;
                
                final borderColor = isSelected ? AppTheme.primaryBlue : AppTheme.borderColor;
                final fillColor = isSelected ? AppTheme.primaryBlue : Colors.transparent;

                // Calculate Radius
                BorderRadius radius = BorderRadius.zero;
                if (isFirst) {
                  radius = const BorderRadius.horizontal(left: Radius.circular(12));
                } else if (isLast) {
                  radius = const BorderRadius.horizontal(right: Radius.circular(12));
                }

                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTiming = option),
                    borderRadius: radius,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                      decoration: BoxDecoration(
                        color: fillColor,
                        borderRadius: radius,
                        // Use Border.all to prevent "Non-uniform border" crash
                        border: Border.all(color: borderColor),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        option,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 2. Meal Type Selection (Animated)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _selectedTiming == 'No Meal'
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Subsection Header
                      Text(
                        'Select Meal',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Merged Segmented Control Style
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: _mealTypeOptions.asMap().entries.map((entry) {
                            final index = entry.key;
                            final option = entry.value;
                            final isSelected = _selectedMealType == option['value'];
                            final isFirst = index == 0;
                            final isLast = index == _mealTypeOptions.length - 1;
                            
                            final borderColor = isSelected ? AppTheme.primaryBlue : AppTheme.borderColor;
                            final fillColor = isSelected ? AppTheme.primaryBlue : Colors.transparent;

                            // Calculate Radius
                            BorderRadius radius = BorderRadius.zero;
                            if (isFirst) {
                              radius = const BorderRadius.horizontal(left: Radius.circular(12));
                            } else if (isLast) {
                              radius = const BorderRadius.horizontal(right: Radius.circular(12));
                            }

                            return Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedMealType = option['value']),
                                borderRadius: radius,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: fillColor,
                                    borderRadius: radius,
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        option['icon'],
                                        size: 20,
                                        color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        option['label'],
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Build notes section
  Widget _buildNotesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);
    final titleIconColor = isDark ? Colors.blue.shade200 : AppTheme.primaryBlue;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: _selectedTiming != 'After Meal'
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Container(
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
                    // Header
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
                            Icons.menu_book,
                            size: 24,
                            color: titleIconColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meal Details',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Optional',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        
                        // AI Toggle Switch Group
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _useAiAutofill = !_useAiAutofill),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: _useAiAutofill ? AppTheme.primaryBlue : AppTheme.borderColor,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 16,
                                      color: _useAiAutofill ? AppTheme.primaryBlue : AppTheme.textSecondaryColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Auto',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _useAiAutofill ? AppTheme.primaryBlue : AppTheme.textSecondaryColor,
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
                                          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          onChanged: (val) => setState(() => _useAiAutofill = val),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.info_outline, size: 22, color: AppTheme.textSecondaryColor),
                              onPressed: _showAiInfoDialog,
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20), // Standard spacing 20px
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Picker Box
                        InkWell(
                          onTap: _isAnalyzing ? null : _showImageSourcePicker,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: _imageBytes != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedImage = null;
                                              _imageBytes = null;
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
                                                const CircularProgressIndicator(color: Colors.white),
                                                const SizedBox(height: 12),
                                                Text(
                                                  _useAiAutofill ? 'Analyzing...' : 'Uploading...',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    shadows: [
                                                      Shadow(blurRadius: 4, color: Colors.black54),
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
                                        'Add Meal Photo',
                                        style: TextStyle(
                                          color: AppTheme.textSecondaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (_useAiAutofill) ...[
                                        const SizedBox(height: 4),
                                        Text(
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

                        // Meal Description Section
                        Row(
                          children: [
                            Text(
                              'Meal Description',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                            ),
                            if (_useAiAutofill) ...[
                              const SizedBox(width: 8),
                              Text(
                                'Leave blank for auto-estimate',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesController,
                          textInputAction: TextInputAction.newline,
                          minLines: 3,
                          maxLines: 3,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'e.g. grilled chicken, 60g carbs, no veggies...',
                            hintStyle: const TextStyle(color: AppTheme.textSecondaryColor),
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor,
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
                            prefixIcon: const Icon(Icons.edit_note, color: AppTheme.textSecondaryColor),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Calories Section
                        Row(
                          children: [
                            Text(
                              'Calories (kcal)',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                            ),
                            if (_useAiAutofill) ...[
                              const SizedBox(width: 8),
                              Text(
                                'Leave blank for auto-estimate',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _caloriesController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'e.g. 500',
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.backgroundColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            prefixIcon: const Icon(Icons.local_fire_department_outlined, color: AppTheme.textSecondaryColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Get glucose color based on value and user thresholds
  Color? _getGlucoseColor(double? value, HealthThreshold? threshold, String unit) {
    if (value == null) return null;
    
    final isMmol = unit == 'mmol/L';
    final min = threshold?.minValue ?? (isMmol ? 3.9 : 70.0);
    final max = threshold?.maxValue ?? (isMmol ? 10.0 : 180.0);

    if (value < min) {
      return AppTheme.warningColor; // Low (Amber)
    } else if (value > max) {
      return AppTheme.errorColor; // High (Red)
    } else {
      return AppTheme.primaryGreen; // Normal (Green)
    }
  }

  /// Get glucose status text
  String _getGlucoseStatus(double? value, HealthThreshold? threshold, String unit) {
    if (value == null) return '';
    
    final isMmol = unit == 'mmol/L';
    final min = threshold?.minValue ?? (isMmol ? 3.9 : 70.0);
    final max = threshold?.maxValue ?? (isMmol ? 10.0 : 180.0);

    if (value < min) {
      return 'Low';
    } else if (value > max) {
      return 'High';
    } else {
      return 'Normal';
    }
  }
}
