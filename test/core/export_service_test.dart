import 'package:flutter_test/flutter_test.dart';

import 'package:stay_manager/core/services/export_service.dart';
import 'package:stay_manager/data/models/booking.dart';
import 'package:stay_manager/data/models/guest.dart';
import 'package:stay_manager/data/models/payment.dart';
import 'package:stay_manager/data/models/payment_mode.dart';
import 'package:stay_manager/data/repositories/in_memory_operations_repository.dart';
import 'package:stay_manager/data/repositories/local_file_operations_repository.dart';

Booking _booking({String guest = 'Ann, A', String notes = ''}) => Booking(
  id: 'b1',
  propertyId: 'p1',
  guestId: 'g1',
  roomId: 'room-1',
  guestName: guest,
  checkInDate: DateTime(2026, 3, 1),
  checkOutDate: DateTime(2026, 3, 3),
  pricePerNight: 1500,
  numberOfNights: 2,
  subtotal: 3000,
  total: 3000,
  notes: notes,
);

void main() {
  group('ExportService CSV', () {
    test('writes a header row for bookings', () {
      final csv = ExportService.bookingsToCsv([_booking()]);
      expect(csv.split('\n').first, startsWith('Booking ID,Guest,Phone,Room'));
    });

    test('quotes values that contain a comma', () {
      final csv = ExportService.bookingsToCsv([_booking(guest: 'Ann, A')]);
      expect(csv, contains('"Ann, A"'));
    });

    test('escapes embedded double quotes', () {
      final csv = ExportService.bookingsToCsv([
        _booking(guest: 'Ann "The Boss"'),
      ]);
      expect(csv, contains('"Ann ""The Boss"""'));
    });

    test('handles newlines inside a field', () {
      final csv = ExportService.bookingsToCsv([_booking(notes: 'line1\nline2')]);
      expect(csv, contains('"line1\nline2"'));
    });

    test('produces one row per booking', () {
      final csv = ExportService.bookingsToCsv([
        _booking(),
        _booking(),
      ]);
      final lines = csv.trim().split('\n');
      expect(lines.length, 3); // header + 2
    });

    test('payments and guests get their own headers', () {
      expect(
        ExportService.paymentsToCsv(const <Payment>[]),
        startsWith('Payment ID,Booking ID,Amount'),
      );
      expect(
        ExportService.guestsToCsv(const <Guest>[]),
        startsWith('Guest ID,Name,Phone'),
      );
    });
  });

  group('ExportService JSON', () {
    test('includes counts and the property name', () {
      final json = ExportService.toJson(
        bookings: [_booking()],
        payments: const <Payment>[],
        guests: const <Guest>[],
        propertyName: 'Veda',
      );

      expect(json, contains('"formatVersion": 1'));
      expect(json, contains('"property": "Veda"'));
      expect(json, contains('"bookings": 1'));
    });
  });

  group('LocalFileOperationsRepository', () {
    test('stores and reloads bookings', () async {
      final repository = LocalFileOperationsRepository(
        fileName: 'test_persistence.json',
      );

      await repository.saveBooking(_booking());
      final reloaded = await repository.loadBookings();

      expect(reloaded.length, 1);
      expect(reloaded.first.guestName, 'Ann, A');
      expect(reloaded.first.numberOfNights, 2);
    });

    test('an update replaces the existing record rather than duplicating', () async {
      final repository = LocalFileOperationsRepository(
        fileName: 'test_update.json',
      );

      await repository.saveBooking(_booking());
      await repository.saveBooking(_booking(notes: 'changed'));

      final reloaded = await repository.loadBookings();
      expect(reloaded.length, 1);
      expect(reloaded.first.notes, 'changed');
    });

    test('deleting removes the record', () async {
      final repository = LocalFileOperationsRepository(
        fileName: 'test_delete.json',
      );

      await repository.saveBooking(_booking());
      await repository.deleteBooking('b1');

      expect(await repository.loadBookings(), isEmpty);
    });

    test('payments and guests persist independently', () async {
      final repository = LocalFileOperationsRepository(
        fileName: 'test_mixed.json',
      );

      await repository.saveGuest(const Guest(id: 'g1', propertyId: 'p1', name: 'Ann'));
      await repository.savePayment(
        Payment(
          id: 'pay1',
          propertyId: 'p1',
          bookingId: 'b1',
          amount: 500,
          paymentMode: PaymentMode.cash,
          paymentDate: DateTime(2026, 3, 1),
        ),
      );

      expect((await repository.loadGuests()).single.name, 'Ann');
      expect((await repository.loadPayments()).single.amount, 500);
      expect(await repository.loadBookings(), isEmpty);
    });
  });

  group('InMemoryOperationsRepository still behaves the same', () {
    test('saves and reloads a booking', () async {
      final repository = InMemoryOperationsRepository();
      await repository.saveBooking(_booking());
      expect((await repository.loadBookings()).length, 1);
    });
  });
}
