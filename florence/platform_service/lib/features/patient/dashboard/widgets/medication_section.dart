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
        // clipBehavior ensures the square header doesn't bleed out of the rounded corners
        clipBehavior: Clip.antiAlias,
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
            // 50/50 Split Seamless Header
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.02) : AppTheme.backgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
              ),
              // ClipRRect prevents the transparent hover box from bleeding out of the corners
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                child: TabBar(
                  dividerColor: borderColor, // Creates a clean separator line under the tabs
                  indicatorSize: TabBarIndicatorSize.tab, // Forces exact 50/50 width
                  indicator: BoxDecoration(
                    color: containerColor, // Matches the card background for a seamless look
                    border: const Border(
                      top: BorderSide(color: AppTheme.primaryBlue, width: 3), // Blue highlight on top
                    ),
                  ),
                  labelColor: AppTheme.primaryBlue,
                  unselectedLabelColor: AppTheme.textSecondaryColor,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overlayColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                    if (states.contains(WidgetState.hovered)) {
                      return AppTheme.primaryBlue.withOpacity(0.04);
                    }
                    return null; 
                  }),
                  tabs: [
                    Tab(
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: borderColor.withOpacity(0.6), 
                              width: 1,
                            ),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 18),
                            SizedBox(width: 8),
                            Text("Today's Schedule"),
                          ],
                        ),
                      ),
                    ),
                    const Tab(
                      height: 56,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medical_information_outlined, size: 18),
                          SizedBox(width: 8),
                          Text("Cabinet"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Body Area
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
