import 'package:flutter/foundation.dart';
import '../services/assemblyai_service.dart';

/// Simple test utilities for AssemblyAI integration
class AssemblyAITest {
  static final _service = AssemblyAIService();
  
  /// Test the AssemblyAI connection
  static Future<bool> testConnection() async {
    debugPrint('=== AssemblyAI Connection Test ===');
    
    try {
      final isConnected = await _service.testConnection();
      
      if (isConnected) {
        debugPrint('✅ AssemblyAI connection successful');
        debugPrint('   API key is valid and service is reachable');
        return true;
      } else {
        debugPrint('❌ AssemblyAI connection failed');
        debugPrint('   Check API key and network connectivity');
        return false;
      }
    } catch (e) {
      debugPrint('❌ AssemblyAI connection error: $e');
      return false;
    }
  }
  
  /// Test transcription with a sample audio file (if available)
  static Future<String?> testTranscription(String audioFilePath) async {
    debugPrint('=== AssemblyAI Transcription Test ===');
    debugPrint('Testing with file: $audioFilePath');
    
    try {
      // Listen to status updates
      _service.onStatusChanged.listen((status) {
        debugPrint('Status: ${status.displayName}');
      });
      
      // Listen to errors
      _service.onError.listen((error) {
        debugPrint('Error: $error');
      });
      
      // Start transcription
      final result = await _service.transcribeAudioFile(audioFilePath);
      
      if (result != null && result.isNotEmpty) {
        debugPrint('✅ Transcription successful');
        debugPrint('   Result: $result');
        return result;
      } else {
        debugPrint('❌ Transcription failed or returned empty');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Transcription error: $e');
      return null;
    }
  }
  
  /// Get supported languages
  static void printSupportedLanguages() {
    debugPrint('=== AssemblyAI Supported Languages ===');
    final languages = AssemblyAIService.getSupportedLanguages();
    
    for (final lang in languages) {
      debugPrint('  - $lang');
    }
    
    debugPrint('Total: ${languages.length} languages supported');
  }
  
  /// Run all tests
  static Future<Map<String, bool>> runAllTests() async {
    final results = <String, bool>{};
    
    debugPrint('🚀 Starting AssemblyAI Integration Tests...\n');
    
    // Test 1: Connection
    results['connection'] = await testConnection();
    debugPrint('');
    
    // Test 2: Supported languages
    printSupportedLanguages();
    debugPrint('');
    
    // Summary
    debugPrint('=== Test Summary ===');
    results.forEach((test, passed) {
      final icon = passed ? '✅' : '❌';
      debugPrint('$icon $test: ${passed ? 'PASSED' : 'FAILED'}');
    });
    
    final totalTests = results.length;
    final passedTests = results.values.where((v) => v).length;
    debugPrint('\nOverall: $passedTests/$totalTests tests passed');
    
    return results;
  }
  
  /// Dispose the test service
  static void dispose() {
    _service.dispose();
  }
}
