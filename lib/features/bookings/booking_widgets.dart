import 'package:flutter/material.dart';

import '../../data/models/booking.dart';
import '../../data/models/booking_status.dart';

/// Label/value row used across detail screens.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Label/money row for price breakdowns.
class MoneyRow extends StatelessWidget {
  const MoneyRow({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          )
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// Context-sensitive actions for a booking, driven purely by its status.
class BookingActions extends StatelessWidget {
  const BookingActions({
    super.key,
    required this.booking,
    required this.busy,
    required this.onCheckIn,
    required this.onCheckOut,
    required this.onPayment,
    required this.onCancel,
    required this.onMarkAvailable,
  });

  final Booking booking;
  final bool busy;
  final Future<void> Function() onCheckIn;
  final Future<void> Function() onCheckOut;
  final Future<void> Function() onPayment;
  final Future<void> Function() onCancel;
  final Future<void> Function() onMarkAvailable;

  @override
  Widget build(BuildContext context) {
    final isBooked = booking.bookingStatus == BookingStatus.booked;
    final isCheckedIn = booking.bookingStatus == BookingStatus.checkedIn;
    final isClosed = booking.bookingStatus == BookingStatus.checkedOut ||
        booking.bookingStatus == BookingStatus.cancelled ||
        booking.bookingStatus == BookingStatus.noShow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isBooked)
          FilledButton.icon(
            onPressed: busy ? null : onCheckIn,
            icon: const Icon(Icons.login),
            label: const Text('Check in'),
          ),
        if (isCheckedIn) ...[
          FilledButton.icon(
            onPressed: busy ? null : onCheckOut,
            icon: const Icon(Icons.logout),
            label: const Text('Check out'),
          ),
          const SizedBox(height: 12),
        ],
        if (!isClosed)
          OutlinedButton.icon(
            onPressed: busy ? null : onPayment,
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Record payment'),
          ),
        if (isClosed) ...[
          OutlinedButton.icon(
            onPressed: busy ? null : onMarkAvailable,
            icon: const Icon(Icons.cleaning_services_outlined),
            label: const Text('Mark room available'),
          ),
          const SizedBox(height: 12),
        ],
        if (!isClosed)
          TextButton.icon(
            onPressed: busy ? null : onCancel,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel booking'),
          ),
      ],
    );
  }
}