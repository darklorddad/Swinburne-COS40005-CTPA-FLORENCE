import 'package:flutter/material.dart';
import 'package:florence/features/clinician/models/patient.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';

class PatientFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? color;

  const PatientFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: color?.withValues(alpha: 0.2) ?? AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: color ?? AppTheme.primaryColor,
    );
  }
}

class PatientFilters extends StatelessWidget {
  final void Function(RiskLevel?) onRiskFilterChanged;
  final void Function(int) onLastUpdateFilterChanged;
  final RiskLevel? selectedRiskLevel;
  final int selectedUpdateFilter; // 0: All, 1: Today, 2: Last 3 days, 3: Last week, 4: Last 3 weeks

  const PatientFilters({
    super.key,
    required this.onRiskFilterChanged,
    required this.onLastUpdateFilterChanged,
    this.selectedRiskLevel,
    this.selectedUpdateFilter = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Text(
            'Risk Level',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              PatientFilterChip(
                label: 'All',
                isSelected: selectedRiskLevel == null,
                onSelected: () => onRiskFilterChanged(null),
              ),
              const SizedBox(width: 8),
              PatientFilterChip(
                label: 'High Risk',
                isSelected: selectedRiskLevel == RiskLevel.high,
                onSelected: () => onRiskFilterChanged(RiskLevel.high),
                color: AppTheme.highRiskColor,
              ),
              const SizedBox(width: 8),
              PatientFilterChip(
                label: 'Medium Risk',
                isSelected: selectedRiskLevel == RiskLevel.medium,
                onSelected: () => onRiskFilterChanged(RiskLevel.medium),
                color: AppTheme.mediumRiskColor,
              ),
              const SizedBox(width: 8),
              PatientFilterChip(
                label: 'Low Risk',
                isSelected: selectedRiskLevel == RiskLevel.low,
                onSelected: () => onRiskFilterChanged(RiskLevel.low),
                color: AppTheme.lowRiskColor,
              ),
            ],
          ),
        ),
        
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            'Last Update',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              PatientFilterChip(
                label: 'All Time',
                isSelected: selectedUpdateFilter == 0,
                onSelected: () => onLastUpdateFilterChanged(0),
              ),
              const SizedBox(width: 8),
              PatientFilterChip(
                label: 'Today',
                isSelected: selectedUpdateFilter == 1,
                onSelected: () => onLastUpdateFilterChanged(1),
              ),
              const SizedBox(width: 8),
              PatientFilterChip(
                label: 'Last 3 Days',
                isSelected: selectedUpdateFilter == 2,
                onSelected: () => onLastUpdateFilterChanged(2),
              ),
              const SizedBox(width: 8),
              PatientFilterChip(
                label: 'Last Week',
                isSelected: selectedUpdateFilter == 3,
                onSelected: () => onLastUpdateFilterChanged(3),
              ),
              const SizedBox(width: 8),
              PatientFilterChip(
                label: 'Last 3 Weeks',
                isSelected: selectedUpdateFilter == 4,
                onSelected: () => onLastUpdateFilterChanged(4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
