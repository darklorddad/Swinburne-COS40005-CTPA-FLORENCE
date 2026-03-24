import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../../../../core/models/medication_models.dart';
import '../../../../core/utils/helpers.dart';
import '../../core/providers/medication_providers.dart';
import '../../core/repositories/medication_repository.dart';
import '../providers/dashboard_providers.dart';

// ==========================================
// 1. MAIN EXPORTED WIDGET (The Header)
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
                  _TodaysMedicationsView(),
                  _MedicationCabinetView(),
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
// 2. TODAY'S SCHEDULE VIEW (Private)
// ==========================================

class _TodaysMedicationsView extends ConsumerWidget {
  const _TodaysMedicationsView();

  int _getDosesPerDay(String? frequencyStr) {
    if (frequencyStr == null) return 1;
    final lower = frequencyStr.toLowerCase();
    if (lower.contains('twice') || lower == 'bid' || lower.contains('2 times')) return 2;
    if (lower.contains('three') || lower == 'tid' || lower.contains('3 times')) return 3;
    if (lower.contains('four') || lower == 'qid' || lower.contains('4 times')) return 4;
    return 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(dailyMedicationScheduleProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: scheduleAsync.when(
        data: (schedule) {
          if (schedule.medications.isEmpty) {
            return Center(
              child: Text(
                "No medications scheduled for today",
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            );
          }

          List<Widget> loggableItems = [];

          for (var med in schedule.medications) {
            final freqText = med.medicationDictionary['dosage_frequencies']?['patient_text']?.toString() ?? 'Once a day';
            int totalDoses = _getDosesPerDay(freqText);
            final logs = schedule.todaysLogs.where((l) => l.patientMedicationId == med.id).toList();
            int timesLoggedToday = logs.length;

            for (int i = 1; i <= totalDoses; i++) {
              final MedicationIntakeLog? log = i <= timesLoggedToday ? logs[i - 1] : null;
              loggableItems.add(
                _buildDoseRow(context, ref, med, log, i, totalDoses),
              );
            }
          }

          return ListView(children: loggableItems);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            "Unable to load schedule",
            style: TextStyle(color: AppTheme.errorColor),
          ),
        ),
      ),
    );
  }

