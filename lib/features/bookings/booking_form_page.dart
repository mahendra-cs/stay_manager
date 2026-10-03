import 'package:flutter/material.dart';

import '../../core/errors/validation_exception.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/booking_builder.dart';
import '../../core/utils/booking_calculator.dart';
import '../../core/utils/money_format.dart';
import '../../core/utils/validators.dart';
import '../../data/models/booking.dart';
import '../../data/models/booking_source.dart';
import '../../data/models/guest.dart';
import '../../data/models/property.dart';
import '../../data/models/room.dart';
import '../guests/guest_picker_sheet.dart';
import '../operations/operations_scope.dart';
import '../settings/config_scope.dart';

/// Create or edit a booking (spec §28 Phase 6).
///
/// The form only collects input. Pricing comes from [BookingBuilder] and
/// availability from the operations controller, so every rule stays in one
/// testable place rather than inside the widget tree.
class BookingFormPage extends StatefulWidget {
  const BookingFormPage({super.key, this.booking});

  /// Existing booking to edit, or `null` to create a new one.
  final Booking? booking;

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _checkIn;
  late DateTime _checkOut;
  Guest? _guest;
  String? _roomId;
  late double _pricePerNight;
  BookingSource _source = BookingSource.walkIn;
  bool _saving = false;

  late final TextEditingController _discount;
  late final TextEditingController _adults;
  late final TextEditingController _children;
  late final TextEditingController _notes;

  bool get _isNew => widget.booking == null;

  @override
  void initState() {
    super.initState();
    final booking = widget.booking;
    final today = AppDate.today();

    _checkIn = booking == null
        ? today
        : AppDate.dateOnly(booking.checkInDate);
    _checkOut = booking == null
        ? today.add(const Duration(days: 1))
        : AppDate.dateOnly(booking.checkOutDate);
    _roomId = booking?.roomId;
    _pricePerNight = booking?.pricePerNight ?? 0;
    _source = booking?.source ?? BookingSource.walkIn;

    final discount = booking?.discount ?? 0;
    _discount = TextEditingController(text: discount == 0 ? '' : '$discount');
    _adults = TextEditingController(text: '${booking?.adults ?? 1}');
    _children = TextEditingController(text: '${booking?.children ?? 0}');
    _notes = TextEditingController(text: booking?.notes ?? '');
  }

  @override
  void dispose() {
    _discount.dispose();
    _adults.dispose();
    _children.dispose();
    _notes.dispose();
    super.dispose();
  }

  double get _discountValue => double.tryParse(_discount.text.trim()) ?? 0;

  int get _adultsValue => int.tryParse(_adults.text.trim()) ?? 1;

  int get _childrenValue => int.tryParse(_children.text.trim()) ?? 0;

  /// Live price breakdown, or `null` while the input is not yet valid.
  BookingQuote? _previewQuote(Property property) {
    return BookingBuilder.preview(
      checkIn: _checkIn,
      checkOut: _checkOut,
      pricePerNight: _pricePerNight,
      discount: _discountValue,
      taxEnabled: property.taxEnabled,
      taxPercentage: property.taxPercentage,
    );
  }

  Future<void> _pickGuest() async {
    final guest = await showGuestPicker(context);
    if (guest != null && mounted) {
      setState(() => _guest = guest);
    }
  }

