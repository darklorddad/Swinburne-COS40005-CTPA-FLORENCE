import 'package:flutter/material.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';

/// Quick Actions Grid
/// Grid of buttons for quick data logging
class QuickActionsGrid extends StatelessWidget {
  final VoidCallback onLogGlucose;
  final VoidCallback onLogBloodPressure;
  final VoidCallback onLogCholesterol;
  final VoidCallback onLogActivity;
  
  const QuickActionsGrid({
    super.key,
    required this.onLogGlucose,
    required this.onLogBloodPressure,
    required this.onLogCholesterol,
    required this.onLogActivity,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final titleIconColor = isDark ? Colors.blue.shade200 : AppTheme.primaryBlue;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(
                context,
                'Glucose',
                Icons.water_drop_rounded,
                AppTheme.primaryRed,
                onLogGlucose,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                context,
                'Pressure',
                Icons.monitor_heart_outlined,
                AppTheme.primaryRed,
                onLogBloodPressure,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                context,
                'Cholesterol',
                Icons.bloodtype_outlined,
                AppTheme.accentPurple,
                onLogCholesterol,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                context,
                'Activity',
                Icons.directions_run_rounded,
                AppTheme.activityColor,
                onLogActivity,
              ),
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
