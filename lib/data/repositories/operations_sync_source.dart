import '../models/booking.dart';
import '../models/cash_session.dart';
import '../models/expense.dart';
import '../models/guest.dart';
import '../models/payment.dart';

/// Optional live-update capability for [OperationsRepository].
///
/// Spec §22/§23 require both phones to converge on the same data without a
/// custom sync layer: Firestore pushes changes, so Phone A and Phone B stay in
/// step for free. A one-shot `load()` cannot do that — it would leave each
/// device showing stale data until the app restarted.
///
/// Repositories that implement this are watched by `OperationsController`;
/// the in-memory implementation deliberately does not, so unit tests and the
/// no-Firebase fallback keep their simple one-shot behaviour.
abstract class OperationsSyncSource {
  Stream<List<Guest>> watchGuests();

  Stream<List<Booking>> watchBookings();

  Stream<List<Payment>> watchPayments();

  Stream<List<Expense>> watchExpenses();

  Stream<List<CashSession>> watchCashSessions();
}