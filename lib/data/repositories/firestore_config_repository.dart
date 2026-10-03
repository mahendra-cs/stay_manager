import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/property_seed.dart';
import '../models/app_settings.dart';
import '../models/property.dart';
import '../models/room.dart';
import 'config_repository.dart';

/// Firestore-backed implementation of [ConfigRepository] (spec §11 Phase 11).
///
/// Documents use the collection layout from the specification:
/// `properties/{propertyId}`, `rooms/{roomId}`, `settings/{settingId}`.
/// Every write carries the audit fields required by spec §9.
///
/// Server timestamps are used so both devices agree on ordering without
/// depending on either phone's clock.
class FirestoreConfigRepository implements ConfigRepository {
  FirestoreConfigRepository({
    required FirebaseFirestore firestore,
    required String propertyId,
  }) :
        // Named parameters cannot be private, so the fields are assigned here.
        // ignore: prefer_initializing_formals
        _db = firestore,
        // ignore: prefer_initializing_formals
        _propertyId = propertyId;

  final FirebaseFirestore _db;
  final String _propertyId;

  CollectionReference<Map<String, dynamic>> get _properties =>
      _db.collection('properties');
  CollectionReference<Map<String, dynamic>> get _rooms =>
      _db.collection('rooms');
  CollectionReference<Map<String, dynamic>> get _settings =>
      _db.collection('settings');

  @override
  Future<Property> loadProperty() async {
    final doc = await _properties.doc(_propertyId).get();
    final data = doc.data();
    if (data == null) {
      // First run: provision from the seed so the admin has a starting point.
      final seeded = PropertySeed.property();
      await saveProperty(seeded);
      return seeded;
    }
    return Property.fromMap(doc.id, data);
  }

  @override
  Future<void> saveProperty(Property property) async {
    await _properties.doc(property.id).set(
      {
        ...property.toMap(),
        'createdAt': property.createdAt ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<List<Room>> loadRooms() async {
    final snapshot = await _rooms
        .where('propertyId', isEqualTo: _propertyId)
        .get();
    return snapshot.docs
        .map((doc) => Room.fromMap(doc.id, doc.data()))
        .toList(growable: false);
  }

  @override
  Future<void> saveRoom(Room room) async {
    await _rooms.doc(room.id).set(
      {
        ...room.toMap(),
        'createdAt': room.createdAt ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    await _rooms.doc(roomId).delete();
  }

  @override
  Future<AppSettings> loadSettings() async {
    final doc = await _settings.doc(_propertyId).get();
    final data = doc.data();
    if (data == null) {
      final seeded = PropertySeed.settings();
      await saveSettings(seeded);
      return seeded;
    }
    return AppSettings.fromMap(doc.id, data);
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _settings.doc(settings.id).set(
      {
        ...settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}