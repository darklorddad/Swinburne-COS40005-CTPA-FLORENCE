import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../core/models/health_data_models.dart'; // Updated import
import '../../../../config/routes.dart';
import 'compact_health_card.dart';

/// Biometrics Section
/// A container widget that groups all health metric cards
class BiometricsSection extends StatelessWidget {
  final List<MonitorData> monitorData;
  final ActivityLog? latestActivity;
  final List<HealthThreshold> thresholds;

  const BiometricsSection({
    super.key,
    required this.monitorData,
    this.latestActivity,
    required this.thresholds,
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
    
    // Helper to find latest data
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

    // Glucose
    if (glucose != null) {
      cards.add(_buildCard(
        context,
        'Glucose',
        glucose.value.toStringAsFixed(0),
        'mg/dL',
        glucose,
        Icons.water_drop_outlined,
        // Ensure this route points to GlucoseDetailScreen in routes.dart
        onTap: () => AppRoutes.push(context, AppRoutes.trendsDetail),
      ));
    }

    // Blood Pressure
    if (bpSystolic != null && bpDiastolic != null) {
      cards.add(_buildBPCard(context, bpSystolic, bpDiastolic));
    }

    // HbA1c
    if (hba1c != null) {
      cards.add(_buildCard(
        context,
        'HbA1c',
        hba1c.value.toStringAsFixed(1),
        '%',
        hba1c,
        Icons.pie_chart_outline,
      ));
    }

    // Cholesterol
    if (cholesterol != null) {
      cards.add(_buildCard(
        context,
        'Cholesterol',
        cholesterol.value.toStringAsFixed(0),
        'mg/dL',
        cholesterol,
        Icons.bloodtype_outlined,
      ));
    }

    // Activity
    if (latestActivity != null) {
      cards.add(CompactHealthCard(
        label: 'Activity',
        value: '${latestActivity!.duration}',
        unit: 'min',
        status: 'Recorded',
        timestamp: latestActivity!.timestamp,
        icon: Icons.directions_run_outlined,
        color: AppTheme.activityColor,
        onTap: () => Helpers.showInfo(context, 'Activity details coming soon'),
      ));
    }

    // BMI
    if (bmi != null) {
      cards.add(_buildCard(
        context,
        'BMI',
        bmi.value.toStringAsFixed(1),
        '',
        bmi,
        Icons.height_outlined,
      ));
    }

    return cards;
  }

  Widget _buildCard(
    BuildContext context,
    String label,
    String value,
    String unit,
    MonitorData data,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final status = HealthStatusEvaluator.evaluate(data.value, data.dataType, thresholds);
    return CompactHealthCard(
      label: label,
      value: value,
      unit: unit,
      status: _getStatusLabel(status),
      timestamp: data.measuredAt,
      icon: icon,
      color: _getStatusColor(status),
      onTap: onTap ?? () => Helpers.showInfo(context, '$label details coming soon'),
    );
  }

  Widget _buildBPCard(BuildContext context, MonitorData sys, MonitorData dia) {
    final sysStatus = HealthStatusEvaluator.evaluate(sys.value, sys.dataType, thresholds);
    final diaStatus = HealthStatusEvaluator.evaluate(dia.value, dia.dataType, thresholds);
    
    HealthStatus status = HealthStatus.safe;
    if (sysStatus == HealthStatus.critical || diaStatus == HealthStatus.critical) {
      status = HealthStatus.critical;
    } else if (sysStatus == HealthStatus.warning || diaStatus == HealthStatus.warning) {
      status = HealthStatus.warning;
    }

    return CompactHealthCard(
      label: 'Blood Pressure',
      value: '${sys.value.toInt()}/${dia.value.toInt()}',
      unit: 'mmHg',
      status: _getStatusLabel(status),
      timestamp: sys.measuredAt,
      icon: Icons.monitor_heart_outlined,
      color: _getStatusColor(status),
      onTap: () => Helpers.showInfo(context, 'Blood Pressure details coming soon'),
    );
  }

  String _getStatusLabel(HealthStatus status) {
    switch (status) {
      case HealthStatus.safe: return 'Normal';
      case HealthStatus.warning: return 'Warning';
      case HealthStatus.critical: return 'Critical';
      default: return 'No Data';
    }
  }

  Color _getStatusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.safe: return AppTheme.primaryGreen;
      case HealthStatus.warning: return AppTheme.warningColor;
      case HealthStatus.critical: return AppTheme.errorColor;
      default: return AppTheme.textSecondaryColor;
    }
  }
}
