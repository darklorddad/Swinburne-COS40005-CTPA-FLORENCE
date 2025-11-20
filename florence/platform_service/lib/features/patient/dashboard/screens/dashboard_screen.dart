import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/notification_bell.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../main.dart';
import '../widgets/health_metric_card.dart';
import '../widgets/biometrics_section.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/health_metric_card.dart';
import '../../trends/screens/trends_screen.dart';
import '../providers/dashboard_providers.dart'; // Added

/// Home Dashboard Screen
/// Main hub showing health summary, quick actions, and insights
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _userName;
  bool _hasShownWelcomeMessage = false;
  int _loadUserRetries = 0;

  // Services
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserData();
      }
    });
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
    // This invalidates the state, forcing a re-fetch from the repositories
    ref.invalidate(monitorDataProvider);
    ref.invalidate(latestActivityProvider);
    ref.invalidate(patientThresholdsProvider);
    ref.invalidate(dailyPatientLogsProvider);
    // Wait for them to rebuild
    await Future.wait([
       ref.read(monitorDataProvider.future),
       ref.read(latestActivityProvider.future),
       ref.read(patientThresholdsProvider.future),
       ref.read(dailyPatientLogsProvider.future),
    ]);
  }

  /// Show quick log modal
  void _showQuickLogModal() {
    Helpers.showBottomSheet(context, child: _QuickLogModal());
  }

  @override
  Widget build(BuildContext context) {
    // Watch Riverpod providers
    final monitorData = ref.watch(monitorDataProvider).valueOrNull ?? [];
    final activity = ref.watch(latestActivityProvider).valueOrNull;
    final thresholds = ref.watch(patientThresholdsProvider).valueOrNull ?? [];
    final mealLogs = ref.watch(dailyPatientLogsProvider).valueOrNull ?? [];

    // Determine latest meal
    DailyPatientLog? latestMeal;
    if (mealLogs.isNotEmpty) {
      final sortedMeals = List<DailyPatientLog>.from(mealLogs);
      sortedMeals.sort((a, b) {
        final dateComp = a.logDate.compareTo(b.logDate);
        if (dateComp != 0) return dateComp;
        return _getMealTimePriority(a.mealTime).compareTo(_getMealTimePriority(b.mealTime));
      });
      latestMeal = sortedMeals.last;
    }
    
    // Define consistent spacing
    const double spacing = 20.0;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        edgeOffset: 0,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(spacing),
          children: [
            // AI Insight (Main Card)
            AIInsightCard(
              insight: 'Your glucose levels are most stable after morning walks. Consider a 15-minute walk after breakfast!',
              onTap: () => AppRoutes.push(context, AppRoutes.recommendations),
            ),
            const SizedBox(height: spacing),

            // Biometrics Section (Loaded via Riverpod)
            BiometricsSection(
              monitorData: monitorData,
              latestActivity: activity,
              latestMeal: latestMeal,
              thresholds: thresholds,
            ),
            const SizedBox(height: spacing),

            // Quick actions
            QuickActionsGrid(
              onLogGlucose: () => AppRoutes.push(context, AppRoutes.logGlucose),
              onLogMeal: () => AppRoutes.push(context, AppRoutes.logMeal),
              onLogActivity: () => AppRoutes.push(context, AppRoutes.logActivity),
              onLogMedication: () => AppRoutes.push(context, AppRoutes.logMedication),
            ),
            const SizedBox(height: spacing),
          ],
        ),
      ),
    );
  }


  /// Build app bar
  AppBar _buildAppBar(BuildContext context) {
    final monitorDataAsync = ref.watch(monitorDataProvider);
    final activityAsync = ref.watch(latestActivityProvider);
    final isLoading = monitorDataAsync.isLoading || activityAsync.isLoading;
    final borderColor = AppTheme.getBorderColor(context);

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
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2.0),
        child: isLoading
            ? const LinearProgressIndicator(minHeight: 2.0)
            : Container(
                color: borderColor,
                height: 1.0,
              ),
      ),
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

  int _getMealTimePriority(String time) {
    switch (time.toUpperCase()) {
      case 'BREAKFAST': return 1;
      case 'LUNCH': return 2;
      case 'DINNER': return 3;
      default: return 0;
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


