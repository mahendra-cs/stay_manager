import 'package:flutter_test/flutter_test.dart';

import 'package:stay_manager/core/errors/validation_exception.dart';
import 'package:stay_manager/core/utils/booking_builder.dart';
import 'package:stay_manager/core/utils/booking_calculator.dart';
import 'package:stay_manager/core/utils/availability_service.dart';
import 'package:stay_manager/core/utils/payment_calculator.dart';
import 'package:stay_manager/data/models/app_settings.dart';
import 'package:stay_manager/data/models/booking.dart';
import 'package:stay_manager/data/models/booking_status.dart';
import 'package:stay_manager/data/models/payment.dart';
import 'package:stay_manager/data/models/payment_mode.dart';
import 'package:stay_manager/data/models/payment_status.dart';
import 'package:stay_manager/data/models/property.dart';
import 'package:stay_manager/data/models/room.dart';
import 'package:stay_manager/data/models/room_status.dart';

Booking _booking({
  String id = 'b1',
  String roomId = 'r1',
  DateTime? checkIn,
  DateTime? checkOut,
  BookingStatus status = BookingStatus.booked,
  double total = 3000,
  double discount = 0,
}) {
  final start = checkIn ?? DateTime(2026, 3, 1);
  final end = checkOut ?? DateTime(2026, 3, 3);
  return Booking(
    id: id,
    propertyId: 'p1',
    guestId: 'g1',
    roomId: roomId,
    guestName: 'Guest',
    checkInDate: start,
    checkOutDate: end,
    pricePerNight: 1500,
    numberOfNights: end.difference(start).inDays,
    subtotal: end.difference(start).inDays * 1500,
    discount: discount,
    total: total,
    bookingStatus: status,
  );
}

