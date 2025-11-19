import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/notification_bell.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';
import '../../../../main.dart';
import '../widgets/health_metric_card.dart';
import '../widgets/biometrics_section.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/ai_insight_card.dart';

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
  int _loadUserRetries = 0;

  // Services
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure the widget is built before calling
    // methods that will trigger a rebuild or state change. This avoids the
    // "setState() or markNeedsBuild() called during build" error and ensures
    // the auth token is available from the navigation event.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HealthDataProvider>().initialize();
        _loadUserData();
      }
    });
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
    super.dispose();
  }

  /// Load user data
  Future<void> _loadUserData() async {
    try {
      // Fetch the full profile from the backend API
      final profile = await _apiService.get('/patients/me');
      if (mounted) {
        setState(() {
          _userName = profile['name'] as String? ?? 'Patient';
          _loadUserRetries = 0; // Reset on success
        });
      }
    } catch (e) {
      debugPrint('Error loading user data for dashboard: $e');

      final user = supabase.auth.currentUser;
      final isNewUser = user != null &&
          user.createdAt != null &&
          DateTime.now().difference(DateTime.parse(user.createdAt!)).inMinutes < 2;

      // If it's a new user and the profile isn't found yet, retry up to 2 times.
      if (isNewUser && e.toString().contains('Access denied') && _loadUserRetries < 2) {
        _loadUserRetries++;
        debugPrint('Dashboard: Patient profile not found for new user. Retry attempt #$_loadUserRetries...');
        await Future.delayed(const Duration(seconds: 3));
        await _loadUserData(); // Recursive retry
      } else {
        // Fallback to a generic name if API fails after retries or for other errors
        if (mounted) {
          setState(() {
            _userName = 'Patient';
          });
        }
      }
    }
  }

  /// Handle refresh
  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    final healthDataProvider = context.read<HealthDataProvider>();
    await healthDataProvider.refreshData();
    if (mounted) {
      setState(() => _isRefreshing = false);
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
    final settingsProvider = context.watch<SettingsProvider>();
    return Consumer<HealthDataProvider>(
      builder: (context, healthData, child) {
        return Scaffold(
          appBar: _buildAppBar(),
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildWelcomeHeader(),
                      ),
                      const SizedBox(height: 24),

                      // AI Insight (Main Card)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildSectionHeader('Today\'s Insight'),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AIInsightCard(
                          insight:
                              'Your glucose levels are most stable after morning walks. Consider a 15-minute walk after breakfast!',
                          onTap: () => AppRoutes.push(context, AppRoutes.recommendations),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Biometrics Section (Health Monitor)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: BiometricsSection(healthData: healthData),
                      ),
                      const SizedBox(height: 24),

                      // Quick actions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildSectionHeader('Quick Actions'),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: QuickActionsGrid(
                          onLogGlucose:
                              () => AppRoutes.push(context, AppRoutes.logGlucose),
                          onLogMeal: () => AppRoutes.push(context, AppRoutes.logMeal),
                          onLogActivity:
                              () => AppRoutes.push(context, AppRoutes.logActivity),
                          onLogMedication:
                              () => AppRoutes.push(context, AppRoutes.logMedication),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              // Loading overlay
              if (_isRefreshing)
                Container(
                  color: Colors.black.withOpacity(0.3),
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
        );
      },
    );
  }


  /// Build app bar
  AppBar _buildAppBar() {
    return AppBar(
      title: InkWell(
        onTap: _handleRefresh,
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text('Florence'),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _showQuickLogModal,
          tooltip: 'Quick Log',
        ),
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



  // --- Health Metric Helpers ---

  Color _getGlucoseColor(double? value) {
    if (value == null) return AppTheme.textSecondaryColor;
    if (value < 70) return AppTheme.glucoseLow;
    if (value > 180) return AppTheme.glucoseHigh;
    return AppTheme.glucoseNormal;
  }

  String _getGlucoseStatus(double? value) {
    if (value == null) return 'N/A';
    if (value < 70) return 'Low';
    if (value > 180) return 'High';
    return 'Normal';
  }

  Color _getBPColor(double systolic, double diastolic) {
    if (systolic > 140 || diastolic > 90) return AppTheme.errorColor;
    if (systolic > 120 || diastolic > 80) return AppTheme.warningColor;
    return AppTheme.primaryGreen;
  }

  String _getBPStatus(double systolic, double diastolic) {
    if (systolic > 140 || diastolic > 90) return 'High';
    if (systolic > 120 || diastolic > 80) return 'Elevated';
    return 'Normal';
  }

  Color _getHba1cColor(double value) {
    if (value >= 7.0) return AppTheme.errorColor;
    if (value >= 6.5) return AppTheme.warningColor;
    return AppTheme.primaryGreen;
  }

  Color _getCholesterolColor(double value) {
    if (value >= 240) return AppTheme.errorColor;
    if (value >= 200) return AppTheme.warningColor;
    return AppTheme.primaryGreen;
  }

  String _getCholesterolStatus(double value) {
    if (value >= 240) return 'High';
    if (value >= 200) return 'Borderline';
    return 'Desirable';
  }

  Color _getBmiColor(double value) {
    if (value < 18.5 || value >= 30) return AppTheme.errorColor;
    if (value >= 25) return AppTheme.warningColor;
    return AppTheme.primaryGreen;
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
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
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
                icon: Icons.monitor_heart,
                label: 'Blood Pressure',
                color: AppTheme.primaryRed,
                onTap: () {
                  Navigator.pop(context);
                  AppRoutes.push(context, AppRoutes.logBloodPressure);
                },
              ),
              _QuickLogButton(
                icon: Icons.bloodtype,
                label: 'Cholesterol',
                color: AppTheme.accentPurple,
                onTap: () {
                  Navigator.pop(context);
                  AppRoutes.push(context, AppRoutes.logCholesterol);
                },
              ),
              _QuickLogButton(
                icon: Icons.height,
                label: 'BMI',
                color: AppTheme.primaryGreen,
                onTap: () {
                  Navigator.pop(context);
                  AppRoutes.push(context, AppRoutes.logBmi);
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
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


