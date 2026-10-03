import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../data/models/property.dart';
import 'config_scope.dart';

/// Form for editing the property configuration.
///
/// Every field is optional except the name, so the same screen works for any
/// property. Values are persisted through [ConfigController].
class PropertySetupPage extends StatefulWidget {
  const PropertySetupPage({super.key, required this.initialProperty});

  final Property initialProperty;

  @override
  State<PropertySetupPage> createState() => _PropertySetupPageState();
}

class _PropertySetupPageState extends State<PropertySetupPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _currency;
  late final TextEditingController _timezone;
  late final TextEditingController _checkIn;
  late final TextEditingController _checkOut;
  late final TextEditingController _taxPercentage;
  late final TextEditingController _logoUrl;

  late bool _taxEnabled;
  late bool _active;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final property = widget.initialProperty;
    _name = TextEditingController(text: property.name);
    _address = TextEditingController(text: property.address);
    _phone = TextEditingController(text: property.phone);
    _email = TextEditingController(text: property.email);
    _currency = TextEditingController(text: property.currency);
    _timezone = TextEditingController(text: property.timezone);
    _checkIn = TextEditingController(text: property.checkInTime);
    _checkOut = TextEditingController(text: property.checkOutTime);
    _taxPercentage = TextEditingController(
      text: property.taxPercentage == 0
          ? ''
          : property.taxPercentage.toString(),
    );
    _logoUrl = TextEditingController(text: property.logoUrl ?? '');
    _taxEnabled = property.taxEnabled;
    _active = property.active;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    _currency.dispose();
    _timezone.dispose();
    _checkIn.dispose();
    _checkOut.dispose();
    _taxPercentage.dispose();
    _logoUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final trimmedLogo = _logoUrl.text.trim();
    final updated = widget.initialProperty.copyWith(
      name: _name.text.trim(),
      address: _address.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      currency: _currency.text.trim(),
      timezone: _timezone.text.trim(),
      taxEnabled: _taxEnabled,
      taxPercentage: double.tryParse(_taxPercentage.text.trim()) ?? 0,
      checkInTime: _checkIn.text.trim(),
      checkOutTime: _checkOut.text.trim(),
      active: _active,
      logoUrl:
          trimmedLogo.isEmpty ? widget.initialProperty.logoUrl : trimmedLogo,
    );

    await ConfigScope.of(context).updateProperty(updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Property saved')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Property setup')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Property name *'),
              validator: (value) =>
                  Validators.required(value, fieldName: 'Property name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _address,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _currency,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Currency code',
                      hintText: 'e.g. INR',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _timezone,
                    decoration: const InputDecoration(
                      labelText: 'Timezone',
                      hintText: 'e.g. Asia/Kolkata',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _checkIn,
                    decoration: const InputDecoration(labelText: 'Check-in'),
                    validator: Validators.timeOfDay,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _checkOut,
                    decoration: const InputDecoration(labelText: 'Check-out'),
                    validator: Validators.timeOfDay,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Apply tax'),
              value: _taxEnabled,
              onChanged: (value) => setState(() => _taxEnabled = value),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _taxPercentage,
              enabled: _taxEnabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Tax percentage',
                suffixText: '%',
              ),
              validator: (value) =>
                  _taxEnabled ? Validators.percentage(value) : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _logoUrl,
              decoration: const InputDecoration(
                labelText: 'Logo URL',
                hintText: 'https://...',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save property'),
            ),
          ],
        ),
      ),
    );
  }
}