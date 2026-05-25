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
        );

        await _dataService.updateClinicianProfile(updatedClinician);

        await ApiService().put('/clinicians/me/settings', {
          'glucose_unit': _glucoseUnit,
          'cholesterol_unit': _cholesterolUnit,
        });

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
                        'Organisation ID: ${_clinician?.organisationId ?? "N/A"}',
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
                      if (_isEditing) ...[
                        DropdownButtonFormField<String>(
                          value: _glucoseUnit,
                          decoration: const InputDecoration(
                              labelText: 'Glucose Unit',
                              prefixIcon: Icon(Icons.water_drop)),
                          items: ['mmol/L', 'mg/dL']
                              .map((u) =>
                                  DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _glucoseUnit = val!),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _cholesterolUnit,
                          decoration: const InputDecoration(
                              labelText: 'Cholesterol Unit',
                              prefixIcon: Icon(Icons.bloodtype)),
                          items: ['mmol/L', 'mg/dL']
                              .map((u) =>
                                  DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _cholesterolUnit = val!),
                        ),
                      ] else ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.water_drop_outlined,
                              color: AppTheme.primaryColor),
                          title: const Text('Glucose'),
                          trailing: Text(_glucoseUnit,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.bloodtype_outlined,
                              color: AppTheme.primaryColor),
                          title: const Text('Cholesterol'),
                          trailing: Text(_cholesterolUnit,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
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

                      const SizedBox(height: 20),

                      // Organisation ID (Read-only)
                      TextFormField(
                        initialValue: _clinician?.organisationId.toString(),
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Organisation ID',
                          prefixIcon: Icon(Icons.business_outlined),
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
                    label: const Text('Logout', style: TextStyle(color: AppTheme.highRiskColor, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.highRiskColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

