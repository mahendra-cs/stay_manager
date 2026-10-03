/// Where a booking originated. The set of sources is configuration driven
/// (see `AppSettings`); this enum lists the typical defaults.
enum BookingSource {
  walkIn('WALK_IN', 'Walk in'),
  phone('PHONE', 'Phone'),
  whatsapp('WHATSAPP', 'WhatsApp'),
  website('WEBSITE', 'Website'),
  bookingCom('BOOKING_COM', 'Booking.com'),
  makeMyTrip('MAKEMYTRIP', 'MakeMyTrip'),
  agoda('AGODA', 'Agoda'),
  other('OTHER', 'Other');

  const BookingSource(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static BookingSource fromWire(Object? value) {
    if (value is String) {
      for (final source in values) {
        if (source.wireValue == value) return source;
      }
    }
    return BookingSource.other;
  }
}