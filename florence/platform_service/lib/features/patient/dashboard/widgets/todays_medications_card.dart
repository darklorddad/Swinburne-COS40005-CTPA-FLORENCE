import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../../../../core/models/medication_models.dart';
import '../../../../core/utils/helpers.dart';
import '../../core/repositories/medication_repository.dart';
import '../providers/dashboard_providers.dart';

/// A card widget for the dashboard that displays the patient's medication schedule for today.
/// Stripped of its own container styling to fit within MedicationSection.
class TodaysMedicationsCard extends ConsumerWidget {
  const TodaysMedicationsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(dailyMedicationScheduleProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content
          Expanded(
            child: scheduleAsync.when(
              data: (schedule) => _buildMedicationList(context, ref, schedule),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, stack) => Center(
                child: Text(
                  "Unable to load schedule",
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationList(
    BuildContext context,
    WidgetRef ref,
    MedicationScheduleResponse schedule,
  ) {
    if (schedule.medications.isEmpty) {
      return Center(
        child: Text(
          "No medications scheduled for today",
          style: TextStyle(color: AppTheme.textSecondaryColor),
        ),
      );
    }

    // Unroll the medications based on frequency
    List<Widget> loggableItems = [];

    for (var med in schedule.medications) {
      // Determine frequency from the dosage frequency patient text or amount
      // For MVP, we'll parse the amount or default to 1
      int frequency = 1;
      final freqText = med.medicationDictionary['dosage_frequencies']?['patient_text']?.toString().toLowerCase() ?? '';
      
      if (freqText.contains('twice') || freqText.contains('2 times')) {
        frequency = 2;
      } else if (freqText.contains('three') || freqText.contains('3 times')) {
        frequency = 3;
      } else if (freqText.contains('four') || freqText.contains('4 times')) {
        frequency = 4;
      }

      // Find logs for this medication today
      final logs = schedule.todaysLogs.where((l) => l.patientMedicationId == med.id).toList();

      for (int i = 1; i <= frequency; i++) {
        // Check if this specific dose index has been logged
        // This is a simplified check assuming logs are sequential
        final MedicationIntakeLog? log = logs.length >= i ? logs[i - 1] : null;

        loggableItems.add(
          _buildDoseRow(
            context: context,
            ref: ref,
            med: med,
            log: log,
            doseIndex: i,
            totalDoses: frequency,
          ),
        );
      }
    }

    return ListView(children: loggableItems);
  }

  Widget _buildDoseRow({
    required BuildContext context,
    required WidgetRef ref,
    required PatientMedication med,
    required MedicationIntakeLog? log,
    required int doseIndex,
    required int totalDoses,
  }) {
    final bool isTaken = log?.status == 'TAKEN' || log?.status == 'LATE';
    final bool isSkipped = log?.status == 'SKIPPED';
    final bool isLogged = isTaken || isSkipped;
    final bool isOverdue = !isLogged && _checkIfOverdue(med, doseIndex, totalDoses);

    final String brandName = med.medicationDictionary['brand_name'] ?? 'Unknown Medication';
    final String displayName = totalDoses > 1 ? "$doseIndex. $brandName" : brandName;
    
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
                    "${med.amount} • ${med.timingInstruction ?? 'Anytime'}",
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
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
                  Icon(
                    isTaken ? Icons.check_circle : Icons.block,
                    color: statusColor,
                    size: 28,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isTaken ? "Taken" : "Skipped",
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: () => _handleTap(context, ref, med, isOverdue),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
    
    // Simple logic for overdue doses based on index and total doses
    if (totalDoses == 1) {
      final instruction = med.timingInstruction?.toUpperCase();
      if ((instruction == 'BEFORE_MEAL' || instruction == 'BREAKFAST') && hour >= 14) {
        return true;
      }
    } else {
      // For multi-dose, approximate times
      if (doseIndex == 1 && hour >= 12) return true; // Morning dose overdue after noon
      if (doseIndex == 2 && totalDoses == 2 && hour >= 20) return true; // Evening dose overdue after 8pm
    }
    
    return false;
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    PatientMedication med,
    bool isOverdue,
  ) async {
    if (isOverdue) {
      _showMissedDoseSheet(context, ref, med);
    } else {
      try {
        await ref.read(medicationRepositoryProvider).logMedicationIntake(med.id, 'TAKEN');
        ref.invalidate(dailyMedicationScheduleProvider);
        if (context.mounted) {
          Helpers.showSuccess(context, "Medication logged");
        }
      } catch (e) {
        if (context.mounted) {
          Helpers.showError(context, "Failed to log medication");
        }
      }
    }
  }

  void _showMissedDoseSheet(BuildContext context, WidgetRef ref, PatientMedication med) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Missed Dose?",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  med.medicationDictionary['brand_name'] ?? 'Medication',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.history, color: AppTheme.primaryGreen),
                  title: const Text("I took it on time"),
                  subtitle: const Text("Log as taken earlier"),
                  onTap: () => _logAndRefresh(context, ref, med.id, 'TAKEN'),
                ),
                ListTile(
                  leading: const Icon(Icons.done, color: AppTheme.primaryBlue),
                  title: const Text("Taking it right now"),
                  subtitle: const Text("Log as taken late"),
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
        );
      },
    );
  }

  Future<void> _logAndRefresh(
    BuildContext context,
    WidgetRef ref,
    int medId,
    String status, {
    DateTime? timestamp,
  }) async {
    try {
      await ref.read(medicationRepositoryProvider).logMedicationIntake(
            medId,
            status,
            takenAt: timestamp,
          );
      ref.invalidate(dailyMedicationScheduleProvider);
      if (context.mounted) {
        Navigator.pop(context);
        Helpers.showSuccess(context, "Schedule updated");
      }
    } catch (e) {
      if (context.mounted) {
        Helpers.showError(context, "Failed to update schedule");
      }
    }
  }
}
