import 'package:flutter/foundation.dart';

import '../../core/utils/map_utils.dart';
import 'booking_source.dart';
import 'payment_mode.dart';
import 'room_status.dart';

/// Property-level configuration lists and application settings.
///
/// These collections make the app generic: room types, payment methods and
/// booking sources are all configurable rather than hard-coded. Operational
/// policy (for example whether a guest may leave with an outstanding balance)
/// lives here too, so behaviour is never baked into widgets.
@immutable
class AppSettings {
  const AppSettings({
    required this.id,
    required this.propertyId,
    this.roomTypes = const <String>[],
    this.paymentModes = const <PaymentMode>[],
    this.bookingSources = const <BookingSource>[],
    this.expenseCategories = const <String>[],
    this.checkoutRequiresSettlement = false,
    this.roomStatusAfterCheckout = RoomStatus.cleaning,
  });

  final String id;
  final String propertyId;

  /// Configurable room type names shown when creating/editing rooms.
  final List<String> roomTypes;
  final List<PaymentMode> paymentModes;
  final List<BookingSource> bookingSources;

  /// Configurable expense category labels (not a fixed enum).
  final List<String> expenseCategories;

  /// When `true`, check-out is blocked while the booking still has an
  /// outstanding amount. Properties differ, so this is configuration rather
  /// than a hard-coded rule.
  final bool checkoutRequiresSettlement;

  /// Room status applied automatically after a guest checks out.
  final RoomStatus roomStatusAfterCheckout;

  AppSettings copyWith({
    String? id,
    String? propertyId,
    List<String>? roomTypes,
    List<PaymentMode>? paymentModes,
    List<BookingSource>? bookingSources,
    List<String>? expenseCategories,
    bool? checkoutRequiresSettlement,
    RoomStatus? roomStatusAfterCheckout,
  }) {
    return AppSettings(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      roomTypes: roomTypes ?? this.roomTypes,
      paymentModes: paymentModes ?? this.paymentModes,
      bookingSources: bookingSources ?? this.bookingSources,
      expenseCategories: expenseCategories ?? this.expenseCategories,
      checkoutRequiresSettlement:
          checkoutRequiresSettlement ?? this.checkoutRequiresSettlement,
      roomStatusAfterCheckout:
          roomStatusAfterCheckout ?? this.roomStatusAfterCheckout,
    );
  }

  factory AppSettings.fromMap(String id, Map<String, dynamic> map) {
    return AppSettings(
      id: id,
      propertyId: MapUtils.asString(map['propertyId']),
      roomTypes: MapUtils.asStringList(map['roomTypes']),
      paymentModes: MapUtils.asStringList(
        map['paymentModes'],
      ).map(PaymentMode.fromWire).toList(growable: false),
      bookingSources: MapUtils.asStringList(
        map['bookingSources'],
      ).map(BookingSource.fromWire).toList(growable: false),
      expenseCategories: MapUtils.asStringList(map['expenseCategories']),
      checkoutRequiresSettlement: MapUtils.asBool(
        map['checkoutRequiresSettlement'],
      ),
      roomStatusAfterCheckout: RoomStatus.fromWire(
        map['roomStatusAfterCheckout'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'propertyId': propertyId,
      'roomTypes': roomTypes,
      'paymentModes': paymentModes.map((mode) => mode.wireValue).toList(),
      'bookingSources': bookingSources
          .map((source) => source.wireValue)
          .toList(),
      'expenseCategories': expenseCategories,
      'checkoutRequiresSettlement': checkoutRequiresSettlement,
      'roomStatusAfterCheckout': roomStatusAfterCheckout.wireValue,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.id == id &&
      other.propertyId == propertyId &&
      listEquals(other.roomTypes, roomTypes) &&
      listEquals(other.paymentModes, paymentModes) &&
      listEquals(other.bookingSources, bookingSources) &&
      listEquals(other.expenseCategories, expenseCategories) &&
      other.checkoutRequiresSettlement == checkoutRequiresSettlement &&
      other.roomStatusAfterCheckout == roomStatusAfterCheckout;

  @override
  int get hashCode => Object.hash(
    id,
    propertyId,
    Object.hashAll(roomTypes),
    Object.hashAll(paymentModes),
    Object.hashAll(bookingSources),
    Object.hashAll(expenseCategories),
    checkoutRequiresSettlement,
    roomStatusAfterCheckout,
  );
}