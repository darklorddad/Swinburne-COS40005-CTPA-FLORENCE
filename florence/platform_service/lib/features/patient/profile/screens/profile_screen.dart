import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../core/providers/health_data_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../shared/widgets/button_widgets.dart';
import '../../../../shared/widgets/input_widgets.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';
import '../../../../main.dart';

/// Profile & Settings Screen
/// Unified screen for user profile, health info, and app settings
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  
  // Mock user data (will be replaced with real data)
  String _userName = 'John Doe';
  String _userEmail = 'john.doe@example.com';
  String _dateOfBirth = 'January 15, 1985';
  String _gender = 'Male';
  String _phoneNumber = '+60 12-345 6789';
  String _diabetesType = 'Type 2';
  double _targetMin = 70.0;
  double _targetMax = 180.0;
  
  // Medications list (mock)
  List<Map<String, String>> _medications = [
    {'name': 'Metformin', 'dosage': '500mg', 'frequency': 'Twice daily'},
    {'name': 'Insulin', 'dosage': '10 units', 'frequency': 'Before meals'},
  ];
  
  // Settings
  String _glucoseUnit = 'mg/dL'; // or 'mmol/L'

  // App info
  final String _appVersion = '1.0.0';
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  /// Load user data
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Get email from the local session (safe)
      final email = supabase.auth.currentUser?.email ?? 'user@example.com';

      // Fetch the full profile from the backend API
      final profile = await _apiService.get('/patients/me');

      if (mounted) {
        setState(() {
          _userEmail = email;
          _userName = profile['name'] ?? 'John Doe';
          _dateOfBirth = profile['date_of_birth'] != null
              ? Formatters.date(DateTime.parse(profile['date_of_birth']))
              : 'Not set';
          _gender = profile['gender'] ?? 'Not set';
          _phoneNumber = profile['phone_number'] ?? 'Not set';
          // TODO: Load other profile fields like diabetes type, targets, etc.
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        Helpers.showError(context, 'Failed to load profile data.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        await supabase.auth.signOut();
        if (mounted) {
          AppRoutes.pushAndRemoveUntil(context, AppRoutes.login);
        }
      } catch (e) {
        if (mounted) {
          // In demo mode, just navigate to login
          AppRoutes.pushAndRemoveUntil(context, AppRoutes.login);
        }
      }
    }
  }
  
  /// Edit profile
  void _editProfile() {
    Helpers.showInfo(context, 'Edit profile feature coming soon');
    // TODO: Navigate to edit profile screen or show bottom sheet
  }
  
  /// Edit health profile
  void _editHealthProfile() {
    Helpers.showInfo(context, 'Edit health profile feature coming soon');
    // TODO: Navigate to edit health profile screen
  }
  
  /// Toggle Demo Mode
  void _toggleDemoMode(bool value) async {
    await context.read<SettingsProvider>().setDemoMode(value);
    context.read<HealthDataProvider>().refreshData();
  }
  
  /// Add medication
  void _addMedication() {
    Helpers.showInfo(context, 'Add medication feature coming soon');
    // TODO: Navigate to add medication screen
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
    Provider.of<ThemeProvider>(context, listen: false).setTheme(
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile header with avatar
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    
                    // Personal info section
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 16),
                    
                    // Health profile section
                    _buildHealthProfileSection(),
                    const SizedBox(height: 16),
                    
                    // Medications section
                    _buildMedicationsSection(),
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
    );
  }
  
  /// Build profile header with avatar
  Widget _buildProfileHeader() {
    return BaseCard(
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
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
                    Icons.edit,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Name
          Text(
            _userName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          
          // Email
          Text(
            _userEmail,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
          const SizedBox(height: 16),
          
          // Edit profile button
          TextButton.icon(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit Profile'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build personal info section
  Widget _buildPersonalInfoSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Personal Information', Icons.person_outline),
          const SizedBox(height: 16),
          
          _buildInfoRow('Date of Birth', _dateOfBirth, Icons.cake),
          const Divider(height: 24),
          _buildInfoRow('Gender', _gender, Icons.wc),
          const Divider(height: 24),
          _buildInfoRow('Phone Number', _phoneNumber, Icons.phone),
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
          
          _buildInfoRow(
            'Diabetes Type',
            _diabetesType,
            Icons.medical_information,
          ),
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
  
  /// Build medications section
  Widget _buildMedicationsSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('Medications', Icons.medication),
              TextButton.icon(
                onPressed: _addMedication,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_medications.isEmpty)
            _buildEmptyState('No medications added yet')
          else
            ..._medications.asMap().entries.map((entry) {
              final index = entry.key;
              final med = entry.value;
              return Column(
                children: [
                  if (index > 0) const Divider(height: 24),
                  _buildMedicationItem(
                    med['name']!,
                    med['dosage']!,
                    med['frequency']!,
                  ),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }
  
  /// Build single medication item
  Widget _buildMedicationItem(String name, String dosage, String frequency) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.medicationColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.medication,
            color: AppTheme.medicationColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '$dosage • $frequency',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.more_vert,
            color: AppTheme.textSecondaryColor,
          ),
          onPressed: () {
            // TODO: Show edit/delete options
            Helpers.showInfo(context, 'Edit medication coming soon');
          },
        ),
      ],
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
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => _buildSettingToggle(
              'Dark Mode',
              'Switch between light and dark theme',
              Icons.dark_mode_outlined,
              themeProvider.isDarkMode,
              _toggleDarkMode,
            ),
          ),
          const Divider(height: 24),
          // Demo mode toggle
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, _) => _buildSettingToggle(
                'Demo Mode', 'Use mock data for demonstration purposes', Icons.science_outlined, settingsProvider.isDemoMode, _toggleDemoMode),
          ),
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
  
  /// Build empty state
  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
        ),
      ),
    );
  }
}
