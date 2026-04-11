import 'package:flutter/material.dart';
import '../../dashboard/screens/diet_detail_screen.dart';
import '../../logging/screens/log_meal_screen.dart';

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
        DietAnalyticsScreen(onSwitchToLog: () => _switchTab(1)),
        LogMealScreen(onSwitchToHistory: () => _switchTab(0)),
      ],
    );
  }
}
