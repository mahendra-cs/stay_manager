import 'package:flutter/foundation.dart';

import '../../core/utils/map_utils.dart';

/// Configuration describing a single property.
///
/// No widget hard-codes property details: this object is supplied by
/// configuration data (a seed today, Firestore from Phase 11) and read through
/// `ConfigScope`.
@immutable
class Property {
  const Property({
    required this.id,
    required this.name,
    this.address = '',
    this.phone = '',
    this.email = '',
    this.currency = '',
    this.timezone = '',
    this.taxEnabled = false,
    this.taxPercentage = 0,
    this.checkInTime = '',
    this.checkOutTime = '',
    this.logoUrl,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;

  /// ISO 4217 code (for example `INR`). Never assume a currency symbol.
  final String currency;

  /// IANA timezone identifier (for example `Asia/Kolkata`).
  final String timezone;
  final bool taxEnabled;

  /// Tax rate as a percentage (0–100).
  final double taxPercentage;

  /// Local time strings in 24-hour `HH:mm` format.
  final String checkInTime;
  final String checkOutTime;
  final String? logoUrl;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasLogo => (logoUrl ?? '').trim().isNotEmpty;
  bool get hasAddress => address.trim().isNotEmpty;

  Property copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? currency,
    String? timezone,
    bool? taxEnabled,
    double? taxPercentage,
    String? checkInTime,
    String? checkOutTime,
    String? logoUrl,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Property(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
      taxEnabled: taxEnabled ?? this.taxEnabled,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      logoUrl: logoUrl ?? this.logoUrl,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Property.fromMap(String id, Map<String, dynamic> map) {
    return Property(
      id: id,
      name: MapUtils.asString(map['name']),
      address: MapUtils.asString(map['address']),
      phone: MapUtils.asString(map['phone']),
      email: MapUtils.asString(map['email']),
      currency: MapUtils.asString(map['currency']),
      timezone: MapUtils.asString(map['timezone']),
      taxEnabled: MapUtils.asBool(map['taxEnabled']),
      taxPercentage: MapUtils.asDouble(map['taxPercentage']),
      checkInTime: MapUtils.asString(map['checkInTime']),
      checkOutTime: MapUtils.asString(map['checkOutTime']),
      logoUrl: map['logoUrl'] is String ? map['logoUrl'] as String : null,
      active: MapUtils.asBool(map['active'], true),
      createdAt: MapUtils.asDateTime(map['createdAt']),
      updatedAt: MapUtils.asDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'currency': currency,
      'timezone': timezone,
      'taxEnabled': taxEnabled,
      'taxPercentage': taxPercentage,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'logoUrl': logoUrl,
      'active': active,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is Property &&
      other.id == id &&
      other.name == name &&
      other.address == address &&
      other.phone == phone &&
      other.email == email &&
      other.currency == currency &&
      other.timezone == timezone &&
      other.taxEnabled == taxEnabled &&
      other.taxPercentage == taxPercentage &&
      other.checkInTime == checkInTime &&
      other.checkOutTime == checkOutTime &&
      other.logoUrl == logoUrl &&
      other.active == active;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    address,
    phone,
    email,
    currency,
    timezone,
    taxEnabled,
    taxPercentage,
    checkInTime,
    checkOutTime,
    logoUrl,
    active,
  );
}