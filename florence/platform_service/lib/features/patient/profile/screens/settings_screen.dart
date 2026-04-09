import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../main.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../chat/services/chatbot_service.dart';
import '../../core/providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
    );

    if (confirmed) {
      try {
        ref.read(chatProvider.notifier).resetSession();
        await supabase.auth.signOut();
      } catch (e) {
        if (mounted) {
          AppRoutes.pushAndRemoveUntil(context, AppRoutes.login);
        }
      }
    }
  }

  void _toggleDarkMode(bool value) {
    ref.read(themeProvider.notifier).setTheme(
          value ? ThemeMode.dark : ThemeMode.light,
        );
  }

  void _checkForUpdates() {
    Helpers.showInfo(context, 'You are using the latest version ($_appVersion)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSettingsSection(),
                  const SizedBox(height: 16),
                  _buildAboutSection(),
                  const SizedBox(height: 24),
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
  }

  Widget _buildSettingsSection() {
    final settings = ref.watch(patientSettingsProvider);

    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Preferences', Icons.settings_outlined),
          const SizedBox(height: 16),

          _buildInteractiveSettingRow(
            title: 'Glucose Unit',
            currentValue: settings.glucoseUnit,
            icon: Icons.straighten,
            options: ['mmol/L', 'mg/dL'],
            onSelect: (value) {
              ref.read(patientSettingsProvider.notifier).updateGlucoseUnit(value);
              Helpers.showSuccess(context, 'Glucose unit changed to $value');
            },
          ),
          const Divider(height: 1),

          _buildInteractiveSettingRow(
            title: 'Cholesterol Unit',
            currentValue: settings.cholesterolUnit,
            icon: Icons.bloodtype_outlined,
            options: ['mmol/L', 'mg/dL'],
            onSelect: (value) {
              ref.read(patientSettingsProvider.notifier).updateCholesterolUnit(value);
              Helpers.showSuccess(context, 'Cholesterol unit changed to $value');
            },
          ),
          const Divider(height: 24),

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

  Widget _buildAboutSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('About', Icons.info_outline),
          const SizedBox(height: 16),
          
          _buildInfoRow('App Version', _appVersion, Icons.phone_android),
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

  Widget _buildInteractiveSettingRow({
    required String title,
    required String currentValue,
    required IconData icon,
    required List<String> options,
    required Function(String) onSelect,
  }) {
    return InkWell(
      onTap: () => _showUnitSelectionModal(title, currentValue, options, onSelect),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.textSecondaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              currentValue,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  void _showUnitSelectionModal(
    String title,
    String currentValue,
    List<String> options,
    Function(String) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select $title',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...options.map((option) {
                  final isSelected = option == currentValue;
                  return ListTile(
                    title: Text(
                      option,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.primaryBlue : null,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryBlue) : null,
                    onTap: () {
                      onSelect(option);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryBlue),
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

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondaryColor),
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
            Icon(icon, size: 20, color: AppTheme.textSecondaryColor),
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
              Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondaryColor),
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
