import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Helper class for debugging authentication issues
class AuthDebugHelper {
  static bool _debugEnabled = kDebugMode;
  
  /// Enable or disable debug logging
  static void setDebugMode(bool enabled) {
    _debugEnabled = enabled;
  }
  
  /// Log authentication events
  static void logAuthEvent(String event, {Map<String, dynamic>? data}) {
    if (_debugEnabled) {
      debugPrint('AUTH DEBUG: $event');
      if (data != null) {
        data.forEach((key, value) {
          debugPrint('  $key: $value');
        });
      }
    }
  }
  
  /// Log Firebase Auth errors with detailed information
  static void logFirebaseAuthError(FirebaseAuthException error) {
    if (_debugEnabled) {
      debugPrint('FIREBASE AUTH ERROR:');
      debugPrint('  Code: ${error.code}');
      debugPrint('  Message: ${error.message}');
      debugPrint('  Plugin: ${error.plugin}');
      if (error.stackTrace != null) {
        debugPrint('  Stack trace: ${error.stackTrace}');
      }
    }
  }
  
  /// Check Firebase Auth configuration
  static void checkAuthConfiguration() {
    if (_debugEnabled) {
      debugPrint('AUTH CONFIG CHECK:');
      final auth = FirebaseAuth.instance;
      debugPrint('  Current user: ${auth.currentUser?.email ?? 'null'}');
      debugPrint('  App name: ${auth.app.name}');
      debugPrint('  Auth domain: ${auth.app.options.authDomain}');
      debugPrint('  Project ID: ${auth.app.options.projectId}');
    }
  }
  
  /// Log user state information
  static void logUserState(User? user) {
    if (_debugEnabled) {
      debugPrint('USER STATE:');
      if (user != null) {
        debugPrint('  Email: ${user.email}');
        debugPrint('  UID: ${user.uid}');
        debugPrint('  Email verified: ${user.emailVerified}');
        debugPrint('  Display name: ${user.displayName ?? 'null'}');
        debugPrint('  Provider data: ${user.providerData.map((p) => p.providerId).join(', ')}');
      } else {
        debugPrint('  User is null (not signed in)');
      }
    }
  }
  
  /// Get common authentication error solutions
  static String getErrorSolution(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return '''
SOLUTION: User account doesn't exist
- Check if the email address is correct
- Try creating a new account if you don't have one
- Check if the user was deleted from Firebase Console
        ''';
        
      case 'wrong-password':
        return '''
SOLUTION: Incorrect password
- Double-check password spelling and case sensitivity
- Try using password reset if you forgot your password
- Check for extra spaces in the password field
        ''';
        
      case 'invalid-email':
        return '''
SOLUTION: Invalid email format
- Check email format (should contain @ and valid domain)
- Remove any extra spaces before/after email
- Ensure email doesn't contain invalid characters
        ''';
        
      case 'too-many-requests':
        return '''
SOLUTION: Too many failed login attempts
- Wait 15-30 minutes before trying again
- Use password reset if you're unsure of the password
- Check Firebase Auth quotas in console
        ''';
        
      case 'network-request-failed':
        return '''
SOLUTION: Network connectivity issue
- Check internet connection
- Try switching between WiFi and mobile data
- Check if Firebase services are accessible
        ''';
        
      case 'operation-not-allowed':
        return '''
SOLUTION: Authentication method not enabled
- Enable Email/Password authentication in Firebase Console
- Check Firebase project configuration
- Verify auth domain settings
        ''';
        
      default:
        return 'No specific solution found. Check Firebase Auth documentation.';
    }
  }
  
  /// Perform comprehensive auth diagnostics
  static void performAuthDiagnostics() {
    if (_debugEnabled) {
      debugPrint('=== AUTH DIAGNOSTICS ===');
      checkAuthConfiguration();
      logUserState(FirebaseAuth.instance.currentUser);
      debugPrint('========================');
    }
  }
}
