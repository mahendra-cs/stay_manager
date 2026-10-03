import 'package:flutter/foundation.dart';

import '../../core/utils/map_utils.dart';

/// What a user is allowed to do. Enforcement happens in Firestore security
/// rules (Phase 11); the UI only uses this to hide admin-only affordances.
enum UserRole {
  admin('ADMIN', 'Admin'),
  staff('STAFF', 'Staff');

  const UserRole(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static UserRole fromWire(Object? value) {
    if (value is String) {
      for (final role in values) {
        if (role.wireValue == value) return role;
      }
    }
    return UserRole.staff;
  }
}

/// An application user, stored in `users/{userId}` per the specification.
@immutable
class AppUser {
  const AppUser({
    required this.id,
    this.displayName = '',
    this.email = '',
    this.role = UserRole.staff,
    required this.propertyId,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String displayName;
  final String email;
  final UserRole role;

  /// The single property this user is assigned to (property isolation).
  final String propertyId;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role == UserRole.admin;

  String get displayLabel => displayName.trim().isEmpty ? email : displayName;

  AppUser copyWith({
    String? id,
    String? displayName,
    String? email,
    UserRole? role,
    String? propertyId,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      propertyId: propertyId ?? this.propertyId,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      displayName: MapUtils.asString(map['displayName']),
      email: MapUtils.asString(map['email']),
      role: UserRole.fromWire(map['role']),
      propertyId: MapUtils.asString(map['propertyId']),
      active: MapUtils.asBool(map['active'], true),
      createdAt: MapUtils.asDateTime(map['createdAt']),
      updatedAt: MapUtils.asDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'displayName': displayName,
      'email': email,
      'role': role.wireValue,
      'propertyId': propertyId,
      'active': active,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.displayName == displayName &&
      other.email == email &&
      other.role == role &&
      other.propertyId == propertyId &&
      other.active == active;

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    email,
    role,
    propertyId,
    active,
  );
}