  Future<void> _pickRoom(List<Room> available, List<Room> all) async {
    if (all.isEmpty) {
      _showMessage('Add rooms from More \u2192 Room setup first.');
      return;
    }
    final selected = await showModalBottomSheet<Room>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _RoomPickerSheet(available: available, all: all),
    );
    if (selected != null && mounted) {
      setState(() {
        _roomId = selected.id;
        // Seed the nightly rate from the room's configured base price.
        if (_isNew || _pricePerNight <= 0) {
          _pricePerNight = selected.basePrice;
        }
      });
    }
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkIn : _checkOut,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (isCheckIn) {
        _checkIn = AppDate.dateOnly(picked);
        if (!_checkOut.isAfter(_checkIn)) {
          _checkOut = _checkIn.add(const Duration(days: 1));
        }
      } else {
        final day = AppDate.dateOnly(picked);
        if (day.isAfter(_checkIn)) _checkOut = day;
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final guest = _guest;
    if (guest == null) {
      _showMessage('Select or create a guest first.');
      return;
    }
    final roomId = _roomId;
    if (roomId == null) {
      _showMessage('Select a room.');
      return;
    }

    setState(() => _saving = true);

    final operations = OperationsScope.of(context);
    final config = ConfigScope.of(context);

    try {
      final built = BookingBuilder.build(
        draft: BookingDraft(
          guestId: guest.id,
          guestName: guest.name,
          guestPhone: guest.phone,
          roomId: roomId,
          checkIn: _checkIn,
          checkOut: _checkOut,
          pricePerNight: _pricePerNight,
          propertyId: config.property.id,
          adults: _adultsValue,
          children: _childrenValue,
          discount: _discountValue,
          source: _source,
          notes: _notes.text.trim(),
        ),
        property: config.property,
        settings: config.settings,
        existing: widget.booking,
      );

      final saved = await operations.upsertBooking(
        built.booking,
        rooms: config.rooms,
      );
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } on ValidationException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(error.message);
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ConfigScope.of(context);
    final operations = OperationsScope.of(context);

    final availableRooms = operations.availableRooms(
      rooms: config.rooms,
      checkIn: _checkIn,
      checkOut: _checkOut,
      ignoreBookingId: widget.booking?.id,
    );
    final selectedRoom = config.roomById(_roomId ?? '');
    final quote = _previewQuote(config.property);
    final currency = config.property.currency;
    final sources = BookingBuilder.availableSources(config.settings);

    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'New booking' : 'Edit booking')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionLabel('Guest'),
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(_guest?.name ?? 'Select guest'),
                subtitle: _guest == null
                    ? const Text('Tap to search or add guest details')
                    : Text(_guestSubtitle(_guest!)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickGuest,
              ),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Stay'),
            Row(
              children: [
                Expanded(
                  child: _PickerField(
                    label: 'Check-in',
                    value: AppDate.format(_checkIn),
                    icon: Icons.login,
                    onTap: () => _pickDate(isCheckIn: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerField(
                    label: 'Check-out',
                    value: AppDate.format(_checkOut),
                    icon: Icons.logout,
                    onTap: () => _pickDate(isCheckIn: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.meeting_room_outlined),
                title: Text(selectedRoom?.displayName ?? 'Select room'),
                subtitle: Text(_roomSubtitle(selectedRoom, availableRooms)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pickRoom(availableRooms, config.rooms),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Occupancy'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _adults,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Adults'),
                    validator: (value) =>
                        Validators.positiveInt(value, fieldName: 'Adults'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _children,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Children'),
                    validator: (value) => Validators.nonNegativeNumber(
                      value,
                      fieldName: 'Children',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Pricing'),
            TextFormField(
              initialValue: _pricePerNight == 0 ? '' : '$_pricePerNight',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Price per night',
                prefixText: currency.isEmpty ? null : '$currency ',
              ),
              validator: (value) => Validators.nonNegativeNumber(
                value,
                fieldName: 'Price per night',
              ),
              onChanged: (value) => setState(
                () => _pricePerNight = double.tryParse(value.trim()) ?? 0,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _discount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Discount',
                prefixText: currency.isEmpty ? null : '$currency ',
              ),
              validator: (value) =>
                  Validators.nonNegativeNumber(value, fieldName: 'Discount'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<BookingSource>(
              initialValue: sources.contains(_source) ? _source : sources.first,
              decoration: const InputDecoration(labelText: 'Source'),
              items: [
                for (final source in sources)
                  DropdownMenuItem<BookingSource>(
                    value: source,
                    child: Text(source.label),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _source = value ?? BookingSource.walkIn),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Summary'),
            _PriceSummary(quote: quote, currency: currency),
            const SizedBox(height: 24),
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
                  : const Icon(Icons.check),
              label: Text(_isNew ? 'Create booking' : 'Save changes'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _guestSubtitle(Guest guest) {
    final parts = <String>[
      if (guest.phone.trim().isNotEmpty) guest.phone,
      if (guest.email.trim().isNotEmpty) guest.email,
    ];
    return parts.isEmpty ? 'No contact details' : parts.join(' \u00b7 ');
  }

  String _roomSubtitle(Room? room, List<Room> available) {
    if (room == null) {
      return available.isEmpty
          ? 'No rooms available for these dates'
          : '${available.length} room(s) available';
    }
    return available.any((r) => r.id == room.id)
        ? 'Available for these dates'
        : 'Occupied for these dates';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// Read-only field that opens a picker — used for dates.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        child: Text(value),
      ),
    );
  }
}

/// Shows the price breakdown produced by `BookingCalculator`.
class _PriceSummary extends StatelessWidget {
  const _PriceSummary({required this.quote, required this.currency});

  final BookingQuote? quote;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = quote;

    if (current == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Enter valid dates and a price to see the total.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    Widget row(String label, num value, {bool emphasise = false}) {
      final style = emphasise
          ? theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            )
          : theme.textTheme.bodyMedium;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: style),
            Text(formatMoney(currency, value), style: style),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row('${current.nights} night(s) x ${formatMoney(currency, current.pricePerNight)}',
                current.subtotal),
            if (current.discount > 0) row('Discount', -current.discount),
            if (current.tax > 0)
              row('Tax', current.tax),
            const Divider(height: 16),
            row('Total', current.total, emphasise: true),
          ],
        ),
      ),
    );
  }
}

/// Room chooser. Available rooms are listed first; occupied ones stay visible
/// but are marked, so the receptionist understands why a room is unavailable.
class _RoomPickerSheet extends StatelessWidget {
  const _RoomPickerSheet({required this.available, required this.all});

  final List<Room> available;
  final List<Room> all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableIds = available.map((room) => room.id).toSet();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (context, controller) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Select a room', style: theme.textTheme.titleMedium),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: all.length,
                itemBuilder: (context, index) {
                  final room = all[index];
                  final isAvailable = availableIds.contains(room.id);
                  return ListTile(
                    enabled: isAvailable,
                    leading: CircleAvatar(child: Text(room.roomNumber)),
                    title: Text(room.displayName),
                    subtitle: Text(
                      isAvailable
                          ? 'Available'
                          : 'Not available for these dates',
                      style: TextStyle(
                        color: isAvailable ? null : theme.disabledColor,
                      ),
                    ),
                    trailing: isAvailable
                        ? const Icon(Icons.chevron_right)
                        : const Icon(Icons.block),
                    onTap: isAvailable
                        ? () => Navigator.of(context).pop(room)
                        : null,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}