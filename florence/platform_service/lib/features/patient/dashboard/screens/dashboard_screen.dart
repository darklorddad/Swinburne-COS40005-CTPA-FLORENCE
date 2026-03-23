import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added

import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/layout/responsive_layout_system.dart';
import '../../../../shared/widgets/notification_bell.dart';
import '../../chat/services/chatbot_service.dart'; // Chat Service
import '../../core/models/health_data_models.dart';
import '../../core/providers/monitor_data_providers.dart' as core_data;
import '../../profile/providers/user_profile_provider.dart'; // Ensure this is imported
import '../providers/dashboard_providers.dart'; // Added
import '../widgets/ai_insight_card.dart';
import '../widgets/biometrics_section.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/todays_medications_card.dart';

// Model for Quick Actions to ensure consistency between Grid and Modal
class _QuickActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  const _QuickActionItem(this.label, this.icon, this.color, this.route);
}

/// Home Dashboard Screen
/// Main hub showing health summary, quick actions, and insights
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Local state for welcome message only
  bool _hasShownWelcomeMessage = false;
  // Track pull-to-refresh state to prevent double loading indicators
  bool _isPullRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Trigger initial chat fetch so it's ready when needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _safeLoadChatHistory();
    });
  }

  Future<void> _safeLoadChatHistory({bool force = false}) async {
    try {
      await ref.read(chatProvider.notifier).loadHistory(force: force);
    } catch (e) {
      debugPrint("Dashboard: Failed to load chat history (Non-critical): $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Handle refresh
  Future<void> _handleRefresh() async {
    setState(() => _isPullRefreshing = true);
    try {
      ref.invalidate(chatProvider);

      // 1. Fetch Profile First ("Prime" the backend)
      // This ensures the profile record exists and prevents race conditions on the heavy queries
      await ref.refresh(userProfileProvider.future);

      // 2. Fetch Data & Chat in Parallel (Safe now)
      await Future.wait([
        ref.refresh(core_data.monitorDataProvider.future),
        _safeLoadChatHistory(force: true),
      ]);
    } finally {
      if (mounted) {
        setState(() => _isPullRefreshing = false);
      }
    }
  }

  /// Show quick log modal
  void _showQuickLogModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickLogModal(actions: _getQuickActions()),
    );
  }

  List<_QuickActionItem> _getQuickActions() {
    return [
      const _QuickActionItem('Glucose', Icons.water_drop_rounded, Color(0xFFEF5350), AppRoutes.logGlucose), // Red
      const _QuickActionItem('B.Pressure', Icons.monitor_heart_outlined, Color(0xFFF50057), AppRoutes.logBloodPressure), // Magenta
      const _QuickActionItem('Diet', Icons.restaurant_outlined, Color(0xFFFFA726), AppRoutes.logMeal), // Orange
      const _QuickActionItem('Activity', Icons.directions_run_rounded, Color(0xFF66BB6A), AppRoutes.logActivity), // Green
      const _QuickActionItem('Meds', Icons.medication_outlined, Color(0xFF42A5F5), AppRoutes.addMedication), // Blue
      const _QuickActionItem('BMI', Icons.monitor_weight_outlined, Color(0xFF26A69A), AppRoutes.logBmi), // Teal
      const _QuickActionItem('Cholesterol', Icons.bloodtype_outlined, Color(0xFFAB47BC), AppRoutes.logCholesterol), // Purple
      const _QuickActionItem('HbA1c', Icons.pie_chart_outline, Color(0xFFFFCA28), AppRoutes.logHba1c), // Amber
    ];
  }

  @override
  Widget build(BuildContext context) {
    // 1. WATCH PROFILE (Triggers immediately)
    final userProfileAsync = ref.watch(userProfileProvider);

    // 2. WATCH DATA (Sequential Trigger)
    // Only trigger the heavy data fetch once we know who the user is.
    // This prevents the "Thundering Herd" of 403s on the backend.
    final healthDataState = userProfileAsync.hasValue 
        ? ref.watch(core_data.monitorDataProvider).asData?.value 
        : null;
    
    // Keep chat provider alive, but load history only after profile is ready
    ref.watch(chatProvider);
    if (userProfileAsync.hasValue) {
      // We use a post-frame callback inside a specialized widget or just let the 
      // initState/Refresh logic handle the explicit calls. 
      // The _handleRefresh logic above covers manual reloads. 
      // For initial load, we rely on the provider lifecycle.
    }
    
    // Derived values (will update automatically as healthDataState arrives)
    final activity = ref.watch(latestActivityProvider).asData?.value;
    final thresholds = ref.watch(patientThresholdsProvider).asData?.value ?? [];
    final mealLogs = ref.watch(dailyPatientLogsProvider).asData?.value ?? [];

    // Monitor Data now already includes meal glucose readings from the repository
    final combinedMonitorData = healthDataState?.allMonitorData ?? [];

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
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.all(spacing),
                  child: Column(
                    children: [
                      // Desktop: Row (Side-by-Side), Mobile: Column (Stacked)
                      if (context.isDesktop)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: AIInsightCard(
                                  insight:
                                      'Your glucose levels are most stable after morning walks. Consider a 15-minute walk after breakfast!',
                                  onTap: () => AppRoutes.push(
                                      context, AppRoutes.recommendations),
                                ),
                              ),
                              const SizedBox(width: spacing),
                              const Expanded(
                                child: TodaysMedicationsCard(),
                              ),
                              const SizedBox(width: spacing),
                              Expanded(
                                child: QuickActionsGrid(
                                  actions: _getQuickActions().map((a) => (
                                    label: a.label,
                                    icon: a.icon,
                                    color: a.color,
                                    onTap: () => AppRoutes.push(context, a.route)
                                  )).toList(),
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        AIInsightCard(
                          insight:
                              'Your glucose levels are most stable after morning walks. Consider a 15-minute walk after breakfast!',
                          onTap: () => AppRoutes.push(
                              context, AppRoutes.recommendations),
                        ),
                        const SizedBox(height: spacing),
                        const TodaysMedicationsCard(),
                        const SizedBox(height: spacing),
                        QuickActionsGrid(
                          actions: _getQuickActions().map((a) => (
                            label: a.label,
                            icon: a.icon,
                            color: a.color,
                            onTap: () => AppRoutes.push(context, a.route)
                          )).toList(),
                        ),
                      ],
                      const SizedBox(height: spacing),

                      // Biometrics Section (Loaded via Riverpod)
                      BiometricsSection(
                        monitorData: combinedMonitorData,
                        latestActivity: activity,
                        latestMeal: latestMeal,
                        thresholds: thresholds,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  /// Build app bar
  AppBar _buildAppBar(BuildContext context) {
    final monitorDataAsync = ref.watch(monitorDataProvider);
    final activityAsync = ref.watch(latestActivityProvider);
    // Only show linear progress if loading AND NOT controlled by pull-to-refresh
    final isLoading = (monitorDataAsync.isLoading || activityAsync.isLoading) && !_isPullRefreshing;
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
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => AppRoutes.push(context, AppRoutes.profile),
            tooltip: 'Profile',
          ),
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
  final List<_QuickActionItem> actions;

  const _QuickLogModal({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Prevents taking full height
            children: [
              // Handle
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
                'Log Health Data',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              // Actions Grid
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: actions.map((action) {
                  return _ModalActionButton(
                    action: action,
                    onTap: () {
                      Navigator.pop(context);
                      AppRoutes.push(context, action.route);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModalActionButton extends StatelessWidget {
  final _QuickActionItem action;
  final VoidCallback onTap;

  const _ModalActionButton({
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 48 - 48) / 4; // Approx 4 items per row minus spacing

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width.clamp(70.0, 100.0), // Min 70, Max 100
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: action.color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: action.color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                action.icon,
                color: action.color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
