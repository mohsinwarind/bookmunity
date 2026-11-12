import 'package:firebase_auth/firebase_auth.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // LOGIN
  Future<User?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseError(e.code));
    }
  }

  // SIGNUP
  Future<User?> signupUser({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user != null &&
          displayName != null &&
          displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
        await user.reload();
      }
      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseError(e.code));
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseError(e.code));
    }
  }

  // CURRENT USER
  User? get currentUser => _auth.currentUser;

  // FIREBASE ERROR HANDLING
  String _getFirebaseError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-not-found':
        return 'No account found with this email.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'email-already-in-use':
        return 'An account already exists with this email.';

      case 'weak-password':
        return 'Password should be at least 6 characters.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
