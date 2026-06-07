import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:florence/features/patient/recommendations/services/recommendation_engine.dart';
import 'package:florence/features/patient/recommendations/models/recommendation_models.dart';
import 'package:florence/features/patient/core/providers/monitor_data_providers.dart' as core_data;
import 'package:florence/features/patient/core/repositories/monitor_data_repository.dart' as core_repo;
import 'package:florence/core/utils/helpers.dart';
import 'package:florence/config/theme.dart';

// ══════════════════════════════════════════════════════════════
// CATEGORY THEME DEFINITIONS
// ══════════════════════════════════════════════════════════════

class _CatTheme {
  final Color primary;
  final Color secondary;
  final IconData icon;

  const _CatTheme({
    required this.primary,
    required this.secondary,
    required this.icon,
  });

  Color get tag       => primary.withValues(alpha: 0.10);
  Color get tagBorder => primary.withValues(alpha: 0.22);
}

const _kThemes = {
  RecommendationCategory.sleep: _CatTheme(
    primary: Color(0xFFA78BFA),
    secondary: Color(0xFF7C3AED),
    icon: Icons.bedtime_outlined,
  ),
  RecommendationCategory.meal: _CatTheme(
    primary: Color(0xFFFBBF24),
    secondary: Color(0xFFD97706),
    icon: Icons.restaurant_outlined,
  ),
  RecommendationCategory.activity: _CatTheme(
    primary: Color(0xFF10B981),
    secondary: Color(0xFF059669),
    icon: Icons.directions_run_rounded,
  ),
  RecommendationCategory.lifestyle: _CatTheme(
    primary: Color(0xFF818CF8),
    secondary: Color(0xFF4F46E5),
    icon: Icons.self_improvement_rounded,
  ),
  RecommendationCategory.timing: _CatTheme(
    primary: Color(0xFF38BDF8),
    secondary: Color(0xFF0284C7),
    icon: Icons.access_time_outlined,
  ),
  RecommendationCategory.medication: _CatTheme(
    primary: Color(0xFF2563EB),
    secondary: Color(0xFF1D4ED8),
    icon: Icons.medication_outlined,
  ),
};

_CatTheme _themeFor(RecommendationCategory cat) =>
    _kThemes[cat] ?? _kThemes[RecommendationCategory.lifestyle]!;

