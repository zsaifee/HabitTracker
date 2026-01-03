import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signUp(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'No signed-in user.');
    }

    await user.sendEmailVerification();

    // Force verify before app usage
    await _auth.signOut();
  }

  // Sign in but block until verified
  Future<void> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'No signed-in user.');
    }

    await user.reload();
    final refreshed = _auth.currentUser;

    if (refreshed != null && !refreshed.emailVerified) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Verify your email before logging in. Check your inbox.',
      );
    }
  }

  /// ✅ Resend verification while on signup screen:
  /// Temporarily sign in with the typed email+password, send verification, sign out.
  Future<void> resendVerificationEmailWithPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user == null) {
      await _auth.signOut();
      throw FirebaseAuthException(code: 'no-user', message: 'No signed-in user.');
    }

    await user.reload();

    if (user.emailVerified) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'already-verified',
        message: 'Email already verified.',
      );
    }

    await user.sendEmailVerification();
    await _auth.signOut();
  }

  Future<void> signOut() async => _auth.signOut();
}
