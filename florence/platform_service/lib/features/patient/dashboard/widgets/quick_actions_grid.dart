import 'package:flutter/material.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';

/// Quick Actions Grid
/// Grid of buttons for quick data logging
class QuickActionsGrid extends StatelessWidget {
  final VoidCallback onLogGlucose;
  final VoidCallback onLogMeal;
  final VoidCallback onLogActivity;
  final VoidCallback onLogMedication;
  
  const QuickActionsGrid({
    super.key,
    required this.onLogGlucose,
    required this.onLogMeal,
    required this.onLogActivity,
    required this.onLogMedication,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(
          context,
          'Glucose',
          Icons.water_drop_rounded,
          AppTheme.primaryRed,
          onLogGlucose,
        ),
        _buildActionButton(
          context,
          'Meal',
          Icons.restaurant_rounded,
          AppTheme.mealColor,
          onLogMeal,
        ),
        _buildActionButton(
          context,
          'Activity',
          Icons.directions_run_rounded,
          AppTheme.activityColor,
          onLogActivity,
        ),
        _buildActionButton(
          context,
          'Meds',
          Icons.medication_rounded,
          AppTheme.medicationColor,
          onLogMedication,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: (MediaQuery.of(context).size.width - 64) / 4, // Distribute space
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppTheme.borderColor.withOpacity(0.5),
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
                    color: AppTheme.textPrimaryColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}