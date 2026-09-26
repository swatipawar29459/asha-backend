import 'package:firebase_auth/firebase_auth.dart';

import 'health_profile_store.dart';
import 'notification_service.dart';

class AuthService {
  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges =>
      _auth.authStateChanges();

  static Future<User?> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user == null) return null;

      await user.updateDisplayName(name.trim());
      await user.reload();

      // A new Firebase account must never inherit
      // another account's scheduled notifications.
      await NotificationService.cancelAll();

      // If onboarding was completed before registration,
      // attach that temporary profile to this new UID.
      final adopted =
          await HealthProfileStore
              .adoptPendingProfileForCurrentUser();

      if (!adopted) {
        await HealthProfileStore.load();
      }

      if (HealthProfileStore.lastPeriodDate != null) {
        await NotificationService
            .scheduleCycleNotification();
      }

      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_readableError(e));
    }
  }

  static Future<User?> login(
    String email,
    String password,
  ) async {
    try {
      final credential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user == null) return null;

      // Remove any scheduled notification from the
      // previously active Firebase account.
      await NotificationService.cancelAll();

      // Pending onboarding data must not be mixed
      // with an existing Firebase account.
      await HealthProfileStore.clearPendingProfile();

      // Load ONLY this Firebase user's profile.
      await HealthProfileStore.load();

      if (HealthProfileStore.lastPeriodDate != null) {
        await NotificationService
            .scheduleCycleNotification();
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_readableError(e));
    }
  }

  static Future<void> logout() async {
    // Stop notifications belonging to the current
    // account before changing Firebase accounts.
    await NotificationService.cancelAll();

    await HealthProfileStore.clearPendingProfile();

    HealthProfileStore.resetInMemory();

    await _auth.signOut();
  }

  static String _readableError(
    FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-not-found':
        return 'No account was found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ??
            'Something went wrong. Please try again.';
    }
  }
}