import '../models/app_user.dart';

/// Authentication / session abstraction (spec §7, §25).
///
/// Roles are stored in `users/{userId}` and enforced by Firestore security
/// rules — the UI only uses [AppUser.isAdmin] to hide admin-only actions.
abstract class AuthService {
  /// Emits whenever the signed-in user changes (sign-in, sign-out, refresh).
  Stream<AppUser?> get userChanges;

  AppUser? get currentUser;

  /// Signs in with email/password (preferred over SMS per the spec).
  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// Creates the account and the matching `users/{userId}` profile.
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    required String propertyId,
    required UserRole role,
  });
}