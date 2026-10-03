import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/validation_exception.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/availability_service.dart';
import '../../core/utils/payment_calculator.dart';
import '../../core/utils/report_calculator.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/booking.dart';
import '../../data/models/booking_status.dart';
import '../../data/models/cash_session.dart';
import '../../data/models/expense.dart';
import '../../data/models/guest.dart';
import '../../data/models/payment.dart';
import '../../data/models/payment_mode.dart';
import '../../data/models/room.dart';
import '../../data/models/room_status.dart';
import '../../data/repositories/operations_repository.dart';
import '../../data/repositories/operations_sync_source.dart';
import '../../data/repositories/room_status_writer.dart';

/// Holds operational state (guests, bookings, payments, expenses, cash) and
/// exposes derived queries to the UI. Flutter-native `ChangeNotifier` — no
/// third-party state management.
///
/// All business rules (availability, price maths, settlement, policy) are
/// delegated to the pure calculators in `core/utils`; this class only
/// orchestrates repository writes and keeps the in-memory cache fresh.
class OperationsController extends ChangeNotifier {
  OperationsController(
    this._repository, {
    RoomStatusWriter? roomStatusWriter,
    this._settings = const AppSettings(id: '', propertyId: ''),
  }) : _roomStatusWriter = roomStatusWriter ?? const _NoopRoomStatusWriter();

  final OperationsRepository _repository;
  final RoomStatusWriter _roomStatusWriter;

  /// The policy document driving check-out behaviour. Updated whenever the
  /// admin changes settings, so behaviour stays configuration-driven.
  AppSettings _settings;

  AppSettings get settings => _settings;

  /// Applies new policy (expense categories, check-out policy, payment modes).
  void updateSettings(AppSettings settings) {
    _settings = settings;
    notifyListeners();
  }

  bool _isLoading = true;
  List<Guest> _guests = const <Guest>[];
  List<Booking> _bookings = const <Booking>[];
  List<Payment> _payments = const <Payment>[];
  List<Expense> _expenses = const <Expense>[];
  List<CashSession> _cashSessions = const <CashSession>[];

