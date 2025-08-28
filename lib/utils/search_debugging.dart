import 'package:flutter/foundation.dart';

/// Debugging utilities for search functionality
class SearchDebugging {
  static bool _debugMode = kDebugMode;
  
  /// Enable or disable debug mode
  static void setDebugMode(bool enabled) {
    _debugMode = enabled;
  }
  
  /// Log search operations for debugging
  static void logSearchOperation(String operation, Map<String, dynamic> data) {
    if (_debugMode) {
      print('SEARCH DEBUG: $operation');
      data.forEach((key, value) {
        print('  $key: $value');
      });
    }
  }
  
  /// Log search errors
  static void logSearchError(String operation, dynamic error, [StackTrace? stackTrace]) {
    if (_debugMode) {
      print('SEARCH ERROR in $operation: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
  }
  
  /// Log search performance metrics
  static void logPerformanceMetric(String operation, Duration duration, {Map<String, dynamic>? metadata}) {
    if (_debugMode) {
      print('SEARCH PERFORMANCE: $operation took ${duration.inMilliseconds}ms');
      if (metadata != null) {
        metadata.forEach((key, value) {
          print('  $key: $value');
        });
      }
    }
  }
  
  /// Log cache operations
  static void logCacheOperation(String operation, String cacheKey, {dynamic data}) {
    if (_debugMode) {
      print('SEARCH CACHE: $operation for key: $cacheKey');
      if (data != null) {
        print('  Data: $data');
      }
    }
  }
}

/// Common search error types and their solutions
class SearchErrorHelper {
  /// Get solution for common search errors
  static String getSolution(String errorMessage) {
    if (errorMessage.contains('Cannot add new events after calling close')) {
      return '''
SOLUTION: StreamController or similar resource was disposed while still being used.
- Ensure all async operations check if the widget is still mounted
- Properly dispose of resources in the dispose() method
- Use try-catch blocks around async operations
- Consider using late initialization for services
      ''';
    }
    
    if (errorMessage.contains('Bad state')) {
      return '''
SOLUTION: Resource was used in an invalid state.
- Check if resources are properly initialized before use
- Ensure proper error handling in async operations
- Verify widget lifecycle management
      ''';
    }
    
    if (errorMessage.contains('Null check operator')) {
      return '''
SOLUTION: Null value was accessed with ! operator.
- Add null checks before using ! operator
- Use null-aware operators (?.) where appropriate
- Ensure proper initialization of nullable variables
      ''';
    }
    
    return 'No specific solution found for this error. Check general debugging steps.';
  }
  
  /// General debugging steps for search issues
  static List<String> getGeneralDebuggingSteps() {
    return [
      '1. Check if widget is mounted before setState calls',
      '2. Ensure proper disposal of resources in dispose() method',
      '3. Use try-catch blocks around async operations',
      '4. Verify proper initialization of services and controllers',
      '5. Check for memory leaks and resource cleanup',
      '6. Enable debug logging to trace the issue',
      '7. Test with different search scenarios',
      '8. Verify network connectivity and permissions',
    ];
  }
}
