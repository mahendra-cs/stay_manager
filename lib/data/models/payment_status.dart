/// Settlement state of a booking.
enum PaymentStatus {
  unpaid('UNPAID', 'Unpaid'),
  partial('PARTIAL', 'Partial'),
  paid('PAID', 'Paid');

  const PaymentStatus(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static PaymentStatus fromWire(Object? value) {
    if (value is String) {
      for (final status in values) {
        if (status.wireValue == value) return status;
      }
    }
    return PaymentStatus.unpaid;
  }
}