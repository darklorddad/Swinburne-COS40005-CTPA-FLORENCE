import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/notification_bell.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';
import '../../../../main.dart';
import '../widgets/health_summary_card.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/upcoming_reminders_card.dart';
import '../../core/services/patient_profile_service.dart';
import '../../core/providers/health_data_provider.dart';

/// ============================================================================
/// RESPONSIVE UTILITIES
/// ============================================================================

extension ResponsiveExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;
  
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  
  const ResponsiveWrapper({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: context.responsive(
            mobile: double.infinity,
            tablet: 800,
            desktop: 1200,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// ============================================================================
/// RESPONSIVE DASHBOARD SCREEN
/// ============================================================================

/// Home Dashboard Screen
/// Main hub showing health summary, quick actions, and insights
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isRefreshing = false;
  String? _userName;
  bool _hasShownWelcomeMessage = false; // Add this flag

  // Services
  final PatientProfileService _profileService = PatientProfileService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _profileService.addListener(_onProfileChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Show a welcome message if passed via arguments from the splash screen
    if (!_hasShownWelcomeMessage) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['message'] != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Helpers.showSuccess(context, args['message']!);
        });
        _hasShownWelcomeMessage = true;
      }
    }
  }

  @override
  void dispose() {
    _profileService.removeListener(_onProfileChanged);
    super.dispose();
  }

  /// Handle profile changes
  void _onProfileChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Load user data
  Future<void> _loadUserData() async {
    try {
      // Try to get user from Supabase if available
      try {
        final user = supabase.auth.currentUser;
        if (user != null) {
          setState(() {
            _userName = user.userMetadata?['full_name'] ?? _profileService.currentProfile.name;
          });
        }
      } catch (e) {
        // If Supabase fails, use profile name
        setState(() {
          _userName = _profileService.currentProfile.name;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  /// Handle refresh
  Future<void> _handleRefresh() async {
    final healthDataProvider = context.read<HealthDataProvider>();
    await healthDataProvider.refreshData();
  }

  /// Handle data regeneration
  Future<void> _handleDataRefresh() async {
    setState(() => _isRefreshing = true);

    try {
      await _profileService.refreshCurrentProfile();

      if (mounted) {
        Helpers.showSuccess(context, 'Data refreshed successfully');
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to refresh data');
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  /// Handle profile switch
  Future<void> _handleProfileSwitch(PatientProfileType newProfile) async {
    if (_profileService.currentProfileType == newProfile) return;

    try {
      await _profileService.switchProfile(newProfile);

      if (mounted) {
        Helpers.showSuccess(
          context,
          'Switched to ${_profileService.currentProfile.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to switch profile');
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
          Helpers.showError(context, 'Failed to sign out');
        }
      }
    }
  }

  /// Show quick log modal
  void _showQuickLogModal() {
    Helpers.showBottomSheet(context, child: _QuickLogModal());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthDataProvider>(
      builder: (context, healthData, child) {
        // Calculate stats from provider
        final latestGlucose = healthData.latestGlucose?.value ?? 0.0;
        final latestGlucoseTime = healthData.latestGlucose?.timestamp ?? DateTime.now();
        final averageGlucose = healthData.getAverageGlucose(
          startDate: DateTime.now().subtract(const Duration(days: 7)),
        );
        final hba1c = healthData.latestHbA1c?.value ?? _profileService.currentProfile.targetHbA1c;
        final todayReadings = healthData.getGlucoseReadings(
          startDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
        ).length;
        const streakDays = 7; // TODO: Implement streak calculation

        return Scaffold(
          appBar: _buildAppBar(),
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ResponsiveWrapper(
                    child: Padding(
                      padding: EdgeInsets.all(
                        context.responsive(
                          mobile: 16.0,
                          tablet: 24.0,
                          desktop: 32.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile switcher
                          _buildProfileSwitcher(),
                          SizedBox(height: context.responsive(mobile: 16.0, desktop: 20.0)),

                          // Welcome header
                          _buildWelcomeHeader(),
                          SizedBox(height: context.responsive(mobile: 24.0, desktop: 32.0)),

                          // Health summary card (hero card)
                          HealthSummaryCard(
                            latestGlucose: latestGlucose,
                            timestamp: latestGlucoseTime,
                            onTap: () => AppRoutes.push(context, AppRoutes.trends),
                          ),
                          SizedBox(height: context.responsive(mobile: 16.0, desktop: 24.0)),

                          // AI Insight
                          _buildSectionHeader('Today\'s Insight'),
                          const SizedBox(height: 12),
                          AIInsightCard(
                            insight:
                                'Your glucose levels are most stable after morning walks. Consider a 15-minute walk after breakfast!',
                            onTap: () => AppRoutes.push(context, AppRoutes.recommendations),
                          ),
                          SizedBox(height: context.responsive(mobile: 16.0, desktop: 24.0)),

                          // Quick stats grid - RESPONSIVE
                          _buildResponsiveStatsGrid(
                            averageGlucose: averageGlucose,
                            hba1c: hba1c,
                            todayReadings: todayReadings,
                            streakDays: streakDays,
                          ),
                          SizedBox(height: context.responsive(mobile: 16.0, desktop: 24.0)),
                  
                          // Quick actions - RESPONSIVE
                          _buildSectionHeader('Quick Actions'),
                          const SizedBox(height: 12),
                          _buildResponsiveQuickActions(),
                          SizedBox(height: context.responsive(mobile: 16.0, desktop: 24.0)),

                          // Weekly Summary - RESPONSIVE
                          _buildSectionHeader('Weekly Summary'),
                          const SizedBox(height: 12),
                          _buildResponsiveWeeklySummary(healthData),
                          SizedBox(height: context.responsive(mobile: 16.0, desktop: 24.0)),

                          // Upcoming reminders
                          _buildSectionHeader('Upcoming Reminders'),
                          const SizedBox(height: 12),
                          UpcomingRemindersCard(
                            reminders: [
                              {
                                'title': 'Log Glucose',
                                'time': '2:00 PM',
                                'icon': Icons.water_drop,
                              },
                              {
                                'title': 'Take Medication',
                                'time': '4:00 PM',
                                'icon': Icons.medication,
                              },
                              {
                                'title': 'Evening Walk',
                                'time': '6:00 PM',
                                'icon': Icons.directions_walk,
                              },
                            ],
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Refresh button
              if (_isRefreshing)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showQuickLogModal,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  /// Build responsive stats grid
  Widget _buildResponsiveStatsGrid({
    required double averageGlucose,
    required double hba1c,
    required int todayReadings,
    required int streakDays,
  }) {
    // Use LayoutBuilder to get available width
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine number of columns based on screen width
        final crossAxisCount = context.responsive(
          mobile: 2,
          tablet: 2,
          desktop: 4,
        );

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: context.responsive(
            mobile: 1.3,
            tablet: 1.4,
            desktop: 1.2,
          ),
          children: [
            _buildStatCard(
              icon: Icons.show_chart,
              iconColor: AppTheme.primaryBlue,
              label: 'Avg Glucose',
              value: averageGlucose.toStringAsFixed(0),
              unit: 'mg/dL',
            ),
            _buildStatCard(
              icon: Icons.pie_chart,
              iconColor: AppTheme.primaryGreen,
              label: 'HbA1c',
              value: hba1c.toStringAsFixed(1),
              unit: '%',
            ),
            _buildStatCard(
              icon: Icons.water_drop,
              iconColor: AppTheme.mealColor,
              label: 'Today\'s Logs',
              value: '$todayReadings',
              unit: 'readings',
            ),
            _buildStatCard(
              icon: Icons.local_fire_department,
              iconColor: AppTheme.primaryRed,
              label: 'Streak',
              value: '$streakDays',
              unit: 'days',
            ),
          ],
        );
      },
    );
  }

  /// Build stat card
  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build responsive quick actions
  Widget _buildResponsiveQuickActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = context.responsive(
          mobile: 2,
          tablet: 2,
          desktop: 4,
        );

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: context.responsive(
            mobile: 1.1,
            tablet: 1.3,
            desktop: 1.2,
          ),
          children: [
            _buildQuickActionCard(
              icon: Icons.water_drop,
              label: 'Log Glucose',
              subtitle: 'Track blood sugar',
              color: AppTheme.primaryRed,
              onTap: () => AppRoutes.push(context, AppRoutes.logGlucose),
            ),
            _buildQuickActionCard(
              icon: Icons.restaurant,
              label: 'Log Meal',
              subtitle: 'Record what you ate',
              color: AppTheme.mealColor,
              onTap: () => AppRoutes.push(context, AppRoutes.logMeal),
            ),
            _buildQuickActionCard(
              icon: Icons.directions_run,
              label: 'Log Activity',
              subtitle: 'Track exercise',
              color: AppTheme.activityColor,
              onTap: () => AppRoutes.push(context, AppRoutes.logActivity),
            ),
            _buildQuickActionCard(
              icon: Icons.medication,
              label: 'Log Medication',
              subtitle: 'Record medicines',
              color: AppTheme.medicationColor,
              onTap: () => AppRoutes.push(context, AppRoutes.logMedication),
            ),
          ],
        );
      },
    );
  }

  /// Build quick action card
  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  /// Build responsive weekly summary
  Widget _buildResponsiveWeeklySummary(HealthDataProvider healthData) {
    final timeInRange = healthData.getTimeInRange(
      startDate: DateTime.now().subtract(const Duration(days: 7)),
    );
    final avgGlucose = healthData.getAverageGlucose(
      startDate: DateTime.now().subtract(const Duration(days: 7)),
    );

    return InkWell(
      onTap: () => AppRoutes.push(context, AppRoutes.trends),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(
          context.responsive(mobile: 16.0, desktop: 20.0),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.summarize,
                    color: AppTheme.accentPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This Week\'s Progress',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tap to view detailed report',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondaryColor,
                ),
              ],
            ),
            SizedBox(height: context.responsive(mobile: 16.0, desktop: 20.0)),
            
            // Responsive metrics layout
            if (context.isMobile)
              // Mobile: Stack vertically
              Column(
                children: [
                  _buildSummaryMetric(
                    'Time in Range',
                    '${timeInRange.toStringAsFixed(0)}%',
                    timeInRange >= 70
                        ? AppTheme.primaryGreen
                        : timeInRange >= 50
                            ? AppTheme.warningColor
                            : AppTheme.errorColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  _buildSummaryMetric(
                    'Avg Glucose',
                    '${avgGlucose.toStringAsFixed(0)} mg/dL',
                    AppTheme.primaryBlue,
                  ),
                ],
              )
            else
              // Tablet/Desktop: Side by side
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryMetric(
                      'Time in Range',
                      '${timeInRange.toStringAsFixed(0)}%',
                      timeInRange >= 70
                          ? AppTheme.primaryGreen
                          : timeInRange >= 50
                              ? AppTheme.warningColor
                              : AppTheme.errorColor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  Expanded(
                    child: _buildSummaryMetric(
                      'Avg Glucose',
                      '${avgGlucose.toStringAsFixed(0)} mg/dL',
                      AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Florence'),
      actions: [
        const NotificationBell(),
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () => AppRoutes.push(context, AppRoutes.chat),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.person),
          onSelected: (value) {
            if (value == 'logout') {
              _handleLogout();
            } else if (value == 'profile') {
              AppRoutes.push(context, AppRoutes.profile);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 12),
                  Text('Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20),
                  SizedBox(width: 12),
                  Text('Sign Out'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build profile switcher
  Widget _buildProfileSwitcher() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Demo Mode - Patient Profile',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _profileService.currentProfile.description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PatientProfileType.values.map((type) {
              final isSelected = _profileService.currentProfileType == type;
              // Get profile from static list
              final profile = PatientProfileService.availableProfiles.firstWhere(
                (p) => p.type == type,
              );
              
              return ActionChip(
                label: Text(profile.name),
                onPressed: () => _handleProfileSwitch(type),
                backgroundColor: isSelected ? AppTheme.primaryBlue : Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
                ),
                avatar: isSelected
                    ? const Icon(Icons.check_circle, size: 16, color: Colors.white)
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build welcome header
  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getGreeting(),
          style: TextStyle(
            fontSize: context.responsive(mobile: 14.0, desktop: 16.0),
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _userName ?? _profileService.currentProfile.name,
          style: TextStyle(
            fontSize: context.responsive(mobile: 24.0, desktop: 28.0),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build summary metric
  Widget _buildSummaryMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: context.responsive(mobile: 20.0, desktop: 24.0),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Get greeting based on time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
}

/// Quick log modal
class _QuickLogModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Quick Log',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Action buttons
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _QuickLogButton(
                icon: Icons.water_drop,
                label: 'Glucose',
                color: AppTheme.primaryRed,
                onTap: () {
                  Navigator.pop(context);
                  AppRoutes.push(context, AppRoutes.logGlucose);
                },
              ),
              _QuickLogButton(
                icon: Icons.restaurant,
                label: 'Meal',
                color: AppTheme.mealColor,
                onTap: () {
                  Navigator.pop(context);
                  AppRoutes.push(context, AppRoutes.logMeal);
                },
              ),
              _QuickLogButton(
                icon: Icons.directions_run,
                label: 'Activity',
                color: AppTheme.activityColor,
                onTap: () {
                  Navigator.pop(context);
                  AppRoutes.push(context, AppRoutes.logActivity);
                },
              ),
              _QuickLogButton(
                icon: Icons.medication,
                label: 'Medication',
                color: AppTheme.medicationColor,
                onTap: () {
                  Navigator.pop(context);
                  AppRoutes.push(context, AppRoutes.logMedication);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Quick log button widget
class _QuickLogButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickLogButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
