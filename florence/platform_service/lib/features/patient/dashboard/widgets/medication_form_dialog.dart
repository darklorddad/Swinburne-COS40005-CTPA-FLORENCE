import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/models/medication_models.dart';

/// A dialog for adding or editing a medication.
class MedicationFormDialog extends StatefulWidget {
  final bool isEdit;
  final PatientMedication? medication;

  const MedicationFormDialog({
    super.key,
    required this.isEdit,
    this.medication,
  });

  @override
  State<MedicationFormDialog> createState() => _MedicationFormDialogState();
}

class _MedicationFormDialogState extends State<MedicationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  late TextEditingController _amountController;
  int? _selectedMedicationId;
  int? _selectedFrequencyId;
  String? _selectedType;
  String? _selectedTiming;

  // Options (Mocked for UI structure, should ideally come from providers)
  final List<Map<String, dynamic>> _medications = [
    {'id': 1, 'name': 'Metformin (Diabetes)'},
    {'id': 7, 'name': 'Lipitor (Cholesterol)'},
    {'id': 10, 'name': 'Panadol (Pain/Fever)'},
  ];

  final List<Map<String, dynamic>> _frequencies = [
    {'id': 1, 'name': 'Once a day'},
    {'id': 2, 'name': 'Twice a day'},
    {'id': 5, 'name': 'As needed'},
  ];

  final List<String> _types = ['TABLET', 'CAPSULE', 'LIQUID', 'INHALER'];
  
  final List<String> _timings = [
    'BEFORE_MEAL',
    'AFTER_MEAL',
    'AS_NEEDED',
    'ANYTIME',
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.isEdit ? widget.medication?.amount : '',
    );
    
    if (widget.isEdit && widget.medication != null) {
      _selectedMedicationId = widget.medication!.medicationDictionary['id'];
      _selectedType = widget.medication!.medicationType;
      _selectedTiming = widget.medication!.timingInstruction;
      // Frequency ID would need to be mapped from the joined data if available
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
        width: 500, // Constrain width for desktop screens
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                
                // Medication Selection
                const Text("Medication", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    prefixIcon: const Icon(Icons.medical_services_outlined),
                  ),
                  value: _selectedMedicationId,
                  items: _medications.map((med) {
                    return DropdownMenuItem<int>(
                      value: med['id'] as int,
                      child: Text(med['name'] as String),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedMedicationId = val),
                  validator: (val) => val == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Frequency Selection
                const Text("Frequency", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    prefixIcon: const Icon(Icons.repeat),
                  ),
                  value: _selectedFrequencyId,
                  items: _frequencies.map((freq) {
                    return DropdownMenuItem<int>(
                      value: freq['id'] as int,
                      child: Text(freq['name'] as String),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedFrequencyId = val),
                  validator: (val) => val == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Amount Input
                const Text("Amount", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    hintText: "e.g. 1 tablet",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Type Selection
                const Text("Type", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                  value: _selectedType,
                  items: _types.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedType = val),
                  validator: (val) => val == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Timing Selection
                const Text("Timing", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    prefixIcon: const Icon(Icons.access_time),
                  ),
                  value: _selectedTiming,
                  items: _timings.map((timing) {
                    return DropdownMenuItem<String>(
                      value: timing,
                      child: Text(timing.replaceAll('_', ' ')),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedTiming = val),
                  validator: (val) => val == null ? 'Required' : null,
                ),

                const SizedBox(height: 32),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // TODO: Save via Repository
                          Navigator.pop(context);
                        }
                      },
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
