import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/services/api_service.dart';
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

/// Log Glucose Screen
/// Allows users to record blood glucose readings
class LogGlucoseScreen extends ConsumerStatefulWidget {
  const LogGlucoseScreen({super.key});

  @override
  ConsumerState<LogGlucoseScreen> createState() => _LogGlucoseScreenState();
}

class _LogGlucoseScreenState extends ConsumerState<LogGlucoseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _glucoseController = TextEditingController();
  final _notesController = TextEditingController();
  final _caloriesController = TextEditingController();

  // State
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  String? _uploadedImageUrl;
  String? _uploadedImagePath; // Track path for deletion
  bool _isSaved = false; // Track if form was saved
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
    {'value': 'BREAKFAST', 'label': 'Breakfast', 'icon': Icons.wb_sunny_outlined},
    {'value': 'LUNCH', 'label': 'Lunch', 'icon': Icons.wb_cloudy_outlined},
    {'value': 'DINNER', 'label': 'Dinner', 'icon': Icons.nights_stay_outlined},
  ];

  @override
  void dispose() {
    // Cleanup orphan image if exiting without saving
    if (!_isSaved && _uploadedImagePath != null) {
      _deleteImage(_uploadedImagePath!);
    }
    _glucoseController.dispose();
    _notesController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _deleteImage(String path) async {
    try {
      final api = ApiService();
      await api.delete('/patients/me/meal-photo?path=${Uri.encodeComponent(path)}');
    } catch (e) {
      debugPrint("Failed to cleanup image: $e");
    }
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
          'When enabled, uploading a meal photo will automatically trigger our AI engine.\n\n'
          'It will analyze the image to estimate calories and generate a description for your notes.\n\n'
          'Disable this if you prefer to enter details manually.',
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
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryColor;
    
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
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: AppTheme.primaryBlue, size: 20),
                  ),
                  title: Text('Take Photo', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await picker.pickImage(source: ImageSource.camera, maxWidth: 800);
                    if (image != null) _processImage(image);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPurple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library, color: AppTheme.accentPurple, size: 20),
                  ),
                  title: Text('Choose from Gallery', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
                    if (image != null) _processImage(image);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processImage(XFile image) async {
    final bytes = await image.readAsBytes();
    
    // Cleanup previous image if exists (Replacement)
    if (_uploadedImagePath != null) {
      _deleteImage(_uploadedImagePath!);
    }

    setState(() {
      _selectedImage = image;
      _imageBytes = bytes;
      _isAnalyzing = true; // Show loading state while uploading
    });

    try {
      // Upload to Supabase via Data Service
      final apiService = ApiService();
      final uploadRes = await apiService.uploadFile('/patients/me/meal-photo', 'file', bytes, image.name);
      
      if (mounted) {
        final url = uploadRes['url'];
        final path = uploadRes['path'];
        setState(() {
          _uploadedImageUrl = url;
          _uploadedImagePath = path;
        });

        // TRIGGER AI IF ENABLED
        if (_useAiAutofill) {
          // Optimisation: Skip AI analysis if both fields are already filled
          if (_caloriesController.text.isNotEmpty && _notesController.text.isNotEmpty) {
            Helpers.showInfo(context, 'Fields already filled. AI analysis skipped.');
          } else {
            final analysis = await _analyzeMeal(url);
            if (mounted && analysis != null) {
              bool updated = false;

              // Only autofill if the user hasn't typed anything
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
              }
            }
          }
        }
      }
    } catch (e) {
      if (mounted) Helpers.showError(context, 'Failed to upload image: $e');
      setState(() {
        _selectedImage = null;
        _imageBytes = null;
      }); // Reset on failure
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  /// Returns map with 'calories' and 'description'
  Future<Map<String, dynamic>?> _analyzeMeal(String imageUrl) async {
    try {
      final llmUrl = '${Environment.llmEngineServiceUrl}/nutrition/analyze';
      final session = Supabase.instance.client.auth.currentSession;
      
      final response = await http.post(
        Uri.parse(llmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session?.accessToken}',
        },
        body: jsonEncode({'image_url': imageUrl}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
    
    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);
    
    try {
      final glucoseValue = double.parse(_glucoseController.text);
      final repo = ref.read(monitorDataRepositoryProvider);

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
          _uploadedImageUrl,
        );
      }
      
      // Invalidate provider to refresh dashboard
      ref.invalidate(monitorDataProvider);

      _isSaved = true; // Prevent deletion on dispose

      if (mounted) {
        Helpers.showSuccess(context, 'Glucose reading saved successfully!');
        AppRoutes.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final glucoseValue = double.tryParse(_glucoseController.text);
    
    // Fetch thresholds
    final healthData = ref.watch(monitorDataProvider).asData?.value;
    HealthThreshold? glucoseThreshold;
    try {
      glucoseThreshold = healthData?.healthThresholds.firstWhere(
        (t) => t.dataType == MonitorDataType.GLUCOSE
      );
    } catch (_) {}

    final glucoseColor = _getGlucoseColor(glucoseValue, glucoseThreshold);

    return Scaffold(
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
            padding: const EdgeInsets.only(right: 4.5),
            child: IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                AppRoutes.push(context, AppRoutes.trendsDetail);
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
                      ),
                      // Extra padding for bottom safe area / gesture bar
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
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

  /// Build info card with target range
  Widget _buildInfoCard(HealthThreshold? threshold) {
    final min = threshold?.minValue ?? 70;
    final max = threshold?.maxValue ?? 180;
    
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
                  'Record your blood glucose reading to track your health trends.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.infoColor,
                      ),
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
                        'Glucose', 
                        style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen.withOpacity(0.8))
                      ),
                      Text(
                        '${min.toInt()} - ${max.toInt()} mg/dL',
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

  /// Build glucose input
  Widget _buildGlucoseInput(Color? glucoseColor, HealthThreshold? threshold) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Tint the whole card background based on status
    final containerColor = glucoseColor != null 
        ? glucoseColor.withOpacity(0.05) 
        : (isDark ? AppTheme.midnightSurface : Colors.white);
        
    final borderColor = glucoseColor ?? AppTheme.getBorderColor(context);
    final hasInput = glucoseColor != null;

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
            color: Colors.black.withOpacity(0.03),
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
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w600,
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
                  validator: Validators.glucose,
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
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : AppTheme.backgroundColor,
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
                'mg/dL',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
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
                  final statusText = glucoseColor != null
                      ? _getGlucoseStatus(
                              double.tryParse(_glucoseController.text), threshold)
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

                  return Container(
                    width: 140, // Fixed width
                    height: 32, // Fixed height
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: glucoseColor == null
                          ? (isDark
                              ? Colors.white.withOpacity(0.05)
                              : AppTheme.backgroundColor)
                          : displayColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: displayColor.withOpacity(0.3),
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
                  );
                },
              ),
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
            color: Colors.black.withOpacity(0.03),
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
          
          // Combined Date & Time Container
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : AppTheme.backgroundColor,
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
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            // Override tertiary colors so AM/PM selector is Blue, not Red
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                              tertiary: AppTheme.primaryBlue,
                              onTertiary: Colors.white,
                              tertiaryContainer: AppTheme.primaryBlue.withOpacity(0.2),
                              onTertiaryContainer: AppTheme.primaryBlue,
                            ),
                            // Fix input field background to make cursor visible
                            timePickerTheme: TimePickerThemeData(
                              hourMinuteColor: MaterialStateColor.resolveWith((states) {
                                return states.contains(MaterialState.selected)
                                    ? AppTheme.primaryBlue.withOpacity(0.1)
                                    : Colors.grey.shade100;
                              }),
                              hourMinuteTextColor: MaterialStateColor.resolveWith((states) {
                                return states.contains(MaterialState.selected)
                                    ? AppTheme.primaryBlue
                                    : AppTheme.textPrimaryColor;
                              }),
                            ),
                            textSelectionTheme: TextSelectionThemeData(
                              cursorColor: AppTheme.primaryBlue,
                              selectionColor: AppTheme.primaryBlue.withOpacity(0.3),
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
              color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.backgroundColor,
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Merged Segmented Control Style
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.backgroundColor,
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
                      color: Colors.black.withOpacity(0.03),
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
                            color: titleIconColor.withOpacity(0.1),
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
                                  color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.backgroundColor,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: _useAiAutofill ? AppTheme.primaryBlue : AppTheme.borderColor,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
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
                                          activeColor: Colors.white,
                                          activeTrackColor: AppTheme.primaryBlue,
                                          inactiveThumbColor: Colors.white,
                                          inactiveTrackColor: Colors.grey.shade300,
                                          trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
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
                              color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.backgroundColor,
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
                                            if (_uploadedImagePath != null) {
                                              _deleteImage(_uploadedImagePath!);
                                            }
                                            setState(() {
                                              _selectedImage = null;
                                              _imageBytes = null;
                                              _uploadedImageUrl = null;
                                              _uploadedImagePath = null;
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
                                            child: const Center(
                                              child: CircularProgressIndicator(color: Colors.white),
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
                                        _isAnalyzing 
                                            ? (_useAiAutofill ? 'Analyzing...' : 'Uploading...') 
                                            : 'Add Meal Photo',
                                        style: TextStyle(
                                          color: AppTheme.textSecondaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
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
                          decoration: InputDecoration(
                            hintText: 'e.g. 500',
                            filled: true,
                            fillColor: isDark ? Colors.white.withOpacity(0.05) : AppTheme.backgroundColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            prefixIcon: const Icon(Icons.local_fire_department_outlined, color: Colors.orange),
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
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'e.g. Grilled chicken, 60g carbs, no veggies...',
                            hintStyle: const TextStyle(color: AppTheme.textSecondaryColor),
                            filled: true,
                            fillColor: isDark ? Colors.white.withOpacity(0.05) : AppTheme.backgroundColor,
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
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Get glucose color based on value and user thresholds
  Color? _getGlucoseColor(double? value, HealthThreshold? threshold) {
    if (value == null) return null;
    
    final min = threshold?.minValue ?? 70;
    final max = threshold?.maxValue ?? 180;

    if (value < min) {
      return AppTheme.warningColor; // Low (Amber)
    } else if (value > max) {
      return AppTheme.errorColor; // High (Red)
    } else {
      return AppTheme.primaryGreen; // Normal (Green)
    }
  }

  /// Get glucose status text
  String _getGlucoseStatus(double? value, HealthThreshold? threshold) {
    if (value == null) return '';
    
    final min = threshold?.minValue ?? 70;
    final max = threshold?.maxValue ?? 180;

    if (value < min) {
      return 'Low';
    } else if (value > max) {
      return 'High';
    } else {
      return 'Normal';
    }
  }
}
