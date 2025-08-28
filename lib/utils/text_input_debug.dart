import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Debug utility for text input issues
class TextInputDebug {
  static bool _debugEnabled = kDebugMode;
  
  /// Enable or disable debug logging
  static void setDebugMode(bool enabled) {
    _debugEnabled = enabled;
  }
  
  /// Log text input events
  static void logTextEvent(String event, {Map<String, dynamic>? data}) {
    if (_debugEnabled) {
      debugPrint('TEXT INPUT DEBUG: $event');
      if (data != null) {
        data.forEach((key, value) {
          debugPrint('  $key: $value');
        });
      }
    }
  }
  
  /// Check if text input is working
  static void checkTextInputConfiguration() {
    if (_debugEnabled) {
      debugPrint('=== TEXT INPUT CONFIGURATION ===');
      
      // Check platform text input
      try {
        final textInputPlugin = ServicesBinding.instance.defaultBinaryMessenger;
        debugPrint('✅ ServicesBinding available: ${textInputPlugin != null}');
      } catch (e) {
        debugPrint('❌ ServicesBinding error: $e');
      }
      
      // Check if we're in a valid Flutter context
      try {
        final binding = WidgetsBinding.instance;
        debugPrint('✅ WidgetsBinding available: ${binding != null}');
        debugPrint('   Build owner: ${binding.buildOwner != null}');
        debugPrint('   Focus manager: ${binding.focusManager != null}');
      } catch (e) {
        debugPrint('❌ WidgetsBinding error: $e');
      }
      
      debugPrint('================================');
    }
  }
  
  /// Monitor text controller
  static void monitorTextController(String name, TextEditingController controller) {
    if (_debugEnabled) {
      debugPrint('MONITORING TEXT CONTROLLER: $name');
      debugPrint('  Initial text: "${controller.text}"');
      debugPrint('  Text length: ${controller.text.length}');
      debugPrint('  Selection: ${controller.selection}');
      
      controller.addListener(() {
        debugPrint('$name TEXT CHANGED:');
        debugPrint('  New text: "${controller.text}"');
        debugPrint('  Length: ${controller.text.length}');
        debugPrint('  Selection: ${controller.selection}');
      });
    }
  }
  
  /// Test text field interaction
  static void testTextFieldInteraction(String fieldName) {
    logTextEvent('Field interaction test', data: {
      'field_name': fieldName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Log focus events
  static void logFocusEvent(String fieldName, bool hasFocus) {
    logTextEvent('Focus changed', data: {
      'field_name': fieldName,
      'has_focus': hasFocus,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Log text changes
  static void logTextChange(String fieldName, String oldText, String newText) {
    logTextEvent('Text changed', data: {
      'field_name': fieldName,
      'old_text': oldText,
      'new_text': newText,
      'old_length': oldText.length,
      'new_length': newText.length,
      'change_size': newText.length - oldText.length,
    });
  }
  
  /// Check for common text input blocking issues
  static List<String> diagnosePotentialIssues() {
    final issues = <String>[];
    
    if (_debugEnabled) {
      debugPrint('=== DIAGNOSING TEXT INPUT ISSUES ===');
      
      // Check for common problems
      try {
        final binding = WidgetsBinding.instance;
        
        if (binding.focusManager.primaryFocus == null) {
          issues.add('No primary focus available');
          debugPrint('❌ No primary focus');
        } else {
          debugPrint('✅ Primary focus available');
        }
        
        if (binding.buildOwner == null) {
          issues.add('Build owner is null');
          debugPrint('❌ Build owner is null');
        } else {
          debugPrint('✅ Build owner available');
        }
        
      } catch (e) {
        issues.add('Error checking Flutter bindings: $e');
        debugPrint('❌ Bindings error: $e');
      }
      
      debugPrint('=====================================');
    }
    
    return issues;
  }
  
  /// Run comprehensive text input diagnostics
  static Map<String, dynamic> runFullDiagnostics() {
    debugPrint('🔍 Starting Text Input Diagnostics...\n');
    
    final results = <String, dynamic>{};
    
    // Test 1: Configuration check
    checkTextInputConfiguration();
    
    // Test 2: Issue diagnosis
    final issues = diagnosePotentialIssues();
    results['issues'] = issues;
    
    // Test 3: Platform info
    results['platform'] = {
      'is_debug': kDebugMode,
      'is_release': kReleaseMode,
      'is_profile': kProfileMode,
      'platform': defaultTargetPlatform.toString(),
    };
    
    // Summary
    debugPrint('=== TEXT INPUT DIAGNOSTICS SUMMARY ===');
    if (issues.isEmpty) {
      debugPrint('✅ No obvious issues detected');
    } else {
      debugPrint('❌ Potential issues found:');
      for (final issue in issues) {
        debugPrint('  - $issue');
      }
    }
    
    debugPrint('\n📱 Manual testing recommendations:');
    debugPrint('  1. Tap on title field and try typing');
    debugPrint('  2. Tap on content field and try typing');
    debugPrint('  3. Check console for "Text field tapped" messages');
    debugPrint('  4. Check console for "Text changed" messages');
    debugPrint('  5. Try voice recording and check transcription');
    
    return results;
  }
  
  /// Simple text input test
  static void simpleTextTest() {
    debugPrint('=== SIMPLE TEXT INPUT TEST ===');
    debugPrint('If you can see this message, debug logging is working.');
    debugPrint('Now try typing in the text fields and watch for messages.');
    debugPrint('Expected messages:');
    debugPrint('  - "Text field tapped - focus gained"');
    debugPrint('  - "Text changed: X characters"');
    debugPrint('===============================');
  }
}
