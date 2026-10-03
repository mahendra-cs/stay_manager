import 'package:flutter/foundation.dart';

import '../../data/models/app_settings.dart';
import '../../data/models/property.dart';
import '../../data/models/room.dart';
import '../../data/models/room_status.dart';
import '../../data/repositories/config_repository.dart';
import '../../data/repositories/room_status_writer.dart';

/// Holds the application's configuration state and exposes it to the widget
/// tree. Deliberately small and Flutter-native (a plain [ChangeNotifier]) — no
/// third-party state-management dependency is introduced.
///
/// Also implements [RoomStatusWriter] so the operations layer can drive room
/// status transitions (check-in / check-out / block) without reaching into
/// configuration internals.
class ConfigController extends ChangeNotifier implements RoomStatusWriter {
  ConfigController(this._repository);

  final ConfigRepository _repository;

  bool _isLoading = true;
  Property? _property;
  AppSettings? _settings;
  List<Room> _rooms = const <Room>[];

  bool get isLoading => _isLoading;

  /// Configured property. Only valid once [isLoading] is `false`.
  Property get property => _property!;

  /// Configured settings. Only valid once [isLoading] is `false`.
  AppSettings get settings => _settings!;

  List<Room> get rooms => List<Room>.unmodifiable(_rooms);

  /// Count of active (sellable/usable) rooms.
  int get totalRooms => _rooms.where((room) => room.active).length;

  int get availableRooms => _rooms
      .where((room) => room.active && room.status == RoomStatus.available)
      .length;

  int get occupiedRooms =>
      _rooms.where((room) => room.active && room.isOccupied).length;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _property = await _repository.loadProperty();
    _settings = await _repository.loadSettings();
    _rooms = await _repository.loadRooms();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProperty(Property property) async {
    _property = property.copyWith(updatedAt: DateTime.now());
    await _repository.saveProperty(_property!);
    notifyListeners();
  }

  Future<void> upsertRoom(Room room) async {
    final saved = room.createdAt == null
        ? room.copyWith(createdAt: DateTime.now(), updatedAt: DateTime.now())
        : room.copyWith(updatedAt: DateTime.now());
    await _repository.saveRoom(saved);
    _rooms = await _repository.loadRooms();
    notifyListeners();
  }

  Future<void> deleteRoom(String roomId) async {
    await _repository.deleteRoom(roomId);
    _rooms = await _repository.loadRooms();
    notifyListeners();
  }

  @override
  Future<void> setRoomStatus(String roomId, RoomStatus status) async {
    final room = roomById(roomId);
    if (room == null || room.status == status) return;
    await upsertRoom(room.copyWith(status: status, updatedAt: DateTime.now()));
  }

  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    await _repository.saveSettings(settings);
    notifyListeners();
  }

  Room? roomById(String id) {
    for (final room in _rooms) {
      if (room.id == id) return room;
    }
    return null;
  }

  /// Generates a stable-enough identifier for a newly created room.
  String generateRoomId() => 'room-${DateTime.now().microsecondsSinceEpoch}';
}