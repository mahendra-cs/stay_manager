import '../models/room_status.dart';

/// Narrow seam that lets the operations layer move a room between states
/// (check-in, check-out, blocking) without importing the configuration
/// controller. `ConfigController` implements this; keeping it behind an
/// interface preserves the repository/service separation.
abstract class RoomStatusWriter {
  /// Applies [status] to the room with [roomId].
  Future<void> setRoomStatus(String roomId, RoomStatus status);
}