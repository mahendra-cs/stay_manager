import '../models/app_settings.dart';
import '../models/property.dart';
import '../models/room.dart';

/// Read/write access to configuration data (property, rooms, settings).
///
/// The UI depends on this abstraction only. Phase 2 ships an in-memory
/// implementation; Phase 11 adds a Firestore-backed implementation without
/// changing any screen.
abstract class ConfigRepository {
  Future<Property> loadProperty();

  Future<void> saveProperty(Property property);

  Future<List<Room>> loadRooms();

  Future<void> saveRoom(Room room);

  Future<void> deleteRoom(String roomId);

  Future<AppSettings> loadSettings();

  Future<void> saveSettings(AppSettings settings);
}