import 'package:flutter/material.dart';
import '../../dashboard/screens/hba1c_detail_screen.dart';
import '../../logging/screens/log_hba1c_screen.dart';

class HbA1cUnifiedContainer extends StatefulWidget {
  final int initialTab;

  const HbA1cUnifiedContainer({super.key, this.initialTab = 0});

  @override
  State<HbA1cUnifiedContainer> createState() => _HbA1cUnifiedContainerState();
}

class _HbA1cUnifiedContainerState extends State<HbA1cUnifiedContainer> {
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
        HbA1cDetailScreen(onSwitchToLog: () => _switchTab(1)),
        LogHba1cScreen(onSwitchToHistory: () => _switchTab(0)),
      ],
    );
  }
}
