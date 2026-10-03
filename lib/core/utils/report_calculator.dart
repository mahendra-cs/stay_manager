import '../../data/models/booking.dart';
import '../../data/models/expense.dart';
import '../../data/models/payment.dart';
import '../../data/models/payment_mode.dart';
import 'app_date.dart';

/// Aggregated figures for a single day, as required by the dashboard (spec §16)
/// and the daily report (spec §19).
class DailyReport {
  const DailyReport({
    required this.date,
    required this.bookingsCreated,
    required this.checkIns,
    required this.checkOuts,
    required this.revenue,
    required this.cashCollected,
    required this.onlineCollected,
    required this.expenses,
    required this.outstanding,
  });

  final DateTime date;
  final int bookingsCreated;
  final int checkIns;
  final int checkOuts;
  final double revenue;
  final double cashCollected;
  final double onlineCollected;
  final double expenses;

  /// Money still owed across bookings that are still active.
  final double outstanding;

  double get net => revenue - expenses;
}

/// Monthly aggregates: revenue, expenses, net and occupancy (spec §19).
class MonthlyReport {
  const MonthlyReport({
    required this.month,
    required this.revenue,
    required this.expenses,
    required this.nightsBooked,
    required this.bookings,
  });

  final DateTime month;
  final double revenue;
  final double expenses;
  final int nightsBooked;
  final int bookings;

  double get net => revenue - expenses;
}

/// Revenue and occupancy for a single room.
class RoomReport {
  const RoomReport({
    required this.roomId,
    required this.roomNumber,
    required this.bookings,
    required this.nights,
    required this.revenue,
  });

  final String roomId;
  final String roomNumber;
  final int bookings;
  final int nights;
  final double revenue;
}

/// Payment totals grouped by mode — the "payment-wise" report (spec §19).
class PaymentModeTotal {
  const PaymentModeTotal({
    required this.mode,
    required this.amount,
    required this.count,
  });

  final PaymentMode mode;
  final double amount;
  final int count;
}

/// Pure aggregation helpers shared by the dashboard and the reports screen.
///
/// All business maths lives here (never inside widgets) so it can be unit
/// tested, exactly like `BookingCalculator` and `PaymentCalculator`.
class ReportCalculator {
  const ReportCalculator._();

  static DailyReport daily({
    required DateTime date,
    required Iterable<Booking> bookings,
    required Iterable<Payment> payments,
    required Iterable<Expense> expenses,
    double outstanding = 0,
  }) {
    final day = AppDate.dateOnly(date);

    final dayPayments = payments
        .where((payment) => AppDate.isSameDay(payment.paymentDate, day))
        .toList(growable: false);

    final revenue = dayPayments.fold<double>(0, (sum, p) => sum + p.amount);
    final cash = dayPayments
        .where((payment) => payment.paymentMode == PaymentMode.cash)
        .fold<double>(0, (sum, p) => sum + p.amount);

    final expenseTotal = expenses
        .where((expense) => AppDate.isSameDay(expense.date, day))
        .fold<double>(0, (sum, e) => sum + e.amount);

    return DailyReport(
      date: day,
      bookingsCreated: _bookingsCreatedOn(bookings, day),
      checkIns: _transitionsOn(bookings, day, (b) => b.checkInAt).length,
      checkOuts: _transitionsOn(bookings, day, (b) => b.checkOutAt).length,
      revenue: revenue,
      cashCollected: cash,
      onlineCollected: revenue - cash,
      expenses: expenseTotal,
      outstanding: outstanding,
    );
  }

  static MonthlyReport monthly({
    required DateTime month,
    required Iterable<Booking> bookings,
    required Iterable<Payment> payments,
    required Iterable<Expense> expenses,
  }) {
    final (start, end) = AppDate.monthRange(month);

    final revenue = payments
        .where((payment) => _within(payment.paymentDate, start, end))
        .fold<double>(0, (sum, payment) => sum + payment.amount);

    final expenseTotal = expenses
        .where((expense) => _within(expense.date, start, end))
        .fold<double>(0, (sum, expense) => sum + expense.amount);

    final monthBookings = bookings
        .where((booking) => booking.bookingStatus.occupiesRoom)
        .where(
          (booking) => _overlaps(
            booking.checkInDate,
            booking.checkOutDate,
            start,
            end,
          ),
        )
        .toList(growable: false);

    return MonthlyReport(
      month: start,
      revenue: revenue,
      expenses: expenseTotal,
      nightsBooked: monthBookings.fold<int>(
        0,
        (sum, booking) => sum + _nightsWithin(
          booking.checkInDate,
          booking.checkOutDate,
          start,
          end,
        ),
      ),
      bookings: monthBookings.length,
    );
  }

