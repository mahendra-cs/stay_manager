/// Lifecycle status of a room.
///
/// [wireValue] is the stable identifier persisted to storage (Firestore later);
/// [label] is the human friendly text shown in the UI.
enum RoomStatus {
  available('AVAILABLE', 'Available'),
  booked('BOOKED', 'Booked'),
  checkedIn('CHECKED_IN', 'Checked in'),
  checkedOut('CHECKED_OUT', 'Checked out'),
  cleaning('CLEANING', 'Cleaning'),
  blocked('BLOCKED', 'Blocked');

  const RoomStatus(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static RoomStatus fromWire(Object? value) {
    if (value is String) {
      for (final status in values) {
        if (status.wireValue == value) return status;
      }
    }
    return RoomStatus.available;
  }
}