void main() {
  group('BookingCalculator', () {
    test('single night', () {
      final quote = BookingCalculator.quote(
        checkIn: DateTime(2026, 3, 1),
        checkOut: DateTime(2026, 3, 2),
        pricePerNight: 1000,
      );
      expect(quote.nights, 1);
      expect(quote.subtotal, 1000);
      expect(quote.total, 1000);
    });

    test('multiple nights', () {
      final quote = BookingCalculator.quote(
        checkIn: DateTime(2026, 3, 1),
        checkOut: DateTime(2026, 3, 4),
        pricePerNight: 1000,
      );
      expect(quote.nights, 3);
      expect(quote.subtotal, 3000);
    });

    test('discount reduces the taxable amount', () {
      final quote = BookingCalculator.quote(
        checkIn: DateTime(2026, 3, 1),
        checkOut: DateTime(2026, 3, 3),
        pricePerNight: 1000,
        discount: 500,
      );
      expect(quote.taxableAmount, 1500);
      expect(quote.total, 1500);
    });

    test('tax is applied only when enabled', () {
      final withTax = BookingCalculator.quote(
        checkIn: DateTime(2026, 3, 1),
        checkOut: DateTime(2026, 3, 3),
        pricePerNight: 1000,
        taxEnabled: true,
        taxPercentage: 10,
      );
      expect(withTax.tax, 200);
      expect(withTax.total, 2200);

      final withoutTax = BookingCalculator.quote(
        checkIn: DateTime(2026, 3, 1),
        checkOut: DateTime(2026, 3, 3),
        pricePerNight: 1000,
        taxEnabled: false,
        taxPercentage: 10,
      );
      expect(withoutTax.tax, 0);
      expect(withoutTax.total, 2000);
    });

    test('rejects zero or negative nights', () {
      expect(
        () => BookingCalculator.quote(
          checkIn: DateTime(2026, 3, 1),
          checkOut: DateTime(2026, 3, 1),
          pricePerNight: 1000,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects a negative discount and a discount above the subtotal', () {
      expect(
        () => BookingCalculator.quote(
          checkIn: DateTime(2026, 3, 1),
          checkOut: DateTime(2026, 3, 2),
          pricePerNight: 1000,
          discount: -5,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => BookingCalculator.quote(
          checkIn: DateTime(2026, 3, 1),
          checkOut: DateTime(2026, 3, 2),
          pricePerNight: 1000,
          discount: 5000,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('PaymentCalculator', () {
    Payment payment(String id, double amount) => Payment(
      id: id,
      propertyId: 'p1',
      bookingId: 'b1',
      amount: amount,
      paymentMode: PaymentMode.cash,
      paymentDate: DateTime(2026, 3, 1),
    );

    test('no payment is unpaid', () {
      final summary = PaymentCalculator.summarize(
        total: 1000,
        payments: const <Payment>[],
      );
      expect(summary.paid, 0);
      expect(summary.outstanding, 1000);
      expect(summary.status, PaymentStatus.unpaid);
    });

    test('partial payment leaves a balance', () {
      final summary = PaymentCalculator.summarize(
        total: 1000,
        payments: [payment('p1', 400)],
      );
      expect(summary.status, PaymentStatus.partial);
      expect(summary.outstanding, 600);
    });

    test('multiple payments fully settle the booking', () {
      final summary = PaymentCalculator.summarize(
        total: 1000,
        payments: [payment('p1', 400), payment('p2', 600)],
      );
      expect(summary.status, PaymentStatus.paid);
      expect(summary.outstanding, 0);
    });

    test('rejects a payment above the outstanding amount', () {
      expect(
        PaymentCalculator.canAccept(
          total: 1000,
          alreadyPaid: 900,
          amount: 200,
        ),
        isFalse,
      );
      expect(
        PaymentCalculator.canAccept(
          total: 1000,
          alreadyPaid: 0,
          amount: 0,
        ),
        isFalse,
      );
      expect(
        PaymentCalculator.canAccept(
          total: 1000,
          alreadyPaid: 400,
          amount: 600,
        ),
        isTrue,
      );
    });
  });

  group('AvailabilityService', () {
    Room room({RoomStatus status = RoomStatus.available}) => Room(
      id: 'r1',
      propertyId: 'p1',
      roomNumber: '1',
      status: status,
    );

    test('a free room is available', () {
      expect(
        AvailabilityService.isRoomAvailable(
          room: room(),
          checkIn: DateTime(2026, 3, 1),
          checkOut: DateTime(2026, 3, 3),
          bookings: const <Booking>[],
        ),
        isTrue,
      );
    });

    test('a booked room is unavailable on overlapping dates', () {
      expect(
        AvailabilityService.isRoomAvailable(
          room: room(),
          checkIn: DateTime(2026, 3, 2),
          checkOut: DateTime(2026, 3, 4),
          bookings: [_booking()],
        ),
        isFalse,
      );
    });

    test('a booked room is available for a non-overlapping range', () {
      expect(
        AvailabilityService.isRoomAvailable(
          room: room(),
          checkIn: DateTime(2026, 3, 3),
          checkOut: DateTime(2026, 3, 5),
          bookings: [_booking()],
        ),
        isTrue,
      );
    });

    test('a blocked room is never available', () {
      expect(
        AvailabilityService.isRoomAvailable(
          room: room(status: RoomStatus.blocked),
          checkIn: DateTime(2026, 6, 1),
          checkOut: DateTime(2026, 6, 3),
          bookings: const <Booking>[],
        ),
        isFalse,
      );
    });

    test('a cancelled booking frees the room', () {
      expect(
        AvailabilityService.isRoomAvailable(
          room: room(),
          checkIn: DateTime(2026, 3, 1),
          checkOut: DateTime(2026, 3, 3),
          bookings: [_booking(status: BookingStatus.cancelled)],
        ),
        isTrue,
      );
    });
  });

  group('BookingBuilder', () {
    const property = Property(id: 'p1', name: 'Test', currency: 'INR');
    const settings = AppSettings(id: 's1', propertyId: 'p1');

    BookingDraft draft({
      double price = 1500,
      double discount = 0,
      int adults = 2,
    }) => BookingDraft(
      guestId: 'g1',
      guestName: 'Guest',
      guestPhone: '9999999999',
      roomId: 'r1',
      checkIn: DateTime(2026, 3, 1),
      checkOut: DateTime(2026, 3, 3),
      pricePerNight: price,
      propertyId: 'p1',
      adults: adults,
      discount: discount,
    );

    test('builds a fully priced booking', () {
      final built = BookingBuilder.build(
        draft: draft(),
        property: property,
        settings: settings,
      );
      expect(built.booking.numberOfNights, 2);
      expect(built.booking.subtotal, 3000);
      expect(built.booking.total, 3000);
      expect(built.booking.guestName, 'Guest');
    });

    test('rejects a booking without a guest or room', () {
      expect(
        () => BookingBuilder.build(
          draft: BookingDraft(
            guestId: '',
            guestName: 'Guest',
            guestPhone: '',
            roomId: 'r1',
            checkIn: DateTime(2026, 3, 1),
            checkOut: DateTime(2026, 3, 3),
            pricePerNight: 1500,
            propertyId: 'p1',
          ),
          property: property,
          settings: settings,
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => BookingBuilder.build(
          draft: BookingDraft(
            guestId: 'g1',
            guestName: 'Guest',
            guestPhone: '',
            roomId: '',
            checkIn: DateTime(2026, 3, 1),
            checkOut: DateTime(2026, 3, 3),
            pricePerNight: 1500,
            propertyId: 'p1',
          ),
          property: property,
          settings: settings,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('preview returns null for invalid input instead of throwing', () {
      expect(
        BookingBuilder.preview(
          checkIn: DateTime(2026, 3, 3),
          checkOut: DateTime(2026, 3, 1),
          pricePerNight: 1000,
        ),
        isNull,
      );
      expect(
        BookingBuilder.preview(
          checkIn: DateTime(2026, 3, 1),
          checkOut: DateTime(2026, 3, 3),
          pricePerNight: 1000,
        ),
        isNotNull,
      );
    });
  });
}
