import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    final doc = await _firestore.collection('usernames').doc(username.toLowerCase()).get();
    return !doc.exists;
  }

  // Get username for current user
  Future<String?> getUserUsername(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['username'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Sign up with email and password
  Future<Map<String, dynamic>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String username,
    String? phone,
  }) async {
    try {
      // Validate WVSU email
      if (!email.endsWith('@wvsu.edu.ph')) {
        return {
          'success': false,
          'message': 'Please use your WVSU email address'
        };
      }

      // Validate username (alphanumeric and underscore only, 3-20 characters)
      final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
      if (!usernameRegex.hasMatch(username)) {
        return {
          'success': false,
          'message': 'Username must be 3-20 characters and contain only letters, numbers, and underscores'
        };
      }

      // Check if username is available
      final usernameToCheck = username.toLowerCase();
      final isAvailable = await isUsernameAvailable(usernameToCheck);
      if (!isAvailable) {
        return {
          'success': false,
          'message': 'Username is already taken. Please choose another one.'
        };
      }
      
      debugPrint('Username "$usernameToCheck" is available for registration');

      // Create user account (Firebase Auth)
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name locally on the auth user
      await userCredential.user?.updateDisplayName(fullName);

      final usernameLower = username.toLowerCase();
      final usernameRef = _firestore.collection('usernames').doc(usernameLower);
      final userRef = _firestore.collection('users').doc(userCredential.user?.uid);

      // Use a transaction to ensure the username doc does not already exist and
      // atomically create both the `usernames/{username}` and `users/{uid}` docs.
      try {
        await _firestore.runTransaction((tx) async {
          final usernameSnap = await tx.get(usernameRef);
          if (usernameSnap.exists) {
            // Signal a username collision from inside the transaction
            throw FirebaseException(
                plugin: 'cloud_firestore', code: 'username-already-exists', message: 'Username already taken');
          }

          tx.set(usernameRef, {
            'uid': userCredential.user?.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });

          tx.set(userRef, {
            'uid': userCredential.user?.uid,
            'email': email,
            'fullName': fullName,
            'username': usernameLower,
            'phone': phone,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });
      } catch (e) {
        // If the transaction failed because the username already exists,
        // delete the newly-created auth user to avoid leaving a dangling account.
        try {
          await userCredential.user?.delete();
        } catch (_) {
          // Ignore errors deleting the auth user; we'll still return an error to the caller.
        }

        if (e is FirebaseException && e.code == 'username-already-exists') {
          return {
            'success': false,
            'message': 'Username is already taken. Please choose another one.'
          };
        }

        return {'success': false, 'message': 'An error occurred creating your account: $e'};
      }

      // Send email verification after Firestore writes succeeded
      await userCredential.user?.sendEmailVerification();

      return {
        'success': true,
        'message': 'Account created successfully! Please verify your email.',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          message = 'The email address is invalid.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled.';
          break;
        default:
          message = 'An error occurred: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Validate WVSU email
      if (!email.endsWith('@wvsu.edu.ph')) {
        return {
          'success': false,
          'message': 'Please use your WVSU email address'
        };
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if email is verified
      if (!userCredential.user!.emailVerified) {
        return {
          'success': false,
          'message': 'Please verify your email before logging in.',
          'needsVerification': true,
        };
      }

      return {
        'success': true,
        'message': 'Login successful!',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'The email address is invalid.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many failed attempts. Please try again later.';
          break;
        default:
          message = 'An error occurred: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword({required String email}) async {
    try {
      if (!email.endsWith('@wvsu.edu.ph')) {
        return {
          'success': false,
          'message': 'Please use your WVSU email address'
        };
      }

      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent. Please check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'invalid-email':
          message = 'The email address is invalid.';
          break;
        default:
          message = 'An error occurred: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  // Resend verification email
  Future<Map<String, dynamic>> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      await user.sendEmailVerification();
      return {
        'success': true,
        'message': 'Verification email sent. Please check your inbox.',
      };
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // Delete account
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      // Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete user account
      await user.delete();

      return {'success': true, 'message': 'Account deleted successfully'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }
}
