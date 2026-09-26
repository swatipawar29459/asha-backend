import 'package:firebase_auth/firebase_auth.dart';

import 'health_profile_store.dart';
import 'notification_service.dart';

class AuthService {
  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static User? get currentUser =>
      _auth.currentUser;

  static Stream<User?> get authStateChanges =>
      _auth.authStateChanges();

  // ============================================================
  // REGISTER
  // ============================================================

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

      if (user == null) {
        return null;
      }

      await user.updateDisplayName(
        name.trim(),
      );

      await user.reload();

      // Make sure no previous account's
      // scheduled notifications remain active.
      await NotificationService.cancelAll();

      // ----------------------------------------------------------
      // ADOPT ONBOARDING PROFILE
      // ----------------------------------------------------------
      //
      // If onboarding was completed before registration,
      // HealthProfileStore will now correctly load the pending
      // values and save them under this Firebase UID.
      //
      final adopted =
          await HealthProfileStore
              .adoptPendingProfileForCurrentUser();

      if (!adopted) {
        await HealthProfileStore.load();
      }

      // ----------------------------------------------------------
      // NOTIFICATION
      // ----------------------------------------------------------

      if (HealthProfileStore.lastPeriodDate != null) {
        await NotificationService
            .scheduleCycleNotification();
      }

      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(
        _readableError(e),
      );
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

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

      if (user == null) {
        return null;
      }

      // Remove notifications belonging to
      // the previously active account.
      await NotificationService.cancelAll();

      // A normal login must NEVER copy temporary onboarding
      // data from another account.
      await HealthProfileStore.clearPendingProfile();

      // Load only the profile belonging to this Firebase UID.
      await HealthProfileStore.load();

      // Schedule notifications only if this account
      // actually has a saved last-period date.
      if (HealthProfileStore.lastPeriodDate != null) {
        await NotificationService
            .scheduleCycleNotification();
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(
        _readableError(e),
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<void> logout() async {
    // Stop notifications belonging to the current account.
    await NotificationService.cancelAll();

    // Never allow pending onboarding information to remain
    // after logging out.
    await HealthProfileStore.clearPendingProfile();

    // Clear only in-memory values.
    // Saved Firebase UID profile remains untouched.
    HealthProfileStore.resetInMemory();

    await _auth.signOut();
  }

  // ============================================================
  // FIREBASE ERROR MESSAGES
  // ============================================================

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