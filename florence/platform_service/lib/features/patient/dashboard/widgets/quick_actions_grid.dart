import 'package:flutter/material.dart';
import '../../../../core/layout/responsive_layout_system.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';

/// Quick Actions Grid
/// Grid of buttons for quick data logging
class QuickActionsGrid extends StatelessWidget {
  final VoidCallback onLogGlucose;
  final VoidCallback onLogBloodPressure;
  final VoidCallback onLogMeal;
  final VoidCallback onLogActivity;
  final VoidCallback onLogMedication;
  final VoidCallback onLogBmi;
  final VoidCallback onLogCholesterol;
  final VoidCallback onLogHba1c;

  const QuickActionsGrid({
    super.key,
    required this.onLogGlucose,
    required this.onLogBloodPressure,
    required this.onLogMeal,
    required this.onLogActivity,
    required this.onLogMedication,
    required this.onLogBmi,
    required this.onLogCholesterol,
    required this.onLogHba1c,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final titleIconColor = isDark ? Colors.blue.shade200 : AppTheme.primaryBlue;

    // Define buttons list for reuse
    final buttons = [
      _buildActionButton(context, 'Glucose', Icons.water_drop_rounded, AppTheme.primaryRed, onLogGlucose),
      _buildActionButton(context, 'B.Pressure', Icons.monitor_heart_outlined, AppTheme.primaryRed, onLogBloodPressure),
      _buildActionButton(context, 'Diet', Icons.restaurant_outlined, AppTheme.mealColor, onLogMeal),
      _buildActionButton(context, 'Activity', Icons.directions_run_rounded, AppTheme.activityColor, onLogActivity),
      // Extended actions for Desktop
      _buildActionButton(context, 'Meds', Icons.medication_outlined, AppTheme.medicationColor, onLogMedication),
      _buildActionButton(context, 'BMI', Icons.monitor_weight_outlined, AppTheme.primaryGreen, onLogBmi),
      _buildActionButton(context, 'Cholesterol', Icons.bloodtype_outlined, AppTheme.accentPurple, onLogCholesterol),
      _buildActionButton(context, 'HbA1c', Icons.pie_chart_outline, AppTheme.accentGold, onLogHba1c),
    ];

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Icons.flash_on_outlined,
                  color: titleIconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (context.isDesktop)
            Column(
              children: [
                // Row 1
                Row(
                  children: [
                    buttons[0],
                    const SizedBox(width: 12),
                    buttons[1],
                    const SizedBox(width: 12),
                    buttons[2],
                    const SizedBox(width: 12),
                    buttons[3],
                  ],
                ),
                const SizedBox(height: 12),
                // Row 2
                Row(
                  children: [
                    buttons[4],
                    const SizedBox(width: 12),
                    buttons[5],
                    const SizedBox(width: 12),
                    buttons[6],
                    const SizedBox(width: 12),
                    buttons[7],
                  ],
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buttons[0],
                const SizedBox(width: 12),
                buttons[1],
                const SizedBox(width: 12),
                buttons[2],
                const SizedBox(width: 12),
                buttons[3],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : AppTheme.borderColor.withOpacity(0.5);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 10,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
