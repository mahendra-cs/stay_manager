import '../models/booking.dart';
import '../models/cash_session.dart';
import '../models/expense.dart';
import '../models/guest.dart';
import '../models/payment.dart';

/// Read/write access to operational data (guests, bookings, payments,
/// expenses, cash).
///
/// Screens depend on this abstraction only. Phase 3-10 ship the in-memory
/// implementation; Phase 11 adds a Firestore-backed one behind the same
/// interface.
abstract class OperationsRepository {
  Future<List<Guest>> loadGuests();

  Future<void> saveGuest(Guest guest);

  Future<void> deleteGuest(String guestId);

  Future<List<Booking>> loadBookings();

  Future<void> saveBooking(Booking booking);

  Future<void> deleteBooking(String bookingId);

  Future<List<Payment>> loadPayments();

  Future<void> savePayment(Payment payment);

  Future<void> deletePayment(String paymentId);

  Future<List<Expense>> loadExpenses();

  Future<void> saveExpense(Expense expense);

  Future<void> deleteExpense(String expenseId);

  Future<List<CashSession>> loadCashSessions();

  Future<void> saveCashSession(CashSession session);
}