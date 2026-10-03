import 'dart:async';

import '../../core/errors/validation_exception.dart';
import '../models/app_user.dart';
import 'auth_service.dart';

/// Offline stand-in for Firebase Authentication.
///
/// Used while Firebase is not configured, and by tests. It deliberately
/// accepts any well-formed credentials and keeps the user in memory: it is a
/// development convenience, never a security boundary. Once Firebase is
/// connected, `main.dart` wires [FirebaseAuthService] instead and the real
/// rules in firestore.rules take over (spec 25).
class InMemoryAuthService implements AuthService {
  InMemoryAuthService({this.propertyId = 'property-default'});

  final String propertyId;

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  /// Credentials captured during registration so sign-in works after a restart
  /// of the flow within one app session.
  final Map<String, String> _passwords = <String, String>{};

  @override
  AppUser? get currentUser => _current;

  @override
  Stream<AppUser?> get userChanges => _controller.stream;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final key = email.trim().toLowerCase();
    if (!_passwords.containsKey(key) || _passwords[key] != password) {
      throw const ValidationException('Incorrect email or password.');
    }
    return _emit(_current ?? _demoUser(key));
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    required String propertyId,
    required UserRole role,
  }) async {
    final key = email.trim().toLowerCase();
    _passwords[key] = password;
    return _emit(
      AppUser(
        id: 'local-$key',
        displayName: displayName,
        email: key,
        role: role,
        propertyId: propertyId.isEmpty ? this.propertyId : propertyId,
      ),
    );
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  AppUser _emit(AppUser user) {
    _current = user;
    _controller.add(user);
    return user;
  }

  AppUser _demoUser(String email) => AppUser(
        id: 'local-$email',
        displayName: 'Local User',
        email: email,
        role: UserRole.admin,
        propertyId: propertyId,
      );

  Future<void> dispose() => _controller.close();
}
