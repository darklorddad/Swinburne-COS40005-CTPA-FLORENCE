import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/config/admin_theme.dart';
import 'package:florence/core/utils/validators.dart';
import 'package:florence/features/admin/core/providers/admin_providers.dart';
import 'package:florence/features/admin/core/models/admin_models.dart';

class OrganizationFormDialog extends ConsumerStatefulWidget {
  final AdminOrganization? organization;
  const OrganizationFormDialog({super.key, this.organization});

  @override
  ConsumerState<OrganizationFormDialog> createState() => _OrganizationFormDialogState();
}

class _OrganizationFormDialogState extends ConsumerState<OrganizationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _phoneCtrl, _emailCtrl, _websiteCtrl, _addressCtrl, _stateCtrl, _hoursCtrl;
  String _sector = 'Private';
  String _facilityType = 'Clinic';
  bool _is24Hours = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final o = widget.organization;
    _nameCtrl = TextEditingController(text: o?.name ?? '');
    _phoneCtrl = TextEditingController(text: o?.phoneNumber ?? '');
    _emailCtrl = TextEditingController(text: o?.email ?? '');
    _websiteCtrl = TextEditingController(text: o?.website ?? '');
    _addressCtrl = TextEditingController(text: o?.fullAddress ?? '');
    _stateCtrl = TextEditingController(text: o?.state ?? '');
    _hoursCtrl = TextEditingController(text: o?.operatingHours ?? '');
    if (o != null) {
      _sector = o.sector ?? 'Private';
      _facilityType = o.facilityType ?? 'Clinic';
      _is24Hours = o.is24Hours;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'phone_number': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'sector': _sector,
        'facility_type': _facilityType,
        'full_address': _addressCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'is_24_hours': _is24Hours,
        'operating_hours': _is24Hours ? '24 Hours' : _hoursCtrl.text.trim(),
      };

      await ref.read(adminRepositoryProvider).saveOrganization(data, id: widget.organization?.id);
      ref.invalidate(adminOrganizationsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Organization saved successfully'), backgroundColor: AdminTheme.primary));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AdminTheme.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.organization == null ? 'New Organization' : 'Edit Organization', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Organization Name *'), validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v!.isNotEmpty ? Validators.email(v) : null)),
                    const SizedBox(width: 16),
                    Expanded(child: TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number'))),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(controller: _websiteCtrl, decoration: const InputDecoration(labelText: 'Website')),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: DropdownButtonFormField<String>(value: _sector, decoration: const InputDecoration(labelText: 'Sector'), items: ['Public', 'Private', 'NGO', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _sector = v!))),
                    const SizedBox(width: 16),
                    Expanded(child: DropdownButtonFormField<String>(value: _facilityType, decoration: const InputDecoration(labelText: 'Facility Type'), items: ['Hospital', 'Clinic', 'Health Centre', 'Lab', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _facilityType = v!))),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(controller: _addressCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Full Address')),
                const SizedBox(height: 16),
                TextFormField(controller: _stateCtrl, decoration: const InputDecoration(labelText: 'State / Province')),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('24 Hours Operation'),
                  value: _is24Hours,
                  activeColor: AdminTheme.primary,
                  onChanged: (v) => setState(() => _is24Hours = v),
                ),
                if (!_is24Hours) ...[
                  const SizedBox(height: 16),
                  TextFormField(controller: _hoursCtrl, decoration: const InputDecoration(labelText: 'Operating Hours (e.g., Mon-Fri 8am-5pm)')),
                ],
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const SizedBox(width: 16),
                    FilledButton(onPressed: _isLoading ? null : _submit, style: FilledButton.styleFrom(backgroundColor: AdminTheme.primary, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)), child: _isLoading ? const CircularProgressIndicator() : const Text('Save Changes', style: TextStyle(color: Colors.white))),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}