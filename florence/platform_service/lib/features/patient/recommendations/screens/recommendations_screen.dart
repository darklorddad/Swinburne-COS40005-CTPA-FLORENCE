import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/recommendation_engine.dart';
import '../models/recommendation_models.dart';
import '../../profile/providers/user_profile_provider.dart';
import '../../../../core/utils/helpers.dart';

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

  Color get glow => primary.withValues(alpha: 0.20);
  Color get tag => primary.withValues(alpha: 0.12);
  Color get tagBorder => primary.withValues(alpha: 0.25);
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
    primary: Color(0xFF22D3EE),
    secondary: Color(0xFF0891B2),
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
    primary: Color(0xFF60A5FA),
    secondary: Color(0xFF2563EB),
    icon: Icons.medication_outlined,
  ),
};

_CatTheme _themeFor(RecommendationCategory cat) =>
    _kThemes[cat] ?? _kThemes[RecommendationCategory.lifestyle]!;

// ══════════════════════════════════════════════════════════════
// THEME-AWARE COLOR TOKENS
// ══════════════════════════════════════════════════════════════

class _RecsColors {
  final bool isDark;
  const _RecsColors(this.isDark);

  Color get bg         => isDark ? const Color(0xFF080D1A) : const Color(0xFFF0F4FA);
  Color get accent     => isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB);
  Color get cardBg     => isDark ? const Color(0xCC0A1029) : Colors.white;
  Color get cardBorder => isDark ? const Color(0x2E38BDF8) : const Color(0x1F2563EB);
  Color get txtPrimary => isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B);
  Color get txtMuted   => isDark ? const Color(0x8ACBD5E1) : const Color(0xFF64748B);
  Color get divider    => isDark ? const Color(0x1ACBD5E1) : const Color(0xFFE2E8F0);
  double get orbOpacity1 => isDark ? 0.60 : 0.08;
  double get orbOpacity2 => isDark ? 0.50 : 0.06;
  double get orbOpacity3 => isDark ? 0.40 : 0.05;
  bool get useBlur     => isDark;
}

// ── Helpers ────────────────────────────────────────────────────
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

/// Returns (startColor, endColor, stateLabel, orbTint) based on vitality score.
/// Phase 2: orbTint drives background orb colour shift (WHOOP++ atmosphere).
(Color, Color, String, Color) _scoreState(int score) {
  if (score >= 75) {
    return (const Color(0xFF22D3EE), const Color(0xFF10B981), 'Thriving', const Color(0xFF22D3EE));
  }
  if (score >= 50) {
    return (const Color(0xFF38BDF8), const Color(0xFF4F46E5), 'Rising', const Color(0xFF38BDF8));
  }
  if (score >= 30) {
    return (const Color(0xFFFBBF24), const Color(0xFFF59E0B), 'Straining', const Color(0xFFFBBF24));
  }
  return (
    const Color(0xFFF87171), const Color(0xFFEF4444), 'Depleted',
    const Color(0xFFF87171), // red
  );
}

/// Priority sort order: urgent first, then high, medium, low.
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

double _priorityFill(RecommendationPriority p) {
  switch (p) {
    case RecommendationPriority.urgent: return 0.95;
    case RecommendationPriority.high:   return 0.72;
    case RecommendationPriority.medium: return 0.50;
    case RecommendationPriority.low:    return 0.28;
  }
}

double _urgencyOpacity(RecommendationPriority p) {
  switch (p) {
    case RecommendationPriority.urgent: return 1.0;
    case RecommendationPriority.high:   return 0.80;
    case RecommendationPriority.medium: return 0.50;
    case RecommendationPriority.low:    return 0.25;
  }
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning,';
  if (h < 17) return 'Good afternoon,';
  return 'Good evening,';
}