  /// Live subscriptions, present only when the repository can push updates.
  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];

  bool get isLive => _subscriptions.isNotEmpty;

  bool get isLoading => _isLoading;

  List<Guest> get guests => List<Guest>.unmodifiable(_guests);
  List<Booking> get bookings => List<Booking>.unmodifiable(_bookings);
  List<Payment> get payments => List<Payment>.unmodifiable(_payments);
  List<Expense> get expenses => List<Expense>.unmodifiable(_expenses);
  List<CashSession> get cashSessions =>
      List<CashSession>.unmodifiable(_cashSessions);

  Future<void> load() async {
    // Re-loading would otherwise stack duplicate live subscriptions.
    await cancelSubscriptions();

    _isLoading = true;
    notifyListeners();

    final source = _repository is OperationsSyncSource
        ? _repository as OperationsSyncSource
        : null;

    if (source == null) {
      // One-shot load (in-memory / tests).
      _guests = await _repository.loadGuests();
      _bookings = await _repository.loadBookings();
      _payments = await _repository.loadPayments();
      _expenses = await _repository.loadExpenses();
      _cashSessions = await _repository.loadCashSessions();

      _isLoading = false;
      notifyListeners();
      return;
    }

    // Live mode: each stream replaces its slice of state and repaints, so a
    // booking created on Phone A appears on Phone B without a refresh
    // (spec §16 "avoid excessive listeners" — one stream per collection).
    _subscribe(
      source.watchGuests().listen((items) {
        _guests = items;
        notifyListeners();
      }),
    );
    _subscribe(
      source.watchBookings().listen((items) {
        _bookings = items;
        notifyListeners();
      }),
    );
    _subscribe(
      source.watchPayments().listen((items) {
        _payments = items;
        notifyListeners();
      }),
    );
    _subscribe(
      source.watchExpenses().listen((items) {
        _expenses = items;
        notifyListeners();
      }),
    );
    _subscribe(
      source.watchCashSessions().listen((items) {
        _cashSessions = items;
        notifyListeners();
      }),
    );

    // Firestore serves cached data immediately and syncs when online, so this
    // resolves fast even with no connectivity (spec §22).
    _guests = await _repository.loadGuests();
    _isLoading = false;
    notifyListeners();
  }

  void _subscribe(StreamSubscription<Object?> subscription) =>
      _subscriptions.add(subscription);

  /// Stops all live subscriptions. Called on [dispose] and before a re-load.
  Future<void> cancelSubscriptions() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    unawaited(cancelSubscriptions());
    super.dispose();
  }

  // ----- queries -----------------------------------------------------------

  Guest? guestById(String id) => _firstWhereOrNull(_guests, (g) => g.id == id);

  Booking? bookingById(String id) =>
      _firstWhereOrNull(_bookings, (b) => b.id == id);

  List<Payment> paymentsForBooking(String bookingId) => _payments
      .where((payment) => payment.bookingId == bookingId)
      .toList(growable: false);

  double paidForBooking(String bookingId) => paymentsForBooking(
        bookingId,
      ).fold<double>(0, (sum, payment) => sum + payment.amount);

  PaymentSummary summaryFor(Booking booking) => PaymentCalculator.summarize(
        total: booking.total,
        payments: paymentsForBooking(booking.id),
      );

  List<Booking> bookingsForGuest(String guestId) {
    final list = _bookings
        .where((booking) => booking.guestId == guestId)
        .toList(growable: false);
    return list;
  }

  List<Guest> searchGuests(String query) =>
      _guests.where((guest) => guest.matches(query)).toList(growable: false);

  // ----- availability ------------------------------------------------------

  /// Rooms that can be sold for the given range (spec §10 / §28 Phase 6).
  List<Room> availableRooms({
    required List<Room> rooms,
    required DateTime checkIn,
    required DateTime checkOut,
    String? ignoreBookingId,
  }) {
    return AvailabilityService.availableRooms(
      rooms: rooms,
      checkIn: checkIn,
      checkOut: checkOut,
      bookings: _bookings,
      ignoreBookingId: ignoreBookingId,
    );
  }

  bool isRoomAvailable({
    required Room room,
    required DateTime checkIn,
    required DateTime checkOut,
    String? ignoreBookingId,
  }) {
    return AvailabilityService.isRoomAvailable(
      room: room,
      checkIn: checkIn,
      checkOut: checkOut,
      bookings: _bookings,
      ignoreBookingId: ignoreBookingId,
    );
  }

  /// The booking currently occupying [roomId] (booked or checked in).
  Booking? currentBookingForRoom(String roomId) => _firstWhereOrNull(
        _bookings,
        (booking) =>
            booking.roomId == roomId && booking.bookingStatus.occupiesRoom,
      );

  List<Booking> bookingsForRoom(String roomId) {
    final list = _bookings
        .where((booking) => booking.roomId == roomId)
        .toList(growable: false);
    list.sort((a, b) => b.checkInDate.compareTo(a.checkInDate));
    return list;
  }

  /// Today's arrivals — bookings expected to check in today.
  List<Booking> arrivalsOn(DateTime day) {
    final list = _bookings
        .where(
          (booking) =>
              AppDate.isSameDay(booking.checkInDate, day) &&
              booking.bookingStatus.occupiesRoom,
        )
        .toList(growable: false);
    list.sort((a, b) => a.checkInDate.compareTo(b.checkInDate));
    return list;
  }

  /// Today's departures — bookings expected to check out today.
  List<Booking> departuresOn(DateTime day) {
    final list = _bookings
        .where(
          (booking) =>
              AppDate.isSameDay(booking.checkOutDate, day) &&
              booking.bookingStatus.occupiesRoom,
        )
        .toList(growable: false);
    list.sort((a, b) => a.checkOutDate.compareTo(b.checkOutDate));
    return list;
  }

  static T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }

  // ----- guests ------------------------------------------------------------

  Future<Guest> upsertGuest(Guest guest) async {
    final now = DateTime.now();
    final saved = guest.createdAt == null
        ? guest.copyWith(createdAt: now, updatedAt: now)
        : guest.copyWith(updatedAt: now);
    await _repository.saveGuest(saved);
    _guests = await _repository.loadGuests();
    notifyListeners();
    return saved;
  }

  Future<void> deleteGuest(String guestId) async {
    await _repository.deleteGuest(guestId);
    _guests = await _repository.loadGuests();
    notifyListeners();
  }

  // ----- bookings ----------------------------------------------------------

  /// Creates or updates a booking, enforcing availability and recomputing all
  /// money fields centrally (spec §12).
  ///
  /// Availability is validated against every other booking that occupies a
  /// room for an overlapping range; the booking being edited is excluded.
  Future<Booking> upsertBooking(
    Booking booking, {
    List<Room> rooms = const <Room>[],
  }) async {
    if (rooms.isNotEmpty) {
      final room = rooms.where((r) => r.id == booking.roomId).firstOrNull;
      if (room == null) {
        throw const ValidationException('Select a room for this booking.');
      }
      final available = AvailabilityService.isRoomAvailable(
        room: room,
        checkIn: booking.checkInDate,
        checkOut: booking.checkOutDate,
        bookings: _bookings,
        ignoreBookingId: booking.id,
      );
      if (!available) {
        throw const ValidationException(
          'That room is not available for the selected dates.',
        );
      }
    }

    final now = DateTime.now();
    final summary = summaryFor(booking);
    final saved = booking.copyWith(
      outstandingAmount: summary.outstanding,
      paymentStatus: summary.status,
      createdAt: booking.createdAt ?? now,
      updatedAt: now,
    );
    await _repository.saveBooking(saved);
    _bookings = await _repository.loadBookings();

    // A booking reserves the room immediately.
    if (saved.bookingStatus == BookingStatus.booked) {
      await _roomStatusWriter.setRoomStatus(saved.roomId, RoomStatus.booked);
    }
    notifyListeners();
    return saved;
  }

  Future<void> deleteBooking(String bookingId) async {
    final booking = bookingById(bookingId);
    await _repository.deleteBooking(bookingId);
    for (final payment in paymentsForBooking(bookingId)) {
      await _repository.deletePayment(payment.id);
    }
    _bookings = await _repository.loadBookings();
    _payments = await _repository.loadPayments();
    await _releaseRoom(booking);
    notifyListeners();
  }

  /// Checks a guest in: verifies the booking, moves both statuses and records
  /// the timestamp plus the acting user (spec §14).
  Future<Booking> checkIn(Booking booking, {String actor = ''}) async {
    if (booking.bookingStatus != BookingStatus.booked) {
      throw const ValidationException(
        'Only a booked reservation can be checked in.',
      );
    }
    final now = DateTime.now();
    final saved = await upsertBooking(
      booking.copyWith(
        bookingStatus: BookingStatus.checkedIn,
        checkInAt: now,
        checkedInBy: actor,
        updatedAt: now,
      ),
    );
    await _roomStatusWriter.setRoomStatus(booking.roomId, RoomStatus.checkedIn);
    return saved;
  }

  /// Checks a guest out. Enforces the configured settlement policy and moves
  /// the room to the configured post-check-out status (spec §14).
  Future<Booking> checkOut(
    Booking booking, {
    String actor = '',
    RoomStatus? roomStatusAfter,
  }) async {
    if (booking.bookingStatus != BookingStatus.checkedIn) {
      throw const ValidationException(
        'Only a checked-in guest can be checked out.',
      );
    }

    final summary = summaryFor(booking);
    if (_settings.checkoutRequiresSettlement && summary.outstanding > 0) {
      throw ValidationException(
        'Outstanding amount must be settled before check-out '
        '(${summary.outstanding.toStringAsFixed(2)}).',
      );
    }

    final now = DateTime.now();
    final saved = await upsertBooking(
      booking.copyWith(
        bookingStatus: BookingStatus.checkedOut,
        checkOutAt: now,
        checkedOutBy: actor,
        updatedAt: now,
      ),
    );

    final next = roomStatusAfter ?? _settings.roomStatusAfterCheckout;
    await _roomStatusWriter.setRoomStatus(
      booking.roomId,
      next == RoomStatus.checkedOut ? RoomStatus.cleaning : next,
    );
    return saved;
  }

  /// Marks a room as ready to sell again after cleaning.
  Future<void> markRoomAvailable(String roomId) =>
      _roomStatusWriter.setRoomStatus(roomId, RoomStatus.available);

  /// Blocks / unblocks a room from selling (spec §10).
  Future<void> setRoomBlocked(String roomId, bool blocked) =>
      _roomStatusWriter.setRoomStatus(
        roomId,
        blocked ? RoomStatus.blocked : RoomStatus.available,
      );

  Future<Booking> setBookingStatus(
    Booking booking,
    BookingStatus status, {
    String actor = '',
  }) async {
    return upsertBooking(
      booking.copyWith(
        bookingStatus: status,
        checkedInBy:
            status == BookingStatus.checkedIn && booking.checkInAt == null
                ? actor
                : booking.checkedInBy,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Frees a room only when no other booking still occupies it.
  Future<void> _releaseRoom(Booking? booking) async {
    if (booking == null) return;
    final stillOccupied = _bookings.any(
      (b) => b.roomId == booking.roomId && b.bookingStatus.occupiesRoom,
    );
    if (!stillOccupied) {
      await _roomStatusWriter.setRoomStatus(booking.roomId, RoomStatus.available);
    }
  }

  // ----- payments ----------------------------------------------------------

  Future<void> addPayment(Payment payment) async {
    final booking = bookingById(payment.bookingId);
    if (booking == null) {
      throw const ValidationException('Booking not found.');
    }
    final alreadyPaid = paidForBooking(booking.id);
    if (!PaymentCalculator.canAccept(
      total: booking.total,
      alreadyPaid: alreadyPaid,
      amount: payment.amount,
    )) {
      throw const ValidationException(
        'Payment exceeds the outstanding amount.',
      );
    }

    await _repository.savePayment(
      payment.createdAt == null
          ? payment.copyWith(createdAt: DateTime.now())
          : payment,
    );
    _payments = await _repository.loadPayments();
    await _refreshSettlement(booking.id);
  }

  Future<void> deletePayment(String paymentId) async {
    final payment = _firstWhereOrNull(_payments, (p) => p.id == paymentId);
    await _repository.deletePayment(paymentId);
    _payments = await _repository.loadPayments();
    if (payment != null) {
      await _refreshSettlement(payment.bookingId);
    }
  }

  Future<void> _refreshSettlement(String bookingId) async {
    final booking = bookingById(bookingId);
    if (booking == null) {
      notifyListeners();
      return;
    }
    final summary = summaryFor(booking);
    await _repository.saveBooking(
      booking.copyWith(
        outstandingAmount: summary.outstanding,
        paymentStatus: summary.status,
        updatedAt: DateTime.now(),
      ),
    );
    _bookings = await _repository.loadBookings();
    notifyListeners();
  }

  // ----- expenses ----------------------------------------------------------

  Future<void> upsertExpense(Expense expense) async {
    final now = DateTime.now();
    await _repository.saveExpense(
      expense.createdAt == null
          ? expense.copyWith(createdAt: now, updatedAt: now)
          : expense.copyWith(updatedAt: now),
    );
    _expenses = await _repository.loadExpenses();
    notifyListeners();
  }

  Future<void> deleteExpense(String expenseId) async {
    await _repository.deleteExpense(expenseId);
    _expenses = await _repository.loadExpenses();
    notifyListeners();
  }

  // ----- cash --------------------------------------------------------------

  CashSession? cashSessionFor(DateTime day) => _firstWhereOrNull(
        _cashSessions,
        (session) => AppDate.isSameDay(session.date, day),
      );

  double openingCashFor(DateTime day) => cashSessionFor(day)?.openingCash ?? 0;

  double cashInFor(DateTime day) => _payments
      .where(
        (payment) =>
            payment.paymentMode == PaymentMode.cash &&
            AppDate.isSameDay(payment.paymentDate, day),
      )
      .fold<double>(0, (sum, payment) => sum + payment.amount);

  double cashOutFor(DateTime day) => _expenses
      .where(
        (expense) =>
            expense.paymentMode == PaymentMode.cash &&
            AppDate.isSameDay(expense.date, day),
      )
      .fold<double>(0, (sum, expense) => sum + expense.amount);

  double expectedCashFor(DateTime day) =>
      openingCashFor(day) + cashInFor(day) - cashOutFor(day);

  Future<void> saveCashSession({
    required DateTime day,
    double? openingCash,
    double? countedCash,
  }) async {
    final existing = cashSessionFor(day);
    final now = DateTime.now();
    final base = existing ??
        CashSession(
          id: 'cash-${AppDate.format(day)}',
          propertyId: '',
          date: AppDate.dateOnly(day),
        );
    final session = base.copyWith(
      openingCash: openingCash ?? base.openingCash,
      countedCash: countedCash ?? base.countedCash,
      createdAt: base.createdAt ?? now,
      updatedAt: now,
    );
    await _repository.saveCashSession(session);
    _cashSessions = await _repository.loadCashSessions();
    notifyListeners();
  }

  // ----- dashboard aggregates ---------------------------------------------

  List<Booking> get activeBookings => _bookings
      .where((booking) => booking.bookingStatus.occupiesRoom)
      .toList(growable: false);

  List<Booking> get todaysCheckIns => _bookings
      .where(
        (booking) =>
            booking.bookingStatus == BookingStatus.booked &&
            AppDate.isSameDay(booking.checkInDate, AppDate.today()),
      )
      .toList(growable: false);

  List<Booking> get todaysCheckOuts => _bookings
      .where(
        (booking) =>
            booking.bookingStatus == BookingStatus.checkedIn &&
            AppDate.isSameDay(booking.checkOutDate, AppDate.today()),
      )
      .toList(growable: false);

  double get revenueToday => _payments
      .where((payment) => AppDate.isSameDay(payment.paymentDate, AppDate.today()))
      .fold<double>(0, (sum, payment) => sum + payment.amount);

  double get cashToday => _payments
      .where(
        (payment) =>
            payment.paymentMode == PaymentMode.cash &&
            AppDate.isSameDay(payment.paymentDate, AppDate.today()),
      )
      .fold<double>(0, (sum, payment) => sum + payment.amount);

  double get onlineToday => revenueToday - cashToday;

  double get expenseToday => _expenses
      .where((expense) => AppDate.isSameDay(expense.date, AppDate.today()))
      .fold<double>(0, (sum, expense) => sum + expense.amount);

  double get outstandingTotal => activeBookings.fold<double>(
        0,
        (sum, booking) => sum + booking.outstandingAmount,
      );

  bool isRoomOccupied(String roomId) =>
      activeBookings.any((booking) => booking.roomId == roomId);

  /// Most recently created bookings, newest first — dashboard "Recent".
  List<Booking> recentBookings({int limit = 5}) {
    final list = List<Booking>.from(_bookings);
    list.sort((a, b) {
      final aAt = a.createdAt ?? a.checkInDate;
      final bAt = b.createdAt ?? b.checkInDate;
      return bAt.compareTo(aAt);
    });
    return list.take(limit).toList(growable: false);
  }

  // ----- reports -----------------------------------------------------------

  /// Daily figures for [day] (dashboard cards + the daily report).
  DailyReport dailyReport(DateTime day) => ReportCalculator.daily(
        date: day,
        bookings: _bookings,
        payments: _payments,
        expenses: _expenses,
        outstanding: outstandingTotal,
      );

  MonthlyReport monthlyReport(DateTime month) => ReportCalculator.monthly(
        month: month,
        bookings: _bookings,
        payments: _payments,
        expenses: _expenses,
      );

  List<RoomReport> roomWiseReport({
    required Map<String, String> roomNumbersById,
    DateTime? from,
    DateTime? to,
  }) {
    final scoped = _bookings.where((booking) {
      if (!booking.bookingStatus.occupiesRoom) return false;
      if (from == null || to == null) return true;
      return !booking.checkOutDate.isBefore(from) &&
          !booking.checkInDate.isAfter(to);
    });
    return ReportCalculator.withRoomNumbers(
      ReportCalculator.roomWise(scoped),
      roomNumbersById,
    );
  }

  List<PaymentModeTotal> paymentWiseReport({DateTime? from, DateTime? to}) {
    final scoped = _payments.where((payment) {
      if (from == null || to == null) return true;
      return !payment.paymentDate.isBefore(from) &&
          !payment.paymentDate.isAfter(to);
    });
    return ReportCalculator.paymentWise(scoped);
  }

  List<Expense> expensesOn(DateTime day) {
    final list = _expenses
        .where((expense) => AppDate.isSameDay(expense.date, day))
        .toList(growable: false);
    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  /// Expense totals per category for the month containing [month].
  Map<String, double> expenseBreakdown(DateTime month) {
    final (start, end) = AppDate.monthRange(month);
    final totals = <String, double>{};
    for (final expense in _expenses) {
      if (expense.date.isBefore(start) || !expense.date.isBefore(end)) continue;
      final key = expense.category.trim().isEmpty
          ? 'Uncategorised'
          : expense.category;
      totals[key] = (totals[key] ?? 0) + expense.amount;
    }
    return totals;
  }
}

/// Fallback used when no room writer is wired (for example in unit tests), so
/// operations code can always run without a configuration controller.
class _NoopRoomStatusWriter implements RoomStatusWriter {
  const _NoopRoomStatusWriter();

  @override
  Future<void> setRoomStatus(String roomId, RoomStatus status) async {}
}