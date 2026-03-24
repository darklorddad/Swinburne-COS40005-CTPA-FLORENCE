import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import 'todays_medications_card.dart';
import 'medication_cabinet_card.dart';

/// A tabbed section for the dashboard that toggles between 
/// Today's Schedule and the Medication Cabinet.
class MedicationTabSection extends StatelessWidget {
  const MedicationTabSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: SizedBox(
        // Fixed height ensures no RenderFlex overflow and works perfectly with Desktop's IntrinsicHeight
        height: 550, 
        child: Column(
          children: [
            // Custom Floating Tab Bar
            Container(
              height: 50,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.midnightSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.getBorderColor(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                dividerColor: Colors.transparent, // Removes the default underline
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondaryColor,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: "Today's Schedule"),
                  Tab(text: "Med Cabinet"),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Tab Content Area
            const Expanded(
              child: TabBarView(
                // This allows smooth swiping on mobile, but clean clicking on desktop
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
