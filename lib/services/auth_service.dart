import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/auth_debug_helper.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  AuthService() {
    // Initialize current user
    _user = _auth.currentUser;
    
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      AuthDebugHelper.logAuthEvent('Auth state changed', data: {
        'user_email': user?.email ?? 'null',
        'user_id': user?.uid ?? 'null',
      });
      _user = user;
      notifyListeners();
    });
    
    AuthDebugHelper.logAuthEvent('AuthService initialized', data: {
      'current_user': _user?.email ?? 'null',
    });
    
    // Perform initial diagnostics
    AuthDebugHelper.performAuthDiagnostics();
  }

  Future<String?> signInWithEmailAndPassword(String email, String password) async {
    try {
      AuthDebugHelper.logAuthEvent('Attempting sign in', data: {
        'email': email,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = result.user;
      
      // Force notify listeners immediately
      notifyListeners();
      
      AuthDebugHelper.logAuthEvent('Sign in successful', data: {
        'user_email': _user?.email ?? 'unknown',
        'user_id': _user?.uid ?? 'unknown',
      });
      
      return null; // Success
    } on FirebaseAuthException catch (e) {
      AuthDebugHelper.logFirebaseAuthError(e);
      
      // Provide more user-friendly error messages
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-email':
          return 'Invalid email address format.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled.';
        case 'invalid-credential':
          return 'Invalid email or password. Please check your credentials.';
        default:
          return e.message ?? 'Authentication failed';
      }
    } catch (e) {
      AuthDebugHelper.logAuthEvent('Unexpected sign in error', data: {
        'error': e.toString(),
      });
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }

  Future<String?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = result.user;
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'User creation failed';
    } catch (e) {
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Password reset failed';
    } catch (e) {
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }
  
  Future<String?> updatePassword(String newPassword) async {
    try {
      if (_user == null) {
        return 'No user is currently signed in.';
      }
      
      await _user!.updatePassword(newPassword);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'requires-recent-login':
          return 'For security reasons, you need to sign in again before changing your password. Please sign out and sign back in.';
        case 'weak-password':
          return 'Password is too weak. Please choose a stronger password.';
        case 'user-mismatch':
          return 'User authentication mismatch. Please sign in again.';
        case 'user-not-found':
          return 'User not found. Please sign in again.';
        case 'invalid-credential':
          return 'Invalid credentials. Please sign in again.';
        default:
          return 'Password update failed: ${e.message ?? e.code}';
      }
    } catch (e) {
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }
  
  /// Check if user needs re-authentication
  bool get needsReauthentication {
    if (_user == null) return true;
    
    // Check if the user's credentials are still valid
    // Firebase automatically handles this, but we can add additional checks
    return false;
  }
  
  /// Get user email for debugging
  String? get userEmail => _user?.email;
  
  /// Get user ID for debugging
  String? get userId => _user?.uid;
}
