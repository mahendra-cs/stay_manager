import 'package:flutter/material.dart';

import '../../core/errors/validation_exception.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/money_format.dart';
import '../../data/models/booking_status.dart';
import '../../data/models/payment.dart';
import '../operations/operations_scope.dart';
import '../payments/payment_form_page.dart';
import '../settings/config_scope.dart';
import 'booking_form_page.dart';
import 'booking_widgets.dart';

/// Booking detail with the operational actions a receptionist needs:
/// check-in, check-out, record payment, cancel (spec §6 / §8 / §14).
class BookingDetailsPage extends StatefulWidget {
  const BookingDetailsPage({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final operations = OperationsScope.of(context);
    final config = ConfigScope.of(context);
    final booking = operations.bookingById(widget.bookingId);

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking')),
        body: const Center(child: Text('Booking not found.')),
      );
    }

    final summary = operations.summaryFor(booking);
    final room = config.roomById(booking.roomId);
    final currency = config.property.currency;
    final payments = operations.paymentsForBooking(booking.id)
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    return Scaffold(
      appBar: AppBar(
        title: Text(booking.guestName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit booking',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => BookingFormPage(booking: booking),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  InfoRow(label: 'Guest', value: booking.guestName),
                  InfoRow(label: 'Phone', value: booking.guestPhone),
                  InfoRow(label: 'Room', value: room?.displayName ?? ''),
                  InfoRow(
                    label: 'Check-in',
                    value: AppDate.format(booking.checkInDate),
                  ),
                  InfoRow(
                    label: 'Check-out',
                    value: AppDate.format(booking.checkOutDate),
                  ),
                  InfoRow(label: 'Nights', value: '${booking.numberOfNights}'),
                  InfoRow(label: 'Status', value: booking.bookingStatus.label),
                  InfoRow(label: 'Source', value: booking.source.label),
                  if (booking.notes.trim().isNotEmpty)
                    InfoRow(label: 'Notes', value: booking.notes),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  MoneyRow(
                    label: 'Subtotal',
                    value: formatMoney(currency, booking.subtotal),
                  ),
                  if (booking.discount > 0)
                    MoneyRow(
                      label: 'Discount',
                      value: '-${formatMoney(currency, booking.discount)}',
                    ),
                  if (booking.tax > 0)
                    MoneyRow(
                      label: 'Tax',
                      value: formatMoney(currency, booking.tax),
                    ),
                  const Divider(height: 20),
                  MoneyRow(
                    label: 'Total',
                    value: formatMoney(currency, booking.total),
                    bold: true,
                  ),
                  MoneyRow(
                    label: 'Paid',
                    value: formatMoney(currency, summary.paid),
                  ),
                  MoneyRow(
                    label: 'Outstanding',
                    value: formatMoney(currency, summary.outstanding),
                    bold: summary.outstanding > 0,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          BookingActions(
            booking: booking,
            busy: _busy,
            onCheckIn: _checkIn,
            onCheckOut: _checkOut,
            onPayment: _addPayment,
            onCancel: _confirmCancel,
            onMarkAvailable: _markRoomAvailable,
          ),
          const SizedBox(height: 24),
          Text('Payments', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (payments.isEmpty)
            const Text('No payments recorded.')
          else
            for (final payment in payments)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(formatMoney(currency, payment.amount)),
                  subtitle: Text(
                    '${payment.paymentMode.label} \u00b7 '
                    '${AppDate.format(payment.paymentDate)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete payment',
                    onPressed: () => _confirmDeletePayment(payment),
                  ),
                ),
              ),
        ],
      ),
    );
  }
/// Runs an action, surfacing validation problems as a snackbar.
  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
    } on ValidationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkIn() {
    final operations = OperationsScope.of(context);
    final booking = operations.bookingById(widget.bookingId)!;
    return _run(() => operations.checkIn(booking), 'Guest checked in');
  }

  Future<void> _checkOut() {
    final operations = OperationsScope.of(context);
    final booking = operations.bookingById(widget.bookingId)!;
    return _run(() => operations.checkOut(booking), 'Guest checked out');
  }

  Future<void> _markRoomAvailable() {
    final booking = OperationsScope.of(context).bookingById(widget.bookingId)!;
    return _run(
      () => OperationsScope.of(context).markRoomAvailable(booking.roomId),
      'Room marked available',
    );
  }

  Future<void> _addPayment() async {
    final booking = OperationsScope.of(context).bookingById(widget.bookingId);
    if (booking == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PaymentFormPage(booking: booking),
      ),
    );
  }

  Future<void> _confirmCancel() async {
    final operations = OperationsScope.of(context);
    final booking = operations.bookingById(widget.bookingId);
    if (booking == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text('The room will be released for other guests.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(
        () => operations.setBookingStatus(booking, BookingStatus.cancelled),
        'Booking cancelled',
      );
    }
  }

  Future<void> _confirmDeletePayment(Payment payment) async {
    final operations = OperationsScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete payment?'),
        content: const Text('The booking balance will be recalculated.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(() => operations.deletePayment(payment.id), 'Payment deleted');
    }
  }
}