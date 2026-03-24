import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import 'todays_medications_card.dart';
import 'medication_cabinet_card.dart';

/// A unified, seamless section for medication management.
/// Handles the border and background for both the tabs and the content.
class MedicationSection extends StatelessWidget {
  const MedicationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    return DefaultTabController(
      length: 2,
      child: Container(
        height: 550,
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Seamless Header (Tabs)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondaryColor,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: "Today's Schedule"),
                  Tab(text: "Cabinet"),
                ],
              ),
            ),
            
            // Body (Swipeable Cards)
            const Expanded(
              child: TabBarView(
                physics: BouncingScrollPhysics(),
                children: [
                  TodaysMedicationsCard(),
                  MedicationCabinetCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
