import 'dart:math' as math;
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

    final filtered = _activeFilter == null
        ? active
        : active.where((r) => r.category == _activeFilter).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
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
          RefreshIndicator(
            onRefresh: _generateRecommendations,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildVitalityCard(score, active, ringStart, ringEnd, stateLabel),
                ),
                SliverToBoxAdapter(child: _buildSectionHeader(active.length, recs)),
                SliverToBoxAdapter(child: _buildRefreshBtn()),
                if (active.isNotEmpty)
                  SliverToBoxAdapter(child: _buildFilterPills(active)),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Score ring
              Column(
                children: [
                  SizedBox(
                    width: 96,
                    height: 96,
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
                ],
              ),
              const SizedBox(width: 20),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VITALITY INDEX',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stateLabel,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      active.isEmpty
                          ? 'Your health data is being analysed.'
                          : 'You have ${active.length} active health signal${active.length == 1 ? '' : 's'}. Review each for personalised guidance.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                        height: 1.5,
                      ),
                    ),
                    if (_streakDays > 0) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            '$_streakDays-day streak',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue,
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
    );
  }

  // ── Section header ────────────────────────────────────────────
  Widget _buildSectionHeader(int count, List<HealthRecommendation> recs) {
    final generatedAt = recs.isNotEmpty ? recs.first.generatedAt : DateTime.now();
    final isStale = DateTime.now().difference(generatedAt).inHours >= 24;
    final freshnessText = _freshnessLabel(generatedAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Your recommendations',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count signals',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
            ],
          ),
          if (recs.isNotEmpty) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: isStale ? _generateRecommendations : null,
              child: Text(
                freshnessText,
                style: TextStyle(
                  fontSize: 12,
                  color: isStale ? AppTheme.warningColor : AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Filter pills ──────────────────────────────────────────────
  Widget _buildFilterPills(List<HealthRecommendation> all) {
    final presentCategories = all.map((r) => r.category).toSet().toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _FilterPill(
              label: 'All',
              isSelected: _activeFilter == null,
              color: AppTheme.primaryBlue,
              onTap: () => setState(() => _activeFilter = null),
            ),
            ...presentCategories.map((cat) {
              final theme = _themeFor(cat);
              final label = cat.name[0].toUpperCase() + cat.name.substring(1);
              return _FilterPill(
                label: label,
                isSelected: _activeFilter == cat,
                color: theme.primary,
                onTap: () => setState(
                  () => _activeFilter = _activeFilter == cat ? null : cat,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Empty hint ────────────────────────────────────────────────
  Widget _buildEmptyHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Text(
        _activeFilter != null
            ? 'No ${_activeFilter!.name} recommendations right now.'
            : 'Tap "Regenerate Analysis" to analyse your recent health data.',
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
    final catTheme    = _themeFor(rec.category);
    final isOpen      = _expandedId == rec.id;
    final urgencyColor = _urgencyColor(rec.priority);
    final number      = (index + 1).toString().padLeft(2, '0');

    return GestureDetector(
      onTap: () => setState(() => _expandedId = isOpen ? null : rec.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOpen
                ? catTheme.primary.withValues(alpha: 0.40)
                : AppTheme.borderColor,
          ),
          boxShadow: isOpen
              ? [BoxShadow(
                  color: catTheme.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )]
              : [],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Collapsed row ──────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Large number
                    SizedBox(
                      width: 36,
                      child: Text(
                        number,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: catTheme.primary.withValues(
                            alpha: isOpen ? 1.0 : 0.22,
                          ),
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Category icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: catTheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(catTheme.icon, color: catTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    // Category label + title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec.categoryLabel.toUpperCase(),
                            style: TextStyle(
                              color: catTheme.primary,
                              fontSize: 9,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rec.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Urgency badge
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
                          fontSize: 9,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Expanded detail ────────────────────────────
                if (isOpen) ...[
                  const SizedBox(height: 16),
                  Divider(color: AppTheme.borderColor, height: 1),
                  const SizedBox(height: 16),

                  // WHY THIS MATTERS block
                  Container(
                    padding: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: catTheme.primary, width: 3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WHY THIS MATTERS',
                          style: TextStyle(
                            color: catTheme.primary,
                            fontSize: 9,
                            letterSpacing: 1.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          rec.explanation?.rationale.isNotEmpty == true
                              ? rec.explanation!.rationale
                              : rec.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                            height: 1.6,
                          ),
                        ),
                        // Triggering data points
                        if (rec.explanation?.triggeringData.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: rec.explanation!.triggeringData.take(3).map((dp) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: catTheme.primary.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${dp.description}: ${dp.value}',
                                  style: TextStyle(
                                    color: catTheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // STEPS TO TAKE
                  if (rec.actionItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'STEPS TO TAKE',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 9,
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
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.value,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textPrimaryColor,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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
                          fontSize: 11,
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
        ),
      ),
    );
  }

  // ── Refresh button ────────────────────────────────────────────
  Widget _buildRefreshBtn() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: OutlinedButton.icon(
        onPressed: _isGenerating ? null : _generateRecommendations,
        icon: _isGenerating
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryBlue,
                ),
              )
            : const Icon(Icons.refresh_rounded, size: 16),
        label: const Text('Regenerate Analysis'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryBlue,
          side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.30)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// FILTER PILL WIDGET
// ══════════════════════════════════════════════════════════════

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
    final radius = size.width / 2 - 7;
    final rect   = Rect.fromCircle(center: center, radius: radius);

    // Track
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = ringStart.withValues(alpha: 0.12)
        ..strokeWidth = 6
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
          ..strokeWidth = 6
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
