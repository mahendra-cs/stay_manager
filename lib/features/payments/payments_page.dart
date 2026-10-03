import 'package:flutter/material.dart';

import '../../core/utils/app_date.dart';
import '../../core/utils/money_format.dart';
import '../../core/widgets/section_placeholder.dart';
import '../../data/models/payment.dart';
import '../bookings/booking_details_page.dart';
import '../operations/operations_scope.dart';
import '../settings/config_scope.dart';

/// Payment history across every booking, newest first (spec §28 Phase 7).
class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final operations = OperationsScope.of(context);
    final config = ConfigScope.of(context);
    final currency = config.property.currency;

    final payments = List<Payment>.from(operations.payments)
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    final total = payments.fold<double>(0, (sum, p) => sum + p.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: payments.isEmpty
          ? const SectionPlaceholder(
              icon: Icons.payments_outlined,
              title: 'No payments yet',
              message: 'Payments recorded against a booking appear here.',
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total collected',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            formatMoney(currency, total),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: payments.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      final booking = operations.bookingById(payment.bookingId);

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.payments_outlined),
                          title: Text(
                            booking?.guestName ?? 'Unknown booking',
                          ),
                          subtitle: Text(
                            '${payment.paymentMode.label} \u00b7 '
                            '${AppDate.format(payment.paymentDate)}'
                            '${payment.reference.trim().isEmpty ? '' : ' \u00b7 ${payment.reference}'}',
                          ),
                          trailing: Text(formatMoney(currency, payment.amount)),
                          onTap: booking == null
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (context) => BookingDetailsPage(
                                        bookingId: booking.id,
                                      ),
                                    ),
                                  ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}