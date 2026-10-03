import '../../core/errors/validation_exception.dart';
import '../../core/utils/app_date.dart';

/// Immutable breakdown of a booking's price.
class BookingQuote {
  const BookingQuote({
    required this.nights,
    required this.pricePerNight,
    required this.subtotal,
    required this.discount,
    required this.taxableAmount,
    required this.tax,
    required this.total,
  });

  final int nights;
  final double pricePerNight;
  final double subtotal;
  final double discount;
  final double taxableAmount;
  final double tax;
  final double total;
}

/// Centralised booking price calculation.
///
/// Spec formula:
/// ```
/// nights    = checkOut - checkIn
/// subtotal  = pricePerNight * nights
/// taxable   = subtotal - discount
/// tax       = taxable * taxPercentage
/// total     = taxable + tax
/// ```
class BookingCalculator {
  const BookingCalculator._();

  static double round2(double value) => (value * 100).roundToDouble() / 100;

  static int nights(DateTime checkIn, DateTime checkOut) =>
      AppDate.dateOnly(checkOut)
          .difference(AppDate.dateOnly(checkIn))
          .inDays;

  static BookingQuote quote({
    required DateTime checkIn,
    required DateTime checkOut,
    required double pricePerNight,
    double discount = 0,
    bool taxEnabled = false,
    double taxPercentage = 0,
  }) {
    if (pricePerNight < 0) {
      throw const ValidationException('Price per night cannot be negative.');
    }
    if (discount < 0) {
      throw const ValidationException('Discount cannot be negative.');
    }

    final numberOfNights = nights(checkIn, checkOut);
    if (numberOfNights <= 0) {
      throw const ValidationException('Check-out must be after check-in.');
    }

    final subtotal = round2(pricePerNight * numberOfNights);
    if (discount > subtotal) {
      throw const ValidationException('Discount cannot exceed the subtotal.');
    }

    final taxableAmount = round2(subtotal - discount);
    final tax =
        taxEnabled ? round2(taxableAmount * (taxPercentage / 100)) : 0.0;

    return BookingQuote(
      nights: numberOfNights,
      pricePerNight: pricePerNight,
      subtotal: subtotal,
      discount: round2(discount),
      taxableAmount: taxableAmount,
      tax: tax,
      total: round2(taxableAmount + tax),
    );
  }
}