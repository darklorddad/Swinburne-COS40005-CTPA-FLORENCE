import 'package:flutter/material.dart';
import '../../dashboard/screens/blood_pressure_detail_screen.dart';
import '../../logging/screens/log_blood_pressure_screen.dart';

class BloodPressureUnifiedContainer extends StatefulWidget {
  final int initialTab;

  const BloodPressureUnifiedContainer({super.key, this.initialTab = 0});

  @override
  State<BloodPressureUnifiedContainer> createState() => _BloodPressureUnifiedContainerState();
}

class _BloodPressureUnifiedContainerState extends State<BloodPressureUnifiedContainer> {
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
        BloodPressureDetailScreen(onSwitchToLog: () => _switchTab(1)),
        LogBloodPressureScreen(onSwitchToHistory: () => _switchTab(0)),
      ],
    );
  }
}
