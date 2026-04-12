import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../core/providers/monitor_data_providers.dart';
import '../../core/repositories/monitor_data_repository.dart';

/// Log Meal Screen
/// Allows users to record meals, photos, and calories
class LogMealScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSwitchToHistory;
  final VoidCallback? onKeepEditing;
  const LogMealScreen({
    super.key,
    this.onSwitchToHistory,
    this.onKeepEditing,
  });

  @override
  ConsumerState<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends ConsumerState<LogMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mealNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  
  // State
  bool _forcePop = false;
  String _initialMealName = '';
  String _initialCalories = '';
  late DateTime _initialDateTime;
  late String _initialMealType;
  bool _isLoading = false;
  bool _isAnalyzing = false;
  bool _useAiAutofill = true;
  DateTime _selectedDateTime = DateTime.now();
  late String _selectedMealType;
  
  // Image State
  XFile? _selectedImage;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _selectedMealType = _getMealTypeFromTime(DateTime.now());
    _initialDateTime = _selectedDateTime;
    _initialMealType = _selectedMealType;
  }

  String _getMealTypeFromTime(DateTime time) {
    final hour = time.hour;
    if (hour >= 4 && hour < 11) return 'Breakfast';
    if (hour >= 11 && hour < 16) return 'Lunch';
    return 'Dinner';
  }
  
  final List<Map<String, dynamic>> _mealTypeOptions = [
    {'name': 'Breakfast', 'icon': Icons.wb_sunny_rounded},
    {'name': 'Lunch', 'icon': Icons.wb_cloudy_rounded},
    {'name': 'Dinner', 'icon': Icons.nights_stay_rounded},
  ];
  
  @override
  void dispose() {
    _mealNameController.dispose();
    _caloriesController.dispose();
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
          'When enabled, selecting a meal photo will automatically trigger our AI engine to estimate calories and generate a description.\n\n'
          'Note: Analysis only happens when the image is first selected.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
      ),
    );
  }

  Future<void> _showImageSourcePicker() async {
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
                    color: Colors.grey.withOpacity(0.3),
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

  Widget _buildPhotoOption(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
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
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
          ],
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

    if (!_useAiAutofill) {
      setState(() => _isAnalyzing = false);
      return;
    }

    if (_caloriesController.text.isNotEmpty && _mealNameController.text.isNotEmpty) {
      Helpers.showInfo(context, 'Fields already filled. AI analysis skipped.');
      setState(() => _isAnalyzing = false);
      return;
    }

    try {
      final analysis = await _analyzeMeal(bytes, image.name);
      
      if (mounted && analysis != null) {
        bool updated = false;
        if (analysis['calories'] != null && _caloriesController.text.isEmpty) {
          _caloriesController.text = analysis['calories'].toString();
          updated = true;
        }
        if (analysis['description'] != null && _mealNameController.text.isEmpty) {
          _mealNameController.text = analysis['description'];
          updated = true;
        }
        
        if (updated) Helpers.showSuccess(context, 'Meal details auto-filled!');
        else Helpers.showInfo(context, 'Could not identify meal. Please enter details manually.');
      } else if (mounted) {
         Helpers.showWarning(context, 'AI analysis unavailable. Please enter details manually.');
      }
    } catch (e) {
      debugPrint("Analysis error: $e");
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<Map<String, dynamic>?> _analyzeMeal(Uint8List imageBytes, String filename) async {
    try {
      final llmUrl = '${Environment.llmEngineServiceUrl}/nutrition/analyze';
      final session = Supabase.instance.client.auth.currentSession;
      final request = http.MultipartRequest('POST', Uri.parse(llmUrl));
      request.headers.addAll({'Authorization': 'Bearer ${session?.accessToken}'});
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: filename));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Analysis error: $e");
    }
    return null;
  }
  
  /// Handle save
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Prevent submitting completely empty meal logs
    if (_mealNameController.text.trim().isEmpty && 
        _caloriesController.text.trim().isEmpty && 
        _selectedImage == null) {
      Helpers.showError(context, 'Please provide a photo, description, or calories to log this meal.');
      return;
    }

    final now = DateTime.now();
    // Validate that the date is not in future
    if (_selectedDateTime.isAfter(now)) {
      Helpers.showError(context, 'Cannot log meals in the future.');
      return;
    }
    
    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);
    
    try {
      // 1. Upload Image (if any)
      String? finalImageUrl;
      if (_imageBytes != null && _selectedImage != null) {
        final apiService = ApiService();
        final uploadRes = await apiService.uploadFile('/patients/me/meal-photo', 'file', _imageBytes!, _selectedImage!.name);
        finalImageUrl = uploadRes['url'];
      }

      final calories = int.tryParse(_caloriesController.text.trim());
      
      // 2. Save Data
      await ref.read(monitorDataRepositoryProvider).addMeal(
        _selectedMealType.toUpperCase(),
        _selectedDateTime.toUtc(),
        _mealNameController.text.trim(),
        null, null, null, null, // No glucose data here
        calories,
        finalImageUrl,
      );
      
      ref.invalidate(monitorDataProvider);
      
      if (mounted) {
        Helpers.showSuccess(context, 'Meal logged successfully!');
        AppRoutes.pushAndRemoveUntil(context, AppRoutes.dashboard);
      }
    } catch (e) {
      if (mounted) Helpers.showError(context, 'Failed to log meal: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      // Allow time selection for meals
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
            time.minute
          );
          _selectedMealType = _getMealTypeFromTime(_selectedDateTime);
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
      _mealNameController.text = _initialMealName;
      _caloriesController.text = _initialCalories;
      _selectedDateTime = _initialDateTime;
      _selectedMealType = _initialMealType;
      _initialMealType = _selectedMealType; // Sync initial state for next return
      _selectedImage = null;
      _imageBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasChanges = !_forcePop && 
        (_mealNameController.text != _initialMealName || 
         _caloriesController.text != _initialCalories || 
         _imageBytes != null ||
         _selectedDateTime != _initialDateTime ||
         _selectedMealType != _initialMealType);

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
          title: const Text('Log Diet'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: AppTheme.getBorderColor(context), height: 1.0),
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
                    AppRoutes.pushReplacement(context, AppRoutes.mealDetail);
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
                        // Info
                        _buildInfoCard(),
                        const SizedBox(height: 20),
                        
                        // Date & Time (Moved up as requested)
                        _buildDateTimeSection(),
                        const SizedBox(height: 20),

                        // Meal Type
                        _buildMealTypeSection(),
                        const SizedBox(height: 20),
                        
                        // Combined Meal Details (Photo + Inputs)
                        _buildMealDetailsSection(),
                        const SizedBox(height: 32),
                        
                        // Save
                        PrimaryButton(
                          text: 'Save Meal',
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
  
  Widget _buildInfoCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleIconColor = isDark ? Colors.blue.shade200 : AppTheme.primaryBlue; // App blue
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: titleIconColor, size: 24), // Info icon
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Log your meals to track calories and identify patterns.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.infoColor),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: titleIconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.calendar_today, color: titleIconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text('Date and Time', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          // Combined container
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : AppTheme.borderColor),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDateTime,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDateTime = DateTime(picked.year, picked.month, picked.day, _selectedDateTime.hour, _selectedDateTime.minute);
                      });
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: AppTheme.textSecondaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Text('Date:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 8),
                              Text(Formatters.date(_selectedDateTime), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondaryColor),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: AppTheme.borderColor.withOpacity(0.5)),
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDateTime = DateTime(_selectedDateTime.year, _selectedDateTime.month, _selectedDateTime.day, picked.hour, picked.minute);
                        _selectedMealType = _getMealTypeFromTime(_selectedDateTime);
                      });
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_outlined, color: AppTheme.textSecondaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Text('Time:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 8),
                              Text(Formatters.time(_selectedDateTime), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondaryColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTypeSection() {
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: titleIconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.restaurant, size: 24, color: titleIconColor),
              ),
              const SizedBox(width: 12),
              Text('Context', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          // Segmented Control
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: _mealTypeOptions.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelectedNorm = _selectedMealType.toUpperCase() == option['name'].toUpperCase();
                
                final isFirst = index == 0;
                final isLast = index == _mealTypeOptions.length - 1;
                BorderRadius radius = BorderRadius.zero;
                if (isFirst) radius = const BorderRadius.horizontal(left: Radius.circular(12));
                else if (isLast) radius = const BorderRadius.horizontal(right: Radius.circular(12));

                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedMealType = option['name']),
                    borderRadius: radius,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelectedNorm ? AppTheme.primaryBlue : Colors.transparent,
                        borderRadius: radius,
                        border: Border.all(color: isSelectedNorm ? AppTheme.primaryBlue : AppTheme.borderColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(option['icon'], size: 20, color: isSelectedNorm ? Colors.white : AppTheme.textSecondaryColor),
                          const SizedBox(height: 6),
                          Text(
                            option['name'],
                            style: TextStyle(
                              color: isSelectedNorm ? Colors.white : AppTheme.textPrimaryColor,
                              fontWeight: isSelectedNorm ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
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
    );
  }

  Widget _buildMealDetailsSection() {
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
              Text(
                'Meal Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
          const SizedBox(height: 24),
          Text(
            'Note: Provide at least a photo, description or calories to save this log.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
          const SizedBox(height: 12),

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
                controller: _mealNameController,
                textInputAction: TextInputAction.newline,
                minLines: 3,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'e.g. grilled chicken, 60g carbs, no veggies...',
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
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'e.g. 500',
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : AppTheme.backgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.local_fire_department_outlined, color: AppTheme.textSecondaryColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
