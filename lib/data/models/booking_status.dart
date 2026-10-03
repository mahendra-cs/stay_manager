/// Lifecycle of a booking.
enum BookingStatus {
  booked('BOOKED', 'Booked'),
  checkedIn('CHECKED_IN', 'Checked in'),
  checkedOut('CHECKED_OUT', 'Checked out'),
  cancelled('CANCELLED', 'Cancelled'),
  noShow('NO_SHOW', 'No show');

  const BookingStatus(this.wireValue, this.label);

  final String wireValue;
  final String label;

  /// True while the booking still occupies its room.
  bool get occupiesRoom =>
      this == BookingStatus.booked || this == BookingStatus.checkedIn;

  static BookingStatus fromWire(Object? value) {
    if (value is String) {
      for (final status in values) {
        if (status.wireValue == value) return status;
      }
    }
    return BookingStatus.booked;
  }
}