import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../../../../core/models/medication_models.dart';
import '../../../../core/utils/helpers.dart';
import '../../core/providers/medication_providers.dart';
import '../../core/repositories/medication_repository.dart';
import '../providers/dashboard_providers.dart';

// ==========================================
// 1. PROVIDERS
// ==========================================

/// Fetch the medication dictionary for the Autocomplete
final medicationDictionaryProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return repository.getMedicationDictionary(); 
});

/// Fetch the dosage frequencies
final dosageFrequenciesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return repository.getDosageFrequencies(); 
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
// 3. TODAY'S SCHEDULE VIEW (Private)
// ==========================================

class _TodaysMedicationsView extends ConsumerWidget {
  const _TodaysMedicationsView();

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

  int _getDosesPerDay(PatientMedication med) {
    // Try to get frequency from the linked dictionary or fallback to a default
    final freqText = med.medicationDictionary['dosage_frequencies']?['patient_text']?.toString() ?? 
                     med.medicationDictionary['frequency_text']?.toString();
    
    if (freqText == null) return 1;
    final lower = freqText.toLowerCase();
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
            int totalDoses = _getDosesPerDay(med);
            final logs = schedule.todaysLogs.where((l) => l.patientMedicationId == med.id).toList();
            int timesLoggedToday = logs.length;

            for (int i = 1; i <= totalDoses; i++) {
              final MedicationIntakeLog? log = i <= timesLoggedToday ? logs[i - 1] : null;
              final bool isTaken = log != null;
              // Logic: if current_time > meal_time and not logged. 
              // For MVP, we use a simplified check.
              final bool isLate = !isTaken && _checkIfOverdue(med, i, totalDoses);

              loggableItems.add(
                _buildMedicationRow(context, ref, med, i, totalDoses, isTaken, isLate),
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

  Widget _buildMedicationRow(
    BuildContext context,
    WidgetRef ref,
    PatientMedication med,
    int index,
    int total,
    bool isTaken,
    bool isLate,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String brandName = med.medicationDictionary['brand_name'] ?? 
                             med.customMedicationName ?? 
                             'Unknown';
    final String type = (med.medicationType ?? 'Pill').toLowerCase();
    final String timing = _formatTiming(med.timingInstruction);

    // Dynamic Display String
    final String contentText = total > 1 
      ? "${_getOrdinal(index)} $brandName - $type - $timing"
      : "$brandName - $type - $timing";

    // Gradient Selection
    LinearGradient backgroundGradient;
    if (isTaken) {
      backgroundGradient = LinearGradient(
        colors: isDark 
          ? [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.05)]
          : [Colors.green.shade50, Colors.green.shade100],
      );
    } else if (isLate) {
      backgroundGradient = LinearGradient(
        colors: isDark 
          ? [Colors.orange.withOpacity(0.2), Colors.yellow.withOpacity(0.05)]
          : [Colors.orange.shade50, Colors.yellow.shade50],
      );
    } else {
      backgroundGradient = LinearGradient(
        colors: isDark 
          ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]
          : [Colors.grey.shade100, Colors.grey.shade200],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: backgroundGradient,
          borderRadius: BorderRadius.circular(16),
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
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text(
                  "Late", 
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)
                ),
              ),
            if (isTaken)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text(
                  "Taken", 
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)
                ),
              ),
            
