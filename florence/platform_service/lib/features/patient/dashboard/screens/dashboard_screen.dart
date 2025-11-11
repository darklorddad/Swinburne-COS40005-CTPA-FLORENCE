import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../shared/widgets/notification_bell.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';
import '../../../../main.dart';
import '../widgets/health_summary_card.dart';
import '../widgets/quick_stats_grid.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/upcoming_reminders_card.dart';
import '../../core/services/patient_profile_service.dart';
import '../../core/providers/health_data_provider.dart';

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
    // Show a welcome message if passed via arguments from auth flow
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile switcher
                      _buildProfileSwitcher(),
                      const SizedBox(height: 16),

                      // Welcome header
                      _buildWelcomeHeader(),
                      const SizedBox(height: 24),

                      // Health summary card (hero card)
                      HealthSummaryCard(
                        latestGlucose: latestGlucose,
                        timestamp: latestGlucoseTime,
                        onTap: () => AppRoutes.push(context, AppRoutes.trends),
                      ),
                      const SizedBox(height: 16),

                      // AI Insight
                      _buildSectionHeader('Today\'s Insight'),
                      const SizedBox(height: 12),
                      AIInsightCard(
                        insight:
                            'Your glucose levels are most stable after morning walks. Consider a 15-minute walk after breakfast!',
                        onTap: () => AppRoutes.push(context, AppRoutes.recommendations),
                      ),
                      const SizedBox(height: 16),

                      // Quick stats grid
                      QuickStatsGrid(
                        averageGlucose: averageGlucose,
                        hba1c: hba1c,
                        todayReadings: todayReadings,
                        streakDays: streakDays,
                      ),
                      const SizedBox(height: 16),
              
              // Quick actions
              _buildSectionHeader('Quick Actions'),
              const SizedBox(height: 12),
              QuickActionsGrid(
                onLogGlucose:
                    () => AppRoutes.push(context, AppRoutes.logGlucose),
                onLogMeal: () => AppRoutes.push(context, AppRoutes.logMeal),
                onLogActivity:
                    () => AppRoutes.push(context, AppRoutes.logActivity),
                onLogMedication:
                    () => AppRoutes.push(context, AppRoutes.logMedication),
              ),
              const SizedBox(height: 16),

              // Weekly Summary
              _buildSectionHeader('Weekly Summary'),
              const SizedBox(height: 12),
              _buildWeeklySummaryCard(healthData),
              const SizedBox(height: 16),

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
                onViewAll:
                    () => AppRoutes.push(context, AppRoutes.notifications),
              ),
              const SizedBox(height: 24),
            ],
          ),
            ),
          ),
          // Loading overlay
          if (_isRefreshing)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Refreshing data...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Refresh data button
              FloatingActionButton(
                heroTag: 'refresh',
                onPressed: _isRefreshing ? null : _handleDataRefresh,
                tooltip: 'Refresh Data',
                backgroundColor: AppTheme.primaryBlue,
                child: Icon(_isRefreshing ? Icons.hourglass_empty : Icons.refresh),
              ),
              const SizedBox(height: 16),
              // Quick log button
              FloatingActionButton(
                heroTag: 'add',
                onPressed: _showQuickLogModal,
                tooltip: 'Quick Log',
                child: const Icon(Icons.add),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build profile switcher
  Widget _buildProfileSwitcher() {
    final currentProfile = _profileService.currentProfile;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.1),
            AppTheme.primaryBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science_outlined,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo Mode - Patient Profile',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentProfile.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Profile selection chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PatientProfileService.availableProfiles.map((profile) {
              final isSelected = profile.type == _profileService.currentProfileType;

              return ChoiceChip(
                label: Text(profile.name),
                selected: isSelected,
                onSelected: (_) => _handleProfileSwitch(profile.type),
                selectedColor: AppTheme.primaryBlue,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                avatar: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.white, size: 18)
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build app bar
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('BioTective Health'),
      actions: [
        const NotificationBell(),
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () => AppRoutes.push(context, AppRoutes.chat),
          tooltip: 'AI Health Assistant',
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => AppRoutes.push(context, AppRoutes.profile),
          tooltip: 'Profile',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') {
              _handleLogout();
            } else if (value == 'settings') {
              AppRoutes.push(context, AppRoutes.settings);
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined),
                      SizedBox(width: 12),
                      Text('Settings'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
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

  /// Build welcome header
  Widget _buildWelcomeHeader() {
    final greeting = _getGreeting();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 4),
        Text(
          _userName ?? 'Welcome',
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  /// Build weekly summary card
  Widget _buildWeeklySummaryCard(HealthDataProvider healthData) {
    final summary = healthData.last7DaysSummary;
    final timeInRange = summary.timeInRange;
    final avgGlucose = summary.averageGlucose;

    return Card(
      child: InkWell(
        onTap: () => AppRoutes.push(context, AppRoutes.weeklyReport),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 16),
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
      ),
    );
  }


  /// Build summary metric
  Widget _buildSummaryMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
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


