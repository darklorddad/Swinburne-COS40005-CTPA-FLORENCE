import 'package:flutter/material.dart';
import 'package:florence/features/patient/dashboard/screens/diet_detail_screen.dart';
import 'package:florence/features/patient/logging/screens/log_meal_screen.dart';
import 'package:florence/features/patient/logging/screens/log_glucose_screen.dart';

class DietUnifiedContainer extends StatefulWidget {
  final int initialTab;

  const DietUnifiedContainer({super.key, this.initialTab = 0});

  @override
  State<DietUnifiedContainer> createState() => _DietUnifiedContainerState();
}

class _DietUnifiedContainerState extends State<DietUnifiedContainer> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentIndex,
      children: [
        HeroMode(
          enabled: _currentIndex == 0,
          child: DietAnalyticsScreen(
            onSwitchToLogMeal: () => _switchTab(1),
            onSwitchToLogGlucose: () => _switchTab(2),
          ),
        ),
        HeroMode(
          enabled: _currentIndex == 1,
          child: LogMealScreen(
            onSwitchToHistory: () => _switchTab(0),
            onKeepEditing: () => _switchTab(1),
          ),
        ),
        HeroMode(
          enabled: _currentIndex == 2,
          child: LogGlucoseScreen(
            onKeepEditing: () => _switchTab(2),
          ),
        ),
      ],
    );
  }
}
