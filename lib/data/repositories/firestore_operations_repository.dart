import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking.dart';
import '../models/cash_session.dart';
import '../models/expense.dart';
import '../models/guest.dart';
import '../models/payment.dart';
import 'operations_repository.dart';

/// Firestore-backed implementation of [OperationsRepository] (spec §13/§17).
///
/// Mirrors the specified collections (`guests`, `bookings`, `payments`,
/// `expenses`) and always scopes queries by `propertyId` so a user can only
/// ever touch their own property's data — enforced again by security rules,
/// never by the UI alone (spec §25).
class FirestoreOperationsRepository implements OperationsRepository {
  FirestoreOperationsRepository({
    required FirebaseFirestore firestore,
    required String propertyId,
  }) :
        // Named parameters cannot be private, so the fields are assigned here.
        // ignore: prefer_initializing_formals
        _db = firestore,
        // ignore: prefer_initializing_formals
        _propertyId = propertyId;

  final FirebaseFirestore _db;
  final String _propertyId;

  CollectionReference<Map<String, dynamic>> _scoped(String name) =>
      _db.collection(name);

  Future<List<T>> _loadAll<T>(
    String collection,
    T Function(String id, Map<String, dynamic> data) fromDoc,
  ) async {
    final snapshot = await _scoped(collection)
        .where('propertyId', isEqualTo: _propertyId)
        .get();
    return [
      for (final doc in snapshot.docs) fromDoc(doc.id, doc.data()),
    ];
  }

  Future<void> _save(
    String collection,
    String id,
    Map<String, dynamic> data, {
    DateTime? createdAt,
  }) async {
    await _scoped(collection).doc(id).set(
      {
        ...data,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ----- guests ------------------------------------------------------------

  @override
  Future<List<Guest>> loadGuests() => _loadAll(
        'guests',
        (id, data) => Guest.fromMap(id, data),
      );

  @override
  Future<void> saveGuest(Guest guest) => _save(
        'guests',
        guest.id,
        guest.toMap(),
        createdAt: guest.createdAt,
      );

  @override
  Future<void> deleteGuest(String guestId) async {
    await _scoped('guests').doc(guestId).delete();
  }

  // ----- bookings ----------------------------------------------------------

  @override
  Future<List<Booking>> loadBookings() => _loadAll(
        'bookings',
        (id, data) => Booking.fromMap(id, data),
      );

  @override
  Future<void> saveBooking(Booking booking) => _save(
        'bookings',
        booking.id,
        booking.toMap(),
        createdAt: booking.createdAt,
      );

  @override
  Future<void> deleteBooking(String bookingId) async {
    await _scoped('bookings').doc(bookingId).delete();
  }

  // ----- payments ----------------------------------------------------------

  @override
  Future<List<Payment>> loadPayments() => _loadAll(
        'payments',
        (id, data) => Payment.fromMap(id, data),
      );

  @override
  Future<void> savePayment(Payment payment) => _save(
        'payments',
        payment.id,
        payment.toMap(),
        createdAt: payment.createdAt,
      );

  @override
  Future<void> deletePayment(String paymentId) async {
    await _scoped('payments').doc(paymentId).delete();
  }

  // ----- expenses ----------------------------------------------------------

  @override
  Future<List<Expense>> loadExpenses() => _loadAll(
        'expenses',
        (id, data) => Expense.fromMap(id, data),
      );

  @override
  Future<void> saveExpense(Expense expense) => _save(
        'expenses',
        expense.id,
        expense.toMap(),
        createdAt: expense.createdAt,
      );

  @override
  Future<void> deleteExpense(String expenseId) async {
    await _scoped('expenses').doc(expenseId).delete();
  }

  // ----- cash --------------------------------------------------------------

  @override
  Future<List<CashSession>> loadCashSessions() => _loadAll(
        'cashSessions',
        (id, data) => CashSession.fromMap(id, data),
      );

  @override
  Future<void> saveCashSession(CashSession session) => _save(
        'cashSessions',
        session.id,
        session.toMap(),
        createdAt: session.createdAt,
      );
}