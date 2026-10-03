import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/validation_exception.dart';
import '../models/app_user.dart';
import 'auth_service.dart';

/// Firebase Authentication implementation of [AuthService] (spec §7).
///
/// Email/password only — the spec explicitly avoids SMS to keep cost and
/// complexity down. The role lives in `users/{userId}` rather than in the
/// auth token, so it can be changed without re-issuing credentials.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required String propertyId,
  }) :
        // Named parameters cannot be private, so the fields are assigned here.
        // ignore: prefer_initializing_formals
        _auth = auth,
        // ignore: prefer_initializing_formals
        _db = firestore,
        // ignore: prefer_initializing_formals
        _propertyId = propertyId;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final String _propertyId;

  User? get _firebaseUser => _auth.currentUser;

  @override
  AppUser? get currentUser {
    final user = _firebaseUser;
    return user == null ? null : _fromFirebaseUser(user);
  }

  @override
  Stream<AppUser?> get userChanges => _auth.authStateChanges().map(
        (user) => user == null ? null : _fromFirebaseUser(user),
      );

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw const ValidationException('Sign-in failed. Please try again.');
    }
    // Make sure a profile exists even for accounts created before the app.
    await _ensureProfile(user);
    return _fromFirebaseUser(user);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    required String propertyId,
    required UserRole role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw const ValidationException('Could not create the account.');
    }

    await user.updateDisplayName(displayName.trim());
    await _db.collection('users').doc(user.uid).set({
      'displayName': displayName.trim(),
      'email': user.email ?? '',
      'role': role.wireValue,
      'propertyId': propertyId.isEmpty ? _propertyId : propertyId,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return AppUser(
      id: user.uid,
      displayName: displayName.trim(),
      email: user.email ?? '',
      role: role,
      propertyId: propertyId.isEmpty ? _propertyId : propertyId,
    );
  }

  /// Creates a default STAFF profile when one is missing, so the app can
  /// always resolve a property for the signed-in user.
  Future<void> _ensureProfile(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final doc = await ref.get();
    if (doc.exists) return;

    await ref.set({
      'displayName': user.displayName ?? '',
      'email': user.email ?? '',
      // Least privilege by default: an admin promotes the user explicitly.
      'role': UserRole.staff.wireValue,
      'propertyId': _propertyId,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  AppUser _fromFirebaseUser(User user) {
    return AppUser(
      id: user.uid,
      displayName: user.displayName ?? '',
      email: user.email ?? '',
      // Fall back to STAFF until the stored profile is read; Firestore rules
      // remain the real authority on what this user may do.
      role: UserRole.staff,
      propertyId: _propertyId,
    );
  }
}