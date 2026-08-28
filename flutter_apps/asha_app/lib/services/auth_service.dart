import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================================================
  // REGISTER
  // ==================================================

  Future<User?> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;

      if (user != null) {
        // Save user's name in Firebase Authentication
        await user.updateDisplayName(name.trim());

        // Refresh Firebase user information
        await user.reload();
      }

      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      throw _readable(e);
    }
  }

  // ==================================================
  // LOGIN
  // ==================================================

  Future<User?> login(
    String email,
    String password,
  ) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw _readable(e);
    }
  }

  // ==================================================
  // LOGOUT
  // ==================================================

  Future<void> logout() async {
    await _auth.signOut();
  }

  // ==================================================
  // CURRENT USER
  // ==================================================

  User? get currentUser => _auth.currentUser;

  // ==================================================
  // AUTH STATE
  // ==================================================

  Stream<User?> get authStateChanges =>
      _auth.authStateChanges();

  // ==================================================
  // ERROR MESSAGES
  // ==================================================

  String _readable(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with that email.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'You have not put in your password correctly.';

      case 'email-already-in-use':
        return 'An account already exists with that email.';

      case 'weak-password':
        return 'Password should be at least 6 characters.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      default:
        return e.message ?? 'Something went wrong. Try again.';
    }
  }
}