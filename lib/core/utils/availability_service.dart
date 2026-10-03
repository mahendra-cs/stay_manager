import '../../data/models/booking.dart';
import '../../data/models/room.dart';
import '../../data/models/room_status.dart';
import 'app_date.dart';

/// Decides whether a room can be sold for a date range.
///
/// A room is unavailable when it is inactive, blocked, or already has an
/// active (booked / checked-in) booking overlapping the requested range.
class AvailabilityService {
  const AvailabilityService._();

  static bool isRoomAvailable({
    required Room room,
    required DateTime checkIn,
    required DateTime checkOut,
    required Iterable<Booking> bookings,
    String? ignoreBookingId,
  }) {
    if (!room.active) return false;
    if (room.status == RoomStatus.blocked) return false;

    final start = AppDate.dateOnly(checkIn);
    final end = AppDate.dateOnly(checkOut);
    if (!end.isAfter(start)) return false;

    for (final booking in bookings) {
      if (booking.roomId != room.id) continue;
      if (!booking.bookingStatus.occupiesRoom) continue;
      if (ignoreBookingId != null && booking.id == ignoreBookingId) continue;
      if (booking.isOverlapping(start, end)) return false;
    }
    return true;
  }

  static List<Room> availableRooms({
    required Iterable<Room> rooms,
    required DateTime checkIn,
    required DateTime checkOut,
    required Iterable<Booking> bookings,
    String? ignoreBookingId,
  }) {
    return rooms
        .where(
          (room) => isRoomAvailable(
            room: room,
            checkIn: checkIn,
            checkOut: checkOut,
            bookings: bookings,
            ignoreBookingId: ignoreBookingId,
          ),
        )
        .toList(growable: false);
  }
}