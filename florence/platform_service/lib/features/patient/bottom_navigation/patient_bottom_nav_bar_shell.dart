import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/routes.dart';
import '../dashboard/screens/dashboard_screen.dart';
import '../profile/screens/profile_screen.dart';
import '../profile/screens/settings_screen.dart';
import '../chat/screens/chat_screen.dart';

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
  int _tabIndex = 0; // 0=Home, 1=Chatbot, 2=Profile, 3=Settings

  // ── Animation controllers ──────────────────────────────────
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

  @override
  void initState() {
    super.initState();

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

    return Scaffold(
      extendBody: true, // Allows the sheet to slide up from behind the BottomAppBar
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Tab content
          Positioned.fill(
            child: IndexedStack(
              index: _tabIndex,
              children: const [
                DashboardScreen(),
                ChatScreen(),
                ProfileScreen(),
                SettingsScreen(),
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

          // 3. Sheet content — slides up from behind the nav bar
          AnimatedBuilder(
            animation: _sheetAnim,
            builder: (context, child) {
              final navHeight = 65.0 + safeBottom; // BottomAppBar height + notch
              final bottomOffset = navHeight - ((1 - _sheetAnim.value) * _sheetContentHeight);
              return Positioned(
                bottom: bottomOffset,
                left: 0,
                right: 0,
                child: child!,
              );
            },
            child: _buildSheetContent(),
          ),
        ],
      ),
      
      // 4. Standard Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleSheet,
        backgroundColor: const Color(0xFF2B4EFF),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        child: AnimatedBuilder(
          animation: _crossAnim,
          builder: (context, _) => Transform.rotate(
            angle: _crossAnim.value * (pi / 4),
            child: const Icon(Icons.add, size: 28),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      // 5. Standard Nav Bar (No border radius)
      bottomNavigationBar: _buildNavBar(),
    );
  }

  // ── Nav bar ────────────────────────────────────────────────
  Widget _buildNavBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: Colors.white.withOpacity(0.98),
      elevation: 16, // Adds a drop shadow
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 65,
        child: Row(
          children: [
            _buildNavItem(
              tabIndex: 0,
              icon: Icons.home_rounded,
              label: 'Home',
              onTap: () => _switchTab(0),
            ),
            _buildNavItem(
              tabIndex: 1,
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chatbot',
              onTap: () => _switchTab(1),
            ),
            
            // Empty centre slot for the docked FAB
            const Expanded(child: SizedBox()),
            
            _buildNavItem(
              tabIndex: 2,
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () => _switchTab(2),
            ),
            _buildNavItem(
              tabIndex: 3,
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => _switchTab(3),
            ),
          ],
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
    final isActive = tabIndex == _tabIndex;
    const accent = Color(0xFF2B4EFF);
    const inactive = Color(0xFF9CA3AF);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active pill above icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut, // Use easeOut to fix the negative width Flex Error
              width: isActive ? 20.0 : 0.0,
              height: 3.0,
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
                (0, Icons.water_drop_rounded, 'Glucose', Color(0xFFEF5350), AppRoutes.logGlucose),
                (1, Icons.monitor_heart_outlined, 'B.Pressure', Color(0xFFF50057), AppRoutes.logBloodPressure),
                (2, Icons.restaurant_outlined, 'Diet', Color(0xFFFFA726), AppRoutes.logMeal),
                (3, Icons.directions_run_rounded, 'Activity', Color(0xFF66BB6A), AppRoutes.logActivity),
                (4, Icons.history_edu_rounded, 'Meds', Color(0xFF42A5F5), AppRoutes.logMedication),
                (5, Icons.monitor_weight_outlined, 'BMI', Color(0xFF26A69A), AppRoutes.logBmi),
                (6, Icons.bloodtype_outlined, 'Cholesterol', Color(0xFFAB47BC), AppRoutes.logCholesterol),
                (7, Icons.pie_chart_outline, 'HbA1c', Color(0xFFFFCA28), AppRoutes.logHba1c),
              ];
              final (i, icon, label, color, route) = _items[index];
              return _logItem(i, icon, label, color, route);
            },
          ),
        ],
      ),
    );
  }

  Widget _logItem(
    int index,
    IconData icon,
    String label,
    Color color,
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
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F1020),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
