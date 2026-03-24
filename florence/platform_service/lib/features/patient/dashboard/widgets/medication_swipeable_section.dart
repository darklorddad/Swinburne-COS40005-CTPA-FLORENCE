import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import 'todays_medications_card.dart';
import 'medication_cabinet_card.dart';

/// A swipeable section for the dashboard that toggles between 
/// Today's Schedule and the Medication Cabinet.
class MedicationSwipeableSection extends StatefulWidget {
  const MedicationSwipeableSection({super.key});

  @override
  State<MedicationSwipeableSection> createState() => _MedicationSwipeableSectionState();
}

class _MedicationSwipeableSectionState extends State<MedicationSwipeableSection> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Swipeable Area
        SizedBox(
          height: 380, // Fixed height to ensure consistency in the dashboard grid
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            children: const [
              TodaysMedicationsCard(),
              MedicationCabinetCard(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Swipe Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            final isActive = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: isActive ? 24 : 8,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryBlue : AppTheme.borderColor,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
