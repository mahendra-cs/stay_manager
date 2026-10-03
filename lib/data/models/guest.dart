import 'package:flutter/foundation.dart';

import '../../core/utils/map_utils.dart';

/// A person who stays at the property. Guests are shared across bookings so
/// history is preserved without duplicating data.
@immutable
class Guest {
  const Guest({
    required this.id,
    required this.propertyId,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.idType = '',
    this.idNumber = '',
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String propertyId;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String idType;
  final String idNumber;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) || phone.toLowerCase().contains(q);
  }

  Guest copyWith({
    String? id,
    String? propertyId,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? idType,
    String? idNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Guest(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Guest.fromMap(String id, Map<String, dynamic> map) {
    return Guest(
      id: id,
      propertyId: MapUtils.asString(map['propertyId']),
      name: MapUtils.asString(map['name']),
      phone: MapUtils.asString(map['phone']),
      email: MapUtils.asString(map['email']),
      address: MapUtils.asString(map['address']),
      idType: MapUtils.asString(map['idType']),
      idNumber: MapUtils.asString(map['idNumber']),
      notes: MapUtils.asString(map['notes']),
      createdAt: MapUtils.asDateTime(map['createdAt']),
      updatedAt: MapUtils.asDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'propertyId': propertyId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'idType': idType,
      'idNumber': idNumber,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  bool operator ==(Object other) => other is Guest && other.id == id;

  @override
  int get hashCode => id.hashCode;
}