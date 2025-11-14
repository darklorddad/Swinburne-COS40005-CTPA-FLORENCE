import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../core/models/health_data_models.dart';

/// Quick Stats Grid
/// Displays key health metrics in a grid layout
class QuickStatsGrid extends StatelessWidget {
  final double averageGlucose;
  final double hba1c;
  final BloodPressureReading? bloodPressure;
  final double cholesterol;
  final double bmi;
  final int todayReadings;

  const QuickStatsGrid({
    super.key,
    required this.averageGlucose,
    required this.hba1c,
    required this.bloodPressure,
    required this.cholesterol,
    required this.bmi,
    required this.todayReadings,
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
          value: averageGlucose > 0 ? averageGlucose.toStringAsFixed(0) : '--',
          unit: 'mg/dL',
          icon: Icons.show_chart,
          color: AppTheme.primaryBlue,
        ),
        StatCard(
          label: 'HbA1c',
          value: hba1c > 0 ? hba1c.toStringAsFixed(1) : '--',
          unit: '%',
          icon: Icons.pie_chart,
          color: AppTheme.primaryGreen,
        ),
        StatCard(
          label: 'Blood Pressure',
          value: bloodPressure?.value ?? '--',
          unit: 'mmHg',
          icon: Icons.monitor_heart,
          color: AppTheme.primaryRed,
        ),
        StatCard(
          label: 'Cholesterol',
          value: cholesterol > 0 ? cholesterol.toStringAsFixed(0) : '--',
          unit: 'mg/dL',
          icon: Icons.bloodtype,
          color: AppTheme.accentPurple,
        ),
        StatCard(
          label: 'BMI',
          value: bmi > 0 ? bmi.toStringAsFixed(1) : '--',
          unit: '',
          icon: Icons.height,
          color: AppTheme.activityColor,
        ),
        StatCard(
          label: 'Today\'s Logs',
          value: todayReadings.toString(),
          unit: 'readings',
          icon: Icons.water_drop_outlined,
          color: AppTheme.mealColor,
        ),
      ],
    );
  }
}
