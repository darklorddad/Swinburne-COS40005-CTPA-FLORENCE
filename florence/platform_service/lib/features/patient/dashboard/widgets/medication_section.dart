import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme.dart';
import '../../../../core/models/medication_models.dart';
import '../../../../core/utils/helpers.dart';
import '../../core/providers/medication_providers.dart';
import '../../core/repositories/medication_repository.dart';

// ==========================================
// 1. PROVIDERS
// ==========================================

/// Fetch the medication dictionary for the Autocomplete
/// Removed .autoDispose to cache dictionary data
final medicationDictionaryProvider = FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return repository.getMedicationDictionary(); 
});

/// Fetch the dosage frequencies
/// Removed .autoDispose to cache frequency data
final dosageFrequenciesProvider = FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return repository.getDosageFrequencies(); 
});

/// Provider for the daily medication schedule and intake logs.
/// Removed .autoDispose to ensure the schedule persists when switching tabs.
final todaysScheduleProvider = FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return repository.getMedicationSchedule();
});

// ==========================================
// 2. MAIN EXPORTED WIDGET (The Header)
// ==========================================

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
                  
                  // COMPLETELY REMOVES HOVER AND RIPPLE EFFECTS
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  splashFactory: NoSplash.splashFactory,
                  
                  tabs: const [
                    Tab(
                      height: 56,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 18),
                          SizedBox(width: 8),
                          Text("Today's Schedule"),
                        ],
                      ),
                    ),
                    Tab(
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
                  MedicationLoggingSection(),
                  MedicationCabinetSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. TODAY'S SCHEDULE VIEW (Filtered)
// ==========================================

enum ScheduleFilter { all, pending, taken }

class MedicationLoggingSection extends ConsumerStatefulWidget {
  const MedicationLoggingSection({super.key});

  @override
  ConsumerState<MedicationLoggingSection> createState() => _MedicationLoggingSectionState();
}

class _MedicationLoggingSectionState extends ConsumerState<MedicationLoggingSection> with AutomaticKeepAliveClientMixin {
  ScheduleFilter _currentFilter = ScheduleFilter.all;

  @override
  bool get wantKeepAlive => true;

  // Helper to convert index to Ordinal string
  String _getOrdinal(int index) {
    const ordinals = ["First", "Second", "Third", "Fourth", "Fifth"];
    if (index <= ordinals.length) return ordinals[index - 1];
    return "$index.";
  }

  // Helper to format Timing Instructions
  String _formatTiming(String? raw) {
    if (raw == null) return "Anytime";
    return raw.replaceAll('_', ' ').toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  LinearGradient _getGradient(bool isTaken, bool isLate, bool isDark) {
    if (isTaken) {
      return LinearGradient(
        colors: [
          Colors.green.withOpacity(isDark ? 0.1 : 0.05),
          Colors.green.withOpacity(isDark ? 0.1 : 0.05),
        ],
      );
    }
    return LinearGradient(
      colors: [
        isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        isDark ? Colors.white.withOpacity(0.05) : Colors.white,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheduleAsync = ref.watch(todaysScheduleProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // FILTER ROW
          Row(
            children: [
              _buildFilterChip("All", ScheduleFilter.all),
              const SizedBox(width: 8),
              _buildFilterChip("Pending", ScheduleFilter.pending),
              const SizedBox(width: 8),
              _buildFilterChip("Taken", ScheduleFilter.taken),
            ],
          ),
          const SizedBox(height: 16),

          // SCHEDULE LIST
          scheduleAsync.when(
            skipLoadingOnReload: true,
            data: (scheduleItems) {
              if (scheduleItems.isEmpty) return const Center(child: Text("No schedule"));

              List<Widget> loggableItems = [];
              
              for (var item in scheduleItems) {
                final med = PatientMedication.fromJson(item['medication']);
                final int timesLogged = item['times_logged'] ?? 0;
                final bool isWeekly = item['is_weekly'] ?? false;
                
                int totalDoses = med.timingInstructions.isNotEmpty ? med.timingInstructions.length : 1;
                bool isLate = false; 

                for (int i = 1; i <= totalDoses; i++) {
                  bool isTaken = i <= timesLogged;
                  
                  // APPLY FILTER LOGIC
                  bool shouldShow = true;
                  if (_currentFilter == ScheduleFilter.pending && isTaken) shouldShow = false;
                  if (_currentFilter == ScheduleFilter.taken && !isTaken) shouldShow = false;

                  if (shouldShow) {
                    loggableItems.add(_buildMedicationRow(context, ref, med, i, totalDoses, isTaken, isLate, isWeekly));
                  }
                }
              }

              if (loggableItems.isEmpty) {
                return Center(child: Text("No medications match this filter", style: TextStyle(color: AppTheme.textSecondaryColor)));
              }

              return ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: loggableItems,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => const Center(child: Text("Error loading schedule")),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ScheduleFilter filterValue) {
    final isSelected = _currentFilter == filterValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _currentFilter = filterValue);
      },
      selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondaryColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
      side: BorderSide.none,
    );
  }

  Widget _buildMedicationRow(
    BuildContext context,
    WidgetRef ref,
    PatientMedication med,
    int index,
    int total,
    bool isTaken,
    bool isLate,
    bool isWeekly,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String brandName = med.medicationDictionary['brand_name'] ?? 
                             med.customMedicationName ?? 
                             'Unknown';
    final String type = (med.medicationType ?? 'Pill').toLowerCase();
    
    // Pull specific timing from the array safely
    String rawTiming = 'ANYTIME';
    if (med.timingInstructions.isNotEmpty) {
      int tIndex = (index - 1) < med.timingInstructions.length ? (index - 1) : (med.timingInstructions.length - 1);
      rawTiming = med.timingInstructions[tIndex];
    }
    final String timing = _formatTiming(rawTiming);
    final String amount = med.amount;

    // Dynamic Display String
    String contentText = total > 1 
      ? "${_getOrdinal(index)} $brandName - $amount $type - $timing"
      : "$brandName - $amount $type - $timing";

    if (isWeekly && isTaken) {
      contentText = "$brandName (Taken for this week)";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _handleToggle(context, ref, med, isTaken),
        borderRadius: BorderRadius.circular(16),
        mouseCursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: _getGradient(isTaken, isLate, isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTaken
                  ? Colors.green.withOpacity(0.3)
                  : AppTheme.getBorderColor(context),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  contentText,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: isTaken ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                    decoration: isTaken ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (isLate && !isTaken)
                const _StatusLabel(text: "Late", color: Colors.orange),
              if (isTaken)
                const _StatusLabel(text: "Taken", color: Colors.green),
              
              // Radial Tick Button
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTaken ? Colors.green : Colors.transparent,
                  border: Border.all(
                    color: isTaken ? Colors.green : Colors.grey.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: isTaken 
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleToggle(BuildContext context, WidgetRef ref, PatientMedication med, bool currentlyTaken) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(currentlyTaken ? "Unlog Medication?" : "Log Medication?"),
        content: Text(currentlyTaken 
          ? "This will mark the dose as not taken. Continue?" 
          : "Confirm that you have taken your dose."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final repo = ref.read(medicationRepositoryProvider);
              try {
                if (currentlyTaken) {
                  await repo.unlogMedicationIntake(med.id);
                } else {
                  await repo.logMedicationIntake(med.id, 'TAKEN');
                }
                ref.invalidate(todaysScheduleProvider);
                if (context.mounted) {
                  Helpers.showSuccess(context, currentlyTaken ? "Medication unlogged" : "Medication logged");
                }
              } catch (e) {
                if (context.mounted) {
                  Helpers.showError(context, "Failed to update schedule");
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: currentlyTaken ? Colors.grey : Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}

/// Small helper for status text labels
class _StatusLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ==========================================
// 4. MEDICATION CABINET VIEW (Filtered)
// ==========================================

enum CabinetFilter { active, past, all }

class MedicationCabinetSection extends ConsumerStatefulWidget {
  const MedicationCabinetSection({super.key});

  @override
  ConsumerState<MedicationCabinetSection> createState() => _MedicationCabinetSectionState();
}

class _MedicationCabinetSectionState extends ConsumerState<MedicationCabinetSection> with AutomaticKeepAliveClientMixin {
  CabinetFilter _currentFilter = CabinetFilter.active;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final medsAsync = ref.watch(patientMedicationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = AppTheme.getBorderColor(context);
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_services_rounded,
                  size: 18, color: AppTheme.primaryBlue),
              const SizedBox(width: 10),
              const Text(
                "Medication Cabinet",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("Active", CabinetFilter.active),
                      const SizedBox(width: 8),
                      _buildFilterChip("Past", CabinetFilter.past),
                      const SizedBox(width: 8),
                      _buildFilterChip("All", CabinetFilter.all),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                medsAsync.when(
                  skipLoadingOnReload: true,
                  data: (meds) {
                    if (meds.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                            child: Text("Cabinet is empty",
                                style: TextStyle(color: AppTheme.textSecondaryColor))),
                      );
                    }

                    final filteredMeds = meds.where((m) {
                      if (_currentFilter == CabinetFilter.active)
                        return m.status != 'PAST';
                      if (_currentFilter == CabinetFilter.past)
                        return m.status == 'PAST';
                      return true;
                    }).toList();

                    if (filteredMeds.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                            child: Text("No medications found",
                                style: TextStyle(color: AppTheme.textSecondaryColor))),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredMeds.length,
                      separatorBuilder: (context, index) => Divider(
                        color: borderColor,
                        height: 32,
                      ),
                      itemBuilder: (context, index) {
                        final med = filteredMeds[index];
                        return _buildCabinetRow(context, ref, med, isActive: med.status != 'PAST');
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => const Center(child: Text("Failed to load cabinet")),
                ),

                const SizedBox(height: 16),

                OutlinedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("Add Medication"),
                  onPressed: () => _showFormModal(context, isEdit: false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, CabinetFilter filterValue) {
    final isSelected = _currentFilter == filterValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _currentFilter = filterValue);
      },
      selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondaryColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
      side: BorderSide.none,
    );
  }

  Widget _buildCabinetRow(BuildContext context, WidgetRef ref, dynamic med,
      {required bool isActive}) {
    final String brandName = med.medicationDictionary['brand_name'] ??
        med.customMedicationName ??
        'Unknown';

    return Opacity(
      opacity: isActive ? 1.0 : 0.5,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medication_rounded,
                color: AppTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brandName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    decoration: isActive ? null : TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  "${med.amount} ${med.medicationType ?? 'Pill'}",
                  style:
                      TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'edit') {
                _showFormModal(context, isEdit: true, med: med);
              } else if (value == 'stop') {
                _confirmStop(context, ref, med, brandName);
              } else if (value == 'restart') {
                _confirmRestart(context, ref, med, brandName);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit')
                  ])),
              if (isActive)
                const PopupMenuItem(
                    value: 'stop',
                    child: Row(children: [
                      Icon(Icons.stop_circle, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Stop', style: TextStyle(color: Colors.red))
                    ]))
              else
                const PopupMenuItem(
                    value: 'restart',
                    child: Row(children: [
                      Icon(Icons.play_circle, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Restart', style: TextStyle(color: Colors.green))
                    ])),
            ],
          ),
        ],
      ),
    );
  }

  void _showFormModal(BuildContext context, {required bool isEdit, dynamic med}) {
    showDialog(context: context, builder: (context) => _MedicationFormDialog(isEdit: isEdit, medication: med));
  }

  void _confirmStop(BuildContext context, WidgetRef ref, dynamic med, String medName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Stop Medication"),
        content: Text("Are you sure you want to stop taking $medName? It will be moved to your history."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await ref.read(medicationRepositoryProvider).updateMedicationStatus(med.id, 'PAST');
              ref.invalidate(patientMedicationsProvider);
              ref.invalidate(todaysScheduleProvider); // Refresh schedule to remove it
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0),
            child: const Text("Stop Medication"),
          ),
        ],
      ),
    );
  }

  // Logic to restart a past medication
  void _confirmRestart(BuildContext context, WidgetRef ref, dynamic med, String medName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Restart Medication"),
        content: Text("Do you want to move $medName back to your active medications and schedule?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await ref.read(medicationRepositoryProvider).updateMedicationStatus(med.id, 'CURRENT');
              ref.invalidate(patientMedicationsProvider);
              ref.invalidate(todaysScheduleProvider); // Refresh schedule to add it back
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0),
            child: const Text("Restart Medication"),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. MEDICATION FORM MODAL (Private)
// ==========================================

class _MedicationFormDialog extends ConsumerStatefulWidget {
  final bool isEdit;
  final PatientMedication? medication;

  const _MedicationFormDialog({required this.isEdit, this.medication});

  @override
  ConsumerState<_MedicationFormDialog> createState() => _MedicationFormDialogState();
}

class _MedicationFormDialogState extends ConsumerState<_MedicationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // State Variables
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  Map<String, dynamic>? _selectedDictionaryItem; // Holds the dictionary object if they pick a verified one
  dynamic _selectedFrequency;      // Holds the frequency object
  
  String _selectedType = 'TABLET';
  List<String> _selectedTimings = ['ANYTIME'];

  // Fixed lists based on database schema constraints
  final List<String> _medicationTypes = ['TABLET', 'CAPSULE', 'INJECTION', 'LIQUID', 'INHALER', 'OTHER'];
  final List<String> _timingInstructions = [
    'BEFORE_BREAKFAST', 'WITH_BREAKFAST', 'AFTER_BREAKFAST',
    'BEFORE_LUNCH', 'WITH_LUNCH', 'AFTER_LUNCH',
    'BEFORE_DINNER', 'WITH_DINNER', 'AFTER_DINNER',
    'BEFORE_SUPPER', 'WITH_SUPPER', 'AFTER_SUPPER',
    'WITH_SNACK', 'BEFORE_BED', 'EMPTY_STOMACH', 'AS_NEEDED', 'ANYTIME'
  ];

  // Helper to calculate doses based on selected frequency
  int _getDosesFromFrequency(dynamic freq) {
    if (freq == null) return 1;
    final text = (freq['patient_text'] ?? freq['latin_code']).toString().toLowerCase();
    if (text.contains('twice') || text == 'bid' || text.contains('2 times')) return 2;
    if (text.contains('three') || text == 'tid' || text.contains('3 times')) return 3;
    if (text.contains('four') || text == 'qid' || text.contains('4 times')) return 4;
    return 1;
  }

  void _onFrequencyChanged(dynamic val) {
    setState(() {
      _selectedFrequency = val;
      int requiredDoses = _getDosesFromFrequency(val);
      
      // Grow or shrink the timings list based on frequency
      while (_selectedTimings.length < requiredDoses) {
        _selectedTimings.add('ANYTIME');
      }
      if (_selectedTimings.length > requiredDoses) {
        _selectedTimings = _selectedTimings.sublist(0, requiredDoses);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.medication != null) {
      final med = widget.medication!;
      
      _nameController.text = med.medicationDictionary['brand_name'] ?? med.customMedicationName ?? "";
      _amountController.text = med.amount;
      _selectedType = _medicationTypes.contains(med.medicationType) ? med.medicationType! : 'TABLET';
      
      // --- THE FIX: RESTORE DICTIONARY ITEM ---
      // If the medication has an ID, re-assign it to the selected item
      // so the app knows it is a Verified Medication, not a Custom one!
      if (med.medicationDictionary['id'] != null) {
        _selectedDictionaryItem = med.medicationDictionary;
      }
      // ----------------------------------------

      // Restore the array of timings
      if (med.timingInstructions.isNotEmpty) {
        _selectedTimings = List<String>.from(med.timingInstructions);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // 1. Determine if it's a Dictionary Med or a Custom Med
      final bool isCustom = _selectedDictionaryItem == null;

      // 2. Build the payload matching the Database Schema
      final Map<String, dynamic> payload = {
        'medication_id': isCustom ? (widget.isEdit ? widget.medication!.medicationId : null) : _selectedDictionaryItem!['id'],
        'custom_medication_name': isCustom ? _nameController.text.trim() : null,
        'frequency_id': _selectedFrequency?['id'],
        'amount': _amountController.text.trim(),
        'medication_type': _selectedType,
        'timing_instructions': _selectedTimings,
        'status': 'CURRENT',
      };

      try {
        final repo = ref.read(medicationRepositoryProvider);
        if (widget.isEdit) {
          await repo.updatePatientMedication(widget.medication!.id, payload);
        } else {
          await repo.addPatientMedication(payload);
        }
        
        ref.invalidate(patientMedicationsProvider);
        ref.invalidate(todaysScheduleProvider);
        
        if (mounted) {
          Navigator.pop(context);
          Helpers.showSuccess(context, widget.isEdit ? 'Medication updated' : 'Medication added');
        }
      } catch (e) {
        if (mounted) {
          Helpers.showError(context, 'Failed to save medication');
        }
      }
    }
  }

  // ==========================================
  // STYLING HELPER FOR ALL INPUTS
  // ==========================================
  InputDecoration _getCustomInputDecoration(BuildContext context, {required String hint, Widget? suffixIcon}) {
    final borderColor = AppTheme.getBorderColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.textSecondaryColor.withOpacity(0.6), fontSize: 14),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.02) : AppTheme.backgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
      // Default Border
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      // Active/Typing Border
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
      ),
      // Error Border
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  // Helper to format ordinals (1st, 2nd)
  String _getOrdinalLabel(int index) {
    const ordinals = ["1st", "2nd", "3rd", "4th", "5th"];
    if (index <= ordinals.length) return ordinals[index - 1];
    return "${index}th";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final menuBackgroundColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);
    
    // Fetch data for dropdowns
    final dictAsync = ref.watch(medicationDictionaryProvider);
    final freqAsync = ref.watch(dosageFrequenciesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: menuBackgroundColor,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isEdit ? "Edit Medication" : "Add Medication", 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                
                // 1. MEDICATION NAME (Autocomplete / Custom)
                const Text("Medication Name", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                dictAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => const Text("Error loading dictionary"),
                  data: (dictionaryList) {
                    final dictionary = dictionaryList.cast<Map<String, dynamic>>();

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return Autocomplete<Map<String, dynamic>>(
                          initialValue: TextEditingValue(text: _nameController.text),
                          displayStringForOption: (option) => (option['brand_name'] ?? option['generic_name']).toString(),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
                            return dictionary.where((med) {
                              final brand = (med['brand_name']?.toString() ?? '').toLowerCase();
                              final generic = (med['generic_name']?.toString() ?? '').toLowerCase();
                              final query = textEditingValue.text.toLowerCase();
                              return brand.contains(query) || generic.contains(query);
                            });
                          },
                          onSelected: (selection) {
                            setState(() => _selectedDictionaryItem = selection);
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                color: menuBackgroundColor,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: borderColor),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: constraints.maxWidth, 
                                    maxHeight: 250,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      final name = option['brand_name'] ?? option['generic_name'];
                                      return InkWell(
                                        onTap: () => onSelected(option),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                                          child: Text(name.toString()),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            // Keep our local controller in sync so we can read the raw text for custom meds
                            controller.addListener(() {
                              _nameController.text = controller.text;
                              // If they alter the text after selecting, wipe the dictionary selection so it becomes custom
                              if (_selectedDictionaryItem != null && 
                                  controller.text != _selectedDictionaryItem!['brand_name']) {
                                _selectedDictionaryItem = null; 
                              }
                            });
                            
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                              decoration: _getCustomInputDecoration(
                                context, 
                                hint: "Search dictionary or type custom name...", 
                                suffixIcon: const Icon(Icons.search)
                              ),
                            );
                          },
                        );
                      }
                    );
                  },
                ),
                
                const SizedBox(height: 16),

                // 2. AMOUNT, TYPE & FREQUENCY ROW
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Amount", style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _amountController,
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            
                            // 1. Pops up the number keyboard on mobile
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            
                            // 2. ONLY allows digits and a single decimal point
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            
                            decoration: _getCustomInputDecoration(context, hint: "e.g. 1, 1.5"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Type", style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return DropdownButtonFormField<String>(
                                value: _selectedType,
                                isExpanded: true,
                                dropdownColor: menuBackgroundColor,
                                borderRadius: BorderRadius.circular(16),
                                elevation: 4,
                                icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondaryColor),
                                decoration: _getCustomInputDecoration(context, hint: "Type"),
                                items: _medicationTypes.map((t) => DropdownMenuItem(
                                  value: t, 
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: constraints.maxWidth - 40),
                                    child: Text(t, overflow: TextOverflow.ellipsis),
                                  )
                                )).toList(),
                                onChanged: (val) => setState(() => _selectedType = val!),
                              );
                            }
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Frequency", style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          freqAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, s) => const Text("Error"),
                            data: (frequencies) {
                              // Match frequency if editing
                              if (widget.isEdit && _selectedFrequency == null) {
                                try {
                                  _selectedFrequency = frequencies.firstWhere(
                                    (f) => f['id'] == widget.medication!.frequencyId
                                  );
                                } catch (_) {}
                              }

                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  return DropdownButtonFormField<dynamic>(
                                    value: _selectedFrequency,
                                    isExpanded: true,
                                    validator: (val) => val == null ? 'Required' : null,
                                    dropdownColor: menuBackgroundColor,
                                    borderRadius: BorderRadius.circular(16),
                                    elevation: 4,
                                    icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondaryColor),
                                    decoration: _getCustomInputDecoration(context, hint: "Select freq"),
                                    items: frequencies.map((f) {
                                      return DropdownMenuItem(
                                        value: f, 
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(maxWidth: constraints.maxWidth - 40),
                                          child: Text(
                                            f['patient_text'] ?? f['latin_code'],
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )
                                      );
                                    }).toList(),
                                    onChanged: _onFrequencyChanged,
                                  );
                                }
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // 3. DYNAMIC TIMING DROPDOWNS
                const Text("Specific Timings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                
                ...List.generate(_selectedTimings.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            "${_selectedTimings.length > 1 ? _getOrdinalLabel(index + 1) : 'Daily'} Dose:", 
                            style: TextStyle(color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w600)
                          ),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return DropdownButtonFormField<String>(
                                value: _selectedTimings[index],
                                isExpanded: true,
                                dropdownColor: menuBackgroundColor,
                                borderRadius: BorderRadius.circular(16),
                                elevation: 4,
                                icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondaryColor),
                                decoration: _getCustomInputDecoration(context, hint: "Timing"),
                                items: _timingInstructions.map((t) {
                                  final formatted = t.replaceAll('_', ' ').toLowerCase();
                                  return DropdownMenuItem(
                                    value: t, 
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(maxWidth: constraints.maxWidth - 40),
                                      child: Text(
                                        formatted[0].toUpperCase() + formatted.substring(1),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedTimings[index] = val!);
                                },
                              );
                            }
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                
                const SizedBox(height: 24),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(widget.isEdit ? "Save Changes" : "Add Medication"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
