import '../models/booking.dart';
import '../models/cash_session.dart';
import '../models/expense.dart';
import '../models/guest.dart';
import '../models/payment.dart';
import 'operations_repository.dart';

/// In-memory implementation of [OperationsRepository].
///
/// Starts empty: no operational data is fabricated. Records created through
/// the UI are kept for the lifetime of the running app. Phase 11 replaces this
/// with Firestore without touching any screen.
class InMemoryOperationsRepository implements OperationsRepository {
  final Map<String, Guest> _guests = <String, Guest>{};
  final Map<String, Booking> _bookings = <String, Booking>{};
  final Map<String, Payment> _payments = <String, Payment>{};
  final Map<String, Expense> _expenses = <String, Expense>{};
  final Map<String, CashSession> _cash = <String, CashSession>{};

  @override
  Future<List<Guest>> loadGuests() async =>
      _guests.values.toList(growable: false);

  @override
  Future<void> saveGuest(Guest guest) async {
    _guests[guest.id] = guest;
  }

  @override
  Future<void> deleteGuest(String guestId) async {
    _guests.remove(guestId);
  }

  @override
  Future<List<Booking>> loadBookings() async =>
      _bookings.values.toList(growable: false);

  @override
  Future<void> saveBooking(Booking booking) async {
    _bookings[booking.id] = booking;
  }

  @override
  Future<void> deleteBooking(String bookingId) async {
    _bookings.remove(bookingId);
  }

  @override
  Future<List<Payment>> loadPayments() async =>
      _payments.values.toList(growable: false);

  @override
  Future<void> savePayment(Payment payment) async {
    _payments[payment.id] = payment;
  }

  @override
  Future<void> deletePayment(String paymentId) async {
    _payments.remove(paymentId);
  }

  @override
  Future<List<Expense>> loadExpenses() async =>
      _expenses.values.toList(growable: false);

  @override
  Future<void> saveExpense(Expense expense) async {
    _expenses[expense.id] = expense;
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    _expenses.remove(expenseId);
  }

  @override
  Future<List<CashSession>> loadCashSessions() async =>
      _cash.values.toList(growable: false);

  @override
  Future<void> saveCashSession(CashSession session) async {
    _cash[session.id] = session;
  }
}