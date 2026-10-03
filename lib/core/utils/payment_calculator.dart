import '../../data/models/payment.dart';
import '../../data/models/payment_status.dart';

/// Aggregated settlement state of a booking.
class PaymentSummary {
  const PaymentSummary({
    required this.total,
    required this.paid,
    required this.outstanding,
    required this.status,
  });

  final double total;
  final double paid;
  final double outstanding;
  final PaymentStatus status;
}

/// Centralised payment / outstanding calculation.
class PaymentCalculator {
  const PaymentCalculator._();

  /// Small tolerance so floating-point noise never blocks a full settlement.
  static const double _epsilon = 0.005;

  static PaymentSummary summarize({
    required double total,
    required Iterable<Payment> payments,
  }) {
    final paid = payments.fold<double>(0, (sum, payment) => sum + payment.amount);
    final outstanding = (total - paid) < 0 ? 0.0 : total - paid;

    final PaymentStatus status;
    if (paid <= _epsilon) {
      status = PaymentStatus.unpaid;
    } else if (paid + _epsilon < total) {
      status = PaymentStatus.partial;
    } else {
      status = PaymentStatus.paid;
    }

    return PaymentSummary(
      total: total,
      paid: paid,
      outstanding: outstanding,
      status: status,
    );
  }

  /// Whether [amount] can be accepted given what has already been paid.
  static bool canAccept({
    required double total,
    required double alreadyPaid,
    required double amount,
  }) {
    if (amount <= 0) return false;
    return alreadyPaid + amount <= total + _epsilon;
  }
}