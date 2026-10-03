import 'package:flutter/foundation.dart';

import '../../core/utils/app_date.dart';
import '../../core/utils/map_utils.dart';
import 'booking_source.dart';
import 'booking_status.dart';
import 'payment_status.dart';

/// A stay for a guest in a room.
///
/// Monetary fields are derived by `BookingCalculator` and stored on the record
/// (mirroring the Firestore shape); [outstandingAmount] and [paymentStatus] are
/// refreshed whenever payments change.
@immutable
class Booking {
  const Booking({
    required this.id,
    required this.propertyId,
    required this.guestId,
    required this.roomId,
    required this.guestName,
    this.guestPhone = '',
    this.adults = 1,
    this.children = 0,
    required this.checkInDate,
    required this.checkOutDate,
    required this.pricePerNight,
    required this.numberOfNights,
    required this.subtotal,
    this.discount = 0,
    this.tax = 0,
    required this.total,
    this.outstandingAmount = 0,
    this.paymentStatus = PaymentStatus.unpaid,
    this.bookingStatus = BookingStatus.booked,
    this.source = BookingSource.walkIn,
    this.notes = '',
    this.checkInAt,
    this.checkOutAt,
    this.checkedInBy = '',
    this.checkedOutBy = '',
    this.createdAt,
    this.updatedAt,
    this.createdBy = '',
    this.updatedBy = '',
  });

  final String id;
  final String propertyId;
  final String guestId;
  final String roomId;
  final String guestName;
  final String guestPhone;
  final int adults;
  final int children;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final double pricePerNight;
  final int numberOfNights;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final double outstandingAmount;
  final PaymentStatus paymentStatus;
  final BookingStatus bookingStatus;
  final BookingSource source;
  final String notes;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;

  /// Audit: who performed the check-in / check-out.
  final String checkedInBy;
  final String checkedOutBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final String updatedBy;

  int get guestCount => adults + children;

  bool isOverlapping(DateTime start, DateTime end) {
    final checkIn = AppDate.dateOnly(checkInDate);
    final checkOut = AppDate.dateOnly(checkOutDate);
    return checkIn.isBefore(end) && start.isBefore(checkOut);
  }

  Booking copyWith({
    String? id,
    String? propertyId,
    String? guestId,
    String? roomId,
    String? guestName,
    String? guestPhone,
    int? adults,
    int? children,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    double? pricePerNight,
    int? numberOfNights,
    double? subtotal,
    double? discount,
    double? tax,
    double? total,
    double? outstandingAmount,
    PaymentStatus? paymentStatus,
    BookingStatus? bookingStatus,
    BookingSource? source,
    String? notes,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    String? checkedInBy,
    String? checkedOutBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return Booking(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      guestId: guestId ?? this.guestId,
      roomId: roomId ?? this.roomId,
      guestName: guestName ?? this.guestName,
      guestPhone: guestPhone ?? this.guestPhone,
      adults: adults ?? this.adults,
      children: children ?? this.children,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      numberOfNights: numberOfNights ?? this.numberOfNights,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      checkInAt: checkInAt ?? this.checkInAt,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      checkedInBy: checkedInBy ?? this.checkedInBy,
      checkedOutBy: checkedOutBy ?? this.checkedOutBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    return Booking(
      id: id,
      propertyId: MapUtils.asString(map['propertyId']),
      guestId: MapUtils.asString(map['guestId']),
      roomId: MapUtils.asString(map['roomId']),
      guestName: MapUtils.asString(map['guestName']),
      guestPhone: MapUtils.asString(map['guestPhone']),
      adults: MapUtils.asInt(map['adults'], 1),
      children: MapUtils.asInt(map['children']),
      checkInDate: MapUtils.asDateTime(map['checkInDate']) ?? DateTime.now(),
      checkOutDate: MapUtils.asDateTime(map['checkOutDate']) ?? DateTime.now(),
      pricePerNight: MapUtils.asDouble(map['pricePerNight']),
      numberOfNights: MapUtils.asInt(map['numberOfNights']),
      subtotal: MapUtils.asDouble(map['subtotal']),
      discount: MapUtils.asDouble(map['discount']),
      tax: MapUtils.asDouble(map['tax']),
      total: MapUtils.asDouble(map['total']),
      outstandingAmount: MapUtils.asDouble(map['outstandingAmount']),
      paymentStatus: PaymentStatus.fromWire(map['paymentStatus']),
      bookingStatus: BookingStatus.fromWire(map['bookingStatus']),
      source: BookingSource.fromWire(map['source']),
      notes: MapUtils.asString(map['notes']),
      checkInAt: MapUtils.asDateTime(map['checkInAt']),
      checkOutAt: MapUtils.asDateTime(map['checkOutAt']),
      checkedInBy: MapUtils.asString(map['checkedInBy']),
      checkedOutBy: MapUtils.asString(map['checkedOutBy']),
      createdAt: MapUtils.asDateTime(map['createdAt']),
      updatedAt: MapUtils.asDateTime(map['updatedAt']),
      createdBy: MapUtils.asString(map['createdBy']),
      updatedBy: MapUtils.asString(map['updatedBy']),
    );
  }

  /// JSON-encodable view of this booking.
  ///
  /// [toMap] deliberately keeps raw `DateTime`s (Firestore stores them as
  /// timestamps), so anything written to a JSON file or exported must convert
  /// them to ISO-8601 strings first.
  Map<String, dynamic> toJsonMap() {
    final map = toMap();
    for (final key in const <String>[
      'checkInDate',
      'checkOutDate',
      'checkInAt',
      'checkOutAt',
      'createdAt',
      'updatedAt',
    ]) {
      final value = map[key];
      if (value is DateTime) map[key] = value.toIso8601String();
    }
    return map;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'propertyId': propertyId,
      'guestId': guestId,
      'roomId': roomId,
      'guestName': guestName,
      'guestPhone': guestPhone,
      'adults': adults,
      'children': children,
      'checkInDate': checkInDate,
      'checkOutDate': checkOutDate,
      'pricePerNight': pricePerNight,
      'numberOfNights': numberOfNights,
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'outstandingAmount': outstandingAmount,
      'paymentStatus': paymentStatus.wireValue,
      'bookingStatus': bookingStatus.wireValue,
      'source': source.wireValue,
      'notes': notes,
      'checkInAt': checkInAt,
      'checkOutAt': checkOutAt,
      'checkedInBy': checkedInBy,
      'checkedOutBy': checkedOutBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  @override
  bool operator ==(Object other) => other is Booking && other.id == id;

  @override
  int get hashCode => id.hashCode;
}