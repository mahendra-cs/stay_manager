import 'package:flutter/material.dart';

import '../../core/utils/app_date.dart';
import '../../core/utils/money_format.dart';
import '../../data/models/guest.dart';
import '../operations/operations_scope.dart';
import '../settings/config_scope.dart';
import 'guest_form_page.dart';

class GuestDetailsPage extends StatelessWidget {
  const GuestDetailsPage({super.key, required this.guestId});

  final String guestId;

  @override
  Widget build(BuildContext context) {
    final operations = OperationsScope.of(context);
    final config = ConfigScope.of(context);
    final guest = operations.guestById(guestId);

    if (guest == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Guest')),
        body: const Center(child: Text('Guest not found.')),
      );
    }

    final bookings = operations.bookingsForGuest(guestId);

    return Scaffold(
      appBar: AppBar(
        title: Text(guest.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit guest',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<Guest>(
                builder: (context) => GuestFormPage(guest: guest),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoRow(label: 'Phone', value: guest.phone),
          _InfoRow(label: 'Email', value: guest.email),
          _InfoRow(label: 'Address', value: guest.address),
          _InfoRow(
            label: 'ID',
            value: [
              guest.idType,
              guest.idNumber,
            ].where((part) => part.trim().isNotEmpty).join(' '),
          ),
          _InfoRow(label: 'Notes', value: guest.notes),
          const SizedBox(height: 24),
          Text(
            'Booking history',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (bookings.isEmpty)
            const Text('No bookings yet.')
          else
            for (final booking in bookings)
              Card(
                child: ListTile(
                  title: Text(
                    '${AppDate.format(booking.checkInDate)} \u2192 '
                    '${AppDate.format(booking.checkOutDate)}',
                  ),
                  subtitle: Text(
                    '${booking.numberOfNights} night(s) \u00b7 '
                    '${booking.bookingStatus.label} \u00b7 '
                    '${booking.paymentStatus.label}',
                  ),
                  trailing: Text(
                    formatMoney(config.property.currency, booking.total),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}