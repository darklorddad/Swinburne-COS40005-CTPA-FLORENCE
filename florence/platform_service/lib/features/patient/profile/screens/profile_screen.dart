import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/layout/responsive_layout_system.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/api_service.dart'; // Added
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../main.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../shared/widgets/input_widgets.dart';
import '../../chat/services/chatbot_service.dart';
import '../../dashboard/widgets/medication_section.dart';
import '../providers/user_profile_provider.dart';

/// Profile & Settings Screen
/// Unified screen for user profile, health info, and app settings
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Mock user data (fallback)
  String _userName = 'John Doe';
  String _userEmail = 'john.doe@example.com';
  String _dateOfBirth = 'January 15, 1985';
  String _gender = 'Male';
  String _phoneNumber = '+60 12-345 6789';
  String? _profileImageUrl;
  String _emergencyContactName = 'Not set';
  String _emergencyContactPhone = 'Not set';
  String _emergencyContactRelationship = 'Not set';
  double? _height;
  double? _weight;
  double _targetMin = 70.0;
  double _targetMax = 180.0;

  final List<Map<String, String>> _countryCodes = [
    {'code': '+1', 'name': 'USA/CAN'},
    {'code': '+44', 'name': 'UK'},
    {'code': '+60', 'name': 'MY'},
    {'code': '+61', 'name': 'AUS'},
    {'code': '+65', 'name': 'SGP'},
    {'code': '+81', 'name': 'JPN'},
    {'code': '+86', 'name': 'CHN'},
    {'code': '+91', 'name': 'IND'},
    {'code': '+62', 'name': 'IDN'},
    {'code': '+63', 'name': 'PHL'},
    {'code': '+66', 'name': 'THA'},
    {'code': '+84', 'name': 'VNM'},
    {'code': '+49', 'name': 'DEU'},
    {'code': '+33', 'name': 'FRA'}
  ];

  final List<String> _relationships = ['Parent', 'Spouse', 'Child', 'Sibling', 'Partner', 'Guardian', 'Relative', 'Friend', 'Other'];
  
  List<String> _parsePhone(String? fullNumber) {
    if (fullNumber == null || fullNumber.isEmpty) return ['+60', ''];
    
    // Sort codes by length desc so +1 doesn't match +123
    final codes = _countryCodes.map((e) => e['code']!).toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final code in codes) {
      if (fullNumber.startsWith(code)) {
        String number = fullNumber.substring(code.length).trim();
        // Remove any formatting spaces/dashes for the input field
        number = number.replaceAll(RegExp(r'\D'), ''); 
        return [code, number];
      }
    }
    // Default fallback
    return ['+60', fullNumber.replaceAll(RegExp(r'\D'), '')];
  }

  String _formatDisplayPhone(String phone) {
    if (phone.isEmpty || phone == 'Not set') return phone;

    // Sort by length desc so +60 matches before +6
    final sortedCodes = _countryCodes
      ..sort((a, b) => b['code']!.length.compareTo(a['code']!.length));

    String? code;
    for (final c in sortedCodes) {
      if (phone.startsWith(c['code']!)) {
        code = c['code'];
        break;
      }
    }

    if (code == null) return phone;

    final number = phone.substring(code.length);

    if (code == '+60') {
      // Malaysia: +60 13-830 0886 (9 digits after +60) or +60 11-xxxx xxxx (10 digits)
      if (number.length == 9) {
        // e.g. 138300886 -> 13-830 0886
        return '$code ${number.substring(0, 2)}-${number.substring(2, 5)} ${number.substring(5)}';
      } else if (number.length >= 10) {
        // e.g. 11xxxxxxxx -> 11-xxxx xxxx
        return '$code ${number.substring(0, 2)}-${number.substring(2, 6)} ${number.substring(6)}';
      }
    } else if (code == '+1') {
      // US/Can
      if (number.length == 10) {
        return '$code (${number.substring(0, 3)}) ${number.substring(3, 6)}-${number.substring(6)}';
      }
    } 
    
    // UK (+44) -> +44 7911 123456
    else if (code == '+44') {
      if (number.length >= 10) return '$code ${number.substring(0, 4)} ${number.substring(4)}';
    }
    
    // Australia (+61) -> +61 412 345 678 (Standard mobile is 9 digits after 0)
    else if (code == '+61') {
      if (number.length == 9) return '$code ${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}';
    }
    
    // Singapore (+65) -> +65 9123 4567 (8 digits)
    else if (code == '+65') {
      if (number.length == 8) return '$code ${number.substring(0, 4)} ${number.substring(4)}';
    }
    
    // India (+91) -> +91 98765 43210 (10 digits)
    else if (code == '+91') {
      if (number.length == 10) return '$code ${number.substring(0, 5)} ${number.substring(5)}';
    }
    
    // Indonesia (+62) -> +62 812-3456-7890
    else if (code == '+62') {
      if (number.length >= 10) return '$code ${number.substring(0, 3)}-${number.substring(3, 7)}-${number.substring(7)}';
    }
    
    // Japan (+81) -> +81 90-1234-5678
    else if (code == '+81') {
      if (number.length == 10) return '$code ${number.substring(0, 2)}-${number.substring(2, 6)}-${number.substring(6)}';
    }

    return '$code $number';
  }

  // Settings
  String _glucoseUnit = 'mg/dL'; // or 'mmol/L'

  // App info
  String _appVersion = '';
  
  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        // Display as "1.0.0 (1)"
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    }
  }

  /// Upload Profile Picture via Backend
  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
    );

    if (imageFile == null) return;

    // Show loading indicator
    Helpers.showLoadingDialog(context, message: "Uploading...");

    try {
      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.name;

      final ApiService apiService = ApiService();
      
      // Call the backend endpoint
      final response = await apiService.uploadFile(
        '/patients/me/avatar', 
        'file', 
        bytes, 
        fileName
      );

      // Optimistic update
      if (mounted) {
        setState(() {
          _profileImageUrl = response['url'];
        });
        Helpers.hideLoadingDialog(context);
        Helpers.showSuccess(context, 'Profile picture updated');
        // Refresh provider to sync everything
        ref.refresh(userProfileProvider);
      }
    } catch (e) {
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        Helpers.showError(context, 'Failed to upload image: $e');
      }
    }
  }
  
  /// Handle logout
  Future<void> _handleLogout() async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
    );
    
    if (confirmed) {
      try {
        // Clear chatbot session state
        ref.read(chatProvider.notifier).resetSession();
        
        // Sign out - this triggers the onAuthStateChange listener in app.dart
        // which handles the navigation to the login screen.
        await supabase.auth.signOut();
      } catch (e) {
        if (mounted) {
          // Fallback manual navigation if error occurs
          AppRoutes.pushAndRemoveUntil(context, AppRoutes.login);
        }
      }
    }
  }
  
  /// Edit profile
  void _editProfile() {
    final profileData = ref.read(userProfileProvider).value;
    if (profileData != null) {
      _showEditProfileDialog(profileData);
    }
  }

  /// Show edit profile dialog
  void _showEditProfileDialog(Map<String, dynamic> profile) {
    final nameController = TextEditingController(text: profile['name']);
    final emailController = TextEditingController(text: profile['email']);
    final heightController = TextEditingController(text: profile['height']?.toString() ?? '');
    final weightController = TextEditingController(text: profile['weight']?.toString() ?? '');
    
    // Parse User Phone
    final parsedPhone = _parsePhone(profile['phone_number']);
    String selectedPhoneCode = parsedPhone[0];
    final phoneNumController = TextEditingController(text: parsedPhone[1]);

    final genderController = TextEditingController(text: profile['gender']);
    
    // Emergency Contact
    final ecNameController = TextEditingController(text: profile['emergency_contact_name']);
    
    // Parse EC Phone
    final parsedEcPhone = _parsePhone(profile['emergency_contact_phone']);
    String selectedEcPhoneCode = parsedEcPhone[0];
    final ecPhoneNumController = TextEditingController(text: parsedEcPhone[1]);
    
    String? selectedRelationship = profile['emergency_contact_relationship'];
    if (!_relationships.contains(selectedRelationship)) selectedRelationship = null;

    DateTime? selectedDob = profile['date_of_birth'] != null 
        ? DateTime.tryParse(profile['date_of_birth']) 
        : null;
        
    final dobController = TextEditingController(
      text: selectedDob != null ? Formatters.dateShort(selectedDob) : '',
    );

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    // Calculate max date allowed (13 years ago from today)
    final now = DateTime.now();
    final maxDateOfBirth = DateTime(now.year - 13, now.month, now.day);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      label: 'Full Name',
                      controller: nameController,
                      validator: Validators.name,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Email',
                      controller: emailController,
                      validator: Validators.email,
                      prefixIcon: const Icon(Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDob != null && selectedDob!.isBefore(maxDateOfBirth) 
                              ? selectedDob! 
                              : maxDateOfBirth,
                          firstDate: DateTime(1900),
                          lastDate: maxDateOfBirth, // Enforce 13yo limit
                          helpText: 'SELECT DATE OF BIRTH (Min Age: 13)',
                        );
                        if (date != null) {
                          setState(() {
                            selectedDob = date;
                            dobController.text = Formatters.dateShort(date);
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: CustomTextField(
                          label: 'Date of Birth',
                          controller: dobController,
                          prefixIcon: const Icon(Icons.calendar_today),
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                          validator: (val) => val == null || val.isEmpty ? 'Date of birth required' : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownField<String>(
                      label: 'Gender',
                      value: ['Male', 'Female', 'Other'].contains(genderController.text) 
                          ? genderController.text 
                          : null,
                      items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (val) {
                        setState(() {
                           genderController.text = val ?? '';
                        });
                      },
                      validator: (val) => val == null ? 'Gender required' : null,
                      prefixIcon: const Icon(Icons.wc),
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone Number with Country Code
                    Text('Phone Number', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 100,
                          child: DropdownButtonFormField<String>(
                            value: selectedPhoneCode,
                            isExpanded: true,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: _countryCodes.map((c) => DropdownMenuItem(
                              value: c['code'],
                              child: Text('${c['code']}'),
                            )).toList(),
                            onChanged: (val) => setState(() => selectedPhoneCode = val!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomTextField(
                            controller: phoneNumController,
                            validator: Validators.phoneDigits, // Validate digits only
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Height (cm)',
                            controller: heightController,
                            validator: (val) => Validators.range(val, 50, 300, fieldName: 'Height'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefixIcon: const Icon(Icons.height),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            label: 'Weight (kg)',
                            controller: weightController,
                            validator: (val) => Validators.range(val, 20, 500, fieldName: 'Weight'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefixIcon: const Icon(Icons.scale),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Emergency Contact',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Contact Name',
                      controller: ecNameController,
                      validator: Validators.name,
                      prefixIcon: const Icon(Icons.person),
                    ),
                    const SizedBox(height: 16),
                    DropdownField<String>(
                      label: 'Relationship',
                      value: selectedRelationship,
                      items: _relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) => setState(() => selectedRelationship = val),
                      validator: (val) => val == null ? 'Required' : null,
                      prefixIcon: const Icon(Icons.people),
                    ),
                    const SizedBox(height: 16),
                    
                    // EC Phone Number with Country Code
                    Text('Contact Phone', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 100,
                          child: DropdownButtonFormField<String>(
                            value: selectedEcPhoneCode,
                            isExpanded: true,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: _countryCodes.map((c) => DropdownMenuItem(
                              value: c['code'],
                              child: Text('${c['code']}'),
                            )).toList(),
                            onChanged: (val) => setState(() => selectedEcPhoneCode = val!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomTextField(
                            controller: ecPhoneNumController,
                            validator: Validators.phoneDigits,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (formKey.currentState!.validate()) {
                  setState(() => isSaving = true);
                  try {
                    final apiService = ApiService();

                    String cleanPhone(String num) {
                      if (num.startsWith('0')) return num.substring(1);
                      return num;
                    }
                    // Combine Country Code + Number
                    final fullPhone = '$selectedPhoneCode${cleanPhone(phoneNumController.text.trim())}';
                    final fullEcPhone = '$selectedEcPhoneCode${cleanPhone(ecPhoneNumController.text.trim())}';

                    await apiService.put('/patients/me', {
                      'name': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'phone_number': fullPhone,
                      'gender': genderController.text,
                      'date_of_birth': selectedDob?.toIso8601String().split('T')[0],
                      'emergency_contact_name': ecNameController.text.trim(),
                      'emergency_contact_relationship': selectedRelationship,
                      'emergency_contact_phone': fullEcPhone,
                      'height': double.tryParse(heightController.text.replaceAll(',', '.')),
                      'weight': double.tryParse(weightController.text.replaceAll(',', '.')),
                    });
                    
                    if (mounted) {
                      Navigator.pop(context);
                      ref.refresh(userProfileProvider);
                      Helpers.showSuccess(context, 'Profile updated successfully');
                    }
                  } catch (e) {
                    if (mounted) {
                      Helpers.showError(context, 'Failed to update profile: ${e.toString().replaceAll('Exception: ', '')}');
                    }
                  } finally {
                    if (mounted) setState(() => isSaving = false);
                  }
                }
              },
              child: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Edit health profile
  void _editHealthProfile() {
    Helpers.showInfo(context, 'Edit health profile feature coming soon');
    // TODO: Navigate to edit health profile screen
  }
  
  /// Toggle glucose unit
  void _toggleGlucoseUnit() {
    setState(() {
      _glucoseUnit = _glucoseUnit == 'mg/dL' ? 'mmol/L' : 'mg/dL';
    });
    Helpers.showSuccess(context, 'Glucose unit changed to $_glucoseUnit');
    // TODO: Save preference to storage
  }
  
  /// Toggle dark mode
  void _toggleDarkMode(bool value) {
    ref.read(themeProvider.notifier).setTheme(
          value ? ThemeMode.dark : ThemeMode.light,
        );
  }
  
  /// Check for updates
  void _checkForUpdates() {
    Helpers.showInfo(context, 'You are using the latest version ($_appVersion)');
    // TODO: Implement version check
  }
  
  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout,
              tooltip: 'Sign Out',
            ),
          ),
        ],
      ),
      body: userProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading profile: $error'),
              ElevatedButton(
                onPressed: () => ref.refresh(userProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profileData) {
          // Update local state from fetched data
          _userName = profileData['name'] ?? 'John Doe';
          _userEmail = profileData['email'] ?? 'user@example.com';
          _dateOfBirth = profileData['date_of_birth'] != null
              ? Formatters.date(DateTime.parse(profileData['date_of_birth']))
              : 'Not set';
          _gender = profileData['gender'] ?? 'Not set';
          _phoneNumber = profileData['phone_number'] ?? 'Not set';
          _profileImageUrl = profileData['profile_picture_url']; // Added
          _height = profileData['height'] != null ? (profileData['height'] as num).toDouble() : null;
          _weight = profileData['weight'] != null ? (profileData['weight'] as num).toDouble() : null;
          _emergencyContactName = profileData['emergency_contact_name'] ?? 'Not set';
          _emergencyContactPhone = profileData['emergency_contact_phone'] ?? 'Not set';
          _emergencyContactRelationship = profileData['emergency_contact_relationship'] ?? 'Not set';

          return RefreshIndicator(
            onRefresh: () => ref.refresh(userProfileProvider.future),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Personal info section
                        _buildPersonalInfoSection(),
                      const SizedBox(height: 16),

                      // Health Profile section
                      _buildHealthProfileSection(),
                      const SizedBox(height: 16),

                      // Medication Cabinet Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Medication Cabinet', Icons.medical_services_rounded),
                            const SizedBox(height: 12),
                            const MedicationCabinetSection(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Settings section
                      _buildSettingsSection(),
                      const SizedBox(height: 16),
                      
                      // About section
                      _buildAboutSection(),
                      const SizedBox(height: 24),
                      
                      // Sign out button
                      OutlinedButton(
                        onPressed: _handleLogout,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: BorderSide(color: AppTheme.errorColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Sign Out'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
    },
      ),
    );
  }
  
  /// Build profile header with avatar
 Widget _buildPersonalInfoSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Avatar & Basic Info (Centered)
          Center(
            child: Column(
              children: [
                // Wrap GestureDetector with MouseRegion
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _uploadProfilePicture,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: ClipOval(
                            child: (_profileImageUrl != null &&
                                    _profileImageUrl!.isNotEmpty)
                                ? Image.network(
                                    _profileImageUrl!,
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Text(
                                          _userName.isNotEmpty
                                              ? _userName[0].toUpperCase()
                                              : 'U',
                                          style: Theme.of(context)
                                              .textTheme
                                              .displayMedium
                                              ?.copyWith(
                                                color: AppTheme.primaryBlue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Text(
                                      _userName.isNotEmpty
                                          ? _userName[0].toUpperCase()
                                          : 'U',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayMedium
                                          ?.copyWith(
                                            color: AppTheme.primaryBlue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _userName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _userEmail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Personal Information', Icons.person_outline),

          const SizedBox(height: 16),

          // Details
          _buildInfoRow('Date of Birth', _dateOfBirth, Icons.cake),
          const Divider(height: 24),
          _buildInfoRow('Gender', _gender, Icons.wc),
          const Divider(height: 24),
          _buildInfoRow('Phone Number', _formatDisplayPhone(_phoneNumber), Icons.phone),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(child: _buildInfoRow('Height', _height != null ? '${_height!.toStringAsFixed(1)} cm' : 'Not set', Icons.height)),
              Expanded(child: _buildInfoRow('Weight', _weight != null ? '${_weight!.toStringAsFixed(1)} kg' : 'Not set', Icons.scale)),
            ],
          ),

          const SizedBox(height: 40),

          // Emergency Contact Header
          _buildSectionHeader('Emergency Contact', Icons.contact_emergency),
          const SizedBox(height: 16),

          _buildInfoRow('Name', _emergencyContactName, Icons.person),
          const Divider(height: 24),
          _buildInfoRow('Phone Number', _formatDisplayPhone(_emergencyContactPhone), Icons.phone),
          const Divider(height: 24),
          _buildInfoRow('Relationship', _emergencyContactRelationship, Icons.people),
          const SizedBox(height: 24),

          // Edit button
          Center(
            child: TextButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
  /// Build health profile section
  Widget _buildHealthProfileSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('Health Profile', Icons.favorite_outline),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: _editHealthProfile,
                tooltip: 'Edit',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          const Divider(height: 24),
          _buildInfoRow(
            'Target Glucose Range',
            '${_targetMin.toInt()}-${_targetMax.toInt()} mg/dL',
            Icons.track_changes,
          ),
        ],
      ),
    );
  }
  
  /// Build settings section
  Widget _buildSettingsSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Settings', Icons.settings_outlined),
          const SizedBox(height: 16),

          // Glucose unit
          _buildSettingItem(
            'Glucose Unit',
            _glucoseUnit,
            Icons.straighten,
            onTap: _toggleGlucoseUnit,
            showChevron: true,
          ),
          const Divider(height: 24),

          // Dark mode toggle
          _buildSettingToggle(
            'Dark Mode',
            'Switch between light and dark theme',
            Icons.dark_mode_outlined,
            ref.watch(themeProvider) == ThemeMode.dark,
            _toggleDarkMode,
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }
  
  /// Build about section
  Widget _buildAboutSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('About', Icons.info_outline),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            'App Version',
            _appVersion,
            Icons.phone_android,
          ),
          const Divider(height: 24),
          
          _buildSettingItem(
            'Check for Updates',
            'Tap to check',
            Icons.system_update,
            onTap: _checkForUpdates,
            showChevron: true,
          ),
          const Divider(height: 24),
          
          _buildSettingItem(
            'Privacy Policy',
            'View our privacy policy',
            Icons.privacy_tip_outlined,
            onTap: () => Helpers.showInfo(context, 'Privacy policy coming soon'),
            showChevron: true,
          ),
          const Divider(height: 24),
          
          _buildSettingItem(
            'Terms of Service',
            'View terms of service',
            Icons.description_outlined,
            onTap: () => Helpers.showInfo(context, 'Terms coming soon'),
            showChevron: true,
          ),
        ],
      ),
    );
  }
  
  /// Build section header
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryBlue,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
  
  /// Build info row
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Build setting item (clickable)
  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
    bool showChevron = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondaryColor,
              ),
          ],
        ),
      ),
    );
  }
  
  /// Build setting toggle
  Widget _buildSettingToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppTheme.primaryBlue,
        ),
      ],
    );
  }
  
}
