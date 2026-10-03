import 'package:flutter/foundation.dart';

import '../../core/utils/app_date.dart';
import '../../core/utils/map_utils.dart';

/// Opening-cash record for a single calendar day.
///
/// Closing figures (cash in/out, expected, actual, variance) are derived at
/// report time from payments and expenses so historical data is never mutated.
@immutable
class CashSession {
  const CashSession({
    required this.id,
    required this.propertyId,
    required this.date,
    this.openingCash = 0,
    this.countedCash,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String propertyId;
  final DateTime date;
  final double openingCash;

  /// Physically counted cash at end of day (null until counted).
  final double? countedCash;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get dayKey => _key(date);

  static String _key(DateTime date) => AppDate.format(date);

  CashSession copyWith({
    String? id,
    String? propertyId,
    DateTime? date,
    double? openingCash,
    double? countedCash,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CashSession(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      date: date ?? this.date,
      openingCash: openingCash ?? this.openingCash,
      countedCash: countedCash ?? this.countedCash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CashSession.fromMap(String id, Map<String, dynamic> map) {
    return CashSession(
      id: id,
      propertyId: MapUtils.asString(map['propertyId']),
      date: MapUtils.asDateTime(map['date']) ?? DateTime.now(),
      openingCash: MapUtils.asDouble(map['openingCash']),
      countedCash: map['countedCash'] == null
          ? null
          : MapUtils.asDouble(map['countedCash']),
      createdAt: MapUtils.asDateTime(map['createdAt']),
      updatedAt: MapUtils.asDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'propertyId': propertyId,
      'date': date,
      'openingCash': openingCash,
      'countedCash': countedCash,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  bool operator ==(Object other) => other is CashSession && other.id == id;

  @override
  int get hashCode => id.hashCode;
}