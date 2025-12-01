import 'package:firebase_auth/firebase_auth.dart';
import 'package:projecte_pm/models/User.dart' as ClaseUsuari;

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. LOGIN - Sign in with email/password
  Future<ClaseUsuari.User?> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!userCredential.user!.emailVerified) {
        await _auth.signOut(); // Sign them out
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Verifica el teu correu electrònic per registrar-te.',
        ); // Remove "rethrow;" from here
      }
      return _userFromFirebaseUser(userCredential.user);
    } on FirebaseAuthException catch (e) {
      print("Login error: ${e.code}: ${e.message}");
      rethrow; // Keep this here
    } catch (e) {
      print("Login error: $e");
      rethrow;
    }
  }

  // 2. REGISTER - Create new account
  Future<ClaseUsuari.User?> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name in Firebase
      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.sendEmailVerification();
      await _auth.signOut();
      return _userFromFirebaseUser(userCredential.user);
    } on FirebaseAuthException catch (e) {
      print("Registration error: ${e.code}: ${e.message}");
      rethrow;
    } catch (e) {
      print("Registration error: $e");
      rethrow; // Change this from "return null" to "rethrow"
    }
  }

  // NEW: Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      print("Resend verification error: $e");
      rethrow;
    }
  }

  // NEW: Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload(); // Refresh user data
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      print("Email verification check error: $e");
      return false;
    }
  }

  // NEW: Wait for email verification (polling)
  Future<bool> waitForEmailVerification({int maxSeconds = 60}) async {
    int secondsWaited = 0;

    while (secondsWaited < maxSeconds) {
      await Future.delayed(Duration(seconds: 2));
      secondsWaited += 2;

      if (await isEmailVerified()) {
        return true;
      }
    }

    return false;
  }

  // 3. Convert Firebase User to your User class
  ClaseUsuari.User? _userFromFirebaseUser(User? firebaseUser) {
    if (firebaseUser == null) return null;

    return ClaseUsuari.User(
      id: firebaseUser.uid,
      role: false,
      name: firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
      email: firebaseUser.email!,
      password: '',
      albumId: null,
      playlistId: [],
      seguits: [],
      seguidors: [],
      createdAt: DateTime.now(),
    );
  }

  // 4. Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // 5. Check current user
  ClaseUsuari.User? get currentUser {
    final user = _auth.currentUser;
    return user != null ? _userFromFirebaseUser(user) : null;
  }
}
