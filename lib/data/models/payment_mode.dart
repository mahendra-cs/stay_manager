/// How money was collected. The set of modes is configuration driven
/// (see `AppSettings`); this enum lists the typical defaults.
enum PaymentMode {
  cash('CASH', 'Cash'),
  upi('UPI', 'UPI'),
  card('CARD', 'Card'),
  bankTransfer('BANK_TRANSFER', 'Bank transfer'),
  other('OTHER', 'Other');

  const PaymentMode(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static PaymentMode fromWire(Object? value) {
    if (value is String) {
      for (final mode in values) {
        if (mode.wireValue == value) return mode;
      }
    }
    return PaymentMode.other;
  }
}