import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/routes.dart';
import '../dashboard/screens/dashboard_screen.dart';
import '../profile/screens/profile_screen.dart';

class PatientBottomNavBarShell extends ConsumerStatefulWidget {
  const PatientBottomNavBarShell({super.key});

  @override
  ConsumerState<PatientBottomNavBarShell> createState() =>
      _PatientBottomNavBarShellState();
}

class _PatientBottomNavBarShellState
    extends ConsumerState<PatientBottomNavBarShell>
    with TickerProviderStateMixin {
  // ── Tab state ──────────────────────────────────────────────
  int _tabIndex = 0; // 0=Home, 1=Settings, 2=Chat

  // ── Animation controllers ──────────────────────────────────
  late final AnimationController _ringController;
  late final AnimationController _sheetController;
  late final AnimationController _crossController;

  late final Animation<double> _sheetAnim;
  late final Animation<double> _crossAnim;

  // ── Sheet state ────────────────────────────────────────────
  bool _sheetOpen = false;
  double _sheetContentHeight = 380;
  final GlobalKey _sheetContentKey = GlobalKey();

  // ── Log item stagger ───────────────────────────────────────
  final List<double> _itemOpacity = List.filled(8, 1.0);
  final List<Offset> _itemOffset = List.filled(8, Offset.zero);

  static const double _kNavHeight = 80.0;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 540),
    );

    _crossController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _sheetAnim = CurvedAnimation(
      parent: _sheetController,
      curve: const Cubic(0.34, 1.16, 0.64, 1),
      reverseCurve: const Cubic(0.4, 0, 0.2, 1),
    );

    _crossAnim = CurvedAnimation(
      parent: _crossController,
      curve: const Cubic(0.34, 1.56, 0.64, 1),
      reverseCurve: Curves.easeIn,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureSheet());
  }

  void _measureSheet() {
    final ctx = _sheetContentKey.currentContext;
    if (ctx != null) {
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        setState(() => _sheetContentHeight = box.size.height);
      }
    }
  }

  @override
  void dispose() {
    _ringController.dispose();
    _sheetController.dispose();
    _crossController.dispose();
    super.dispose();
  }

  // ── Sheet open / close ─────────────────────────────────────
  void _openSheet() {
    setState(() {
      _sheetOpen = true;
      for (int i = 0; i < 8; i++) {
        _itemOpacity[i] = 0;
        _itemOffset[i] = const Offset(0, 20);
      }
    });
    _sheetController.forward();
    _crossController.forward();

    for (int i = 0; i < 8; i++) {
      Future.delayed(Duration(milliseconds: 190 + i * 42), () {
        if (mounted) {
          setState(() {
            _itemOpacity[i] = 1;
            _itemOffset[i] = Offset.zero;
          });
        }
      });
    }
  }

  void _closeSheet() {
    _sheetController.reverse();
    _crossController.reverse();
    setState(() => _sheetOpen = false);
  }

  void _toggleSheet() => _sheetOpen ? _closeSheet() : _openSheet();

  void _switchTab(int index) {
    setState(() => _tabIndex = index);
    if (_sheetOpen) _closeSheet();
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final totalNavHeight = _kNavHeight + safeBottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Tab content — padded so it doesn't sit behind the nav bar
          Positioned.fill(
            bottom: totalNavHeight,
            child: IndexedStack(
              index: _tabIndex,
              children: const [
                DashboardScreen(),
                ProfileScreen(),
                ProfileScreen(),
              ],
            ),
          ),

          // 2. Backdrop — blurs and darkens content when sheet is open
          if (_sheetOpen)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _sheetAnim,
                builder: (context, _) {
                  return GestureDetector(
                    onTap: _closeSheet,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: _sheetAnim.value * 4,
                        sigmaY: _sheetAnim.value * 4,
                      ),
                      child: Container(
                        color: Color.lerp(
                          Colors.transparent,
                          const Color(0xFF060618).withOpacity(0.42),
                          _sheetAnim.value,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // 3. Sheet content — slides up from below the nav bar
          AnimatedBuilder(
            animation: _sheetAnim,
            builder: (context, child) {
              final bottom = totalNavHeight -
                  (1 - _sheetAnim.value) * _sheetContentHeight;
              return Positioned(
                bottom: bottom,
                left: 0,
                right: 0,
                child: child!,
              );
            },
            child: _buildSheetContent(),
          ),

          // 4. Nav bar — sits above sheet so it covers sheet bottom edge
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildNavBar(safeBottom),
          ),

          // 5. Plus button — always on top, animates upward with sheet
          AnimatedBuilder(
            animation: _sheetAnim,
            builder: (context, _) {
              final buttonBottom = (totalNavHeight - 44) +
                  _sheetAnim.value * _sheetContentHeight;
              return Positioned(
                bottom: buttonBottom,
                left: 0,
                right: 0,
                child: Center(child: _buildPlusButton()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Nav bar ────────────────────────────────────────────────
  Widget _buildNavBar(double safeBottom) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          height: _kNavHeight + safeBottom,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: const Border(
              top: BorderSide(color: Color(0x80CCD0E6), width: 1),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 30,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: safeBottom),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildNavItem(
                  tabIndex: 0,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  onTap: () => _switchTab(0),
                ),
                _buildNavItem(
                  tabIndex: -1, // -1 = disabled
                  icon: Icons.monitor_heart_outlined,
                  label: 'Analysis',
                  onTap: null,
                ),
                // Empty centre slot — plus button floats above this
                const Expanded(flex: 13, child: SizedBox()),
                _buildNavItem(
                  tabIndex: 1,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => _switchTab(1),
                ),
                _buildNavItem(
                  tabIndex: 2,
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  onTap: () => _switchTab(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int tabIndex,
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final isActive = tabIndex == _tabIndex && tabIndex != -1;
    const accent = Color(0xFF2B4EFF);
    const inactive = Color(0xFF9CA3AF);

    return Expanded(
      flex: 10,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active pill above icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: const Cubic(0.34, 1.56, 0.64, 1),
              width: isActive ? 20 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              icon,
              size: 24,
              color: isActive ? accent : inactive,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? accent : inactive,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Plus button ────────────────────────────────────────────
  Widget _buildPlusButton() {
    const sweepColors = [
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFF43F5E),
      Color(0xFFA855F7),
      Color(0xFF8B5CF6),
    ];

    return GestureDetector(
      onTap: _toggleSheet,
      child: SizedBox(
        width: 76,
        height: 76,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Layer 1: bloom (blurred, behind ring)
            AnimatedBuilder(
              animation: _ringController,
              builder: (_, __) {
                final pulse =
                    0.55 + 0.30 * sin(_ringController.value * 2 * pi);
                return Transform.rotate(
                  angle: _ringController.value * 2 * pi,
                  child: Opacity(
                    opacity: pulse,
                    child: ImageFiltered(
                      imageFilter:
                          ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(colors: sweepColors),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Layer 2: sharp spinning ring
            AnimatedBuilder(
              animation: _ringController,
              builder: (_, __) => Transform.rotate(
                angle: _ringController.value * 2 * pi,
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(colors: sweepColors),
                  ),
                ),
              ),
            ),
            // Layer 3: dark inner circle with plus / X
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF121228),
              ),
              child: Center(
                child: AnimatedBuilder(
                  animation: _crossAnim,
                  builder: (_, __) => Transform.rotate(
                    angle: _crossAnim.value * (pi / 4),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 2,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Container(
                            width: 22,
                            height: 2,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sheet content ──────────────────────────────────────────
  Widget _buildSheetContent() {
    return Container(
      key: _sheetContentKey,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Color(0x17000000),
            blurRadius: 60,
            offset: Offset(0, -20),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag pill
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(bottom: 22),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E4EF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Log Health Data',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF0F1020),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select a metric to record',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 26),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 14,
              crossAxisSpacing: 10,
              mainAxisExtent: 100,
            ),
            itemCount: 8,
            itemBuilder: (context, index) {
              const _items = [
                (0, '🩸', 'Glucose',     [Color(0xFFFFECEC), Color(0xFFFFD6D6)], AppRoutes.logGlucose),
                (1, '❤️', 'B.Pressure',  [Color(0xFFFFEAF5), Color(0xFFFFD0EA)], AppRoutes.logBloodPressure),
                (2, '🍽️', 'Diet',        [Color(0xFFFFFAE8), Color(0xFFFFF0C0)], AppRoutes.logMeal),
                (3, '🏃', 'Activity',    [Color(0xFFE8FFF4), Color(0xFFC6FCE4)], AppRoutes.logActivity),
                (4, '💊', 'Meds',        [Color(0xFFEEF0FF), Color(0xFFD8DDFF)], AppRoutes.addMedication),
                (5, '⚖️', 'BMI',         [Color(0xFFF4EEFF), Color(0xFFE4D2FF)], AppRoutes.logBmi),
                (6, '🫀', 'Cholesterol', [Color(0xFFFFF3EE), Color(0xFFFFE2D0)], AppRoutes.logCholesterol),
                (7, '🔬', 'HbA1c',       [Color(0xFFEEF8FF), Color(0xFFD0E8FF)], AppRoutes.logHba1c),
              ];
              final (i, emoji, label, colors, route) = _items[index];
              return _logItem(i, emoji, label, colors, route);
            },
          ),
        ],
      ),
    );
  }

  Widget _logItem(
    int index,
    String emoji,
    String label,
    List<Color> gradientColors,
    String route,
  ) {
    return GestureDetector(
      onTap: () {
        _closeSheet();
        Navigator.pushNamed(context, route);
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 320),
        opacity: _itemOpacity[index],
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 360),
          offset: _itemOffset[index] / 100,
          curve: const Cubic(0.34, 1.56, 0.64, 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 23),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
