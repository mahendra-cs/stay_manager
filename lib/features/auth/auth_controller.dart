import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/validation_exception.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/auth_service.dart';

/// Session state for the signed-in user (spec §7).
///
/// Mirrors the auth service's stream so the widget tree rebuilds on sign-in,
/// sign-out and token refresh.
class AuthController extends ChangeNotifier {
  AuthController(this._authService) {
    _subscription = _authService.userChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final AuthService _authService;
  late final StreamSubscription<AppUser?> _subscription;

  AppUser? _user;
  bool _busy = false;
  String? _error;

  AppUser? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isBusy => _busy;
  String? get error => _error;

  /// Admin-only screens and actions rely on this; the real authority is the
  /// Firestore security rules (spec §25).
  bool get isAdmin => _user?.isAdmin ?? false;

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    return _run(() => _authService.signIn(email: email, password: password));
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    required String propertyId,
    required UserRole role,
  }) async {
    return _run(
      () => _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
        propertyId: propertyId,
        role: role,
      ),
    );
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  /// Runs an auth action, translating Firebase failures into messages the
  /// receptionist can act on rather than raw exception text.
  Future<bool> _run(Future<AppUser> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _user = await action();
      return true;
    } on ValidationException catch (error) {
      _error = error.message;
      return false;
    } on Object catch (error) {
      _error = _friendly(error);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  String _friendly(Object error) {
    final text = error.toString();
    if (text.contains('invalid-email')) {
      return 'That email address is not valid.';
    }
    if (text.contains('user-not-found') || text.contains('wrong-password')) {
      return 'Incorrect email or password.';
    }
    if (text.contains('email-already-in-use')) {
      return 'An account already exists for this email.';
    }
    if (text.contains('weak-password')) {
      return 'Choose a stronger password (at least 6 characters).';
    }
    if (text.contains('network-request-failed')) {
      return 'No connection. Check your internet and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}