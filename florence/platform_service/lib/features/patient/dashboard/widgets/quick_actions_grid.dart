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

    final actions = [
      (label: 'Glucose', icon: Icons.water_drop_rounded, color: AppTheme.primaryRed, onTap: onLogGlucose),
      (label: 'B.Pressure', icon: Icons.monitor_heart_outlined, color: AppTheme.primaryRed, onTap: onLogBloodPressure),
      (label: 'Diet', icon: Icons.restaurant_outlined, color: AppTheme.mealColor, onTap: onLogMeal),
      (label: 'Activity', icon: Icons.directions_run_rounded, color: AppTheme.activityColor, onTap: onLogActivity),
      (label: 'Meds', icon: Icons.medication_outlined, color: AppTheme.medicationColor, onTap: onLogMedication),
      (label: 'BMI', icon: Icons.monitor_weight_outlined, color: AppTheme.primaryGreen, onTap: onLogBmi),
      (label: 'Cholesterol', icon: Icons.bloodtype_outlined, color: AppTheme.accentPurple, onTap: onLogCholesterol),
      (label: 'HbA1c', icon: Icons.pie_chart_outline, color: AppTheme.accentGold, onTap: onLogHba1c),
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
                        for (var i = 0; i < 4; i++) ...[
                          _buildActionButton(context, actions[i].label, actions[i].icon, actions[i].color, actions[i].onTap),
                          if (i < 3) const SizedBox(width: 12),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Row 2
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 4; i < 8; i++) ...[
                          _buildActionButton(context, actions[i].label, actions[i].icon, actions[i].color, actions[i].onTap),
                          if (i < 7) const SizedBox(width: 12),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate item width to fit exactly 4 items
                // Available width minus 3 gaps of 12px each
                final itemWidth = (constraints.maxWidth - (3 * 12)) / 4;
                
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        _buildActionButton(
                          context, 
                          actions[i].label, 
                          actions[i].icon, 
                          actions[i].color, 
                          actions[i].onTap, 
                          isExpanded: false,
                          fixedWidth: itemWidth,
                        ),
                        if (i < actions.length - 1) const SizedBox(width: 12),
                      ],
                    ],
                  ),
                );
              },
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
    double? fixedWidth,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : AppTheme.borderColor.withOpacity(0.5);

    Widget content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: isExpanded ? null : (fixedWidth ?? 90),
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
