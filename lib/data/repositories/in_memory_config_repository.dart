import '../config/property_seed.dart';
import '../models/app_settings.dart';
import '../models/property.dart';
import '../models/room.dart';
import 'config_repository.dart';

/// Phase 2 in-memory implementation of [ConfigRepository].
///
/// Changes are kept for the lifetime of the running app only. This keeps the
/// application free of extra dependencies and backend code while still
/// exercising the full configuration flow. Phase 11 swaps this for a Firestore
/// repository behind the same [ConfigRepository] interface.
class InMemoryConfigRepository implements ConfigRepository {
  InMemoryConfigRepository({
    required Property property,
    required AppSettings settings,
    required List<Room> rooms,
  }) {
    _property = property;
    _settings = settings;
    for (final room in rooms) {
      _rooms[room.id] = room;
    }
  }

  /// Creates a repository pre-populated with [PropertySeed] data.
  factory InMemoryConfigRepository.seeded() {
    return InMemoryConfigRepository(
      property: PropertySeed.property(),
      settings: PropertySeed.settings(),
      rooms: PropertySeed.rooms(),
    );
  }

  late Property _property;
  late AppSettings _settings;
  final Map<String, Room> _rooms = <String, Room>{};

  @override
  Future<Property> loadProperty() async => _property;

  @override
  Future<void> saveProperty(Property property) async {
    _property = property;
  }

  @override
  Future<List<Room>> loadRooms() async =>
      _rooms.values.toList(growable: false);

  @override
  Future<void> saveRoom(Room room) async {
    _rooms[room.id] = room;
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    _rooms.remove(roomId);
  }

  @override
  Future<AppSettings> loadSettings() async => _settings;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
  }
}