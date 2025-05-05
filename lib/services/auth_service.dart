import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth change user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print("Attempting to sign in with email: $email");
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("Sign in successful for uid: ${userCredential.user?.uid}");
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Exception during login: ${e.code} - ${e.message}");

      // For security, combine user-not-found and wrong-password
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        throw FirebaseAuthException(
          code: 'invalid-credentials',
          message: 'Invalid email or password. Please try again.',
        );
      } else if (e.code == 'invalid-email') {
        throw FirebaseAuthException(
          code: e.code,
          message: 'Please enter a valid email address.',
        );
      } else if (e.code == 'user-disabled') {
        throw FirebaseAuthException(
          code: e.code,
          message: 'This account has been disabled.',
        );
      } else if (e.code == 'too-many-requests') {
        throw FirebaseAuthException(
          code: e.code,
          message: 'Too many attempts. Please try again later.',
        );
      } else if (e.code == 'network-request-failed') {
        throw FirebaseAuthException(
          code: e.code,
          message: 'Network error. Please check your connection.',
        );
      } else {
        throw FirebaseAuthException(
          code: e.code,
          message: 'Authentication failed. Please try again.',
        );
      }
    } catch (e) {
      print("Generic error during login: $e");
      throw Exception('Unable to sign in. Please try again later.');
    }
  }

  // Create user only - does NOT sign in automatically
  Future<void> createUserOnly(
    String email,
    String password,
    String fullName,
    String username,
  ) async {
    try {
      print("Starting user registration process for email: $email");

      // Create authentication account
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      print(
        "Auth account created successfully. UID: ${userCredential.user?.uid}",
      );

      // Save additional user data to Firestore
      if (userCredential.user != null) {
        print("Attempting to save user data to Firestore");

        try {
          // Create user data map
          final userData = {
            'fullName': fullName,
            'username': username,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          };

          print("User data prepared: $userData");

          // Save to Firestore
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(userData);
          print("User data saved to Firestore successfully");

          // Sign out immediately to prevent auto-login
          await _auth.signOut();
          print("User signed out after registration - needs explicit login");
        } catch (firestoreError) {
          print("Error saving to Firestore: $firestoreError");

          // Since the auth account was created but Firestore failed, delete the auth account
          try {
            await userCredential.user?.delete();
            print("Auth account deleted due to Firestore error");
          } catch (deleteError) {
            print("Could not delete auth account: $deleteError");
          }

          throw Exception(
            'Unable to save your profile information. Please try again.',
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      print(
        "Firebase Auth Exception during registration: ${e.code} - ${e.message}",
      );

      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage =
              'This email is already registered. Try signing in instead.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak. Use at least 6 characters.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Account creation is currently disabled.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        default:
          errorMessage = 'Unable to create account. Please try again.';
      }

      throw FirebaseAuthException(code: e.code, message: errorMessage);
    } catch (e) {
      print("Generic error during registration: $e");
      throw Exception('Unable to create account. Please try again later.');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print("Sending password reset email to: $email");
      await _auth.sendPasswordResetEmail(email: email);
      print("Password reset email sent successfully");
    } on FirebaseAuthException catch (e) {
      print(
        "Firebase Auth Exception during password reset: ${e.code} - ${e.message}",
      );

      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'user-not-found':
          // For security, don't reveal if user exists or not
          errorMessage =
              'If this email is registered, a reset link will be sent.';
          break;
        default:
          errorMessage = 'Unable to send reset email. Please try again.';
      }

      throw FirebaseAuthException(code: e.code, message: errorMessage);
    } catch (e) {
      print("Generic error during password reset: $e");
      throw Exception('Unable to send reset email. Please try again later.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print("Signing out user");
      await _auth.signOut();
      print("User signed out successfully");
    } catch (e) {
      print("Error signing out: $e");
      throw Exception('Error signing out. Please try again.');
    }
  }
}
