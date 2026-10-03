import 'package:flutter/material.dart';

import '../../core/utils/app_date.dart';
import '../../core/utils/money_format.dart';
import '../../data/models/booking.dart';

/// Occupancy / arrival / departure / revenue blocks (spec \u00a716).
class DashboardBookingList extends StatelessWidget {
  const DashboardBookingList({
    super.key,
    required this.title,
    required this.bookings,
    required this.currency,
    required this.emptyMessage,
  });

  final String title;
  final List<Booking> bookings;
  final String currency;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (bookings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(emptyMessage),
          )
        else
          for (final booking in bookings)
            Card(
              child: ListTile(
                dense: true,
                title: Text(booking.guestName),
                subtitle: Text(
                  '${AppDate.format(booking.checkInDate)} \u2192 '
                  '${AppDate.format(booking.checkOutDate)} \u00b7 '
                  '${booking.bookingStatus.label}',
                ),
                trailing: Text(formatMoney(currency, booking.total)),
              ),
            ),
      ],
    );
  }
}

/// Label / amount row used for the collection summary.
class DashboardMoneyRow extends StatelessWidget {
  const DashboardMoneyRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  final String label;
  final String value;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final style = emphasise
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.error,
          )
        : Theme.of(context).textTheme.bodyLarge;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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

/// Compact occupancy / activity counter.
class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
