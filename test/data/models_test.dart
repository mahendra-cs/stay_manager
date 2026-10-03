import 'package:flutter_test/flutter_test.dart';

import 'package:stay_manager/data/models/app_settings.dart';
import 'package:stay_manager/data/models/booking_source.dart';
import 'package:stay_manager/data/models/payment_mode.dart';
import 'package:stay_manager/data/models/property.dart';
import 'package:stay_manager/data/models/room.dart';
import 'package:stay_manager/data/models/room_status.dart';

void main() {
  group('Property', () {
    test('round-trips through a map', () {
      const property = Property(
        id: 'p1',
        name: 'Test Property',
        currency: 'INR',
        taxEnabled: true,
        taxPercentage: 12,
      );

      final restored = Property.fromMap('p1', property.toMap());

      expect(restored.name, 'Test Property');
      expect(restored.currency, 'INR');
      expect(restored.taxEnabled, isTrue);
      expect(restored.taxPercentage, 12);
    });

    test('fromMap tolerates missing and invalid values', () {
      final property = Property.fromMap('p1', const <String, dynamic>{});

      expect(property.name, '');
      expect(property.active, isTrue);
      expect(property.taxPercentage, 0);
    });

    test('copyWith overrides only the provided fields', () {
      const property = Property(id: 'p1', name: 'A', currency: 'INR');
      final updated = property.copyWith(name: 'B');

      expect(updated.name, 'B');
      expect(updated.currency, 'INR');
      expect(updated.id, 'p1');
    });
  });

  group('Room', () {
    test('displayName falls back to the room number', () {
      const room = Room(id: 'r1', propertyId: 'p1', roomNumber: '7');
      expect(room.displayName, '7');
    });

    test('isOccupied reflects the status', () {
      const booked = Room(
        id: 'r1',
        propertyId: 'p1',
        roomNumber: '1',
        status: RoomStatus.booked,
      );
      const available = Room(id: 'r2', propertyId: 'p1', roomNumber: '2');

      expect(booked.isOccupied, isTrue);
      expect(available.isOccupied, isFalse);
    });

    test('round-trips status and price through a map', () {
      const room = Room(
        id: 'r1',
        propertyId: 'p1',
        roomNumber: '1',
        status: RoomStatus.cleaning,
        basePrice: 1500,
      );

      final restored = Room.fromMap('r1', room.toMap());

      expect(restored.status, RoomStatus.cleaning);
      expect(restored.basePrice, 1500);
    });
  });

  group('AppSettings', () {
    test('round-trips enum lists through a map', () {
      const settings = AppSettings(
        id: 's1',
        propertyId: 'p1',
        roomTypes: <String>['Standard'],
        paymentModes: <PaymentMode>[PaymentMode.cash, PaymentMode.upi],
        bookingSources: <BookingSource>[BookingSource.walkIn],
      );

      final restored = AppSettings.fromMap('s1', settings.toMap());

      expect(restored.roomTypes, <String>['Standard']);
      expect(restored.paymentModes, <PaymentMode>[
        PaymentMode.cash,
        PaymentMode.upi,
      ]);
      expect(restored.bookingSources, <BookingSource>[BookingSource.walkIn]);
    });
  });

  group('enums', () {
    test('fromWire maps known values and falls back safely', () {
      expect(RoomStatus.fromWire('CHECKED_IN'), RoomStatus.checkedIn);
      expect(RoomStatus.fromWire('nonsense'), RoomStatus.available);
      expect(PaymentMode.fromWire('UPI'), PaymentMode.upi);
      expect(PaymentMode.fromWire(42), PaymentMode.other);
      expect(BookingSource.fromWire('AGODA'), BookingSource.agoda);
    });
  });
}