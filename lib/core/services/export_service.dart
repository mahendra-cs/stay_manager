import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/booking.dart';
import '../../data/models/guest.dart';
import '../../data/models/payment.dart';

/// Builds a shareable snapshot of booking data and hands it to WhatsApp.
///
/// Design notes:
///  * All formatting is pure and separated into [toCsv] / [toJson] so it can be
///    unit tested without a device or a share sheet.
///  * The default format is CSV, because it is what an admin can open in
///    Excel or Google Sheets straight away.
///  * Sharing is a one-way export. It is deliberately *not* a sync mechanism:
///    nothing is read back from the file, so a staff member cannot overwrite
///    the admin's records by accident.
class ExportService {
  const ExportService._();

  static String _escape(Object? value) {
    final text = value?.toString() ?? '';
    if (text.contains(',') || text.contains('"') || text.contains('\n')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  static String _date(DateTime? value) =>
      value == null ? '' : value.toIso8601String();

  /// Flat, spreadsheet-friendly booking rows.
  static String bookingsToCsv(List<Booking> bookings) {
    final buffer = StringBuffer()
      ..writeln(
        'Booking ID,Guest,Phone,Room,Check In,Check Out,Nights,Subtotal,'
        'Discount,Tax,Total,Paid,Outstanding,Status,Payment Status,Source,Notes',
      );

    for (final booking in bookings) {
      buffer.writeln(
        [
          booking.id,
          booking.guestName,
          booking.guestPhone,
          booking.roomId,
          _date(booking.checkInDate),
          _date(booking.checkOutDate),
          booking.numberOfNights,
          booking.subtotal,
          booking.discount,
          booking.tax,
          booking.total,
          booking.outstandingAmount,
          booking.bookingStatus.wireValue,
          booking.paymentStatus.wireValue,
          booking.source.wireValue,
          booking.notes,
        ].map(_escape).join(','),
      );
    }
    return buffer.toString();
  }

  static String paymentsToCsv(List<Payment> payments) {
    final buffer = StringBuffer()
      ..writeln('Payment ID,Booking ID,Amount,Mode,Reference,Date,Notes');

    for (final payment in payments) {
      buffer.writeln(
        [
          payment.id,
          payment.bookingId,
          payment.amount,
          payment.paymentMode.wireValue,
          payment.reference,
          _date(payment.paymentDate),
          payment.notes,
        ].map(_escape).join(','),
      );
    }
    return buffer.toString();
  }

  static String guestsToCsv(List<Guest> guests) {
    final buffer = StringBuffer()
      ..writeln('Guest ID,Name,Phone,Email,Address,ID Type,ID Number,Notes');

    for (final guest in guests) {
      buffer.writeln(
        [
          guest.id,
          guest.name,
          guest.phone,
          guest.email,
          guest.address,
          guest.idType,
          guest.idNumber,
          guest.notes,
        ].map(_escape).join(','),
      );
    }
    return buffer.toString();
  }

  /// Machine-readable bundle the admin tool can import without retyping.
  static String toJson({
    required List<Booking> bookings,
    required List<Payment> payments,
    required List<Guest> guests,
    required String propertyName,
  }) {
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'formatVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'property': propertyName,
      'counts': <String, dynamic>{
        'bookings': bookings.length,
        'payments': payments.length,
        'guests': guests.length,
      },
      'bookings': [for (final b in bookings) b.toJsonMap()..['id'] = b.id],
      'payments': [for (final p in payments) p.toJsonMap()..['id'] = p.id],
      'guests': [for (final g in guests) g.toJsonMap()..['id'] = g.id],
    });
  }

  /// Writes the export to a temporary file and opens the system share sheet.
  ///
  /// Returns the file path so the UI can show it for confirmation.
  static Future<String> shareCsv({
    required List<Booking> bookings,
    required List<Payment> payments,
    required List<Guest> guests,
    required String propertyName,
    String? recipientHint,
  }) async {
    final stamp = DateTime.now()
        .toIso8601String()
        .substring(0, 19)
        .replaceAll(RegExp(r'[:T]'), '-');
    final base = 'bookings-$propertyName-$stamp'.replaceAll(' ', '_');

    final file = await _writeFile('$base.csv', _combinedCsv(bookings, payments, guests));
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file, mimeType: 'text/csv')],
        subject: 'Booking data export',
        text: recipientHint == null
            ? null
            : 'Booking data export for $recipientHint',
      ),
    );
    return file;
  }

  static String _combinedCsv(
    List<Booking> bookings,
    List<Payment> payments,
    List<Guest> guests,
  ) {
    return [
      bookingsToCsv(bookings).trimRight(),
      '',
      paymentsToCsv(payments).trimRight(),
      '',
      guestsToCsv(guests).trimRight(),
    ].join('\n');
  }

  static Future<String> _writeFile(String name, String contents) async {
    Directory directory;
    try {
      directory = await getTemporaryDirectory();
    } on Object {
      directory = Directory.systemTemp;
    }
    final file = File('${directory.path}/$name');
    await file.writeAsString(contents, flush: true);
    return file.path;
  }
}
