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
    final isDesktop = context.isDesktop;

    // Define buttons list for reuse
    final buttons = [
      _buildActionButton(context, 'Glucose', Icons.water_drop_rounded, AppTheme.primaryRed, onLogGlucose, isExpanded: isDesktop),
      _buildActionButton(context, 'B.Pressure', Icons.monitor_heart_outlined, AppTheme.primaryRed, onLogBloodPressure, isExpanded: isDesktop),
      _buildActionButton(context, 'Diet', Icons.restaurant_outlined, AppTheme.mealColor, onLogMeal, isExpanded: isDesktop),
      _buildActionButton(context, 'Activity', Icons.directions_run_rounded, AppTheme.activityColor, onLogActivity, isExpanded: isDesktop),
      // Extended actions
      _buildActionButton(context, 'Meds', Icons.medication_outlined, AppTheme.medicationColor, onLogMedication, isExpanded: isDesktop),
      _buildActionButton(context, 'BMI', Icons.monitor_weight_outlined, AppTheme.primaryGreen, onLogBmi, isExpanded: isDesktop),
      _buildActionButton(context, 'Cholesterol', Icons.bloodtype_outlined, AppTheme.accentPurple, onLogCholesterol, isExpanded: isDesktop),
      _buildActionButton(context, 'HbA1c', Icons.pie_chart_outline, AppTheme.accentGold, onLogHba1c, isExpanded: isDesktop),
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
              if (!context.isDesktop) ...[
                const Spacer(),
                Icon(
                  Icons.arrow_back,
                  size: 12,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Swipe',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 10,
                      ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  size: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          if (context.isDesktop)
            Expanded(
              child: Column(
                children: [
                  // Row 1
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  ),
                  const SizedBox(height: 12),
                  // Row 2
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < buttons.length; i++) ...[
                    buttons[i],
                    if (i < buttons.length - 1) const SizedBox(width: 12),
                  ],
                ],
              ),
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
    VoidCallback onTap, {
    bool isExpanded = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : AppTheme.borderColor.withOpacity(0.5);

    Widget content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: isExpanded ? null : 90,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
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
          mainAxisAlignment: MainAxisAlignment.center,
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    if (isExpanded) {
      return Expanded(child: content);
    }
    return content;
  }
}
