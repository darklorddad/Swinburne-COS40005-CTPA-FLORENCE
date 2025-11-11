import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';

/// Quick Stats Grid
/// Displays key health metrics in a grid layout
class QuickStatsGrid extends StatelessWidget {
  final double averageGlucose;
  final double hba1c;
  final int todayReadings;
  final int streakDays;
  
  const QuickStatsGrid({
    super.key,
    required this.averageGlucose,
    required this.hba1c,
    required this.todayReadings,
    required this.streakDays,
  });
  
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          label: 'Avg Glucose',
          value: averageGlucose.toStringAsFixed(0),
          unit: 'mg/dL',
          icon: Icons.show_chart,
          color: AppTheme.primaryBlue,
        ),
        StatCard(
          label: 'HbA1c',
          value: hba1c.toStringAsFixed(1),
          unit: '%',
          icon: Icons.pie_chart,
          color: AppTheme.primaryGreen,
        ),
        StatCard(
          label: 'Today\'s Logs',
          value: todayReadings.toString(),
          unit: 'readings',
          icon: Icons.water_drop_outlined,
          color: AppTheme.mealColor,
        ),
        StatCard(
          label: 'Streak',
          value: streakDays.toString(),
          unit: 'days',
          icon: Icons.local_fire_department,
          color: AppTheme.primaryRed,
          trend: '+2 from last week',
          isTrendPositive: true,
        ),
      ],
    );
  }
}