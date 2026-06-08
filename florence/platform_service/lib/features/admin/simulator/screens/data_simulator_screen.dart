import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/config/admin_theme.dart';
import 'package:florence/core/services/api_service.dart';
import 'package:florence/features/admin/core/widgets/admin_sidebar.dart';
import 'package:florence/features/admin/core/providers/admin_providers.dart';

class DataSimulatorScreen extends ConsumerStatefulWidget {
  const DataSimulatorScreen({super.key});

  @override
  ConsumerState<DataSimulatorScreen> createState() => _DataSimulatorScreenState();
}

class _DataSimulatorScreenState extends ConsumerState<DataSimulatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  final _emailController = TextEditingController(text: 'test_patient_1@example.com');
  final _nameController = TextEditingController(text: 'Test Patient 1');
  final _passwordController = TextEditingController(text: 'Florence123!');
  
  String _selectedScenario = 'The Perfect Patient (High Time-in-Range, regular exercise)';
  bool _isLoading = false;

  final List<String> _scenarios = [
    'The Perfect Patient (High Time-in-Range, regular exercise)',
    'The Rollercoaster (Frequent highs and lows, erratic eating)',
    'Dawn Phenomenon (High morning fasting glucose, normal otherwise)',
    'High-Carb Sedentary (Post-meal spikes, zero activity)'
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _generatePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.post('/admin/simulator/generate', {
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'password': _passwordController.text,
        'scenario': _selectedScenario,
        'days': 180,
        'timezone_offset': DateTime.now().timeZoneOffset.inHours,
      });

      // Force patient list refresh so it shows up in directory
      ref.invalidate(adminPatientsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synthetic patient generated successfully!'),
            backgroundColor: AdminTheme.primary,
          ),
        );
        // Reset email iteration for convenience
        _emailController.text = 'test_patient_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}@example.com';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AdminTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSidebar(currentRoute: '/admin/data-simulator'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LLM Data Simulator', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 8),
                  Text(
                    'Instantly orchestrate 180 days of highly-realistic clinical data using LangChain.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Configuration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const Divider(height: 32),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _nameController,
                                    decoration: _inputDeco('Patient Name', Icons.person_outline),
                                    validator: (val) => val!.isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _emailController,
                                    decoration: _inputDeco('Email Address', Icons.email_outlined),
                                    validator: (val) => val!.isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: _inputDeco('Password', Icons.lock_outline),
                              validator: (val) => val!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 24),
                            
                            const Text('Clinical Persona', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedScenario,
                              decoration: _inputDeco('', Icons.psychology_alt),
                              isExpanded: true,
                              items: _scenarios.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (val) => setState(() => _selectedScenario = val!),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _isLoading ? null : _generatePatient,
                                icon: _isLoading 
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.science),
                                label: Text(_isLoading ? 'Orchestrating via LLM... This may take up to 45 seconds' : 'Generate Patient (180 Days)'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.purple.shade600,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label.isEmpty ? null : label,
      prefixIcon: Icon(icon, color: AdminTheme.outline),
      filled: true,
      fillColor: AdminTheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminTheme.outlineVariant)),
    );
  }
}