  /// Per-room performance (spec §19 "Room-wise").
  ///
  /// Only bookings that still occupy their room count, so cancelled and
  /// no-show records never inflate revenue.
  static List<RoomReport> roomWise(Iterable<Booking> bookings) {
    final grouped = <String, List<Booking>>{};
    for (final booking in bookings) {
      if (!booking.bookingStatus.occupiesRoom) continue;
      grouped.putIfAbsent(booking.roomId, () => <Booking>[]).add(booking);
    }

    final reports = grouped.entries
        .map(
          (entry) => RoomReport(
            roomId: entry.key,
            roomNumber: entry.key,
            bookings: entry.value.length,
            nights: entry.value.fold<int>(
              0,
              (sum, booking) => sum + booking.numberOfNights,
            ),
            revenue: entry.value.fold<double>(
              0,
              (sum, booking) => sum + booking.total,
            ),
          ),
        )
        .toList();

    reports.sort((a, b) => b.revenue.compareTo(a.revenue));
    return reports;
  }

  /// Replaces the internal room id with the configured room number so reports
  /// stay human-readable without hard-coding numbers.
  static List<RoomReport> withRoomNumbers(
    List<RoomReport> reports,
    Map<String, String> roomNumbersById,
  ) {
    return [
      for (final report in reports)
        RoomReport(
          roomId: report.roomId,
          roomNumber: roomNumbersById[report.roomId] ?? report.roomNumber,
          bookings: report.bookings,
          nights: report.nights,
          revenue: report.revenue,
        ),
    ];
  }

  /// Payment totals grouped by mode, largest first (spec §19 "Payment-wise").
  static List<PaymentModeTotal> paymentWise(Iterable<Payment> payments) {
    final totals = <PaymentMode, (double amount, int count)>{};
    for (final payment in payments) {
      final current = totals[payment.paymentMode];
      totals[payment.paymentMode] = current == null
          ? (payment.amount, 1)
          : (current.$1 + payment.amount, current.$2 + 1);
    }

    final result = <PaymentModeTotal>[
      for (final entry in totals.entries)
        PaymentModeTotal(
          mode: entry.key,
          amount: entry.value.$1,
          count: entry.value.$2,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    return result;
  }

  static int _bookingsCreatedOn(Iterable<Booking> bookings, DateTime day) {
    return bookings.where((booking) {
      final created = booking.createdAt ?? booking.checkInDate;
      return AppDate.isSameDay(created, day);
    }).length;
  }

  static List<Booking> _transitionsOn(
    Iterable<Booking> bookings,
    DateTime day,
    DateTime? Function(Booking) pick,
  ) {
    return bookings.where((booking) {
      final at = pick(booking);
      return at != null && AppDate.isSameDay(at, day);
    }).toList(growable: false);
  }

  static bool _within(DateTime value, DateTime start, DateTime end) =>
      !value.isBefore(start) && value.isBefore(end);

  static bool _overlaps(
    DateTime checkIn,
    DateTime checkOut,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final start = AppDate.dateOnly(checkIn);
    final end = AppDate.dateOnly(checkOut);
    return start.isBefore(rangeEnd) && rangeStart.isBefore(end);
  }

  /// Nights of a stay that fall inside `[start, end)`.
  static int _nightsWithin(
    DateTime checkIn,
    DateTime checkOut,
    DateTime start,
    DateTime end,
  ) {
    final from = AppDate.dateOnly(checkIn).isBefore(start)
        ? start
        : AppDate.dateOnly(checkIn);
    final to = AppDate.dateOnly(checkOut).isAfter(end)
        ? end
        : AppDate.dateOnly(checkOut);
    final nights = to.difference(from).inDays;
    return nights < 0 ? 0 : nights;
  }
}