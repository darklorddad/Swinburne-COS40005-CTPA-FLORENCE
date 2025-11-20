import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../core/models/health_data_models.dart'; // Updated import
import '../../../../config/routes.dart';
import 'compact_health_card.dart';
import '../screens/hba1c_detail_screen.dart';

/// Biometrics Section
/// A container widget that groups all health metric cards
class BiometricsSection extends StatelessWidget {
  final List<MonitorData> monitorData;
  final ActivityLog? latestActivity;
  final DailyPatientLog? latestMeal;
  final List<HealthThreshold> thresholds;

  const BiometricsSection({
    super.key,
    required this.monitorData,
    this.latestActivity,
    this.latestMeal,
    required this.thresholds,
  });

  @override
  Widget build(BuildContext context) {
    final cards = _buildHealthCards(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final titleIconColor = isDark ? Colors.blue.shade200 : AppTheme.primaryBlue;

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.getBorderColor(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
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
                  color: titleIconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.monitor_heart_outlined,
                  color: titleIconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Health Metrics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            children: cards.map((card) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: card,
            )).toList(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHealthCards(BuildContext context) {
    final cards = <Widget>[];
    
    MonitorData? getData(MonitorDataType type) {
      try {
        return monitorData.firstWhere((d) => d.dataType == type);
      } catch (_) {
        return null;
      }
    }

    final glucose = getData(MonitorDataType.GLUCOSE);
    final bpSystolic = getData(MonitorDataType.BLOOD_PRESSURE_SYSTOLIC);
    final bpDiastolic = getData(MonitorDataType.BLOOD_PRESSURE_DIASTOLIC);
    final hba1c = getData(MonitorDataType.HBA1C);
    final cholesterol = getData(MonitorDataType.CHOLESTEROL_TOTAL);
    final bmi = getData(MonitorDataType.BMI);

    // Glucose (Always show)
    cards.add(CompactHealthCard(
      label: 'Glucose',
      value: glucose?.value.toStringAsFixed(0) ?? '--',
      unit: 'mg/dL',
      status: _getGlucoseStatus(glucose?.value),
      timestamp: glucose?.measuredAt,
      icon: Icons.water_drop_outlined,
      color: _getGlucoseColor(glucose?.value),
      onTap: () => AppRoutes.push(context, AppRoutes.trendsDetail),
    ));

    // Blood Pressure (Always show)
    cards.add(CompactHealthCard(
      label: 'Blood Pressure',
      value: (bpSystolic != null && bpDiastolic != null)
          ? '${bpSystolic.value.toInt()}/${bpDiastolic.value.toInt()}'
          : '--/--',
      unit: 'mmHg',
      status: _getBPStatus(bpSystolic?.value, bpDiastolic?.value),
      timestamp: bpSystolic?.measuredAt,
      icon: Icons.monitor_heart_outlined,
      color: _getBPColor(bpSystolic?.value, bpDiastolic?.value),
      onTap: () => AppRoutes.push(context, AppRoutes.bloodPressureDetail),
    ));

    // HbA1c (Always show)
    cards.add(CompactHealthCard(
      label: 'HbA1c',
      value: hba1c?.value.toStringAsFixed(1) ?? '--',
      unit: '%',
      status: _getHba1cStatus(hba1c?.value),
      timestamp: hba1c?.measuredAt,
      icon: Icons.pie_chart_outline,
      color: _getHba1cColor(hba1c?.value),
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => const HbA1cDetailScreen())
      ),
    ));

    // Cholesterol (Always show)
    cards.add(CompactHealthCard(
      label: 'Cholesterol',
      value: cholesterol?.value.toStringAsFixed(0) ?? '--',
      unit: 'mg/dL',
      status: _getCholesterolStatus(cholesterol?.value),
      timestamp: cholesterol?.measuredAt,
      icon: Icons.bloodtype_outlined,
      color: _getCholesterolColor(cholesterol?.value),
      onTap: () => Helpers.showInfo(context, 'Cholesterol details coming soon'),
    ));

    // Activity (Always show)
    cards.add(CompactHealthCard(
      label: 'Activity',
      value: latestActivity != null ? '${latestActivity!.duration}' : '--',
      unit: 'min',
      status: latestActivity != null ? 'Latest Log' : 'No Data',
      timestamp: latestActivity?.timestamp,
      icon: Icons.directions_run_outlined,
      color: latestActivity != null ? AppTheme.activityColor : AppTheme.textSecondaryColor,
      onTap: () => Helpers.showInfo(context, 'Activity details coming soon'),
    ));

    // Meal (Always show)
    cards.add(CompactHealthCard(
      label: 'Last Meal',
      value: latestMeal != null ? _formatMealTime(latestMeal!.mealTime) : '--',
      unit: '',
      status: latestMeal?.mealDesc ?? 'No Data',
      timestamp: latestMeal?.logDate,
      icon: Icons.restaurant_menu,
      color: latestMeal != null ? AppTheme.mealColor : AppTheme.textSecondaryColor,
      onTap: () => AppRoutes.push(context, AppRoutes.mealImpact),
    ));

    // BMI (Always show)
    cards.add(CompactHealthCard(
      label: 'BMI',
      value: bmi?.value.toStringAsFixed(1) ?? '--',
      unit: '',
      status: bmi != null ? Helpers.getBMICategory(bmi.value) : 'No Data',
      timestamp: bmi?.measuredAt,
      icon: Icons.height_outlined,
      color: _getBmiColor(bmi?.value),
      onTap: () => Helpers.showInfo(context, 'BMI details coming soon'),
    ));

    return cards;
  }

  String _formatMealTime(String mealTime) {
    if (mealTime.isEmpty) return '';
    return mealTime[0].toUpperCase() + mealTime.substring(1).toLowerCase();
  }

  // --- Helper Methods (Updated to handle nulls) ---

  String _getGlucoseStatus(double? value) {
    if (value == null) return 'No Data';
    if (value < 70) return 'Low';
    if (value > 180) return 'High';
    return 'Normal';
  }
  
  Color _getGlucoseColor(double? value) {
    if (value == null) return AppTheme.textSecondaryColor;
    if (value < 70) return AppTheme.glucoseLow;
    if (value > 180) return AppTheme.glucoseHigh;
    return AppTheme.glucoseNormal;
  }

  String _getBPStatus(double? sys, double? dia) {
    if (sys == null || dia == null) return 'No Data';
    if (sys > 140 || dia > 90) return 'High';
    if (sys > 120 || dia > 80) return 'Elevated';
    return 'Normal';
  }

  Color _getBPColor(double? sys, double? dia) {
    if (sys == null || dia == null) return AppTheme.textSecondaryColor;
    if (sys > 140 || dia > 90) return AppTheme.errorColor;
    if (sys > 120 || dia > 80) return AppTheme.warningColor;
    return AppTheme.primaryGreen;
  }

  String _getHba1cStatus(double? value) {
    if (value == null) return 'No Data';
    if (value < 5.7) return 'Normal';
    if (value < 6.5) return 'Pre-diabetes';
    return 'Diabetes';
  }

  Color _getHba1cColor(double? value) {
    if (value == null) return AppTheme.textSecondaryColor;
    if (value >= 6.5) return AppTheme.errorColor;
    if (value >= 5.7) return AppTheme.warningColor;
    return AppTheme.primaryGreen;
  }

  String _getCholesterolStatus(double? value) {
    if (value == null) return 'No Data';
    if (value >= 240) return 'High';
    if (value >= 200) return 'Borderline';
    return 'Desirable';
  }

  Color _getCholesterolColor(double? value) {
    if (value == null) return AppTheme.textSecondaryColor;
    if (value >= 240) return AppTheme.errorColor;
    if (value >= 200) return AppTheme.warningColor;
    return AppTheme.primaryGreen;
  }

  Color _getBmiColor(double? value) {
    if (value == null) return AppTheme.textSecondaryColor;
    if (value < 18.5 || value >= 30) return AppTheme.errorColor;
    if (value >= 25) return AppTheme.warningColor;
    return AppTheme.primaryGreen;
  }
}
