import 'package:flutter/material.dart';
import 'package:florence/features/patient/dashboard/screens/glucose_detail_screen.dart';
import 'package:florence/features/patient/logging/screens/log_glucose_screen.dart';

class GlucoseUnifiedContainer extends StatefulWidget {
  final int initialTab;

  const GlucoseUnifiedContainer({super.key, this.initialTab = 0});

  @override
  State<GlucoseUnifiedContainer> createState() => _GlucoseUnifiedContainerState();
}

class _GlucoseUnifiedContainerState extends State<GlucoseUnifiedContainer> {
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
        GlucoseDetailScreen(onSwitchToLog: () => _switchTab(1)),
        LogGlucoseScreen(onSwitchToHistory: () => _switchTab(0)),
      ],
    );
  }
}
