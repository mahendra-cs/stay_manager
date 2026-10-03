import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../data/models/guest.dart';
import '../operations/operations_scope.dart';
import '../settings/config_scope.dart';

/// Create/edit a guest. Pops with the saved [Guest] on success.
class GuestFormPage extends StatefulWidget {
  const GuestFormPage({super.key, this.guest});

  final Guest? guest;

  @override
  State<GuestFormPage> createState() => _GuestFormPageState();
}

class _GuestFormPageState extends State<GuestFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _idType;
  late final TextEditingController _idNumber;
  late final TextEditingController _notes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final guest = widget.guest;
    _name = TextEditingController(text: guest?.name ?? '');
    _phone = TextEditingController(text: guest?.phone ?? '');
    _email = TextEditingController(text: guest?.email ?? '');
    _address = TextEditingController(text: guest?.address ?? '');
    _idType = TextEditingController(text: guest?.idType ?? '');
    _idNumber = TextEditingController(text: guest?.idNumber ?? '');
    _notes = TextEditingController(text: guest?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _idType.dispose();
    _idNumber.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final operations = OperationsScope.of(context);
    final config = ConfigScope.of(context);
    final base = widget.guest ??
        Guest(
          id: 'guest-${DateTime.now().microsecondsSinceEpoch}',
          propertyId: config.property.id,
          name: '',
        );

    final saved = await operations.upsertGuest(
      base.copyWith(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        address: _address.text.trim(),
        idType: _idType.text.trim(),
        idNumber: _idNumber.text.trim(),
        notes: _notes.text.trim(),
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.guest == null ? 'Add guest' : 'Edit guest'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: (value) =>
                  Validators.required(value, fieldName: 'Name'),
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
            TextFormField(
              controller: _address,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _idType,
                    decoration: const InputDecoration(labelText: 'ID type'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _idNumber,
                    decoration: const InputDecoration(labelText: 'ID number'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes'),
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
              label: Text(widget.guest == null ? 'Save guest' : 'Update guest'),
            ),
          ],
        ),
      ),
    );
  }
}
