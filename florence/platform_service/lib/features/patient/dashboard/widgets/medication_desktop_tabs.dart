import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import 'todays_medications_card.dart';
import 'medication_cabinet_card.dart';

/// A "connected" tab bar section for desktop users.
/// The tabs are styled to look like folder tabs attached to the cards below.
class MedicationDesktopTabs extends StatelessWidget {
  const MedicationDesktopTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabBackgroundColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    return DefaultTabController(
      length: 2,
      child: SizedBox(
        height: 550, // Prevents RenderFlex overflow and matches mobile height
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Connected" Tab Bar Header
            Container(
              width: 380, // Neat sizing for desktop
              decoration: BoxDecoration(
                color: tabBackgroundColor,
                // Only round the top corners to connect seamlessly to the card below
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  top: BorderSide(color: borderColor),
                  left: BorderSide(color: borderColor),
                  right: BorderSide(color: borderColor),
                  // Bottom border is omitted to "attach" to the card
                ),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondaryColor,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: "Today's Schedule"),
                  Tab(text: "Cabinet"),
                ],
              ),
            ),
            
            // Connected Card Content
            const Expanded(
              child: TabBarView(
                physics: NeverScrollableScrollPhysics(), // Desktop users click rather than swipe
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
