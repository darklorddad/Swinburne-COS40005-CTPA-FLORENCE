import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../core/models/health_data_models.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/compact_health_card.dart';
import 'glucose_detail_screen.dart';

class PatientDashboardScreen extends ConsumerWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorDataAsync = ref.watch(monitorDataProvider);
    final activityAsync = ref.watch(latestActivityProvider);
    final thresholdsAsync = ref.watch(patientThresholdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
      ),
      body: monitorDataAsync.when(
        data: (monitorData) {
          return activityAsync.when(
            data: (activity) {
              return thresholdsAsync.when(
                data: (thresholds) {
                  return _buildDashboardList(context, monitorData, activity, thresholds);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error loading thresholds: $err')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading activity: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading health data: $err')),
      ),
    );
  }

  Widget _buildDashboardList(
    BuildContext context,
    List<MonitorData> monitorData,
    ActivityLog? activity,
    List<HealthThreshold> thresholds,
  ) {
    // Helper to find latest data by type
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

    final cards = [
      // 1. Glucose
      _buildCard(
        context,
        'Glucose',
        glucose?.value.toStringAsFixed(0),
        'mg/dL',
        glucose,
        Icons.water_drop_outlined,
        thresholds,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GlucoseDetailScreen(patientId: 1), // Mock ID
            ),
          );
        },
      ),
      // 2. Blood Pressure
      _buildBPCard(context, bpSystolic, bpDiastolic, thresholds),
      // 3. HbA1c
      _buildCard(
        context,
        'HbA1c',
        hba1c?.value.toStringAsFixed(1),
        '%',
        hba1c,
        Icons.pie_chart_outline,
        thresholds,
      ),
      // 4. Cholesterol
      _buildCard(
        context,
        'Cholesterol',
        cholesterol?.value.toStringAsFixed(0),
        'mg/dL',
        cholesterol,
        Icons.bloodtype_outlined,
        thresholds,
      ),
      // 5. Activity
      CompactHealthCard(
        label: 'Activity',
        value: activity != null ? '${activity.duration}' : '--',
        unit: 'min',
        status: activity != null ? 'Recorded' : 'No Data',
        timestamp: activity?.timestamp,
        icon: Icons.directions_run_outlined,
        color: activity != null ? AppTheme.activityColor : AppTheme.textSecondaryColor,
        height: 110,
        onTap: () {}, // TODO: Navigate
      ),
      // 6. BMI
      _buildCard(
        context,
        'BMI',
        bmi?.value.toStringAsFixed(1),
        '',
        bmi,
        Icons.height_outlined,
        thresholds,
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: cards.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => cards[index],
    );
  }

  Widget _buildCard(
    BuildContext context,
    String label,
    String? valueStr,
    String unit,
    MonitorData? data,
    IconData icon,
    List<HealthThreshold> thresholds, {
    VoidCallback? onTap,
  }) {
    final status = data != null
        ? HealthStatusEvaluator.evaluate(data.value, data.dataType, thresholds)
        : HealthStatus.unknown;

    return CompactHealthCard(
      label: label,
      value: valueStr ?? '--',
      unit: unit,
      status: _getStatusLabel(status),
      timestamp: data?.measuredAt,
      icon: icon,
      color: _getStatusColor(status),
      height: 110,
      onTap: onTap,
    );
  }

  Widget _buildBPCard(
    BuildContext context,
    MonitorData? systolic,
    MonitorData? diastolic,
    List<HealthThreshold> thresholds,
  ) {
    String valueStr = '--/--';
    HealthStatus status = HealthStatus.unknown;
    DateTime? timestamp;

    if (systolic != null && diastolic != null) {
      valueStr = '${systolic.value.toInt()}/${diastolic.value.toInt()}';
      timestamp = systolic.measuredAt;
      
      final sysStatus = HealthStatusEvaluator.evaluate(
          systolic.value, MonitorDataType.BLOOD_PRESSURE_SYSTOLIC, thresholds);
      final diaStatus = HealthStatusEvaluator.evaluate(
          diastolic.value, MonitorDataType.BLOOD_PRESSURE_DIASTOLIC, thresholds);

      if (sysStatus == HealthStatus.critical || diaStatus == HealthStatus.critical) {
        status = HealthStatus.critical;
      } else if (sysStatus == HealthStatus.warning || diaStatus == HealthStatus.warning) {
        status = HealthStatus.warning;
      } else {
        status = HealthStatus.safe;
      }
    }

    return CompactHealthCard(
      label: 'Blood Pressure',
      value: valueStr,
      unit: 'mmHg',
      status: _getStatusLabel(status),
      timestamp: timestamp,
      icon: Icons.monitor_heart_outlined,
      color: _getStatusColor(status),
      height: 110,
      onTap: () {}, // TODO: Navigate
    );
  }

  String _getStatusLabel(HealthStatus status) {
    switch (status) {
      case HealthStatus.safe:
        return 'Normal';
      case HealthStatus.warning:
        return 'Warning';
      case HealthStatus.critical:
        return 'Critical';
      case HealthStatus.unknown:
        return 'No Data';
    }
  }

  Color _getStatusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.safe:
        return AppTheme.primaryGreen;
      case HealthStatus.warning:
        return AppTheme.warningColor;
      case HealthStatus.critical:
        return AppTheme.errorColor;
      case HealthStatus.unknown:
        return AppTheme.textSecondaryColor;
    }
  }
}
