import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';
import '../../../../core/models/medication_models.dart';
import '../../core/providers/medication_providers.dart';
import '../../core/repositories/medication_repository.dart';

/// A card for the dashboard that displays the patient's medication cabinet.
/// Stripped of its own container styling to fit within MedicationSection.
class MedicationCabinetCard extends ConsumerWidget {
  const MedicationCabinetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(patientMedicationsProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // Stretches button to full width
        children: [
          // Content
          Expanded(
            child: medsAsync.when(
              data: (meds) => _buildMedicationList(context, ref, meds),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  "Unable to load cabinet",
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Add Medication Button at the bottom
          ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text("Add New Medication"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              foregroundColor: AppTheme.primaryBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => AppRoutes.push(context, AppRoutes.addMedication),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationList(
    BuildContext context,
    WidgetRef ref,
    List<PatientMedication> meds,
  ) {
    if (meds.isEmpty) {
      return Center(
        child: Text(
          "No medications in cabinet",
          style: TextStyle(color: AppTheme.textSecondaryColor),
        ),
      );
    }

    return ListView.builder(
      itemCount: meds.length,
      itemBuilder: (context, index) {
        final med = meds[index];
        return _buildCabinetRow(context, ref, med);
      },
    );
  }

  Widget _buildCabinetRow(
    BuildContext context,
    WidgetRef ref,
    PatientMedication med,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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
                    med.medicationDictionary['brand_name'] ?? 'Unknown',
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
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) {
                // TODO: Implement edit/stop logic
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'stop', child: Text('Stop Medication')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
