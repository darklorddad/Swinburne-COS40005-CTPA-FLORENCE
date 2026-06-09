import 'package:flutter/material.dart';
import 'package:florence/core/utils/helpers.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';
import 'package:florence/features/clinician/services/data_service.dart';
import 'package:florence/features/clinician/services/api_data_service.dart';
import 'package:florence/features/clinician/services/api_service.dart';
import 'package:florence/features/clinician/models/clinician.dart';

class ClinicianProfileScreen extends StatefulWidget {
  const ClinicianProfileScreen({super.key});

  @override
  State<ClinicianProfileScreen> createState() => _ClinicianProfileScreenState();
}

class _ClinicianProfileScreenState extends State<ClinicianProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final DataService _dataService = ApiDataService();
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  
  // Dropdown values
  String? _selectedGender;
  String _glucoseUnit = 'mmol/L';
  String _cholesterolUnit = 'mmol/L';
  
  bool _isEditing = false;
  bool _isLoading = true;
  Clinician? _clinician;
  String? _email;

  // Available options
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final clinician = await _dataService.getClinicianProfile();
      final email = ApiService().currentUserEmail;
      
      if (mounted) {
        setState(() {
          _clinician = clinician;
          _email = email;
          _nameController.text = clinician.name;
          _mobileController.text = clinician.phoneNumber;
          _selectedGender = clinician.gender.isNotEmpty ? clinician.gender : null;
          _isLoading = true;
        });

        try {
          final settings = await ApiService().get('/clinicians/me/settings');
          if (settings != null && mounted) {
            setState(() {
              _glucoseUnit = settings['glucose_unit'] ?? 'mmol/L';
              _cholesterolUnit = settings['cholesterol_unit'] ?? 'mmol/L';
            });
          }
        } catch (e) {
          debugPrint('Failed loading unit settings: $e');
        }

        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && _clinician != null) {
      setState(() => _isLoading = true);
      try {
        final updatedClinician = Clinician(
          id: _clinician!.id,
          userId: _clinician!.userId,
          name: _nameController.text,
          phoneNumber: _mobileController.text,
          gender: _selectedGender ?? '',
          organisationId: _clinician!.organisationId,
          organisationName: _clinician!.organisationName,
          organisationEmail: _clinician!.organisationEmail,
          organisationPhone: _clinician!.organisationPhone,
        );

        await _dataService.updateClinicianProfile(updatedClinician);

        if (mounted) {
          setState(() {
            _clinician = updatedClinician;
            _isEditing = false;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: $e')),
          );
        }
      }
    }
  }

  Future<void> _saveInlineSettings() async {
    try {
      await ApiService().put('/clinicians/me/settings', {
        'glucose_unit': _glucoseUnit,
        'cholesterol_unit': _cholesterolUnit,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Preferences updated successfully!'),
              duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update preferences: $e')),
        );
      }
    }
  }

  void _showOnTheSpotUnitSelector(String title, List<String> options,
      String currentSelection, Function(String) onSelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select $title',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              ...options.map((option) => ListTile(
                    title: Text(option,
                        style: TextStyle(
                          color: option == currentSelection
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimary,
                          fontWeight: option == currentSelection
                              ? FontWeight.bold
                              : FontWeight.normal,
                        )),
                    trailing: option == currentSelection
                        ? const Icon(Icons.check, color: AppTheme.primaryColor)
                        : null,
                    onTap: () {
                      onSelected(option);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _cancelEdit() {
    if (_clinician != null) {
      _nameController.text = _clinician!.name;
      _mobileController.text = _clinician!.phoneNumber;
      _selectedGender = _clinician!.gender.isNotEmpty ? _clinician!.gender : null;
    }
    
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinician Profile'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            color: AppTheme.dividerColor,
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          width: 4,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: Text(
                          _nameController.text.isNotEmpty 
                            ? _nameController.text.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join('').toUpperCase()
                            : '?',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _nameController.text.isEmpty ? 'Loading...' : _nameController.text,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _clinician?.organisationName ?? 'Organisation ID: ${_clinician?.organisationId ?? "N/A"}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Account Information Section
              const Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Name
                      TextFormField(
                        controller: _nameController,
                        readOnly: !_isEditing,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Gender
                      if (_isEditing)
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            prefixIcon: Icon(Icons.wc_outlined),
                          ),
                          items: _genders.map((gender) {
                            return DropdownMenuItem(
                              value: gender,
                              child: Text(gender),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedGender = value;
                              });
                            }
                          },
                        )
                      else
                        TextFormField(
                          initialValue: _selectedGender ?? 'Not Set',
                          readOnly: true,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            prefixIcon: Icon(Icons.wc_outlined),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Mobile Phone
                      TextFormField(
                        controller: _mobileController,
                        readOnly: !_isEditing,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter mobile number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!_isEditing)
                            ElevatedButton.icon(
                              onPressed: _toggleEdit,
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit Profile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            )
                          else ...[
                            OutlinedButton(
                              onPressed: _cancelEdit,
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Save Changes'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Unit Preferences Section
              const Text(
                'Unit Preferences',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.water_drop_outlined,
                            color: AppTheme.primaryColor),
                        title: const Text('Glucose Unit'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_glucoseUnit,
                                style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold)),
                            const Icon(Icons.chevron_right,
                                size: 20, color: AppTheme.textTertiary),
                          ],
                        ),
                        onTap: () => _showOnTheSpotUnitSelector(
                            'Glucose Unit', ['mmol/L', 'mg/dL'], _glucoseUnit,
                            (newUnit) async {
                          setState(() => _glucoseUnit = newUnit);
                          await _saveInlineSettings();
                        }),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.bloodtype_outlined,
                            color: AppTheme.primaryColor),
                        title: const Text('Cholesterol Unit'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_cholesterolUnit,
                                style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold)),
                            const Icon(Icons.chevron_right,
                                size: 20, color: AppTheme.textTertiary),
                          ],
                        ),
                        onTap: () => _showOnTheSpotUnitSelector(
                            'Cholesterol Unit',
                            ['mmol/L', 'mg/dL'],
                            _cholesterolUnit, (newUnit) async {
                          setState(() => _cholesterolUnit = newUnit);
                          await _saveInlineSettings();
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // System Information Section
              const Text(
                'System Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Email (Read-only)
                      TextFormField(
                        initialValue: _email,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Organisation Information Section
              const Text(
                'Organisation Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Organisation Name (Read-only)
                      TextFormField(
                        initialValue: _clinician?.organisationName ?? 'Not Set',
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Organisation Name',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Organisation Email (Read-only)
                      TextFormField(
                        initialValue: _clinician?.organisationEmail ?? 'Not Set',
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Organisation Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Organisation Phone (Read-only)
                      TextFormField(
                        initialValue: _clinician?.organisationPhone ?? 'Not Set',
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Organisation Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),

              if (!_isEditing)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout, color: AppTheme.highRiskColor),
                    label: const Text('Logout',
                        style: TextStyle(
                            color: AppTheme.highRiskColor,
                            fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppTheme.highRiskColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmText: 'Sign Out',
      cancelText: 'Cancel',
      isDangerous: true,
    );

    if (confirmed) {
      setState(() => _isLoading = true);
      try {
        await ApiService().signOut();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to sign out: $e')),
          );
        }
      }
    }
  }
}

