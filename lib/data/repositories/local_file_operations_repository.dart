import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/booking.dart';
import '../models/cash_session.dart';
import '../models/expense.dart';
import '../models/guest.dart';
import '../../core/utils/map_utils.dart';
import '../models/payment.dart';
import 'operations_repository.dart';


/// Each stored entry carries its own id, which the model factories expect as a
/// separate argument.
Guest _guestFrom(Map<String, dynamic> e) =>
    Guest.fromMap(_idOf(e), _fieldsOf(e));

Booking _bookingFrom(Map<String, dynamic> e) =>
    Booking.fromMap(_idOf(e), _fieldsOf(e));

Payment _paymentFrom(Map<String, dynamic> e) =>
    Payment.fromMap(_idOf(e), _fieldsOf(e));

Expense _expenseFrom(Map<String, dynamic> e) =>
    Expense.fromMap(_idOf(e), _fieldsOf(e));

CashSession _cashFrom(Map<String, dynamic> e) =>
    CashSession.fromMap(_idOf(e), _fieldsOf(e));

String _idOf(Map<String, dynamic> entry) => MapUtils.asString(entry['id']);

Map<String, dynamic> _fieldsOf(Map<String, dynamic> entry) =>
    <String, dynamic>{...entry}..remove('id');

/// File-backed operational storage for the staff phone.
///
/// With no cloud backend the data lives only on this device, so persistence is
/// mandatory rather than optional: every write is flushed immediately and the
/// file is re-read on startup. Losing a booking because the app was closed
/// would defeat the purpose of the whole workflow.
///
/// A single JSON document is deliberate: at the scale of a small property it
/// is small, human-inspectable and trivially backed up. If data ever grows to
/// need a real database, this class is the only thing that changes because
/// screens only see [OperationsRepository].
class LocalFileOperationsRepository implements OperationsRepository {
  LocalFileOperationsRepository({this.fileName = _defaultFileName});

  static const String _defaultFileName = 'stay_manager_data.json';
  final String fileName;

  File? _cache;
  Future<void>? _pendingWrite;

  @override
  Future<List<Guest>> loadGuests() async =>
      [for (final e in (await _read())['guests']) _guestFrom(e)];

  @override
  Future<List<Booking>> loadBookings() async =>
      [for (final e in (await _read())['bookings']) _bookingFrom(e)];

  @override
  Future<List<Payment>> loadPayments() async =>
      [for (final e in (await _read())['payments']) _paymentFrom(e)];

  @override
  Future<List<Expense>> loadExpenses() async =>
      [for (final e in (await _read())['expenses']) _expenseFrom(e)];

  @override
  Future<List<CashSession>> loadCashSessions() async =>
      [for (final e in (await _read())['cashSessions']) _cashFrom(e)];

  @override
  Future<void> saveGuest(Guest guest) =>
      _put('guests', guest.id, guest.toJsonMap());

  @override
  Future<void> deleteGuest(String guestId) => _remove('guests', guestId);

  @override
  Future<void> saveBooking(Booking booking) =>
      _put('bookings', booking.id, booking.toJsonMap());

  @override
  Future<void> deleteBooking(String bookingId) =>
      _remove('bookings', bookingId);

  @override
  Future<void> savePayment(Payment payment) =>
      _put('payments', payment.id, payment.toJsonMap());

  @override
  Future<void> deletePayment(String paymentId) =>
      _remove('payments', paymentId);

  @override
  Future<void> saveExpense(Expense expense) =>
      _put('expenses', expense.id, expense.toJsonMap());

  @override
  Future<void> deleteExpense(String expenseId) =>
      _remove('expenses', expenseId);

  @override
  Future<void> saveCashSession(CashSession session) =>
      _put('cashSessions', session.id, session.toJsonMap());

  // ----- storage -----------------------------------------------------------

  Future<File> _file() async =>
      _cache ??= File('${(await _directory()).path}/$fileName');

  Future<Directory> _directory() async {
    try {
      return await getApplicationDocumentsDirectory();
    } on Object {
      // Web / unsupported platform: fall back to the system temp directory so
      // the app still runs (data is not persisted between sessions there).
      return Directory.systemTemp;
    }
  }

  Future<Map<String, dynamic>> _read() async {
    // Serialise writes so two quick saves cannot clobber each other.
    await _pendingWrite;
    try {
      final file = await _file();
      if (!await file.exists()) return _empty();
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return _empty();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return _empty();
      return _normalise(decoded);
    } on Object {
      // A corrupt file must not brick the app; start clean rather than crash.
      return _empty();
    }
  }

  static Map<String, dynamic> _empty() => <String, dynamic>{
        'guests': <Map<String, dynamic>>[],
        'bookings': <Map<String, dynamic>>[],
        'payments': <Map<String, dynamic>>[],
        'expenses': <Map<String, dynamic>>[],
        'cashSessions': <Map<String, dynamic>>[],
      };

  static Map<String, dynamic> _normalise(Map<String, dynamic> raw) {
    final result = _empty();
    for (final key in result.keys) {
      final value = raw[key];
      if (value is List) {
        result[key] = value.whereType<Map>().map(Map<String, dynamic>.from).toList();
      }
    }
    return result;
  }

  Future<void> _put(String collection, String id, Map<String, dynamic> data) async {
    final state = await _read();
    final items = (state[collection] as List).cast<Map<String, dynamic>>();
    final entry = <String, dynamic>{'id': id, ...data};
    final index = items.indexWhere((item) => item['id'] == id);
    if (index >= 0) {
      items[index] = entry;
    } else {
      items.add(entry);
    }
    state[collection] = items;
    return _flush(state);
  }

  Future<void> _remove(String collection, String id) async {
    final state = await _read();
    final items = (state[collection] as List).cast<Map<String, dynamic>>();
    items.removeWhere((item) => item['id'] == id);
    state[collection] = items;
    return _flush(state);
  }

  /// Serialises writes so two quick saves cannot clobber each other.
  Future<void> _flush(Map<String, dynamic> state) async {
    final write = _file().then(
      (f) => f.writeAsString(jsonEncode(state), flush: true),
    );
    _pendingWrite = write;
    try {
      await write;
    } on Object {
      // A failed write must not crash the UI; in-memory state stays valid.
    }
  }
}
