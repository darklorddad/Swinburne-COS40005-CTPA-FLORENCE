import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/config/theme.dart';
import 'package:florence/config/routes.dart';
import 'package:florence/features/patient/dashboard/providers/insight_provider.dart';
import 'package:florence/features/patient/recommendations/services/recommendation_engine.dart';

// Fallback shown while the insight provider has no data yet
const String _kDummyInsight =
    "Welcome to Florence! Start tracking your vitals to receive personalised insights.";

/// AI Insight Card
/// Displays AI-generated health insights with a scanning-line loading animation
/// followed by an Unfold reveal (text grows down from the top edge).
///
/// The scan keeps running until BOTH conditions are met:
///   1. Minimum 1.8s has elapsed (animation floor)
///   2. Real insight data has arrived from the provider
/// A safety-net timer forces reveal after 8s regardless.
class AIInsightCard extends ConsumerStatefulWidget {
  final VoidCallback? onTap;

  const AIInsightCard({
    super.key,
    this.onTap,
  });

  @override
  ConsumerState<AIInsightCard> createState() => _AIInsightCardState();
}

class _AIInsightCardState extends ConsumerState<AIInsightCard>
    with TickerProviderStateMixin {
  // ── Scan animation (repeating, stops when reveal triggers) ────────
  late final AnimationController _scanCtrl;
  late final Animation<double> _scanAnim;

  // ── Unfold reveal animation (plays once after scan ends) ──────────
  late final AnimationController _revealCtrl;
  late final Animation<double> _revealAnim;

  Timer? _minTimer; // fires after 1800ms — sets _minElapsed = true
  Timer? _maxTimer; // fires after 8000ms — forces reveal regardless

  bool _minElapsed = false; // true once 1.8s minimum has passed
  bool _revealed = false;   // true once reveal has been triggered

  @override
  void initState() {
    super.initState();

    // Scan line — sweeps top→bottom→top, repeating at 1.2s per cycle
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _scanAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut),
    );

    // Unfold reveal — heightFactor 0 → 1, with easeOut
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _revealAnim = CurvedAnimation(
      parent: _revealCtrl,
      curve: Curves.easeOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _startSequence());
  }

  void _startSequence() {
    // Minimum scan time — 1.8s floor so animation always plays meaningfully
    _minTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _minElapsed = true;
      });
    });

    // Safety net — force reveal after 8s no matter what (slow API / no data)
    _maxTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted || _revealed) return;
      _doReveal();
    });
  }

  /// Resets the card back to scan mode (e.g. on pull-to-refresh).
  void _resetToScan() {
    if (!mounted) return;
    _minTimer?.cancel();
    _maxTimer?.cancel();
    _revealed = false;
    _minElapsed = false;
    _revealCtrl.reset();
    if (!_scanCtrl.isAnimating) _scanCtrl.repeat();
    setState(() {});
    _startSequence();
  }

  void _doReveal() {
    if (_revealed || !mounted) return;
    _revealed = true;
    _scanCtrl.stop();
    setState(() {}); // switches build() from scanner → unfold text
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _revealCtrl.forward();
    });
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _revealCtrl.dispose();
    _minTimer?.cancel();
    _maxTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGeneratingRecs = ref.watch(recommendationProvider).isLoading;
    final insightTextRaw = ref.watch(insightProvider);
    
    // Declarative animation logic
    // Only force the scanner if the AI is actively generating
    if (isGeneratingRecs) {
      if (_revealed) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _resetToScan());
      }
    } else {
      if (!_revealed && _minElapsed) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _doReveal());
      }
    }

    final insightText = insightTextRaw ?? _kDummyInsight;

    const double borderRadius = 24.0;

    return InkWell(
      onTap: widget.onTap ??
          () => Navigator.pushNamed(context, AppRoutes.recommendations),
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A237E),
                Color(0xFF3949AB),
                AppTheme.primaryBlue,
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ──────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  !_revealed ? 'Analysing...' : 'Insights',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward,
                              color: Colors.white70, size: 20),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Content area ─────────────────────────────────
                      if (!_revealed) _buildScanner() else _buildUnfoldText(insightText),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  // ── Scanning line + shimmer bars ───────────────────────────────
  Widget _buildScanner() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _scanAnim,
          builder: (_, __) {
            final scanY = math.sin(_scanAnim.value * math.pi);
            const double innerHeight = 48.0;

            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      height: innerHeight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _shimmerBar(1.0),
                          const SizedBox(height: 9),
                          _shimmerBar(0.88),
                          const SizedBox(height: 9),
                          _shimmerBar(0.55),
                        ],
                      ),
                    ),
                    Positioned(
                      top: scanY * (innerHeight - 2),
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xD9FFFFFF),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          'SCANNING YOUR DATA',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _shimmerBar(double widthFraction) {
    return AnimatedBuilder(
      animation: _scanAnim,
      builder: (_, __) {
        final opacity =
            0.12 + (math.sin(_scanAnim.value * math.pi * 2) * 0.06);
        return FractionallySizedBox(
          widthFactor: widthFraction,
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white
                  .withValues(alpha: opacity.clamp(0.06, 0.22)),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        );
      },
    );
  }

  // ── Unfold reveal ──────────────────────────────────────────────
  // Text block clips open top→down with a simultaneous fade.
  Widget _buildUnfoldText(String text) {
    return AnimatedBuilder(
      animation: _revealAnim,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topLeft,
            heightFactor: _revealAnim.value,
            child: Opacity(
              opacity: _revealAnim.value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              height: 1.35,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
      ),
    );
  }
}