  Widget _buildDoseRow(
    BuildContext context,
    WidgetRef ref,
    PatientMedication med,
    MedicationIntakeLog? log,
    int doseIndex,
    int totalDoses,
  ) {
    final bool isTaken = log?.status == 'TAKEN' || log?.status == 'LATE';
    final bool isSkipped = log?.status == 'SKIPPED';
    final bool isLogged = isTaken || isSkipped;
    final bool isOverdue = !isLogged && _checkIfOverdue(med, doseIndex, totalDoses);

    final String brandName = med.medicationDictionary['brand_name'] ?? 'Unknown Medication';
    final String displayName = totalDoses > 1 ? "$doseIndex. $brandName" : brandName;
    
    String rawType = med.medicationType ?? 'PILL';
    final String type = rawType[0].toUpperCase() + rawType.substring(1).toLowerCase(); 
    
    String rawTiming = med.timingInstruction ?? 'ANYTIME';
    final String timingInstruction = rawTiming.replaceAll('_', ' ').split(' ').map((word) => 
        word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : '').join(' ');

    Color statusColor = AppTheme.textSecondaryColor;
    if (isTaken) statusColor = AppTheme.primaryGreen;
    if (isSkipped) statusColor = AppTheme.textSecondaryColor;
    if (isOverdue) statusColor = AppTheme.warningColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.03)
              : AppTheme.backgroundColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: isLogged ? Border.all(color: statusColor.withOpacity(0.5)) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: isLogged ? TextDecoration.lineThrough : null,
                      color: isLogged ? AppTheme.textSecondaryColor : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$type • $timingInstruction",
                    style: TextStyle(
                      color: isLogged ? AppTheme.textSecondaryColor.withOpacity(0.7) : AppTheme.textSecondaryColor,
                      fontSize: 13,
                    ),
                  ),
                  if (isOverdue)
                    const Text(
                      "Overdue",
                      style: TextStyle(
                        color: AppTheme.warningColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            if (isLogged)
              Row(
                children: [
                  Icon(isTaken ? Icons.check_circle : Icons.block, color: statusColor, size: 28),
                  const SizedBox(width: 4),
                  Text(
                    isTaken ? "Taken" : "Skipped",
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: () => _handleLogTap(context, ref, med, isOverdue),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text("Log"),
              ),
          ],
        ),
      ),
    );
  }

  bool _checkIfOverdue(PatientMedication med, int doseIndex, int totalDoses) {
    final hour = DateTime.now().hour;
    if (totalDoses == 1) {
      final instruction = med.timingInstruction?.toUpperCase();
      if ((instruction == 'BEFORE_MEAL' || instruction == 'BREAKFAST') && hour >= 14) return true;
    } else {
      if (doseIndex == 1 && hour >= 12) return true;
      if (doseIndex == 2 && totalDoses == 2 && hour >= 20) return true;
    }
    return false;
  }

  Future<void> _handleLogTap(BuildContext context, WidgetRef ref, PatientMedication med, bool isOverdue) async {
    if (isOverdue) {
      _showMissedDoseSheet(context, ref, med);
    } else {
      try {
        await ref.read(medicationRepositoryProvider).logMedicationIntake(med.id, 'TAKEN');
        ref.invalidate(dailyMedicationScheduleProvider);
        if (context.mounted) Helpers.showSuccess(context, "Medication logged");
      } catch (e) {
        if (context.mounted) Helpers.showError(context, "Failed to log medication");
      }
    }
  }

  void _showMissedDoseSheet(BuildContext context, WidgetRef ref, PatientMedication med) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Missed Dose?", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(med.medicationDictionary['brand_name'] ?? 'Medication', style: TextStyle(color: AppTheme.textSecondaryColor)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.history, color: AppTheme.primaryGreen),
                title: const Text("I took it on time"),
                onTap: () => _logAndRefresh(context, ref, med.id, 'TAKEN'),
              ),
              ListTile(
                leading: const Icon(Icons.done, color: AppTheme.primaryBlue),
                title: const Text("Taking it right now"),
                onTap: () => _logAndRefresh(context, ref, med.id, 'LATE'),
              ),
              ListTile(
                leading: Icon(Icons.close, color: AppTheme.textSecondaryColor),
                title: const Text("Skip this dose"),
                onTap: () => _logAndRefresh(context, ref, med.id, 'SKIPPED'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logAndRefresh(BuildContext context, WidgetRef ref, int medId, String status) async {
    try {
      await ref.read(medicationRepositoryProvider).logMedicationIntake(medId, status);
      ref.invalidate(dailyMedicationScheduleProvider);
      if (context.mounted) {
        Navigator.pop(context);
        Helpers.showSuccess(context, "Schedule updated");
      }
    } catch (e) {
      if (context.mounted) Helpers.showError(context, "Failed to update schedule");
    }
  }
}

// ==========================================
// 3. MEDICATION CABINET VIEW (Private)
// ==========================================

class _MedicationCabinetView extends ConsumerWidget {
  const _MedicationCabinetView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(patientMedicationsProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: medsAsync.when(
              data: (meds) {
                final activeMeds = meds.where((m) => m.status != 'PAST').toList();
                if (activeMeds.isEmpty) {
                  return Center(child: Text("No active medications", style: TextStyle(color: AppTheme.textSecondaryColor)));
                }
                return ListView.builder(
                  itemCount: activeMeds.length,
                  itemBuilder: (context, index) => _buildCabinetRow(context, ref, activeMeds[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Unable to load cabinet", style: TextStyle(color: AppTheme.errorColor))),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text("Add New Medication"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              foregroundColor: AppTheme.primaryBlue,
              // FIX: Use elevation 0 and a transparent shadow to prevent shifting on hover
              elevation: 0,
              shadowColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _showFormModal(context, isEdit: false),
          ),
        ],
      ),
    );
  }

  Widget _buildCabinetRow(BuildContext context, WidgetRef ref, PatientMedication med) {
    final String brandName = med.medicationDictionary['brand_name'] ?? 'Unknown';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.03) : AppTheme.backgroundColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(brandName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text("${med.amount} • ${med.timingInstruction ?? 'Anytime'}", style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'edit') _showFormModal(context, isEdit: true, med: med);
                else if (value == 'stop') _confirmStop(context, ref, med, brandName);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                const PopupMenuItem(value: 'stop', child: Row(children: [Icon(Icons.stop_circle, size: 18, color: Colors.red), SizedBox(width: 8), Text('Stop', style: TextStyle(color: Colors.red))])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFormModal(BuildContext context, {required bool isEdit, PatientMedication? med}) {
    showDialog(context: context, builder: (context) => _MedicationFormDialog(isEdit: isEdit, medication: med));
  }

  void _confirmStop(BuildContext context, WidgetRef ref, PatientMedication med, String medName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Stop Medication"),
        content: Text("Are you sure you want to stop taking $medName? It will be moved to your past records."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0),
            child: const Text("Stop Medication"),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 4. MEDICATION FORM MODAL (Private)
// ==========================================

class _MedicationFormDialog extends StatefulWidget {
  final bool isEdit;
  final PatientMedication? medication;

  const _MedicationFormDialog({required this.isEdit, this.medication});

  @override
  State<_MedicationFormDialog> createState() => _MedicationFormDialogState();
}

class _MedicationFormDialogState extends State<_MedicationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  int? _selectedMedicationId;
  int? _selectedFrequencyId;
  String? _selectedType;
  String? _selectedTiming;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.isEdit ? widget.medication?.amount : '');
    if (widget.isEdit && widget.medication != null) {
      _selectedMedicationId = widget.medication!.medicationDictionary['id'];
      _selectedType = widget.medication!.medicationType;
      _selectedTiming = widget.medication!.timingInstruction;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppTheme.midnightSurface : Colors.white,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.isEdit ? "Edit Medication" : "Add Medication", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                const Text("Medication Name", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: "Search or enter medication...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
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
