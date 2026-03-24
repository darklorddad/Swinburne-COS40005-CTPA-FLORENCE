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
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
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
      },
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

    return ListView.builder(
      itemCount: schedule.medications.length,
      itemBuilder: (context, index) {
        final med = schedule.medications[index];
        // Find if there's a log for this medication today
        final log = schedule.todaysLogs.cast<MedicationIntakeLog?>().firstWhere(
              (l) => l?.patientMedicationId == med.id,
              orElse: () => null,
            );

        return _buildMedicationRow(context, ref, med, log);
      },
    );
  }

  Widget _buildMedicationRow(
    BuildContext context,
    WidgetRef ref,
    PatientMedication med,
    MedicationIntakeLog? log,
  ) {
    final bool isTaken = log?.status == 'TAKEN' || log?.status == 'LATE';
    final bool isSkipped = log?.status == 'SKIPPED';
    final bool isOverdue = !isTaken && !isSkipped && _checkIfOverdue(med);

    IconData trailingIcon;
    Color iconColor;
    String? subtext;

    if (isTaken) {
      trailingIcon = Icons.check_circle;
      iconColor = AppTheme.primaryGreen;
      if (log?.status == 'LATE') subtext = "Logged late";
    } else if (isSkipped) {
      trailingIcon = Icons.block;
      iconColor = AppTheme.textSecondaryColor;
      subtext = "Skipped";
    } else if (isOverdue) {
      trailingIcon = Icons.error_outline;
      iconColor = AppTheme.warningColor;
      subtext = "Overdue";
    } else {
      trailingIcon = Icons.radio_button_unchecked;
      iconColor = AppTheme.textSecondaryColor;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: (isTaken || isSkipped)
            ? null
            : () => _handleTap(context, ref, med, isOverdue),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.03)
                : AppTheme.backgroundColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.medicationDictionary['brand_name'] ?? 'Unknown Medication',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${med.amount} • ${med.timingInstruction ?? 'Anytime'}",
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 13,
                      ),
                    ),
                    if (subtext != null)
                      Text(
                        subtext,
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(trailingIcon, color: iconColor, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  bool _checkIfOverdue(PatientMedication med) {
    final instruction = med.timingInstruction?.toUpperCase();
    final hour = DateTime.now().hour;
    // MVP Logic: If it's a morning/pre-meal med and it's past 2 PM, it's overdue.
    if ((instruction == 'BEFORE_MEAL' || instruction == 'BREAKFAST') && hour >= 14) {
      return true;
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
      // Immediate log for pending
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
                  subtitle: const Text("Log as taken at 8:00 AM"),
                  onTap: () => _logAndRefresh(context, ref, med.id, 'TAKEN',
                      timestamp: DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                        8,
                        0,
                      )),
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
