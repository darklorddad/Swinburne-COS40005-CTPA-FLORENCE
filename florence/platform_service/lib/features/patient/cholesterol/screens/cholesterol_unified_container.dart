import 'package:flutter/material.dart';
import '../../dashboard/screens/cholesterol_detail_screen.dart';
import '../../logging/screens/log_cholesterol_screen.dart';

class CholesterolUnifiedContainer extends StatefulWidget {
  final int initialTab;

  const CholesterolUnifiedContainer({super.key, this.initialTab = 0});

  @override
  State<CholesterolUnifiedContainer> createState() => _CholesterolUnifiedContainerState();
}

class _CholesterolUnifiedContainerState extends State<CholesterolUnifiedContainer> {
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
        CholesterolDetailScreen(onSwitchToLog: () => _switchTab(1)),
        LogCholesterolScreen(onSwitchToHistory: () => _switchTab(0)),
      ],
    );
  }
}
