import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Future<User?> register(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw _readable(e);
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw _readable(e);
    }
  }

  Future<void> logout() async => await _auth.signOut();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String _readable(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return 'No account found with that email.';
      case 'wrong-password':
      case 'invalid-credential': return 'You have not put in your password correctly.';
      case 'email-already-in-use': return 'An account already exists with that email.';
      case 'weak-password': return 'Password should be at least 6 characters.';
      default: return e.message ?? 'Something went wrong. Try again.';
    }
  }
}