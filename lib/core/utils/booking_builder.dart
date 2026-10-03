import '../../data/models/app_settings.dart';
import '../../data/models/booking.dart';
import '../../data/models/booking_source.dart';
import '../../data/models/payment_mode.dart';
import '../../data/models/property.dart';
import 'booking_calculator.dart';

/// Turns raw form input into a fully priced [Booking].
///
/// The UI collects text and dates; all arithmetic happens here so the booking
/// form, any future quick-book action and the tests share one code path
/// (spec §12 — calculations are never done inside widgets).
class BookingDraft {
  const BookingDraft({
    required this.guestId,
    required this.guestName,
    required this.guestPhone,
    required this.roomId,
    required this.checkIn,
    required this.checkOut,
    required this.pricePerNight,
    required this.propertyId,
    this.adults = 1,
    this.children = 0,
    this.discount = 0,
    this.source = BookingSource.walkIn,
    this.notes = '',
  });

  final String guestId;
  final String guestName;
  final String guestPhone;
  final String roomId;
  final DateTime checkIn;
  final DateTime checkOut;
  final double pricePerNight;
  final String propertyId;
  final int adults;
  final int children;
  final double discount;
  final BookingSource source;
  final String notes;
}

/// Result of [BookingBuilder.build]: the booking plus the quote used to price
/// it, so the form can show the breakdown without recomputing.
class BuiltBooking {
  const BuiltBooking({required this.booking, required this.quote});

  final Booking booking;
  final BookingQuote quote;
}

class BookingBuilder {
  const BookingBuilder._();

  /// Stable-enough identifier for a newly created booking.
  static String generateId() => 'booking-${DateTime.now().microsecondsSinceEpoch}';

  /// Prices [draft] and returns a booking ready to be persisted.
  static BuiltBooking build({
    required BookingDraft draft,
    required Property property,
    required AppSettings settings,
    Booking? existing,
  }) {
    if (draft.guestId.trim().isEmpty) {
      throw const FormatException('Select or create a guest first.');
    }
    if (draft.roomId.trim().isEmpty) {
      throw const FormatException('Select a room.');
    }
    if (draft.adults < 1) {
      throw const FormatException('At least one adult is required.');
    }
    if (draft.children < 0) {
      throw const FormatException('Children cannot be negative.');
    }

    final quote = BookingCalculator.quote(
      checkIn: draft.checkIn,
      checkOut: draft.checkOut,
      pricePerNight: draft.pricePerNight,
      discount: draft.discount,
      taxEnabled: property.taxEnabled,
      taxPercentage: property.taxPercentage,
    );

    final base = existing ??
        Booking(
          id: generateId(),
          propertyId: draft.propertyId,
          guestId: draft.guestId,
          roomId: draft.roomId,
          guestName: draft.guestName,
          checkInDate: draft.checkIn,
          checkOutDate: draft.checkOut,
          pricePerNight: draft.pricePerNight,
          numberOfNights: quote.nights,
          subtotal: quote.subtotal,
          total: quote.total,
        );

    return BuiltBooking(
      booking: base.copyWith(
        guestId: draft.guestId,
        roomId: draft.roomId,
        guestName: draft.guestName,
        guestPhone: draft.guestPhone,
        adults: draft.adults,
        children: draft.children,
        checkInDate: draft.checkIn,
        checkOutDate: draft.checkOut,
        pricePerNight: draft.pricePerNight,
        numberOfNights: quote.nights,
        subtotal: quote.subtotal,
        discount: quote.discount,
        tax: quote.tax,
        total: quote.total,
        source: draft.source,
        notes: draft.notes,
      ),
      quote: quote,
    );
  }

  /// Live preview of the price breakdown while the user types.
  ///
  /// Returns `null` when the current input is not yet valid, so the form can
  /// show a neutral summary instead of an error while typing.
  static BookingQuote? preview({
    required DateTime checkIn,
    required DateTime checkOut,
    required double pricePerNight,
    double discount = 0,
    bool taxEnabled = false,
    double taxPercentage = 0,
  }) {
    try {
      return BookingCalculator.quote(
        checkIn: checkIn,
        checkOut: checkOut,
        pricePerNight: pricePerNight,
        discount: discount,
        taxEnabled: taxEnabled,
        taxPercentage: taxPercentage,
      );
    } on Object {
      return null;
    }
  }

  /// The payment modes to offer, falling back to the generic defaults so the
  /// form is never empty.
  static List<PaymentMode> availablePaymentModes(AppSettings settings) =>
      settings.paymentModes.isEmpty ? PaymentMode.values : settings.paymentModes;

  /// The booking sources to offer, falling back to the generic defaults.
  static List<BookingSource> availableSources(AppSettings settings) =>
      settings.bookingSources.isEmpty
          ? BookingSource.values
          : settings.bookingSources;
}