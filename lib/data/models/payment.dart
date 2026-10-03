import 'package:flutter/foundation.dart';

import '../../core/utils/map_utils.dart';
import 'payment_mode.dart';

/// A single payment received against a booking. Payments are separate records
/// so history is fully auditable.
@immutable
class Payment {
  const Payment({
    required this.id,
    required this.propertyId,
    required this.bookingId,
    this.guestId = '',
    required this.amount,
    required this.paymentMode,
    this.reference = '',
    this.notes = '',
    required this.paymentDate,
    this.createdAt,
    this.createdBy = '',
  });

  final String id;
  final String propertyId;
  final String bookingId;
  final String guestId;
  final double amount;
  final PaymentMode paymentMode;
  final String reference;
  final String notes;
  final DateTime paymentDate;
  final DateTime? createdAt;
  final String createdBy;

  Payment copyWith({
    String? id,
    String? propertyId,
    String? bookingId,
    String? guestId,
    double? amount,
    PaymentMode? paymentMode,
    String? reference,
    String? notes,
    DateTime? paymentDate,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Payment(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      bookingId: bookingId ?? this.bookingId,
      guestId: guestId ?? this.guestId,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      paymentDate: paymentDate ?? this.paymentDate,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  factory Payment.fromMap(String id, Map<String, dynamic> map) {
    return Payment(
      id: id,
      propertyId: MapUtils.asString(map['propertyId']),
      bookingId: MapUtils.asString(map['bookingId']),
      guestId: MapUtils.asString(map['guestId']),
      amount: MapUtils.asDouble(map['amount']),
      paymentMode: PaymentMode.fromWire(map['paymentMode']),
      reference: MapUtils.asString(map['reference']),
      notes: MapUtils.asString(map['notes']),
      paymentDate: MapUtils.asDateTime(map['paymentDate']) ?? DateTime.now(),
      createdAt: MapUtils.asDateTime(map['createdAt']),
      createdBy: MapUtils.asString(map['createdBy']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'propertyId': propertyId,
      'bookingId': bookingId,
      'guestId': guestId,
      'amount': amount,
      'paymentMode': paymentMode.wireValue,
      'reference': reference,
      'notes': notes,
      'paymentDate': paymentDate,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }

  @override
  bool operator ==(Object other) => other is Payment && other.id == id;

  @override
  int get hashCode => id.hashCode;
}