String _dataSourceLabel(String type) {
  const labels = {
    // Glucose
    'average_glucose': 'Glucose',
    'glucose': 'Glucose',
    'hyper_events': 'Glucose',
    'hypo_events': 'Glucose',
    'time_in_range': 'Glucose',
    'estimated_a1c': 'HbA1c',
    'hba1c': 'HbA1c',
    'latest_hba1c': 'HbA1c',
    // Activity & meals
    'total_activity_minutes': 'Activity',
    'activity': 'Activity',
    'average_calories': 'Meal',
    'calories': 'Meal',
    'meal': 'Meal',
    // Medication & diagnosis
    'medication_adherence': 'Medication',
    'medication': 'Medication',
    'current_medications': 'Medication',
    'active_diseases': 'Diagnosis',
    'disease': 'Diagnosis',
    'diagnosis': 'Diagnosis',
    // Vitals
    'latest_bmi': 'BMI',
    'bmi': 'BMI',
    'latest_systolic': 'BP',
    'latest_diastolic': 'BP',
    'blood_pressure': 'BP',
    // Cholesterol breakdown
    'latest_cholesterol': 'Cholesterol',
    'cholesterol': 'Cholesterol',
    'latest_hdl': 'HDL',
    'hdl': 'HDL',
    'latest_ldl': 'LDL',
    'ldl': 'LDL',
    'latest_triglycerides': 'Triglycerides',
    'triglycerides': 'Triglycerides',
  };
  final key = type.toLowerCase();
  if (labels.containsKey(key)) return labels[key]!;
  return type
      .replaceAll('_', ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

// ══════════════════════════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════════════════════════

/// Computes a clinical 0-100 score based on actual health metrics
int _computeVitalityIndex(core_repo.HealthDataState? data) {
  if (data == null) return 50; // Neutral default while loading

  final summary = data.getHealthSummary(
    startDate: DateTime.now().subtract(const Duration(days: 7)),
    endDate: DateTime.now(),
  );

  // 1. True Zero: If completely inactive, score is 0
  final totalLogs = summary.totalReadings + summary.totalMeals + (summary.totalActivityMinutes > 0 ? 1 : 0);
  if (totalLogs == 0) return 0; 

  // 2. Glucose Control (40 points)
  final glucoseScore = (summary.timeInRange / 100.0) * 40.0;

  // 3. Physical Activity (15 points) - Target: 150 minutes per week
  final activityScore = (summary.totalActivityMinutes / 150.0).clamp(0.0, 1.0) * 15.0;

  // 4. Medication Adherence (20 points)
  double adherenceScore = 20.0; // Full points if no medications are prescribed
  if (summary.currentMedications.isNotEmpty) {
    adherenceScore = summary.medicationAdherence * 20.0;
  }

  // 5. Engagement & Consistency (25 points) - Rewards the habit of tracking (~14 logs/week)
  final engagementScore = (totalLogs / 14.0).clamp(0.0, 1.0) * 25.0;

  // Calculate final score (guaranteed 0 to 100)
  final rawScore = glucoseScore + activityScore + adherenceScore + engagementScore;
  return rawScore.clamp(0, 100).round();
}

/// Returns (ringStart, ringEnd, stateLabel).
(Color, Color, String) _scoreState(int score) {
  if (score >= 75) return (const Color(0xFF22D3EE), const Color(0xFF10B981), 'Thriving');
  if (score >= 50) return (const Color(0xFF38BDF8), const Color(0xFF4F46E5), 'Rising');
  if (score >= 30) return (const Color(0xFFFBBF24), const Color(0xFFF59E0B), 'Straining');
  return (const Color(0xFFF87171), const Color(0xFFEF4444), 'Depleted');
}

int _priorityOrder(RecommendationPriority p) {
  switch (p) {
    case RecommendationPriority.urgent: return 0;
    case RecommendationPriority.high:   return 1;
    case RecommendationPriority.medium: return 2;
    case RecommendationPriority.low:    return 3;
  }
}

String _urgencyLabel(RecommendationPriority p) {
  switch (p) {
    case RecommendationPriority.urgent: return 'URGENT';
    case RecommendationPriority.high:   return 'IMPORTANT';
    case RecommendationPriority.medium: return 'MODERATE';
    case RecommendationPriority.low:    return 'ON TRACK';
  }
}

Color _urgencyColor(RecommendationPriority p) {
  switch (p) {
    case RecommendationPriority.urgent: return AppTheme.errorColor;
    case RecommendationPriority.high:   return AppTheme.warningColor;
    case RecommendationPriority.medium: return AppTheme.infoColor;
    case RecommendationPriority.low:    return AppTheme.successColor;
  }
}

double _priorityFill(RecommendationPriority p) {
  switch (p) {
    case RecommendationPriority.urgent: return 0.95;
    case RecommendationPriority.high:   return 0.72;
    case RecommendationPriority.medium: return 0.50;
    case RecommendationPriority.low:    return 0.28;
  }
}

// ══════════════════════════════════════════════════════════════
// SCREEN
// ══════════════════════════════════════════════════════════════

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState
    extends ConsumerState<RecommendationsScreen>
    with TickerProviderStateMixin {

  bool _isGenerating = false;
  String? _expandedId;
  int _streakDays = 0;
  bool _celebTriggered = false;

  late final AnimationController _scoreCtrl;
  late final AnimationController _staggerCtrl;
  late final AnimationController _celebCtrl;
  late final Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _scoreCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _scoreAnim = CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic);

    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();

    _celebCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoad();
      _updateStreak();
    });
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _staggerCtrl.dispose();
    _celebCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStr = prefs.getString('recs_last_visit');
    final now = DateTime.now();
    // Strip time from "now" so the difference calculation is purely day-to-day
    final today = DateTime(now.year, now.month, now.day);

    if (lastStr == null) {
      _streakDays = 1;
    } else {
      final lastTime = DateTime.parse(lastStr);
      final lastDay = DateTime(lastTime.year, lastTime.month, lastTime.day);
      final diff = today.difference(lastDay).inDays;
      
      if (diff == 0) {
        _streakDays = prefs.getInt('recs_streak') ?? 1;
        return; // Already visited today, no need to save again
      } else if (diff == 1) {
        _streakDays = (prefs.getInt('recs_streak') ?? 0) + 1;
      } else {
        _streakDays = 1;
      }
    }
    await prefs.setString('recs_last_visit', now.toIso8601String());
    await prefs.setInt('recs_streak', _streakDays);
    if (mounted) setState(() {});
  }

  String _freshnessLabel(DateTime generatedAt) {
    final diff = DateTime.now().difference(generatedAt);
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return 'Updated ${diff.inHours}h ago';
    if (diff.inHours < 48)   return 'Updated yesterday';
    return 'Stale · tap to refresh';
  }

  Future<void> _checkAndLoad() async {
    try {
      // WAIT for the database fetch to complete first!
      final recs = await ref.read(recommendationProvider.future);
      if (!mounted) return;

      // Get latest data timestamp
      final healthData = await ref.read(core_data.monitorDataProvider.future);
      DateTime? latestDataTime;
      if (healthData != null) {
        final times = <DateTime>[];
        // The data repository sorts descending (newest first), so .first is the most recent item
        if (healthData.allMonitorData.isNotEmpty) times.add(healthData.allMonitorData.first.measuredAt);
        if (healthData.meals.isNotEmpty) times.add(healthData.meals.first.timestamp);
        if (healthData.activities.isNotEmpty) times.add(healthData.activities.first.startTime);
        
        if (times.isNotEmpty) {
          // Force all to UTC to prevent local timezone parsing bugs
          final utcTimes = times.map((t) => t.isUtc ? t : t.toUtc()).toList();
          utcTimes.sort((a, b) => b.compareTo(a));
          latestDataTime = utcTimes.first;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final lastDailyCheckStr = prefs.getString('last_daily_ai_check');
      final lastWeeklyCheckStr = prefs.getString('last_weekly_ai_check');
      
      // Parse and force UTC
      DateTime? lastDailyCheck = lastDailyCheckStr != null ? DateTime.parse(lastDailyCheckStr) : null;
      if (lastDailyCheck != null && !lastDailyCheck.isUtc) lastDailyCheck = lastDailyCheck.toUtc();
      
      DateTime? lastWeeklyCheck = lastWeeklyCheckStr != null ? DateTime.parse(lastWeeklyCheckStr) : null;
      if (lastWeeklyCheck != null && !lastWeeklyCheck.isUtc) lastWeeklyCheck = lastWeeklyCheck.toUtc();

      final nowUtc = DateTime.now().toUtc();

      // Needs Daily if: never checked, checked >24h ago, or new data was logged AFTER the last check
      bool needsDaily = lastDailyCheck == null ||
          nowUtc.difference(lastDailyCheck).inHours >= 24 ||
          (latestDataTime != null && latestDataTime.isAfter(lastDailyCheck));

      bool needsWeekly = lastWeeklyCheck == null ||
          nowUtc.difference(lastWeeklyCheck).inDays >= 7;

      debugPrint('[Recommendations] CheckAndLoad: needsDaily=$needsDaily, needsWeekly=$needsWeekly');

      bool generatedAny = false;
      if (needsDaily) {
        await _generateRecommendations(timeframe: 'daily', hideToast: true);
        generatedAny = true;
      }
      if (needsWeekly && mounted) {
        await _generateRecommendations(timeframe: 'weekly', hideToast: true);
        generatedAny = true;
      }

      if (!generatedAny && mounted) {
        _scoreCtrl.forward();
      }
    } catch (e) {
      debugPrint("Failed to load initial recommendations: $e");
    }
  }

  Future<void> _generateRecommendations({required String timeframe, bool hideToast = false}) async {
    if (!mounted) return;
    setState(() => _isGenerating = true);
    _scoreCtrl.reset();
    try {
      final usedAI = await ref
          .read(recommendationProvider.notifier)
          .generateRecommendations(timeframe: timeframe);
      
      if (!mounted) return; // Prevent setState after dispose
      
      _staggerCtrl.forward(from: 0);
      _scoreCtrl.forward();
      if (!hideToast) {
        if (usedAI) {
          Helpers.showSuccess(context, '${timeframe[0].toUpperCase()}${timeframe.substring(1)} AI analysis complete');
        } else {
          Helpers.showWarning(context, 'AI unavailable — showing general recommendations');
        }
      }
    } catch (_) {
      if (mounted && !hideToast) Helpers.showError(context, 'Failed to generate insights');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _maybeCelebrate(int score) {
    if (!_celebTriggered && score >= 75 && _streakDays >= 2) {
      _celebTriggered = true;
      _celebCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recsAsync = ref.watch(recommendationProvider);

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Insights'),
        elevation: 0,
        centerTitle: false,
        actions: [
          if (_streakDays > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      '$_streakDays-day streak',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showInfoDialog,
              tooltip: 'About Insights',
            ),
          ),
        ],
        bottom: _isGenerating || recsAsync.isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2.0),
                child: LinearProgressIndicator(minHeight: 2.0),
              )
            : PreferredSize(
                preferredSize: const Size.fromHeight(1.0),
                child: Container(
                  color: AppTheme.getBorderColor(context),
                  height: 1.0,
                ),
              ),
      ),
      body: recsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (recs) {
          final active = recs.where((r) => r.isActive).toList();
          final history = recs.where((r) => !r.isActive).toList()
            ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
          
          // Use Clinical Calculation for Vitality Index
          final score = _computeVitalityIndex(ref.watch(core_data.monitorDataProvider).value);
          final (ringStart, ringEnd, stateLabel) = _scoreState(score);

          WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCelebrate(score));

          final filtered = active;

          final dailyRecs = filtered.where((r) => r.timeframe == 'daily').toList();
          final weeklyRecs = filtered.where((r) => r.timeframe == 'weekly').toList();

          return Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      // Pull-to-refresh: Sync existing recommendations and health data from DB
                      // WITHOUT triggering a new LLM generation.
                      ref.invalidate(recommendationProvider);
                      ref.invalidate(core_data.monitorDataProvider);

                      // Wait for the database fetch to complete before stopping the spinner
                      await ref.read(recommendationProvider.future);
                    },
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.getSurfaceColor(context),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.getBorderColor(context)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. INDEX
                              _buildVitalityIndex(score, active, ringStart, ringEnd, stateLabel),
                              
                              Divider(height: 1, color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
                              
                              // 2. RECOMMENDATIONS
                              _buildSectionHeader(active.length, recs, active),
                              if (filtered.isEmpty && !_isGenerating)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                                  child: _buildEmptyHint(),
                                ),
                              
                              if (dailyRecs.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(24, 12, 24, 8),
                                  child: Text("Daily Recommendations", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                                ...dailyRecs.asMap().entries.map((e) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                  child: _buildRecCard(e.value, e.key),
                                )),
                              ],

                              if (weeklyRecs.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(24, 12, 24, 8),
                                  child: Text("Weekly Action Plan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                                ...weeklyRecs.asMap().entries.map((e) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                  child: _buildRecCard(e.value, dailyRecs.length + e.key),
                                )),
                              ],

                              if (dailyRecs.isNotEmpty || weeklyRecs.isNotEmpty || (filtered.isEmpty && !_isGenerating))
                                const SizedBox(height: 20),

                              // 3. HISTORY
                              if (history.isNotEmpty) ...[
                                Divider(height: 1, color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
                                _RecommendationHistorySection(history: history),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Celebration particles overlay
              if (!_celebTriggered || _celebCtrl.isAnimating)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _celebCtrl,
                    builder: (_, __) {
                      if (_celebCtrl.value == 0) return const SizedBox.shrink();
                      return CustomPaint(
                        painter: _ParticlePainter(
                          progress: _celebCtrl.value,
                          ringStart: ringStart,
                          ringEnd: ringEnd,
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── Vitality Index ────────────────────────────────────────────
  Widget _buildVitalityIndex(
    int score,
    List<HealthRecommendation> active,
    Color ringStart,
    Color ringEnd,
    String stateLabel,
  ) {
    final count = active.length;
    final stateIcon = score >= 50 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Padding(
      padding: const EdgeInsets.all(24), // Standardised to 24px
      child: Column(
        children: [
          // "VITALITY INDEX" label
          Text(
            'VITALITY INDEX',
            style: TextStyle(
              color: AppTheme.getTextSecondaryColor(context),
              fontSize: 11,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Score ring (centred, larger)
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: AnimatedBuilder(
                animation: _scoreAnim,
                builder: (_, __) => CustomPaint(
                  painter: _ScoreRingPainter(
                    progress: _scoreAnim.value * score / 100,
                    displayScore: (score * _scoreAnim.value).round(),
                    ringStart: ringStart,
                    ringEnd: ringEnd,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),

          // State pill + streak row
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            children: [
              // State pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ringStart.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(stateIcon, size: 14, color: ringStart),
                    const SizedBox(width: 4),
                    Text(
                      stateLabel,
                      style: TextStyle(
                        color: ringStart,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description text (centred)
          active.isEmpty
              ? Text(
                  score == 0 
                      ? 'Start logging your health data to generate your index and insights.' 
                      : 'You\'re all caught up! No active recommendations.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.getTextSecondaryColor(context),
                        height: 1.5,
                      ),
                )
              : Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.getTextSecondaryColor(context),
                          height: 1.5,
                        ),
                    children: [
                      const TextSpan(text: 'You have '),
                      TextSpan(
                        text: '$count active health signal${count == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: '. Review each for personalised guidance.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
        ],
      ),
    );
  }

  // ── Section header (with inline refresh actions) ─────
  Widget _buildSectionHeader(
      int count, List<HealthRecommendation> recs, List<HealthRecommendation> active) {
    final generatedAt = recs.isNotEmpty ? recs.first.generatedAt : DateTime.now();
    final isStale = DateTime.now().difference(generatedAt).inHours >= 24;
    final freshnessText = _freshnessLabel(generatedAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12), // Standardised left/right/top
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row with action buttons ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Align to top since left side is now taller
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tips_and_updates_outlined,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Your recommendations',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4), // Tight gap between title and time
                    GestureDetector(
                      onTap: isStale ? () async {
                        await _generateRecommendations(timeframe: 'daily', hideToast: true);
                        await _generateRecommendations(timeframe: 'weekly');
                      } : null,
                      child: Text(
                        freshnessText,
                        style: TextStyle(
                          fontSize: 13,
                          color: isStale
                              ? AppTheme.warningColor
                              : AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Refresh icon button
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: _isGenerating ? null : () async {
                    await _generateRecommendations(timeframe: 'daily', hideToast: true);
                    await _generateRecommendations(timeframe: 'weekly');
                  },
                  icon: _isGenerating
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryBlue,
                          ),
                        )
                      : Icon(Icons.refresh_rounded,
                          size: 20,
                          color: AppTheme.textSecondaryColor),
                  tooltip: 'Regenerate',
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }


  // ── Empty hint ────────────────────────────────────────────────
  Widget _buildEmptyHint() {
    final healthData = ref.read(core_data.monitorDataProvider).value;
    bool hasRecentData = false;
    
    if (healthData != null) {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      hasRecentData = healthData.allMonitorData.any((d) => d.measuredAt.toLocal().isAfter(weekAgo)) ||
                      healthData.meals.any((m) => m.timestamp.toLocal().isAfter(weekAgo)) ||
                      healthData.activities.any((a) => a.startTime.toLocal().isAfter(weekAgo));
    }

    String message;
    if (!hasRecentData) {
      message = "We don't have enough recent health data to analyse. Start logging your glucose, meals or activity to receive personalised AI recommendations!";
    } else {
      message =
          'Tap the refresh icon above to analyse your recent health data.';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondaryColor,
          height: 1.5,
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Insights & Vitality Index'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This page provides AI-generated health recommendations based on your recent logs.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'How the Vitality Index is Calculated',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your score (0–100) is calculated locally by the app\'s clinical algorithm using your health data from the last 7 days:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              _buildInfoBullet(context, 'Glucose Control (40 pts)', 'Based on your Time in Range (70–180 mg/dL or 3.9–10.0 mmol/L).'),
              _buildInfoBullet(context, 'Medication Adherence (20 pts)', 'Based on your medication adherence. If you have no medications, you get full points.'),
              _buildInfoBullet(context, 'Physical Activity (15 pts)', 'Based on your total active minutes, capped at 150 mins/week.'),
              _buildInfoBullet(context, 'Engagement (25 pts)', 'Rewards the habit of tracking. Based on total logs (readings, meals, activity) over the week.'),
              const SizedBox(height: 12),
              Text(
                'Note: If you haven\'t logged any data in the last 7 days, your score drops to 0 to reflect unmonitored risk. The final score is strictly clamped between 0 and 100.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic, 
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBullet(BuildContext context, String title, String description) {
    final textColor = AppTheme.getTextPrimaryColor(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: textColor, fontSize: 14, height: 1.4),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Recommendation card ───────────────────────────────────────
  Widget _buildRecCard(HealthRecommendation rec, int index) {
    final delay    = (index * 0.12).clamp(0.0, 0.7);
    final end      = (delay + 0.45).clamp(0.0, 1.0);
    final fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _staggerCtrl, curve: Interval(delay, end)));

    return FadeTransition(
      opacity: fadeAnim,
      child: _buildCardBody(rec, index),
    );
  }

  Widget _buildCardBody(HealthRecommendation rec, int index) {
    final catTheme     = _themeFor(rec.category);
    final isOpen       = _expandedId == rec.id;
    final urgencyColor = _urgencyColor(rec.priority);

    return GestureDetector(
      onTap: () => setState(() => _expandedId = isOpen ? null : rec.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          color: AppTheme.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOpen
                ? catTheme.primary.withValues(alpha: 0.40)
                : AppTheme.getBorderColor(context),
          ),
          boxShadow: isOpen
              ? [BoxShadow(
                  color: catTheme.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Gradient header ──────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        catTheme.primary.withValues(alpha: 0.12),
                        catTheme.primary.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: catTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(catTheme.icon, color: catTheme.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          rec.categoryLabel.toUpperCase(),
                          style: TextStyle(
                            color: catTheme.primary,
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: urgencyColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: urgencyColor.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          _urgencyLabel(rec.priority),
                          style: TextStyle(
                            color: urgencyColor,
                            fontSize: 11,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── White body ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Title
                      Text(
                        rec.title,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                          color: AppTheme.getTextPrimaryColor(context),
                        ),
                      ),


                      // Expanded content
                      if (isOpen) ...[

                        // Key metric pill — first triggering data point
                        if (rec.explanation?.triggeringData.isNotEmpty == true) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.getBackgroundColor(context),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    rec.explanation!.triggeringData.first.description,
                                    style: TextStyle(
                                      color: AppTheme.getTextSecondaryColor(context),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  rec.explanation!.triggeringData.first.value,
                                  style: TextStyle(
                                    color: catTheme.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Rationale / description
                        const SizedBox(height: 12),
                        Text(
                          rec.explanation?.rationale.isNotEmpty == true
                              ? rec.explanation!.rationale
                              : rec.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.getTextSecondaryColor(context),
                            height: 1.6,
                          ),
                        ),

                        // Steps to take
                        if (rec.actionItems.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            'STEPS TO TAKE',
                            style: TextStyle(
                              color: AppTheme.getTextSecondaryColor(context),
                              fontSize: 11,
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...rec.actionItems.take(3).toList().asMap().entries.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${e.key + 1}.',
                                    style: TextStyle(
                                      color: catTheme.primary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      e.value,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.getTextPrimaryColor(context),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],

                        // DATA ANALYSED BASED ON chips
                        if (rec.explanation?.triggeringData.isNotEmpty == true) ...[
                          const SizedBox(height: 16),
                          Text(
                            'DATA ANALYSED BASED ON:',
                            style: TextStyle(
                              color: AppTheme.getTextSecondaryColor(context),
                              fontSize: 11,
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: rec.explanation!.triggeringData
                                .map((dp) => _dataSourceLabel(dp.type))
                                .toSet()
                                .map((label) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: catTheme.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: catTheme.primary.withValues(alpha: 0.22),
                                        ),
                                      ),
                                      child: Text(
                                        label.toUpperCase(),
                                        style: TextStyle(
                                          color: catTheme.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],

                        // Priority bar
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _priorityFill(rec.priority),
                                  minHeight: 4,
                                  backgroundColor: AppTheme.borderColor,
                                  valueColor: AlwaysStoppedAnimation<Color>(catTheme.primary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              rec.priorityLabel,
                              style: TextStyle(
                                fontSize: 13,
                                color: catTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

}

// ══════════════════════════════════════════════════════════════
// SCORE RING PAINTER
// ══════════════════════════════════════════════════════════════

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final int displayScore;
  final Color ringStart;
  final Color ringEnd;

  const _ScoreRingPainter({
    required this.progress,
    required this.displayScore,
    required this.ringStart,
    required this.ringEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final rect   = Rect.fromCircle(center: center, radius: radius);

    // Track
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = ringStart.withValues(alpha: 0.12)
        ..strokeWidth = 11
        ..style = PaintingStyle.stroke,
    );

    if (progress > 0) {
      final shader = SweepGradient(
        colors: [ringStart, ringEnd, ringStart],
        stops: const [0.0, 0.5, 1.0],
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
      ).createShader(rect);

      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..shader = shader
          ..strokeWidth = 11
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Score number
    final tp = TextPainter(
      text: TextSpan(
        text: '$displayScore',
        style: TextStyle(
          color: ringStart,
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2 + 5));

    // "/ 100" sub-label
    final sub = TextPainter(
      text: TextSpan(
        text: '/ 100',
        style: TextStyle(
          color: ringStart.withValues(alpha: 0.40),
          fontSize: 8,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    sub.paint(canvas, center - Offset(sub.width / 2, -15));
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) =>
      old.progress != progress ||
      old.displayScore != displayScore ||
      old.ringStart != ringStart ||
      old.ringEnd != ringEnd;
}

// ══════════════════════════════════════════════════════════════
// RECOMMENDATION HISTORY SECTION
// ══════════════════════════════════════════════════════════════

class _RecommendationHistorySection extends StatefulWidget {
  final List<HealthRecommendation> history;

  const _RecommendationHistorySection({required this.history});

  @override
  State<_RecommendationHistorySection> createState() =>
      _RecommendationHistorySectionState();
}

class _RecommendationHistorySectionState
    extends State<_RecommendationHistorySection> {
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = widget.history;
    final totalItems = items.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;

    final start = _currentPage * _itemsPerPage;
    final end = math.min(start + _itemsPerPage, totalItems);
    final currentItems = items.sublist(start, end);

    return Padding(
      padding: const EdgeInsets.all(24), // Standardised to 24px all around
      child: Column(
        children: [
          // ── Header row ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.history,
                        color: AppTheme.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'History',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Pagination controls
              Row(
                children: [
                  IconButton(
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${_currentPage + 1}/${totalPages > 0 ? totalPages : 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: _currentPage < totalPages - 1
                        ? () => setState(() => _currentPage++)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24), // Standardised gap between title and first item

          if (currentItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No history available',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
              ),
            )
          else
            ...currentItems.asMap().entries.map((entry) {
              final i = entry.key;
              final rec = entry.value;
              final theme = _themeFor(rec.category);

              // Status badge
              final String statusLabel;
              final Color statusColor;
              if (rec.isExpired && rec.status == RecommendationStatus.active) {
                statusLabel = 'EXPIRED';
                statusColor = AppTheme.warningColor;
              } else if (rec.status == RecommendationStatus.completed) {
                statusLabel = 'COMPLETED';
                statusColor = AppTheme.primaryGreen;
              } else {
                statusLabel = 'DISMISSED';
                statusColor = AppTheme.textSecondaryColor;
              }

              final isLast = i == currentItems.length - 1;
              return Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 12), // No bottom margin on the last item
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.midnightSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: category icon + title
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(theme.icon,
                                size: 16, color: theme.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              rec.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimaryColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right: status badge + date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('dd/MM/yy HH:mm')
                              .format(rec.generatedAt.toLocal()),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: AppTheme.textSecondaryColor,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PARTICLE PAINTER (celebration burst)
// ══════════════════════════════════════════════════════════════

class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color ringStart;
  final Color ringEnd;

  static final _rng = math.Random(42);
  static final _particles = List.generate(10, (i) {
    final angle = (i / 10) * math.pi * 2 + _rng.nextDouble() * 0.4;
    final speed = 80.0 + _rng.nextDouble() * 120.0;
    final size  = 3.0 + _rng.nextDouble() * 3.5;
    return (angle: angle, speed: speed, size: size);
  });

  const _ParticlePainter({
    required this.progress,
    required this.ringStart,
    required this.ringEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center  = Offset(size.width / 2, size.height * 0.32);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in _particles) {
      final dist = p.speed * progress;
      final pos  = center + Offset(math.cos(p.angle) * dist, math.sin(p.angle) * dist);
      final color = Color.lerp(ringStart, ringEnd, progress)!.withValues(alpha: opacity * 0.85);
      canvas.drawCircle(pos, p.size * (1.0 - progress * 0.5), Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
