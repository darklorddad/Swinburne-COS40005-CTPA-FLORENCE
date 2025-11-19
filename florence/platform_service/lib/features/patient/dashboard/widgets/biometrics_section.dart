import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../core/providers/health_data_provider.dart';
import '../../../../config/routes.dart';
import 'compact_health_card.dart';

/// Biometrics Section
/// A container widget that groups all health metric cards
class BiometricsSection extends StatelessWidget {
  final HealthDataProvider healthData;

  const BiometricsSection({
    super.key,
    required this.healthData,
  });

  @override
  Widget build(BuildContext context) {
    final cards = _buildHealthCards(context);

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Health Monitor',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 1,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 3.2,
            children: cards,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHealthCards(BuildContext context) {
    final cards = <Widget>[];
    final latestGlucose = healthData.latestGlucose;
    final latestBP = healthData.latestBloodPressure;
    final latestHba1c = healthData.latestHbA1c;
    final latestCholesterol = healthData.latestCholesterol;
    final latestBmi = healthData.latestBmi;

    // Glucose
    cards.add(CompactHealthCard(
      label: 'Glucose',
      value: latestGlucose?.value.toStringAsFixed(0) ?? '--',
      unit: 'mg/dL',
      status: _getGlucoseStatus(latestGlucose?.value),
      timestamp: latestGlucose?.timestamp,
      icon: Icons.water_drop_outlined,
      color: _getGlucoseColor(latestGlucose?.value),
      onTap: () => AppRoutes.push(context, AppRoutes.trendsDetail),
    ));

    // Blood Pressure
    cards.add(CompactHealthCard(
      label: 'Blood Pressure',
      value: latestBP != null ? '${latestBP.value}' : '--/--',
      unit: 'mmHg',
      status: _getBPStatus(latestBP?.systolic, latestBP?.diastolic),
      timestamp: latestBP?.timestamp,
      icon: Icons.monitor_heart_outlined,
      color: _getBPColor(latestBP?.systolic, latestBP?.diastolic),
      onTap: () => Helpers.showInfo(context, 'Blood Pressure details coming soon'),
    ));

    // HbA1c
    cards.add(CompactHealthCard(
      label: 'HbA1c',
      value: latestHba1c?.value.toStringAsFixed(1) ?? '--',
      unit: '%',
      status: latestHba1c?.interpretation ?? 'No Data',
      timestamp: latestHba1c?.testDate,
      icon: Icons.pie_chart_outline,
      color: _getHba1cColor(latestHba1c?.value),
      onTap: () => Helpers.showInfo(context, 'HbA1c details coming soon'),
    ));

    // Cholesterol
    cards.add(CompactHealthCard(
      label: 'Cholesterol',
      value: latestCholesterol?.value.toStringAsFixed(0) ?? '--',
      unit: 'mg/dL',
      status: _getCholesterolStatus(latestCholesterol?.value),
      timestamp: latestCholesterol?.testDate,
      icon: Icons.bloodtype_outlined,
      color: _getCholesterolColor(latestCholesterol?.value),
      onTap: () => Helpers.showInfo(context, 'Cholesterol details coming soon'),
    ));

    // BMI
    cards.add(CompactHealthCard(
      label: 'BMI',
      value: latestBmi?.value.toStringAsFixed(1) ?? '--',
      unit: '',
      status: latestBmi != null ? Helpers.getBMICategory(latestBmi.value) : 'No Data',
      timestamp: latestBmi?.testDate,
      icon: Icons.height_outlined,
      color: _getBmiColor(latestBmi?.value),
      onTap: () => Helpers.showInfo(context, 'BMI details coming soon'),
    ));

    // Activity
    final latestActivity = healthData.latestActivity;
    cards.add(CompactHealthCard(
      label: 'Activity',
      value: latestActivity != null ? '${latestActivity.duration}' : '--',
      unit: 'min',
      status: latestActivity != null ? 'Recorded' : 'No Data',
      timestamp: latestActivity?.timestamp,
      icon: Icons.directions_run_outlined,
      color: latestActivity != null ? AppTheme.activityColor : AppTheme.textSecondaryColor,
      onTap: () => Helpers.showInfo(context, 'Activity details coming soon'),
    ));

    return cards;
  }

  // --- Health Metric Helpers ---

  Color _getGlucoseColor(double? value) {
    if (value == null) return AppTheme.textSecondaryColor;
    if (value < 70) return AppTheme.glucoseLow;
    if (value > 180) return AppTheme.glucoseHigh;
    return AppTheme.glucoseNormal;
  }

  String _getGlucoseStatus(double? value) {
    if (value == null) return 'No Data';
    if (value < 70) return 'Low';
    if (value > 180) return 'High';
    return 'Normal';
  }

  Color _getBPColor(double? systolic, double? diastolic) {
    if (systolic == null || diastolic == null) return AppTheme.textSecondaryColor;
    if (systolic > 140 || diastolic > 90) return AppTheme.errorColor;
    if (systolic > 120 || diastolic > 80) return AppTheme.warningColor;
    return AppTheme.primaryGreen;
  }

  String _getBPStatus(double? systolic, double? diastolic) {
    if (systolic == null || diastolic == null) return 'No Data';
    if (systolic > 140 || diastolic > 90) return 'High';
    if (systolic > 120 || diastolic > 80) return 'Elevated';
    return 'Normal';
  }

  Color _getHba1cColor(double? value) {
    if (value == null) return AppTheme.textSecondaryColor;
    if (value >= 7.0) return AppTheme.errorColor;
    if (value >= 6.5) return AppTheme.warningColor;
    return AppTheme.primaryGreen;
  }

  Color _getCholesterolColor(double? value) {
    if (value == null) return AppTheme.textSecondaryColor;
    if (value >= 240) return AppTheme.errorColor;
    if (value >= 200) return AppTheme.warningColor;
    return AppTheme.primaryGreen;
  }

  String _getCholesterolStatus(double? value) {
    if (value == null) return 'No Data';
    if (value >= 240) return 'High';
    if (value >= 200) return 'Borderline';
    return 'Desirable';
  }

  Color _getBmiColor(double? value) {
    if (value == null) return AppTheme.textSecondaryColor;
    if (value < 18.5 || value >= 30) return AppTheme.errorColor;
    if (value >= 25) return AppTheme.warningColor;
    return AppTheme.primaryGreen;
  }
}
