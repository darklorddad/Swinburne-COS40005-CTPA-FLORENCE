import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/services/api_service.dart'; // Added
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../shared/widgets/input_widgets.dart';
import '../../core/providers/disease_providers.dart';
import '../../core/providers/medication_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/providers/threshold_providers.dart';
import '../../core/repositories/medication_repository.dart';
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
  String _diseaseFilter = 'ACTIVE';

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

  // Medication Cabinet Filter
  String _medFilter = 'Active';

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
  
  
  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
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
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 16, bottom: 100),
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
                      _buildMedicationCabinetSection(),
                      const SizedBox(height: 16),

                      // Disease Log Section
                      _buildDiseaseLogSection(context, ref),
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
  /// Build medication cabinet section
  Widget _buildMedicationCabinetSection() {
    final medsAsync = ref.watch(patientMedicationsProvider);

    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('Medication Cabinet', Icons.medical_services_outlined),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: () {
                  // Logic to show add medication form
                  showDialog(
                    context: context,
                    builder: (context) => const MedicationFormDialog(isEdit: false),
                  );
                },
                tooltip: 'Add Medication',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMedFilterChip('Active'),
                const SizedBox(width: 8),
                _buildMedFilterChip('Past'),
                const SizedBox(width: 8),
                _buildMedFilterChip('All'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          medsAsync.when(
            data: (meds) {
              final filteredMeds = meds.where((m) {
                if (_medFilter == 'Active') return m.status != 'PAST';
                if (_medFilter == 'Past') return m.status == 'PAST';
                return true;
              }).toList();

              if (filteredMeds.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No medications found')),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredMeds.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final med = filteredMeds[index];
                  final isActive = med.status != 'PAST';
                  final brandName = med.medicationDictionary['brand_name'] ??
                      med.customMedicationName ??
                      'Unknown';

                  return Opacity(
                    opacity: isActive ? 1.0 : 0.5,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.medication_rounded,
                            color: AppTheme.primaryBlue, size: 20),
                      ),
                      title: Text(
                        brandName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          decoration:
                              isActive ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      subtitle: Text(
                        "${med.amount} ${med.medicationType ?? 'Pill'}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showFormModal(context, isEdit: true, med: med);
                          } else if (value == 'stop') {
                            _confirmStop(context, ref, med, brandName);
                          } else if (value == 'restart') {
                            _confirmRestart(context, ref, med, brandName);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit')
                              ])),
                          if (isActive)
                            const PopupMenuItem(
                                value: 'stop',
                                child: Row(children: [
                                  Icon(Icons.stop_circle, size: 18,
                                      color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Stop',
                                      style: TextStyle(color: Colors.red))
                                ]))
                          else
                            const PopupMenuItem(
                                value: 'restart',
                                child: Row(children: [
                                  Icon(Icons.play_circle, size: 18,
                                      color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Restart',
                                      style: TextStyle(color: Colors.green))
                                ])),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Error loading medications')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedFilterChip(String label) {
    final isSelected = _medFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _medFilter = label);
        }
      },
      selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondaryColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withOpacity(0.05)
          : Colors.grey.shade100,
      side: BorderSide.none,
    );
  }

  void _showFormModal(BuildContext context,
      {required bool isEdit, dynamic med}) {
    showDialog(
        context: context,
        builder: (context) =>
            MedicationFormDialog(isEdit: isEdit, medication: med));
  }

  void _confirmStop(
      BuildContext context, WidgetRef ref, dynamic med, String medName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Stop Medication"),
        content: Text(
            "Are you sure you want to stop taking $medName? It will be moved to your history."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(medicationRepositoryProvider).updateMedicationStatus(med.id, 'PAST');
              ref.invalidate(patientMedicationsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0),
            child: const Text("Stop Medication"),
          ),
        ],
      ),
    );
  }

  void _confirmRestart(
      BuildContext context, WidgetRef ref, dynamic med, String medName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Restart Medication"),
        content: Text(
            "Do you want to move $medName back to your active medications and schedule?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(medicationRepositoryProvider).updateMedicationStatus(med.id, 'CURRENT');
              ref.invalidate(patientMedicationsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0),
            child: const Text("Restart Medication"),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseLogSection(BuildContext context, WidgetRef ref) {
    final diseaseLogsAsync = ref.watch(diseaseLogProvider);

    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('Disease Log', Icons.history_edu_outlined),
              IconButton(
                onPressed: () => _showDiseaseFormModal(context, ref),
                icon: const Icon(Icons.add_circle_outline,
                    color: AppTheme.primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Custom Segmented Filter Control
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildDiseaseFilterButton('ACTIVE', 'Active'),
                _buildDiseaseFilterButton('RESOLVED', 'Resolved'),
                _buildDiseaseFilterButton('ALL', 'All'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          diseaseLogsAsync.when(
            data: (logs) {
              final filteredLogs = logs.where((log) {
                if (_diseaseFilter == 'ALL') return true;
                return log.status.toUpperCase() == _diseaseFilter;
              }).toList();

              if (filteredLogs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text("No disease history found.",
                        style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredLogs.length,
                separatorBuilder: (context, index) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final log = filteredLogs[index];
                  final isActive = log.status.toLowerCase() == 'active';

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.red[50] : Colors.green[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.medical_services_outlined,
                          color: isActive ? Colors.red : Colors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.conditionName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Diagnosed: ${log.diagnosedDate != null ? DateFormat('dd MMM yyyy').format(log.diagnosedDate!) : 'Unknown'}",
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13),
                            ),
                            if (!isActive && log.resolvedDate != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                "Resolved: ${DateFormat('dd MMM yyyy').format(log.resolvedDate!)}",
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),
                            ]
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  isActive ? Colors.red[50] : Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isActive ? 'ACTIVE' : 'RESOLVED',
                              style: TextStyle(
                                color: isActive ? Colors.red : Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon:
                                const Icon(Icons.more_horiz, color: Colors.grey),
                            onSelected: (value) async {
                              if (value == 'edit') {
                                _showDiseaseFormModal(context, ref,
                                    existingLog: log);
                              } else if (value == 'resolve') {
                                _promptResolveDate(context, ref, log);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                  value: 'edit', child: Text('Edit')),
                              if (isActive)
                                const PopupMenuItem(
                                    value: 'resolve',
                                    child: Text('Mark as Resolved')),
                            ],
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text("Error loading logs: $e"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseFilterButton(String filterValue, String label) {
    final isSelected = _diseaseFilter == filterValue;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _diseaseFilter = filterValue;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.primaryBlue : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDiseaseFormModal(BuildContext context, WidgetRef ref,
      {DiseaseLog? existingLog}) {
    final isEditing = existingLog != null;
    final nameController =
        TextEditingController(text: existingLog?.conditionName ?? '');
    String status = existingLog?.status ?? 'active';
    DateTime? diagnosedDate = existingLog?.diagnosedDate;
    DateTime? resolvedDate = existingLog?.resolvedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEditing ? "Edit Condition" : "Log Medical Condition",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Condition Name',
                    hintText: 'e.g. Type 2 Diabetes'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text("Active")),
                  DropdownMenuItem(value: 'resolved', child: Text("Resolved")),
                ],
                onChanged: (val) => setModalState(() {
                  status = val!;
                  if (status == 'active') resolvedDate = null;
                }),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(diagnosedDate == null
                    ? "Select Diagnosed Date"
                    : "Diagnosed: ${DateFormat('dd MMM yyyy').format(diagnosedDate!)}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                      context: context,
                      initialDate: diagnosedDate ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now());
                  if (date != null) setModalState(() => diagnosedDate = date);
                },
              ),
              if (status == 'resolved')
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(resolvedDate == null
                      ? "Select Resolved Date"
                      : "Resolved: ${DateFormat('dd MMM yyyy').format(resolvedDate!)}"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                        context: context,
                        initialDate: resolvedDate ?? DateTime.now(),
                        firstDate: diagnosedDate ?? DateTime(1900),
                        lastDate: DateTime.now());
                    if (date != null) setModalState(() => resolvedDate = date);
                  },
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      final log = DiseaseLog(
                        conditionName: nameController.text,
                        status: status,
                        diagnosedDate: diagnosedDate,
                        resolvedDate: resolvedDate,
                      );

                      if (isEditing) {
                        await ref
                            .read(diseaseLogProvider.notifier)
                            .updateLog(existingLog.id!, log);
                      } else {
                        await ref.read(diseaseLogProvider.notifier).addLog(log);
                      }
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: Text(isEditing ? "Save Changes" : "Save Condition"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _promptResolveDate(
      BuildContext context, WidgetRef ref, DiseaseLog log) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: log.diagnosedDate ?? DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date Resolved',
    );

    if (selectedDate != null && log.id != null) {
      final updatedLog = DiseaseLog(
        conditionName: log.conditionName,
        status: 'resolved',
        diagnosedDate: log.diagnosedDate,
        resolvedDate: selectedDate,
        notes: log.notes,
      );

      await ref.read(diseaseLogProvider.notifier).updateLog(log.id!, updatedLog);
    }
  }

  /// Build health profile section
  Widget _buildHealthProfileSection() {
    final thresholdsAsync = ref.watch(patientThresholdsProvider);
    final settings = ref.watch(patientSettingsProvider);

    final labels = {
      'BLOOD_PRESSURE_SYSTOLIC': 'BP (Systolic)',
      'BLOOD_PRESSURE_DIASTOLIC': 'BP (Diastolic)',
      'GLUCOSE': 'Glucose',
      'BMI': 'Healthy BMI',
      'HBA1C': 'HbA1c',
      'CHOLESTEROL_TOTAL': 'Total Cholesterol',
      'CHOLESTEROL_LDL': 'LDL Cholesterol',
      'CHOLESTEROL_HDL': 'HDL Cholesterol',
      'CHOLESTEROL_TRIGLYCERIDES': 'Triglycerides'
    };

    String getUnit(String type) {
      if (type == 'GLUCOSE') return settings.glucoseUnit;
      if (type.contains('CHOLESTEROL')) return settings.cholesterolUnit;
      if (type.contains('BLOOD_PRESSURE')) return 'mmHg';
      if (type == 'HBA1C') return '%';
      return '';
    }

    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('Health Profile', Icons.favorite_outline),
              TextButton(
                onPressed: thresholdsAsync.value == null
                    ? null
                    : () => _showEditThresholdsModal(
                        context, ref, thresholdsAsync.value!, labels, getUnit),
                child: const Text('Edit',
                    style: TextStyle(color: AppTheme.primaryBlue)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          thresholdsAsync.when(
            data: (thresholds) {
              if (thresholds.isEmpty) return const Text("No thresholds found.");
              return Column(
                children: thresholds.map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(labels[t.dataType] ?? t.dataType,
                            style: const TextStyle(
                                fontSize: 15, color: Colors.grey)),
                        Text(
                          '${t.minValue} - ${t.maxValue} ${getUnit(t.dataType)}',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text("Error: $e"),
          ),
        ],
      ),
    );
  }

  void _showEditThresholdsModal(
      BuildContext context,
      WidgetRef ref,
      List<PatientThreshold> currentThresholds,
      Map<String, String> labels,
      Function(String) getUnit) {
    final Map<String, TextEditingController> minControllers = {};
    final Map<String, TextEditingController> maxControllers = {};
    final formKey = GlobalKey<FormState>();

    for (var t in currentThresholds) {
      minControllers[t.dataType] =
          TextEditingController(text: t.minValue.toString());
      maxControllers[t.dataType] =
          TextEditingController(text: t.maxValue.toString());
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20),
        child: FractionallySizedBox(
          heightFactor: 0.8,
          child: Form(
            key: formKey,
            child: Column(
              children: [
                const Text("Edit Health Thresholds",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: currentThresholds.map((t) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "${labels[t.dataType] ?? t.dataType} (${getUnit(t.dataType)})",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: minControllers[t.dataType],
                                    decoration: const InputDecoration(
                                        labelText: 'Min', isDense: true),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      final minVal = double.tryParse(value);
                                      if (minVal == null) return 'Numbers only';
                                      final maxVal = double.tryParse(
                                          maxControllers[t.dataType]!.text);
                                      if (maxVal != null && minVal >= maxVal) {
                                        return 'Must be < Max';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: maxControllers[t.dataType],
                                    decoration: const InputDecoration(
                                        labelText: 'Max', isDense: true),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      final maxVal = double.tryParse(value);
                                      if (maxVal == null) return 'Numbers only';
                                      final minVal = double.tryParse(
                                          minControllers[t.dataType]!.text);
                                      if (minVal != null && maxVal <= minVal) {
                                        return 'Must be > Min';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      final List<PatientThreshold> updated = [];
                      for (var t in currentThresholds) {
                        updated.add(PatientThreshold(
                          dataType: t.dataType,
                          minValue:
                              double.parse(minControllers[t.dataType]!.text),
                          maxValue:
                              double.parse(maxControllers[t.dataType]!.text),
                        ));
                      }
                      await ref
                          .read(patientThresholdsProvider.notifier)
                          .updateThresholds(updated);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text("Save Changes"),
                  ),
                ),
              ],
            ),
          ),
        ),
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
  
  
}
