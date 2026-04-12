import 'package:flutter/material.dart';
import 'package:florence/features/patient/dashboard/screens/activity_detail_screen.dart';
import 'package:florence/features/patient/logging/screens/log_activity_screen.dart';

class ActivityUnifiedContainer extends StatefulWidget {
  final int initialTab;

  const ActivityUnifiedContainer({super.key, this.initialTab = 0});

  @override
  State<ActivityUnifiedContainer> createState() => _ActivityUnifiedContainerState();
}

class _ActivityUnifiedContainerState extends State<ActivityUnifiedContainer> {
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
        ActivityDetailScreen(onSwitchToLog: () => _switchTab(1)),
        LogActivityScreen(onSwitchToHistory: () => _switchTab(0)),
      ],
    );
  }
}
