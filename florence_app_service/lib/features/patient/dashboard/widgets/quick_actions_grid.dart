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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        ActionCard(
          title: 'Log Glucose',
          subtitle: 'Track blood sugar',
          icon: Icons.water_drop,
          iconColor: AppTheme.primaryRed,
          onTap: onLogGlucose,
        ),
        ActionCard(
          title: 'Log Meal',
          subtitle: 'Record what you ate',
          icon: Icons.restaurant,
          iconColor: AppTheme.mealColor,
          onTap: onLogMeal,
        ),
        ActionCard(
          title: 'Log Activity',
          subtitle: 'Track exercise',
          icon: Icons.directions_run,
          iconColor: AppTheme.activityColor,
          onTap: onLogActivity,
        ),
        ActionCard(
          title: 'Log Medication',
          subtitle: 'Record medicines',
          icon: Icons.medication,
          iconColor: AppTheme.medicationColor,
          onTap: onLogMedication,
        ),
      ],
    );
  }
}