import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../../config/routes.dart';
import '../../../core/utils/helpers.dart';
import '../../../main.dart';

class ClinicianProfileScreen extends StatefulWidget {
  const ClinicianProfileScreen({super.key});

  @override
  State<ClinicianProfileScreen> createState() => _ClinicianProfileScreenState();
}

class _ClinicianProfileScreenState extends State<ClinicianProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController(text: 'Dr. Example Clinician');
  final TextEditingController _mobileController = TextEditingController(text: '+601234567890');
  final TextEditingController _loginIdController = TextEditingController(text: 'clinician01');
  final TextEditingController _passwordController = TextEditingController(text: '••••••••');
  
  // Dropdown values
  String _selectedGender = 'Male';
  String _selectedCountry = 'Malaysia';
  String _selectedProfession = 'Endocrinologist';
  
  bool _isEditing = false;
  bool _obscurePassword = true;

  // Available options
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _countries = [
    'Malaysia',
    'Singapore',
    'Thailand',
    'Indonesia',
    'Philippines',
    'Vietnam',
    'United States',
    'United Kingdom',
    'Australia',
    'India',
    'China',
    'Japan',
  ];
  final List<String> _professions = [
    'Endocrinologist',
    'General Practitioner',
    'Internal Medicine',
    'Family Physician',
    'Diabetologist',
    'Cardiologist',
    'Nephrologist',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  void _cancelEdit() {
    // Reset to original values
    _nameController.text = 'Dr. Example Clinician';
    _mobileController.text = '+601234567890';
    _loginIdController.text = 'clinician01';
    _passwordController.text = '••••••••';
    _selectedGender = 'Male';
    _selectedCountry = 'Malaysia';
    _selectedProfession = 'Endocrinologist';
    
    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
    );

    if (confirmed && mounted) {
      try {
        await supabase.auth.signOut();
        if (mounted) {
          AppRoutes.pushAndRemoveUntil(context, AppRoutes.login);
        }
      } catch (e) {
        if (mounted) {
          Helpers.showError(context, 'Failed to sign out');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinician Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEdit,
              tooltip: 'Edit Profile',
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: _cancelEdit,
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: _saveProfile,
                  child: const Text('Save'),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Sign Out',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                        child: Text(
                          _nameController.text.split(' ').map((e) => e[0]).join(''),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameController.text,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedProfession,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Personal Information Section
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Name
                      TextFormField(
                        controller: _nameController,
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Gender
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.people),
                          border: OutlineInputBorder(),
                        ),
                        items: _genders.map((gender) {
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: _isEditing
                            ? (value) {
                                setState(() {
                                  _selectedGender = value!;
                                });
                              }
                            : null,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Country
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCountry,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          prefixIcon: Icon(Icons.public),
                          border: OutlineInputBorder(),
                        ),
                        items: _countries.map((country) {
                          return DropdownMenuItem(
                            value: country,
                            child: Text(country),
                          );
                        }).toList(),
                        onChanged: _isEditing
                            ? (value) {
                                setState(() {
                                  _selectedCountry = value!;
                                });
                              }
                            : null,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Mobile Phone
                      TextFormField(
                        controller: _mobileController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Phone Number',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
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
              
              const SizedBox(height: 24),
              
              // Professional Information Section
              const Text(
                'Professional Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Type of Profession
                      DropdownButtonFormField<String>(
                        initialValue: _selectedProfession,
                        decoration: const InputDecoration(
                          labelText: 'Type of Profession',
                          prefixIcon: Icon(Icons.work),
                          border: OutlineInputBorder(),
                        ),
                        items: _professions.map((profession) {
                          return DropdownMenuItem(
                            value: profession,
                            child: Text(profession),
                          );
                        }).toList(),
                        onChanged: _isEditing
                            ? (value) {
                                setState(() {
                                  _selectedProfession = value!;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Account Information Section
              const Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Login ID
                      TextFormField(
                        controller: _loginIdController,
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Login ID',
                          prefixIcon: Icon(Icons.alternate_email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter login ID';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Password
                      TextFormField(
                        controller: _passwordController,
                        enabled: _isEditing,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: _isEditing
                              ? IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter password';
                          }
                          if (_isEditing && value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                    ],
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
}

