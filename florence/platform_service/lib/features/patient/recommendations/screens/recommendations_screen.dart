import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:florence/features/patient/recommendations/services/recommendation_engine.dart';
import 'package:florence/features/patient/recommendations/models/recommendation_models.dart';
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

int _computeScore(List<HealthRecommendation> recs) {
  int s = 85;
  for (final r in recs) {
    switch (r.priority) {
      case RecommendationPriority.urgent: s -= 15; break;
      case RecommendationPriority.high:   s -= 8;  break;
      case RecommendationPriority.medium: s -= 4;  break;
      case RecommendationPriority.low:    break;
    }
  }
  return s.clamp(20, 95);
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
  RecommendationCategory? _activeFilter;
  RecommendationPriority? _priorityFilter;
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
    final today = DateTime.now();

    if (lastStr == null) {
      _streakDays = 1;
    } else {
      final last = DateTime.parse(lastStr);
      final diff = today.difference(DateTime(last.year, last.month, last.day)).inDays;
      if (diff == 0) {
        _streakDays = prefs.getInt('recs_streak') ?? 1;
        return;
      } else if (diff == 1) {
        _streakDays = (prefs.getInt('recs_streak') ?? 0) + 1;
      } else {
        _streakDays = 1;
      }
    }
    await prefs.setString('recs_last_visit', today.toIso8601String());
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
    final active = ref.read(recommendationProvider).where((r) => r.isActive).toList();
    if (active.isEmpty) {
      await _generateRecommendations();
    } else {
      _scoreCtrl.forward();
    }
  }

  Future<void> _generateRecommendations() async {
    setState(() => _isGenerating = true);
    _scoreCtrl.reset();
    try {
      final usedAI = await ref
          .read(recommendationProvider.notifier)
          .generateRecommendations(daysToAnalyze: 7);
      _staggerCtrl.forward(from: 0);
      _scoreCtrl.forward();
      if (mounted) {
        if (usedAI) {
          Helpers.showSuccess(context, 'AI analysis complete');
        } else {
          Helpers.showWarning(context, 'AI unavailable — showing general recommendations');
        }
      }
    } catch (_) {
      if (mounted) Helpers.showError(context, 'Failed to generate insights');
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
    final recs   = ref.watch(recommendationProvider);
    final active = recs.where((r) => r.isActive).toList();
    final score  = _computeScore(active);
    final (ringStart, ringEnd, stateLabel) = _scoreState(score);

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCelebrate(score));

    final filtered = active.where((r) {
      if (_activeFilter != null && r.category != _activeFilter) return false;
      if (_priorityFilter != null && r.priority != _priorityFilter) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('AI Health Insights'),
        elevation: 0,
        centerTitle: false,
        bottom: _isGenerating
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: RefreshIndicator(
            onRefresh: _generateRecommendations,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildVitalityCard(score, active, ringStart, ringEnd, stateLabel),
                ),
                SliverToBoxAdapter(child: _buildSectionHeader(active.length, recs, active)),
                if (filtered.isEmpty && !_isGenerating)
                  SliverToBoxAdapter(child: _buildEmptyHint()),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildRecCard(filtered[i], i),
                    childCount: filtered.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
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
      ),
    );
  }

  // ── Vitality card ─────────────────────────────────────────────
  Widget _buildVitalityCard(
    int score,
    List<HealthRecommendation> active,
    Color ringStart,
    Color ringEnd,
    String stateLabel,
  ) {
    final count = active.length;
    final stateIcon = score >= 50 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
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
              SizedBox(
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
                  // Streak
                  if (_streakDays > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '$_streakDays-day streak',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Description text (centred)
              Text(
                active.isEmpty
                    ? 'Your health data is being analysed.'
                    : 'You have $count active health signal${count == 1 ? '' : 's'}. Review each for personalised guidance.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.getTextSecondaryColor(context),
                  height: 1.5,
                ),
              ),

              // "N signals" pill
              if (count > 0) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    '$count signal${count == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Section header (with inline refresh + filter actions) ─────
  Widget _buildSectionHeader(
      int count, List<HealthRecommendation> recs, List<HealthRecommendation> all) {
    final generatedAt = recs.isNotEmpty ? recs.first.generatedAt : DateTime.now();
    final isStale = DateTime.now().difference(generatedAt).inHours >= 24;
    final freshnessText = _freshnessLabel(generatedAt);
    final hasFilter = _activeFilter != null || _priorityFilter != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row with action buttons ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Your recommendations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Refresh icon button
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: _isGenerating ? null : _generateRecommendations,
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
              const SizedBox(width: 2),
              // Filter button with optional active dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  OutlinedButton.icon(
                    onPressed: all.isNotEmpty ? () => _openFilterSheet(all) : null,
                    icon: Icon(Icons.tune_rounded,
                        size: 15,
                        color: hasFilter
                            ? AppTheme.primaryBlue
                            : AppTheme.textSecondaryColor),
                    label: Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: hasFilter
                            ? AppTheme.primaryBlue
                            : AppTheme.textSecondaryColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: hasFilter
                            ? AppTheme.primaryBlue
                            : AppTheme.borderColor,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  if (hasFilter)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              if (hasFilter) ...[
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => setState(
                      () { _activeFilter = null; _priorityFilter = null; }),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondaryColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Clear',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
              const SizedBox(width: 8),
            ],
          ),

          // ── Subtitle: freshness · signal count ──
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: isStale ? _generateRecommendations : null,
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
                if (count > 0) ...[
                  Text(
                    '  ·  ',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor),
                  ),
                  Text(
                    '$count signal${count == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Filter bottom sheet ───────────────────────────────────────
  void _openFilterSheet(List<HealthRecommendation> all) {
    final presentCategories = all.map((r) => r.category).toSet().toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.getBorderColor(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Filter Recommendations',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const Spacer(),
                      if (_activeFilter != null || _priorityFilter != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _activeFilter = null;
                              _priorityFilter = null;
                            });
                            setSheetState(() {});
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textSecondaryColor,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('Clear all'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  // Category section
                  Text(
                    'BY TYPE',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presentCategories.map((cat) {
                      final catTheme = _themeFor(cat);
                      final label =
                          cat.name[0].toUpperCase() + cat.name.substring(1);
                      final isSelected = _activeFilter == cat;
                      return FilterChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() => _activeFilter = val ? cat : null);
                          setSheetState(() {});
                        },
                        selectedColor:
                            catTheme.primary.withValues(alpha: 0.13),
                        checkmarkColor: catTheme.primary,
                        avatar: Icon(catTheme.icon,
                            size: 14,
                            color: isSelected
                                ? catTheme.primary
                                : AppTheme.textSecondaryColor),
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? catTheme.primary
                              : AppTheme.textSecondaryColor,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? catTheme.primary
                              : AppTheme.getBorderColor(ctx),
                        ),
                        backgroundColor: AppTheme.getSurfaceColor(ctx),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),
                  // Priority section
                  Text(
                    'BY PRIORITY',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: RecommendationPriority.values.map((p) {
                      final urgColor = _urgencyColor(p);
                      final label = _urgencyLabel(p);
                      final isSelected = _priorityFilter == p;
                      return FilterChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() => _priorityFilter = val ? p : null);
                          setSheetState(() {});
                        },
                        selectedColor: urgColor.withValues(alpha: 0.10),
                        checkmarkColor: urgColor,
                        showCheckmark: false,
                        avatar: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: urgColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? urgColor
                              : AppTheme.textSecondaryColor,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        side: BorderSide(
                          color: isSelected ? urgColor : AppTheme.getBorderColor(ctx),
                        ),
                        backgroundColor: AppTheme.getSurfaceColor(ctx),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Empty hint ────────────────────────────────────────────────
  Widget _buildEmptyHint() {
    String message;
    if (_activeFilter != null && _priorityFilter != null) {
      final catLabel = _activeFilter!.name[0].toUpperCase() +
          _activeFilter!.name.substring(1);
      message =
          'No ${_urgencyLabel(_priorityFilter!).toLowerCase()} $catLabel recommendations right now.';
    } else if (_activeFilter != null) {
      final catLabel = _activeFilter!.name[0].toUpperCase() +
          _activeFilter!.name.substring(1);
      message = 'No $catLabel recommendations right now.';
    } else if (_priorityFilter != null) {
      message =
          'No ${_urgencyLabel(_priorityFilter!).toLowerCase()} recommendations right now.';
    } else {
      message =
          'Tap the refresh icon above to analyse your recent health data.';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondaryColor,
          height: 1.5,
        ),
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: _buildCardBody(rec, index),
      ),
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
                      Text(
                        rec.categoryLabel.toUpperCase(),
                        style: TextStyle(
                          color: catTheme.primary,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
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
                                Text(
                                  rec.explanation!.triggeringData.first.description,
                                  style: TextStyle(
                                    color: AppTheme.getTextSecondaryColor(context),
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
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
