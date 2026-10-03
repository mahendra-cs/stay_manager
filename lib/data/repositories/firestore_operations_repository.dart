import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking.dart';
import '../models/cash_session.dart';
import '../models/expense.dart';
import '../models/guest.dart';
import '../models/payment.dart';
import 'operations_repository.dart';
import 'operations_sync_source.dart';

/// Firestore-backed implementation of [OperationsRepository] (spec 13/17).
///
/// Mirrors the specified collections (guests, bookings, payments, expenses)
/// and always scopes queries by `propertyId`, so a user can only ever touch
/// their own property's data. The security rules enforce this again on the
/// server side - the query scoping is convenience, not the boundary.
class FirestoreOperationsRepository
    implements OperationsRepository, OperationsSyncSource {
  FirestoreOperationsRepository({
    required FirebaseFirestore firestore,
    required String propertyId,
  }) :
        // Named parameters cannot be private, so fields are assigned here.
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

  // ----- one-shot reads ---------------------------------------------------

  @override
  Future<List<Guest>> loadGuests() =>
      _loadAll('guests', (id, data) => Guest.fromMap(id, data));

  @override
  Future<List<Booking>> loadBookings() =>
      _loadAll('bookings', (id, data) => Booking.fromMap(id, data));

  @override
  Future<List<Payment>> loadPayments() =>
      _loadAll('payments', (id, data) => Payment.fromMap(id, data));

  @override
  Future<List<Expense>> loadExpenses() =>
      _loadAll('expenses', (id, data) => Expense.fromMap(id, data));

  @override
  Future<List<CashSession>> loadCashSessions() =>
      _loadAll('cashSessions', (id, data) => CashSession.fromMap(id, data));

  // ----- writes ------------------------------------------------------------

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

  @override
  Future<void> saveCashSession(CashSession session) => _save(
        'cashSessions',
        session.id,
        session.toMap(),
        createdAt: session.createdAt,
      );

  // ----- live updates ------------------------------------------------------
  //
  // These streams are what make Phone A and Phone B converge (spec 23).
  // Firestore pushes a new snapshot on every remote change - including changes
  // made by the other device - so no custom synchronisation layer is needed.

  @override
  Stream<List<Guest>> watchGuests() => _watch(
        'guests',
        (id, data) => Guest.fromMap(id, data),
      );

  @override
  Stream<List<Booking>> watchBookings() => _watch(
        'bookings',
        (id, data) => Booking.fromMap(id, data),
      );

  @override
  Stream<List<Payment>> watchPayments() => _watch(
        'payments',
        (id, data) => Payment.fromMap(id, data),
      );

  @override
  Stream<List<Expense>> watchExpenses() => _watch(
        'expenses',
        (id, data) => Expense.fromMap(id, data),
      );

  @override
  Stream<List<CashSession>> watchCashSessions() => _watch(
        'cashSessions',
        (id, data) => CashSession.fromMap(id, data),
      );

  Stream<List<T>> _watch<T>(
    String collection,
    T Function(String id, Map<String, dynamic> data) fromDoc,
  ) {
    return _scoped(collection)
        .where('propertyId', isEqualTo: _propertyId)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) fromDoc(doc.id, doc.data()),
          ],
        );
  }
}
