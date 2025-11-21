import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../core/models/health_data_models.dart'; // Updated import
import '../../../../config/routes.dart';
import 'compact_health_card.dart';
import '../screens/hba1c_detail_screen.dart';
import '../screens/cholesterol_detail_screen.dart';

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
      final data = monitorData.where((d) => d.dataType == type).toList();
      if (data.isEmpty) return null;
      // Return the reading with the latest timestamp
      return data.reduce((curr, next) => 
        curr.measuredAt.isAfter(next.measuredAt) ? curr : next);
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
      status: _getGlucoseStatus(glucose?.value, thresholds),
      timestamp: glucose?.measuredAt,
      icon: Icons.water_drop_outlined,
      color: _getGlucoseColor(glucose?.value, thresholds),
      onTap: () => AppRoutes.push(context, AppRoutes.trendsDetail),
    ));

    // Blood Pressure (Always show)
    cards.add(CompactHealthCard(
      label: 'Blood Pressure',
      value: (bpSystolic != null && bpDiastolic != null)
          ? '${bpSystolic.value.toInt()}/${bpDiastolic.value.toInt()}'
          : '--/--',
      unit: 'mmHg',
      status: _getBPStatus(bpSystolic?.value, bpDiastolic?.value, thresholds),
      timestamp: bpSystolic?.measuredAt,
      icon: Icons.monitor_heart_outlined,
      color: _getBPColor(bpSystolic?.value, bpDiastolic?.value, thresholds),
      onTap: () => AppRoutes.push(context, AppRoutes.bloodPressureDetail),
    ));

    // HbA1c (Always show)
    cards.add(CompactHealthCard(
      label: 'HbA1c',
      value: hba1c?.value.toStringAsFixed(1) ?? '--',
      unit: '%',
      status: _getHba1cStatus(hba1c?.value, thresholds),
      timestamp: hba1c?.measuredAt,
      icon: Icons.pie_chart_outline,
      color: _getHba1cColor(hba1c?.value, thresholds),
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
      status: _getCholesterolStatus(cholesterol?.value, thresholds),
      timestamp: cholesterol?.measuredAt,
      icon: Icons.bloodtype_outlined,
      color: _getCholesterolColor(cholesterol?.value, thresholds),
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => const CholesterolDetailScreen())
      ),
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
      label: 'Meal',
      value: latestMeal != null ? _formatMealTime(latestMeal!.mealTime) : '--',
      unit: '',
      status: _getMealStatus(latestMeal),
      timestamp: latestMeal?.logDate,
      icon: Icons.restaurant_menu,
      color: _getMealColor(latestMeal),
      onTap: () => AppRoutes.push(context, AppRoutes.mealImpact),
    ));

    // BMI (Always show)
    cards.add(CompactHealthCard(
      label: 'BMI',
      value: bmi?.value.toStringAsFixed(1) ?? '--',
      unit: '',
      status: _getBmiStatus(bmi?.value, thresholds),
      timestamp: bmi?.measuredAt,
      icon: Icons.height_outlined,
      color: _getBmiColor(bmi?.value, thresholds),
      onTap: () => Helpers.showInfo(context, 'BMI details coming soon'),
    ));

    return cards;
  }

  String _formatMealTime(String mealTime) {
    if (mealTime.isEmpty) return '';
    return mealTime[0].toUpperCase() + mealTime.substring(1).toLowerCase();
  }

  String _getMealStatus(DailyPatientLog? meal) {
    if (meal == null) return 'No Data';

    // 1. If there is a text description, show it
    if (meal.mealDesc != null && meal.mealDesc!.isNotEmpty) {
      return meal.mealDesc!;
    }

    // 2. If no description but glucose was logged, show that
    if (meal.glucoseBeforeMeal != null || meal.glucoseAfterMeal != null) {
      return 'Glucose Tracked';
    }

    // 3. Fallback if it exists but has no details
    return 'Logged';
  }

  Color _getMealColor(DailyPatientLog? meal) {
    if (meal == null) return AppTheme.textSecondaryColor; // Grey (Empty)

    // If we have BOTH readings, check for high spikes
    if (meal.glucoseBeforeMeal != null && meal.glucoseAfterMeal != null) {
      final spike = meal.glucoseAfterMeal! - meal.glucoseBeforeMeal!;
      
      if (spike > 50) return AppTheme.errorColor;    // Red: High Spike (>50)
      if (spike > 30) return AppTheme.warningColor;  // Orange: Elevated Spike (30-50)
    }

    // Default: Green
    // Used for stable spikes (<=30) OR if just the meal is logged (No glucose data yet)
    return AppTheme.primaryGreen; 
  }

  // --- Helper Methods (Updated to handle nulls) ---

  HealthThreshold? _getThreshold(List<HealthThreshold> thresholds, MonitorDataType type) {
    try {
      return thresholds.firstWhere((t) => t.dataType == type);
    } catch (_) {
      return null;
    }
  }

  String _getGlucoseStatus(double? value, List<HealthThreshold> thresholds) {
    if (value == null) return 'No Data';
    final t = _getThreshold(thresholds, MonitorDataType.GLUCOSE);
    if (t == null) return 'Recorded';

    if (value < t.minValue) return 'Low';
    if (value > t.maxValue) return 'High';
    return 'Normal';
  }
  
  Color _getGlucoseColor(double? value, List<HealthThreshold> thresholds) {
    if (value == null) return AppTheme.textSecondaryColor;
    final t = _getThreshold(thresholds, MonitorDataType.GLUCOSE);
    if (t == null) return AppTheme.primaryBlue; // Neutral blue if no target

    if (value < t.minValue) return AppTheme.errorColor;
    if (value > t.maxValue) return AppTheme.errorColor;
    return AppTheme.primaryGreen;
  }

  String _getBPStatus(double? sys, double? dia, List<HealthThreshold> thresholds) {
    if (sys == null || dia == null) return 'No Data';
    final tSys = _getThreshold(thresholds, MonitorDataType.BLOOD_PRESSURE_SYSTOLIC);
    final tDia = _getThreshold(thresholds, MonitorDataType.BLOOD_PRESSURE_DIASTOLIC);
    
    if (tSys == null || tDia == null) return 'Recorded';

    if (sys > tSys.maxValue || dia > tDia.maxValue) return 'Elevated';
    if (sys < tSys.minValue || dia < tDia.minValue) return 'Low';
    return 'Normal';
  }

  Color _getBPColor(double? sys, double? dia, List<HealthThreshold> thresholds) {
    if (sys == null || dia == null) return AppTheme.textSecondaryColor;
    final tSys = _getThreshold(thresholds, MonitorDataType.BLOOD_PRESSURE_SYSTOLIC);
    final tDia = _getThreshold(thresholds, MonitorDataType.BLOOD_PRESSURE_DIASTOLIC);

    if (tSys == null || tDia == null) return AppTheme.primaryBlue;

    if (sys > tSys.maxValue || dia > tDia.maxValue) return AppTheme.errorColor;
    if (sys < tSys.minValue || dia < tDia.minValue) return AppTheme.warningColor;
    return AppTheme.primaryGreen;
  }

  String _getHba1cStatus(double? value, List<HealthThreshold> thresholds) {
    if (value == null) return 'No Data';
    final t = _getThreshold(thresholds, MonitorDataType.HBA1C);
    if (t == null) return 'Recorded';

    if (value <= t.maxValue) return 'Normal';
    return 'High';
  }

  Color _getHba1cColor(double? value, List<HealthThreshold> thresholds) {
    if (value == null) return AppTheme.textSecondaryColor;
    final t = _getThreshold(thresholds, MonitorDataType.HBA1C);
    if (t == null) return AppTheme.primaryBlue;

    if (value <= t.maxValue) return AppTheme.primaryGreen;
    return AppTheme.errorColor;
  }

  String _getCholesterolStatus(double? value, List<HealthThreshold> thresholds) {
    if (value == null) return 'No Data';
    final t = _getThreshold(thresholds, MonitorDataType.CHOLESTEROL_TOTAL);
    if (t == null) return 'Recorded';

    if (value > t.maxValue) return 'High';
    return 'Desirable';
  }

  Color _getCholesterolColor(double? value, List<HealthThreshold> thresholds) {
    if (value == null) return AppTheme.textSecondaryColor;
    final t = _getThreshold(thresholds, MonitorDataType.CHOLESTEROL_TOTAL);
    if (t == null) return AppTheme.primaryBlue;

    if (value > t.maxValue) return AppTheme.errorColor;
    return AppTheme.primaryGreen;
  }

  String _getBmiStatus(double? value, List<HealthThreshold> thresholds) {
    if (value == null) return 'No Data';
    final t = _getThreshold(thresholds, MonitorDataType.BMI);
    if (t == null) return 'Recorded';

    if (value < t.minValue) return 'Low';
    if (value > t.maxValue) return 'High';
    return 'Normal';
  }

  Color _getBmiColor(double? value, List<HealthThreshold> thresholds) {
    if (value == null) return AppTheme.textSecondaryColor;
    final t = _getThreshold(thresholds, MonitorDataType.BMI);
    if (t == null) return AppTheme.primaryBlue;

    if (value < t.minValue) return AppTheme.warningColor; // Underweight
    if (value > t.maxValue) return AppTheme.errorColor; // Overweight/Obese
    return AppTheme.primaryGreen;
  }
}
