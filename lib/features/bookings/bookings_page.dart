import 'package:flutter/material.dart';

import '../../core/utils/app_date.dart';
import '../../core/utils/money_format.dart';
import '../../core/widgets/section_placeholder.dart';
import '../../data/models/booking.dart';
import '../../data/models/booking_status.dart';
import '../operations/operations_scope.dart';
import '../settings/config_scope.dart';
import 'booking_details_page.dart';

/// Booking list with status filters (spec §28 Phase 6).
class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  BookingStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final operations = OperationsScope.of(context);
    final config = ConfigScope.of(context);

    final all = List<Booking>.from(operations.bookings)
      ..sort((a, b) => b.checkInDate.compareTo(a.checkInDate));
    final bookings = _filter == null
        ? all
        : all.where((b) => b.bookingStatus == _filter).toList(growable: false);

    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              const SizedBox(width: 4),
              _FilterChip(
                label: 'All',
                selected: _filter == null,
                onTap: () => setState(() => _filter = null),
              ),
              for (final status in BookingStatus.values)
                _FilterChip(
                  label: status.label,
                  selected: _filter == status,
                  onTap: () => setState(() => _filter = status),
                ),
            ],
          ),
        ),
        Expanded(
          child: bookings.isEmpty
              ? SectionPlaceholder(
                  icon: Icons.calendar_month_outlined,
                  title: _filter == null ? 'No bookings yet' : 'No bookings',
                  message: _filter == null
                      ? 'Tap "New booking" to reserve a room for a guest.'
                      : 'No booking has the "${_filter!.label}" status.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: bookings.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return _BookingCard(
                      booking: booking,
                      currency: config.property.currency,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              BookingDetailsPage(bookingId: booking.id),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.currency,
    required this.onTap,
  });

  final Booking booking;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final summary = OperationsScope.of(context).summaryFor(booking);

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(child: Text(booking.guestName.characters.first)),
        title: Text(booking.guestName),
        subtitle: Text(
          '${AppDate.format(booking.checkInDate)} \u2192 '
          '${AppDate.format(booking.checkOutDate)}\n'
          '${booking.numberOfNights} night(s) \u00b7 '
          '${booking.bookingStatus.label} \u00b7 '
          '${summary.status.label}',
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formatMoney(currency, booking.total)),
            if (summary.outstanding > 0)
              Text(
                'Due ${formatMoney(currency, summary.outstanding)}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}
