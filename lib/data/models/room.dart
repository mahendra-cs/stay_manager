import 'package:flutter/foundation.dart';

import '../../core/utils/map_utils.dart';
import 'room_status.dart';

/// A single rentable room belonging to a property.
///
/// Room numbers, types and prices are data — never assumed in widgets.
@immutable
class Room {
  const Room({
    required this.id,
    required this.propertyId,
    required this.roomNumber,
    this.name = '',
    this.type = '',
    this.floor = 1,
    this.maxOccupancy = 2,
    this.basePrice = 0,
    this.status = RoomStatus.available,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String propertyId;

  /// Identifier shown on the door / in the app (for example `1`, `A`, `G-2`).
  final String roomNumber;
  final String name;

  /// Room type name, configurable via `AppSettings.roomTypes`.
  final String type;
  final int floor;
  final int maxOccupancy;

  /// Default nightly price in the property's configured currency.
  final double basePrice;
  final RoomStatus status;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Falls back to the room number when no friendly name was set.
  String get displayName => name.trim().isEmpty ? roomNumber : name;

  bool get isOccupied =>
      status == RoomStatus.checkedIn || status == RoomStatus.booked;

  bool get isSellable => active && status == RoomStatus.available;

  Room copyWith({
    String? id,
    String? propertyId,
    String? roomNumber,
    String? name,
    String? type,
    int? floor,
    int? maxOccupancy,
    double? basePrice,
    RoomStatus? status,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Room(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      roomNumber: roomNumber ?? this.roomNumber,
      name: name ?? this.name,
      type: type ?? this.type,
      floor: floor ?? this.floor,
      maxOccupancy: maxOccupancy ?? this.maxOccupancy,
      basePrice: basePrice ?? this.basePrice,
      status: status ?? this.status,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Room.fromMap(String id, Map<String, dynamic> map) {
    return Room(
      id: id,
      propertyId: MapUtils.asString(map['propertyId']),
      roomNumber: MapUtils.asString(map['roomNumber']),
      name: MapUtils.asString(map['name']),
      type: MapUtils.asString(map['type']),
      floor: MapUtils.asInt(map['floor'], 1),
      maxOccupancy: MapUtils.asInt(map['maxOccupancy'], 2),
      basePrice: MapUtils.asDouble(map['basePrice']),
      status: RoomStatus.fromWire(map['status']),
      active: MapUtils.asBool(map['active'], true),
      createdAt: MapUtils.asDateTime(map['createdAt']),
      updatedAt: MapUtils.asDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'propertyId': propertyId,
      'roomNumber': roomNumber,
      'name': name,
      'type': type,
      'floor': floor,
      'maxOccupancy': maxOccupancy,
      'basePrice': basePrice,
      'status': status.wireValue,
      'active': active,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is Room &&
      other.id == id &&
      other.propertyId == propertyId &&
      other.roomNumber == roomNumber &&
      other.name == name &&
      other.type == type &&
      other.floor == floor &&
      other.maxOccupancy == maxOccupancy &&
      other.basePrice == basePrice &&
      other.status == status &&
      other.active == active;

  @override
  int get hashCode => Object.hash(
    id,
    propertyId,
    roomNumber,
    name,
    type,
    floor,
    maxOccupancy,
    basePrice,
    status,
    active,
  );
}