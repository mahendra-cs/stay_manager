import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../data/models/room.dart';
import '../../data/models/room_status.dart';
import 'config_scope.dart';

/// Create/edit form for a single room.
class RoomFormPage extends StatefulWidget {
  const RoomFormPage({super.key, this.room});

  /// Existing room to edit, or `null` to create a new one.
  final Room? room;

  @override
  State<RoomFormPage> createState() => _RoomFormPageState();
}

class _RoomFormPageState extends State<RoomFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _roomNumber;
  late final TextEditingController _name;
  late final TextEditingController _type;
  late final TextEditingController _floor;
  late final TextEditingController _maxOccupancy;
  late final TextEditingController _basePrice;

  late RoomStatus _status;
  late bool _active;
  bool _saving = false;

  bool get _isNew => widget.room == null;

  @override
  void initState() {
    super.initState();
    final room = widget.room;
    _roomNumber = TextEditingController(text: room?.roomNumber ?? '');
    _name = TextEditingController(text: room?.name ?? '');
    _type = TextEditingController(text: room?.type ?? '');
    _floor = TextEditingController(text: (room?.floor ?? 1).toString());
    _maxOccupancy = TextEditingController(
      text: (room?.maxOccupancy ?? 2).toString(),
    );
    final price = room?.basePrice ?? 0;
    _basePrice = TextEditingController(text: price == 0 ? '' : price.toString());
    _status = room?.status ?? RoomStatus.available;
    _active = room?.active ?? true;
  }

  @override
  void dispose() {
    _roomNumber.dispose();
    _name.dispose();
    _type.dispose();
    _floor.dispose();
    _maxOccupancy.dispose();
    _basePrice.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final config = ConfigScope.of(context);
    final base = widget.room ??
        Room(
          id: config.generateRoomId(),
          propertyId: config.property.id,
          roomNumber: '',
        );

    final updated = base.copyWith(
      roomNumber: _roomNumber.text.trim(),
      name: _name.text.trim(),
      type: _type.text.trim(),
      floor: int.tryParse(_floor.text.trim()) ?? 1,
      maxOccupancy: int.tryParse(_maxOccupancy.text.trim()) ?? 2,
      basePrice: double.tryParse(_basePrice.text.trim()) ?? 0,
      status: _status,
      active: _active,
    );

    await config.upsertRoom(updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isNew ? 'Room added' : 'Room updated')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final config = ConfigScope.of(context);
    final roomTypes = config.settings.roomTypes;
    final currentType = _type.text.trim();
    final typeItems = <String>[
      ...roomTypes,
      if (currentType.isNotEmpty && !roomTypes.contains(currentType))
        currentType,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'Add room' : 'Edit room')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _roomNumber,
              decoration: const InputDecoration(labelText: 'Room number *'),
              validator: (value) =>
                  Validators.required(value, fieldName: 'Room number'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Display name',
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 16),
            if (typeItems.isEmpty)
              TextFormField(
                controller: _type,
                decoration: const InputDecoration(labelText: 'Room type'),
              )
            else
              DropdownButtonFormField<String>(
                initialValue:
                    typeItems.contains(currentType) ? currentType : null,
                decoration: const InputDecoration(labelText: 'Room type'),
                items: [
                  for (final type in typeItems)
                    DropdownMenuItem<String>(value: type, child: Text(type)),
                ],
                onChanged: (value) =>
                    setState(() => _type.text = value ?? ''),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _floor,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Floor'),
                    validator: (value) =>
                        Validators.positiveInt(value, fieldName: 'Floor'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxOccupancy,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max occupancy',
                    ),
                    validator: (value) => Validators.positiveInt(
                      value,
                      fieldName: 'Max occupancy',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _basePrice,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Base price per night',
                prefixText: config.property.currency.isEmpty
                    ? null
                    : '${config.property.currency} ',
              ),
              validator: (value) => Validators.nonNegativeNumber(
                value,
                fieldName: 'Base price',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RoomStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final status in RoomStatus.values)
                  DropdownMenuItem<RoomStatus>(
                    value: status,
                    child: Text(status.label),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _status = value ?? RoomStatus.available),
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
              label: Text(_isNew ? 'Add room' : 'Save room'),
            ),
          ],
        ),
      ),
    );
  }
}