            // Radial Tick Button
            GestureDetector(
              onTap: () => _handleToggle(context, ref, med, isTaken),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTaken ? Colors.green : Colors.transparent,
                  border: Border.all(
                    color: isTaken ? Colors.green : Colors.grey.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: isTaken 
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
              ),
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
      if ((instruction == 'BEFORE_MEAL' || instruction == 'BREAKFAST' || instruction == 'BEFORE_BREAKFAST') && hour >= 14) return true;
    } else {
      if (doseIndex == 1 && hour >= 12) return true;
      if (doseIndex == 2 && totalDoses == 2 && hour >= 20) return true;
    }
    return false;
  }

  void _handleToggle(BuildContext context, WidgetRef ref, PatientMedication med, bool currentlyTaken) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(currentlyTaken ? "Unlog Medication?" : "Log Medication?"),
        content: Text(currentlyTaken 
          ? "Are you sure you want to mark this as not taken?" 
          : "Confirm that you have taken your medication."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (currentlyTaken) {
                // TODO: Implement unlog logic in repository if needed
              } else {
                try {
                  await ref.read(medicationRepositoryProvider).logMedicationIntake(med.id, 'TAKEN');
                  ref.invalidate(dailyMedicationScheduleProvider);
                  if (context.mounted) Helpers.showSuccess(context, "Medication logged");
                } catch (e) {
                  if (context.mounted) Helpers.showError(context, "Failed to log medication");
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

// ==========================================
// 4. MEDICATION CABINET VIEW (Private)
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
    // SAFE CHECK: Prioritise dictionary brand name, then custom name
    final String brandName = med.medicationDictionary['brand_name'] ?? 
                             med.customMedicationName ?? 
                             'Unknown';
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
  String _selectedTiming = 'ANYTIME';

  // Fixed lists based on database schema constraints
  final List<String> _medicationTypes = ['TABLET', 'CAPSULE', 'INJECTION', 'LIQUID', 'INHALER', 'OTHER'];
  final List<String> _timingInstructions = [
    'BEFORE_BREAKFAST', 'WITH_BREAKFAST', 'AFTER_BREAKFAST',
    'BEFORE_LUNCH', 'WITH_LUNCH', 'AFTER_LUNCH',
    'BEFORE_DINNER', 'WITH_DINNER', 'AFTER_DINNER',
    'BEFORE_SUPPER', 'WITH_SUPPER', 'AFTER_SUPPER',
    'WITH_SNACK', 'BEFORE_BED', 'EMPTY_STOMACH', 'AS_NEEDED', 'ANYTIME'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.medication != null) {
      // SAFE CHECK: Pre-fill name from dictionary or custom field
      _nameController.text = widget.medication!.medicationDictionary['brand_name'] ?? 
                             widget.medication!.customMedicationName ?? '';
      _amountController.text = widget.medication!.amount;
      _selectedType = widget.medication!.medicationType ?? 'TABLET';
      _selectedTiming = widget.medication!.timingInstruction ?? 'ANYTIME';
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
        'medication_id': isCustom ? null : _selectedDictionaryItem!['id'],
        'custom_medication_name': isCustom ? _nameController.text.trim() : null,
        'frequency_id': _selectedFrequency?['id'],
        'amount': _amountController.text.trim(),
        'medication_type': _selectedType,
        'timing_instruction': _selectedTiming,
        'status': 'CURRENT',
      };

      try {
        await ref.read(medicationRepositoryProvider).addPatientMedication(payload);
        ref.invalidate(patientMedicationsProvider);
        ref.invalidate(dailyMedicationScheduleProvider);
        
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

                // 2. AMOUNT & FREQUENCY ROW
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
                            decoration: _getCustomInputDecoration(context, hint: "e.g. 1 pill"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
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
                            data: (frequencies) => LayoutBuilder(
                              builder: (context, constraints) {
                                return DropdownButtonFormField<dynamic>(
                                  value: _selectedFrequency,
                                  isExpanded: true,
                                  validator: (val) => val == null ? 'Required' : null,
                                  dropdownColor: menuBackgroundColor,
                                  borderRadius: BorderRadius.circular(16),
                                  elevation: 4,
                                  icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondaryColor),
                                  decoration: _getCustomInputDecoration(context, hint: "Select frequency"),
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
                                  onChanged: (val) => setState(() => _selectedFrequency = val),
                                );
                              }
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 3. TYPE & TIMING ROW
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Timing", style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return DropdownButtonFormField<String>(
                                value: _selectedTiming,
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
                                onChanged: (val) => setState(() => _selectedTiming = val!),
                              );
                            }
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
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
