import '../../data/models/booking_source.dart';
import '../../data/models/payment_mode.dart';

/// Generic, property-agnostic defaults used when creating new configuration.
///
/// These are *fallbacks*, not business rules: an admin can change every list
/// through the configuration screens.
class AppDefaults {
  const AppDefaults._();

  /// Placeholder shown when a value has not been configured yet.
  static const String emptyValue = '--';

  /// Default room type names offered while creating rooms.
  static const List<String> roomTypes = <String>[
    'Standard',
    'Deluxe',
    'Suite',
  ];

  static const List<PaymentMode> paymentModes = <PaymentMode>[
    PaymentMode.cash,
    PaymentMode.upi,
    PaymentMode.card,
    PaymentMode.bankTransfer,
    PaymentMode.other,
  ];

  static const List<BookingSource> bookingSources = <BookingSource>[
    BookingSource.walkIn,
    BookingSource.phone,
    BookingSource.whatsapp,
    BookingSource.website,
    BookingSource.bookingCom,
    BookingSource.makeMyTrip,
    BookingSource.agoda,
    BookingSource.other,
  ];

  /// Default expense categories (configurable labels, not a fixed enum).
  static const List<String> expenseCategories = <String>[
    'Electricity',
    'Water',
    'Supplies',
    'Maintenance',
    'Salary',
    'Cleaning',
    'Other',
  ];
}