String _dateLabel() {
  final n = DateTime.now();
  const days   = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
                  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
  return '${days[n.weekday - 1]}, ${months[n.month - 1]} ${n.day}';
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

  // Phase 2 state
  RecommendationCategory? _activeFilter; // null = All
  bool _showMilestone = false;
  bool _celebTriggered = false;

  // Phase 1 controllers
  late final AnimationController _scoreCtrl;
  late final AnimationController _waveCtrl;
  late final AnimationController _staggerCtrl;
  late final Animation<double> _scoreAnim;

  // Phase 2 controllers
  late final AnimationController _breatheCtrl;  // 3000ms, repeat reversing
  late final AnimationController _celebCtrl;    // 1200ms, forward once
  late final AnimationController _loadMsgCtrl;  // 1500ms, repeat (loading messages)

  static const _loadingMessages = [
    'Reading glucose patterns…',
    'Cross-referencing activity logs…',
    'Generating personalised insights…',
  ];

  @override
  void initState() {
    super.initState();
    _scoreCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _scoreAnim = CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic);

    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 5))
      ..repeat();

    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();

    // Phase 2
    _breatheCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);

    _celebCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _loadMsgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoad();
      _updateStreak();
    });
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _waveCtrl.dispose();
    _staggerCtrl.dispose();
    _breatheCtrl.dispose();
    _celebCtrl.dispose();
    _loadMsgCtrl.dispose();
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

    // Phase 2: milestone detection
    if (_streakDays == 7 || _streakDays == 30 || _streakDays == 100) {
      if (mounted) {
        setState(() => _showMilestone = true);
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _showMilestone = false);
        });
      }
    } else if (mounted) {
      setState(() {});
    }
  }

  String _freshnessLabel(DateTime generatedAt) {
    final diff = DateTime.now().difference(generatedAt);
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
    if (diff.inHours < 48) return 'Updated yesterday';
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

  /// Phase 2: fire celebration particles once per session when score ≥ 75 and streak ≥ 2.
  void _maybeCelebrate(int score) {
    if (!_celebTriggered && score >= 75 && _streakDays >= 2) {
      _celebTriggered = true;
      _celebCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _RecsColors(Theme.of(context).brightness == Brightness.dark);

    final recs   = ref.watch(recommendationProvider);
    final active = recs.where((r) => r.isActive).toList();
    final score  = _computeScore(active);

    final (ringStart, ringEnd, stateLabel, orbTint) = _scoreState(score);

    // Trigger celebration check after frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCelebrate(score));

    // Apply category filter for the recommendation list
    final filtered = _activeFilter == null
        ? active
        : active.where((r) => r.category == _activeFilter).toList();

    final profileAsync = ref.watch(userProfileProvider);
    final profileMap = profileAsync.asData?.value;
    final firstName =
        profileMap?['first_name'] as String? ??
        profileMap?['name'] as String? ??
        'there';

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          _Orbs(c: c, stateColor: orbTint),
          SafeArea(
            child: (_isGenerating && active.isEmpty)
                ? _buildLoading(c)
                : RefreshIndicator(
                    onRefresh: _generateRecommendations,
                    color: c.accent,
                    backgroundColor: c.isDark ? const Color(0xFF0D1A3A) : Colors.white,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader(firstName, c)),
                        SliverToBoxAdapter(child: _buildDateBand(c)),
                        SliverToBoxAdapter(
                          child: _buildVitalityCard(score, active, c, ringStart, ringEnd, stateLabel),
                        ),
                        // Phase 2: Top Insight hero card
                        if (active.isNotEmpty)
                          SliverToBoxAdapter(child: _buildTopInsight(active, c)),
                        SliverToBoxAdapter(child: _buildSectionHeader(active.length, recs, c)),
                        SliverToBoxAdapter(child: _buildRefreshBtn(c)),
                        // Phase 2: Filter pills
                        if (active.isNotEmpty)
                          SliverToBoxAdapter(child: _buildFilterPills(active, c)),
                        if (filtered.isEmpty && !_isGenerating)
                          SliverToBoxAdapter(child: _buildEmptyHint(c)),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _buildRecCard(filtered[i], i, c),
                            childCount: filtered.length,
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 40)),
                      ],
                    ),
                  ),
          ),
          // Phase 2: Celebration particles overlay
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

  // ── Shared card builder ───────────────────────────────────────
  Widget _buildCard({
    required _RecsColors c,
    required Widget child,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
    Border? border,
    Color? color,
  }) {
    final br = borderRadius ?? BorderRadius.circular(16);
    final decoration = BoxDecoration(
      color: color ?? c.cardBg,
      borderRadius: br,
      border: border ?? Border.all(color: c.cardBorder),
      boxShadow: c.useBlur
          ? null
          : (shadows ??
              [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]),
    );

    if (c.useBlur) {
      return ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(decoration: decoration, child: child),
        ),
      );
    }
    return Container(decoration: decoration, child: child);
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader(String firstName, _RecsColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _LiveChip(accent: c.accent),
                    const SizedBox(width: 8),
                    // Phase 2: milestone banner or normal streak pill
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _showMilestone
                          ? _buildMilestoneBanner(c)
                          : _buildStreakPill(c),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _greeting(),
                  style: TextStyle(
                    color: c.txtPrimary,
                    fontSize: 45,
                    fontWeight: FontWeight.w300,
                    height: 1.1,
                  ),
                ),
                Text(
                  '$firstName.',
                  style: TextStyle(
                    color: c.accent,
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.italic,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: c.isDark
                    ? const [Color(0xFF1E2D5A), Color(0xFF0F1A3A)]
                    : [
                        const Color(0xFF2563EB).withValues(alpha: 0.12),
                        const Color(0xFF2563EB).withValues(alpha: 0.06),
                      ],
              ),
              border: Border.all(color: c.accent.withValues(alpha: 0.20), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: c.accent.withValues(alpha: 0.08),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Text('💙', style: TextStyle(fontSize: 22)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakPill(_RecsColors c) {
    return Container(
      key: const ValueKey('streak'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.accent.withValues(alpha: 0.30)),
      ),
      child: Text(
        '🔥 $_streakDays-day streak',
        style: TextStyle(
          fontSize: 11,
          color: c.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Phase 2: gold-bordered milestone banner shown for 4s on 7/30/100-day hits.
  Widget _buildMilestoneBanner(_RecsColors c) {
    final milestoneDay = [7, 30, 100].firstWhere(
      (d) => d == _streakDays,
      orElse: () => _streakDays,
    );
    return Container(
      key: const ValueKey('milestone'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.40),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        '🎉 $milestoneDay-day milestone!',
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Date band ────────────────────────────────────────────────
  Widget _buildDateBand(_RecsColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  c.accent.withValues(alpha: 0.13),
                  c.accent.withValues(alpha: 0.13),
                  Colors.transparent,
                ],
                stops: const [0, 0.3, 0.7, 1],
              ),
            ),
          ),
          Container(
            color: c.bg,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              _dateLabel(),
              style: TextStyle(
                color: c.accent.withValues(alpha: 0.31),
                fontSize: 8.5,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Vitality card ────────────────────────────────────────────
  /// Phase 2: ringStart/ringEnd/stateLabel passed in so we don't call _scoreState twice.
  Widget _buildVitalityCard(
    int score,
    List<HealthRecommendation> active,
    _RecsColors c,
    Color ringStart,
    Color ringEnd,
    String stateLabel,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: _buildCard(
        c: c,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.accent.withValues(alpha: 0.19)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VITALITY INDEX · TODAY',
                    style: TextStyle(
                      color: c.accent.withValues(alpha: 0.45),
                      fontSize: 8.5,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Phase 2: breathing score ring
                      Column(
                        children: [
                          AnimatedBuilder(
                            animation: Listenable.merge([_scoreAnim, _breatheCtrl]),
                            builder: (_, __) {
                              final breathe = Tween<double>(begin: 0.97, end: 1.03)
                                  .evaluate(CurvedAnimation(
                                parent: _breatheCtrl,
                                curve: Curves.easeInOut,
                              ));
                              final glowOpacity = Tween<double>(begin: 0.3, end: 0.6)
                                  .evaluate(CurvedAnimation(
                                parent: _breatheCtrl,
                                curve: Curves.easeInOut,
                              ));
                              return Transform.scale(
                                scale: breathe,
                                child: SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: CustomPaint(
                                    painter: _ScoreRingPainter(
                                      progress: _scoreAnim.value * score / 100,
                                      displayScore: (score * _scoreAnim.value).round(),
                                      ringStart: ringStart,
                                      ringEnd: ringEnd,
                                      glowOpacity: glowOpacity,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stateLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: ringEnd,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stateLabel,
                              style: TextStyle(
                                color: c.txtPrimary,
                                fontSize: 41,
                                fontWeight: FontWeight.w300,
                                fontStyle: FontStyle.italic,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              active.isEmpty
                                  ? 'Your health data is being analysed. Check back soon.'
                                  : 'You have ${active.length} active health signal${active.length == 1 ? '' : 's'}. Review each for personalised guidance.',
                              style: TextStyle(
                                color: c.txtMuted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w300,
                                height: 1.65,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // HRV strip
            Container(
              height: 52,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: c.divider),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Text(
                    'HRV',
                    style: TextStyle(
                      color: c.accent.withValues(alpha: 0.22),
                      fontSize: 8,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRect(
                      child: AnimatedBuilder(
                        animation: _waveCtrl,
                        builder: (_, __) => CustomPaint(
                          painter: _HrvWavePainter(
                            phase: _waveCtrl.value,
                            waveColor: c.accent,
                          ),
                          child: const SizedBox(height: 30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: '52',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: ' ms',
                          style: TextStyle(
                            color: Color(0x7FFBBF24),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Phase 2: Top Insight hero card (Oura "One Big Thing") ─────
  Widget _buildTopInsight(List<HealthRecommendation> active, _RecsColors c) {
    // Sort by priority and pick the top one
    final sorted = List<HealthRecommendation>.from(active)
      ..sort((a, b) => _priorityOrder(a.priority).compareTo(_priorityOrder(b.priority)));
    final top = sorted.first;
    final catTheme = _themeFor(top.category);

    final cardChild = Stack(
      children: [
        // Category gradient wash
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  catTheme.primary.withValues(alpha: c.isDark ? 0.08 : 0.05),
                  catTheme.secondary.withValues(alpha: 0.02),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large icon with glow
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      catTheme.primary.withValues(alpha: 0.22),
                      catTheme.secondary.withValues(alpha: 0.14),
                    ],
                  ),
                  border: Border.all(color: catTheme.primary.withValues(alpha: 0.35)),
                  boxShadow: [
                    BoxShadow(color: catTheme.glow, blurRadius: 20, spreadRadius: 2),
                  ],
                ),
                child: Center(
                  child: Icon(catTheme.icon, color: catTheme.primary, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TODAY\'S TOP INSIGHT',
                      style: TextStyle(
                        color: catTheme.primary.withValues(alpha: 0.70),
                        fontSize: 8,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      top.title,
                      style: TextStyle(
                        color: c.isDark ? const Color(0xFFEEF2FF) : const Color(0xFF1E293B),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      top.explanation?.expectedImpact.isNotEmpty == true
                          ? top.explanation!.expectedImpact
                          : top.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.txtMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        // Scroll down to full list by expanding the card
                        setState(() {
                          _activeFilter = null;
                          _expandedId = top.id;
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'See all recommendations',
                            style: TextStyle(
                              color: catTheme.primary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 13, color: catTheme.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              catTheme.primary.withValues(alpha: 0.28),
              catTheme.secondary.withValues(alpha: 0.18),
            ],
          ),
        ),
        padding: const EdgeInsets.all(1.5),
        child: c.useBlur
            ? ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.cardBg,
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: cardChild,
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: c.cardBg,
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: [
                    BoxShadow(
                      color: catTheme.primary.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: cardChild,
              ),
      ),
    );
  }

  // ── Phase 2: Category filter pills ───────────────────────────
  Widget _buildFilterPills(List<HealthRecommendation> all, _RecsColors c) {
    final presentCategories = all.map((r) => r.category).toSet().toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            // "All" pill
            _FilterPill(
              label: 'All',
              isSelected: _activeFilter == null,
              color: c.accent,
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

  // ── Section header ───────────────────────────────────────────
  Widget _buildSectionHeader(int count, List<HealthRecommendation> recs, _RecsColors c) {
    final generatedAt = recs.isNotEmpty ? recs.first.generatedAt : DateTime.now();
    final diff = DateTime.now().difference(generatedAt);
    final freshnessText = _freshnessLabel(generatedAt);
    final isStale = diff.inHours >= 24;

    final freshnessWidget = GestureDetector(
      onTap: isStale ? _generateRecommendations : null,
      child: Text(
        freshnessText,
        style: TextStyle(
          fontSize: 11,
          color: isStale ? Colors.amber : c.txtMuted,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Your recommendations',
                style: TextStyle(
                  color: c.txtPrimary,
                  fontSize: 37,
                  fontWeight: FontWeight.w300,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(),
              Text(
                '$count SIGNALS',
                style: TextStyle(
                  color: c.accent.withValues(alpha: 0.28),
                  fontSize: 8.5,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (recs.isNotEmpty) ...[
            const SizedBox(height: 4),
            freshnessWidget,
          ],
        ],
      ),
    );
  }

  // ── Empty hint ───────────────────────────────────────────────
  Widget _buildEmptyHint(_RecsColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Text(
        _activeFilter != null
            ? 'No ${_activeFilter!.name} recommendations right now.'
            : 'Tap "Regenerate Analysis" to analyse your recent health data.',
        style: TextStyle(
          color: c.txtMuted.withValues(alpha: 0.60),
          fontSize: 13,
          fontWeight: FontWeight.w300,
          height: 1.6,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // ── Recommendation card ──────────────────────────────────────
  Widget _buildRecCard(HealthRecommendation rec, int index, _RecsColors c) {
    final catTheme = _themeFor(rec.category);
    final isOpen = _expandedId == rec.id;

    // Stagger animation
    final delay = (index * 0.1).clamp(0.0, 0.7);
    final end   = (delay + 0.45).clamp(0.0, 1.0);
    final slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _staggerCtrl,
      curve: Interval(delay, end, curve: Curves.easeOut),
    ));
    final fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _staggerCtrl,
        curve: Interval(delay, end),
      ),
    );

    // Urgency bar opacity; for urgent, pulse via _staggerCtrl sin()
    final baseOpacity = _urgencyOpacity(rec.priority);

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: GestureDetector(
            onTap: () => setState(
                () => _expandedId = isOpen ? null : rec.id),
            child: Stack(
              children: [
                // Card body
                _buildCardBody(rec, isOpen, catTheme, c),
                // Urgency left bar
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: rec.priority == RecommendationPriority.urgent
                      ? AnimatedBuilder(
                          animation: _staggerCtrl,
                          builder: (_, __) {
                            final pulse = (math.sin(_staggerCtrl.value * math.pi * 4) * 0.25 + 0.75)
                                .clamp(0.5, 1.0);
                            return ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(22),
                                bottomLeft: Radius.circular(22),
                              ),
                              child: Container(
                                width: 3,
                                color: catTheme.primary.withValues(alpha: baseOpacity * pulse),
                              ),
                            );
                          },
                        )
                      : ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(22),
                            bottomLeft: Radius.circular(22),
                          ),
                          child: Container(
                            width: 3,
                            color: catTheme.primary.withValues(alpha: baseOpacity),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardBody(
    HealthRecommendation rec,
    bool isOpen,
    _CatTheme catTheme,
    _RecsColors c,
  ) {
    final cardDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      color: c.cardBg,
      border: Border.all(
        color: isOpen
            ? catTheme.primary.withValues(alpha: 0.38)
            : catTheme.primary.withValues(alpha: 0.14),
      ),
      boxShadow: isOpen
          ? [
              BoxShadow(
                color: catTheme.glow,
                blurRadius: 22,
                spreadRadius: 2,
              ),
            ]
          : (c.useBlur
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]),
    );

    final cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: cardDecoration,
      child: Stack(
        children: [
          // Gradient wash
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    catTheme.primary.withValues(alpha: isOpen ? 0.18 : 0.09),
                    catTheme.secondary.withValues(alpha: isOpen ? 0.08 : 0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon badge
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                catTheme.primary.withValues(alpha: 0.20),
                                catTheme.secondary.withValues(alpha: 0.12),
                              ],
                            ),
                            border: Border.all(
                                color: catTheme.primary.withValues(alpha: 0.28)),
                            boxShadow: [
                              BoxShadow(
                                  color: catTheme.glow, blurRadius: 14),
                            ],
                          ),
                          child: Center(
                            child: Icon(catTheme.icon,
                                color: catTheme.primary, size: 20),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Title area
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                rec.categoryLabel.toUpperCase(),
                                style: TextStyle(
                                  color: catTheme.primary,
                                  fontSize: 8,
                                  letterSpacing: 2.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                rec.title,
                                style: TextStyle(
                                  color: c.isDark
                                      ? const Color(0xFFEEF2FF)
                                      : const Color(0xFF1E293B),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                rec.explanation?.expectedImpact
                                        .isNotEmpty == true
                                    ? rec.explanation!.expectedImpact
                                    : rec.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: c.txtMuted,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w300,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Urgency badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: catTheme.tag,
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: catTheme.tagBorder),
                          ),
                          child: Text(
                            _urgencyLabel(rec.priority),
                            style: TextStyle(
                              color: catTheme.primary,
                              fontSize: 7.5,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Action item tags
                    if (rec.actionItems.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: rec.actionItems.take(2).map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: catTheme.tag,
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                  color: catTheme.tagBorder),
                            ),
                            child: Text(
                              t.toUpperCase(),
                              style: TextStyle(
                                color: catTheme.primary,
                                fontSize: 7.5,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Toggle arrow
                    Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedRotation(
                        turns: isOpen ? 0.5 : 0,
                        duration:
                            const Duration(milliseconds: 260),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isOpen
                                  ? const Color(0x30FFFFFF)
                                  : const Color(0x18FFFFFF),
                            ),
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: isOpen
                                ? const Color(0x80FFFFFF)
                                : const Color(0x40FFFFFF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Expandable body
              AnimatedSize(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeInOutCubic,
                child: isOpen
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(
                            18, 0, 18, 18),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 1,
                              color: catTheme.primary.withValues(alpha: 0.10),
                              margin: const EdgeInsets.only(
                                  bottom: 14),
                            ),
                            Text(
                              rec.description,
                              style: TextStyle(
                                color: c.txtMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                height: 1.7,
                              ),
                            ),
                            if (rec.explanation != null &&
                                rec.explanation!.rationale.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                rec.explanation!.rationale,
                                style: TextStyle(
                                  color:
                                      catTheme.primary.withValues(alpha: 0.55),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w300,
                                  height: 1.6,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            // Metric bar
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(3),
                                    child: Container(
                                      height: 3,
                                      color: c.isDark
                                          ? const Color(0x12FFFFFF)
                                          : const Color(0xFFE2E8F0),
                                      child: FractionallySizedBox(
                                        alignment:
                                            Alignment.centerLeft,
                                        widthFactor: _priorityFill(
                                            rec.priority),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    3),
                                            gradient: LinearGradient(
                                              colors: [
                                                catTheme.secondary,
                                                catTheme.primary,
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: catTheme.glow,
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  rec.priorityLabel,
                                  style: TextStyle(
                                    color: catTheme.primary
                                        .withValues(alpha: 0.70),
                                    fontSize: 9.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );

    if (c.useBlur) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: cardContent,
        ),
      );
    }
    return cardContent;
  }

  // ── Refresh button ───────────────────────────────────────────
  Widget _buildRefreshBtn(_RecsColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Center(
        child: OutlinedButton(
          onPressed: _isGenerating ? null : _generateRecommendations,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: const StadiumBorder(),
            side: BorderSide(color: c.accent.withValues(alpha: 0.16)),
            backgroundColor: c.accent.withValues(alpha: 0.04),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isGenerating)
                SizedBox(
                  width: 11,
                  height: 11,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: c.accent,
                  ),
                )
              else
                Text('◉',
                    style: TextStyle(
                        fontSize: 11,
                        color: c.accent.withValues(alpha: 0.33))),
              const SizedBox(width: 8),
              Text(
                'REGENERATE ANALYSIS',
                style: TextStyle(
                  color: c.accent.withValues(alpha: 0.44),
                  fontSize: 9.5,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Phase 2: AI Personality Loading state ─────────────────────
  Widget _buildLoading(_RecsColors c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pulsing sparkle icon
          AnimatedBuilder(
            animation: _breatheCtrl,
            builder: (_, __) {
              final pulse = Tween<double>(begin: 0.85, end: 1.15)
                  .evaluate(CurvedAnimation(
                parent: _breatheCtrl,
                curve: Curves.easeInOut,
              ));
              final glow = Tween<double>(begin: 0.25, end: 0.60)
                  .evaluate(CurvedAnimation(
                parent: _breatheCtrl,
                curve: Curves.easeInOut,
              ));
              return Transform.scale(
                scale: pulse,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        c.accent.withValues(alpha: glow * 0.35),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c.accent.withValues(alpha: glow * 0.4),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: c.accent.withValues(alpha: 0.85),
                    size: 34,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'FLORENCE IS ANALYSING YOUR HEALTH DATA',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.accent.withValues(alpha: 0.45),
              fontSize: 9,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'AI is reading your\nhealth signals…',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.txtPrimary.withValues(alpha: 0.31),
              fontSize: 34,
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          // Cycling sub-messages
          AnimatedBuilder(
            animation: _loadMsgCtrl,
            builder: (_, __) {
              final idx = (_loadMsgCtrl.value * _loadingMessages.length).floor()
                  .clamp(0, _loadingMessages.length - 1);
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _loadingMessages[idx],
                  key: ValueKey(idx),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.txtMuted.withValues(alpha: 0.70),
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PHASE 2: FILTER PILL WIDGET
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
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.30),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 8)]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// BACKGROUND ORBS
// ══════════════════════════════════════════════════════════════
/// Phase 2: accepts [stateColor] to tint orbs based on health score state.
class _Orbs extends StatelessWidget {
  final _RecsColors c;
  final Color stateColor;
  const _Orbs({required this.c, required this.stateColor});

  @override
  Widget build(BuildContext context) {
    // Blend stateColor into the default blue orb base
    final o1 = Color.lerp(const Color(0xFF1D4ED8), stateColor, 0.55)!;
    final o2 = Color.lerp(const Color(0xFF4F46E5), stateColor, 0.35)!;
    final o3 = Color.lerp(const Color(0xFF7C3AED), stateColor, 0.25)!;

    return Positioned.fill(
      child: Stack(
        children: [
          _orb(top: -100, left: -80,  size: 320, color: o1.withValues(alpha: c.orbOpacity1)),
          _orb(top: -60,  right: -60, size: 240, color: o2.withValues(alpha: c.orbOpacity2)),
          _orb(top: 340,  left: -80,  size: 280, color: o3.withValues(alpha: c.orbOpacity3)),
          _orb(bottom: 80, right: -60, size: 260, color: o1.withValues(alpha: c.orbOpacity3)),
        ],
      ),
    );
  }

  Widget _orb({
    double? top, double? bottom, double? left, double? right,
    required double size, required Color color,
  }) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, Colors.transparent],
              stops: const [0.0, 0.7],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PULSING DOT / LIVE CHIP
// ══════════════════════════════════════════════════════════════
class _LiveChip extends StatefulWidget {
  final Color accent;
  const _LiveChip({required this.accent});

  @override
  State<_LiveChip> createState() => _LiveChipState();
}

class _LiveChipState extends State<_LiveChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 0.30)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: widget.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.accent.withValues(alpha: _anim.value),
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: _anim.value * 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'AI · HEALTH INSIGHTS',
            style: TextStyle(
              color: widget.accent,
              fontSize: 8.5,
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SCORE RING PAINTER
// ══════════════════════════════════════════════════════════════
class _ScoreRingPainter extends CustomPainter {
  final double progress;     // 0.0–1.0
  final int displayScore;
  final Color ringStart;
  final Color ringEnd;
  final double glowOpacity;  // Phase 2: breathing glow

  const _ScoreRingPainter({
    required this.progress,
    required this.displayScore,
    required this.ringStart,
    required this.ringEnd,
    this.glowOpacity = 0.08,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 7;
    final rect   = Rect.fromCircle(center: center, radius: radius);

    // Track — opacity pulses with glowOpacity
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = ringStart.withValues(alpha: glowOpacity)
        ..strokeWidth = 5.5
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
          ..strokeWidth = 5.5
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
          fontSize: 28,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: ringStart.withValues(alpha: 0.40), blurRadius: 20)],
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
          color: ringStart.withValues(alpha: 0.25),
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
      old.ringEnd != ringEnd ||
      old.glowOpacity != glowOpacity;
}

// ══════════════════════════════════════════════════════════════
// HRV WAVE PAINTER
// ══════════════════════════════════════════════════════════════
class _HrvWavePainter extends CustomPainter {
  final double phase; // 0.0–1.0
  final Color waveColor;

  const _HrvWavePainter({required this.phase, required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor.withValues(alpha: 0.21)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const pw = 100.0; // pattern width
    final offset = phase * pw;
    final mid = size.height / 2;

    final path = Path();
    for (double sx = -offset; sx < size.width + pw; sx += pw) {
      path.moveTo(sx, mid);
      path.lineTo(sx + 16, mid);
      path.lineTo(sx + 22, mid - 8);
      path.lineTo(sx + 28, mid + 8);
      path.lineTo(sx + 34, mid);
      path.lineTo(sx + 50, mid);
      path.lineTo(sx + 56, mid - 4);
      path.lineTo(sx + 62, mid + 4);
      path.lineTo(sx + 68, mid);
      path.lineTo(sx + pw, mid);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HrvWavePainter old) =>
      old.phase != phase || old.waveColor != waveColor;
}

// ══════════════════════════════════════════════════════════════
// PHASE 2: PARTICLE PAINTER (celebration burst)
// ══════════════════════════════════════════════════════════════
class _ParticlePainter extends CustomPainter {
  final double progress; // 0.0 → 1.0 (forward once)
  final Color ringStart;
  final Color ringEnd;

  static final _rng = math.Random(42); // seeded for consistency
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
    final center = Offset(size.width / 2, size.height * 0.32);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in _particles) {
      final dist = p.speed * progress;
      final dx = math.cos(p.angle) * dist;
      final dy = math.sin(p.angle) * dist;
      final pos = center + Offset(dx, dy);

      final color = Color.lerp(ringStart, ringEnd, progress)!
          .withValues(alpha: opacity * 0.85);

      canvas.drawCircle(
        pos,
        p.size * (1.0 - progress * 0.5),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.progress != progress;
}
