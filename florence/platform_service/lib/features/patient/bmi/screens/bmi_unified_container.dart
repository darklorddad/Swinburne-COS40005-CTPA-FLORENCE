import 'package:flutter/material.dart';
import 'package:florence/features/patient/dashboard/screens/bmi_detail_screen.dart';
import 'package:florence/features/patient/logging/screens/log_bmi_screen.dart';

class BmiUnifiedContainer extends StatefulWidget {
  final int initialTab;

  const BmiUnifiedContainer({super.key, this.initialTab = 0});

  @override
  State<BmiUnifiedContainer> createState() => _BmiUnifiedContainerState();
}

class _BmiUnifiedContainerState extends State<BmiUnifiedContainer> {
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
        BmiDetailScreen(onSwitchToLog: () => _switchTab(1)),
        LogBmiScreen(onSwitchToHistory: () => _switchTab(0)),
      ],
    );
  }
}
