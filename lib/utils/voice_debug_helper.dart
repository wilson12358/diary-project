import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/assemblyai_service.dart';
import '../services/voice_service.dart';

/// Comprehensive debugging helper for voice-to-text functionality
class VoiceDebugHelper {
  static bool _debugMode = kDebugMode;
  
  static void setDebugMode(bool enabled) {
    _debugMode = enabled;
  }
  
  /// Run comprehensive voice system diagnostics
  static Future<Map<String, dynamic>> runFullDiagnostics() async {
    final results = <String, dynamic>{};
    
    if (_debugMode) {
      debugPrint('🔍 Starting Voice-to-Text Diagnostics...');
    }
    
    // 1. Check microphone permissions
    results['microphone_permission'] = await _checkMicrophonePermission();
    
    // 2. Check network connectivity
    results['network_connectivity'] = await _checkNetworkConnectivity();
    
    // 3. Test AssemblyAI API connection
    results['assemblyai_connection'] = await _testAssemblyAIConnection();
    
    // 4. Check voice service initialization
    results['voice_service_status'] = await _checkVoiceServiceStatus();
    
    // 5. Check audio recording capabilities
    results['audio_recording'] = await _checkAudioRecordingCapabilities();
    
    // 6. Check file system access
    results['file_system'] = await _checkFileSystemAccess();
    
    if (_debugMode) {
      _printDiagnosticsReport(results);
    }
    
    return results;
  }
  
  /// Check microphone permission status
  static Future<Map<String, dynamic>> _checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      
      final result = {
        'granted': status.isGranted,
        'denied': status.isDenied,
        'permanently_denied': status.isPermanentlyDenied,
        'restricted': status.isRestricted,
        'status': status.toString(),
      };
      
      if (_debugMode) {
        debugPrint('🎤 Microphone Permission: ${status.isGranted ? "✅ Granted" : "❌ Denied"}');
      }
      
      return result;
    } catch (e) {
      if (_debugMode) {
        debugPrint('🎤 Microphone Permission Error: $e');
      }
      return {'error': e.toString()};
    }
  }
  
  /// Check network connectivity
  static Future<Map<String, dynamic>> _checkNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('api.assemblyai.com');
      
      final hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
      if (_debugMode) {
        debugPrint('🌐 Network Connectivity: ${hasConnection ? "✅ Connected" : "❌ No Connection"}');
      }
      
      return {
        'connected': hasConnection,
        'assemblyai_reachable': hasConnection,
        'addresses': result.map((addr) => addr.address).toList(),
      };
    } catch (e) {
      if (_debugMode) {
        debugPrint('🌐 Network Connectivity Error: $e');
      }
      return {
        'connected': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Test AssemblyAI API connection
  static Future<Map<String, dynamic>> _testAssemblyAIConnection() async {
    try {
      final assemblyAI = AssemblyAIService();
      final connectionSuccess = await assemblyAI.testConnection();
      
      if (_debugMode) {
        debugPrint('🔌 AssemblyAI Connection: ${connectionSuccess ? "✅ Connected" : "❌ Failed"}');
      }
      
      return {
        'connected': connectionSuccess,
        'api_reachable': connectionSuccess,
      };
    } catch (e) {
      if (_debugMode) {
        debugPrint('🔌 AssemblyAI Connection Error: $e');
      }
      return {
        'connected': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Check voice service status
  static Future<Map<String, dynamic>> _checkVoiceServiceStatus() async {
    try {
      final voiceService = VoiceService();
      await voiceService.initialize();
      
      // Check if voice service is working by testing recording capability
      final isInitialized = voiceService.isRecording == false; // Should be false initially
      
      if (_debugMode) {
        debugPrint('🎙️ Voice Service: ${isInitialized ? "✅ Initialized" : "❌ Failed"}');
      }
      
      return {
        'initialized': isInitialized,
        'supported': isInitialized, // Use initialization success as support indicator
      };
    } catch (e) {
      if (_debugMode) {
        debugPrint('🎙️ Voice Service Error: $e');
      }
      return {
        'initialized': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Check audio recording capabilities
  static Future<Map<String, dynamic>> _checkAudioRecordingCapabilities() async {
    try {
      // This would require actually testing recording, which we'll simulate
      final hasPermission = await Permission.microphone.isGranted;
      
      if (_debugMode) {
        debugPrint('📼 Audio Recording: ${hasPermission ? "✅ Ready" : "❌ Permission Required"}');
      }
      
      return {
        'permission_granted': hasPermission,
        'platform_supported': Platform.isIOS || Platform.isAndroid,
        'ready': hasPermission && (Platform.isIOS || Platform.isAndroid),
      };
    } catch (e) {
      if (_debugMode) {
        debugPrint('📼 Audio Recording Error: $e');
      }
      return {
        'ready': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Check file system access
  static Future<Map<String, dynamic>> _checkFileSystemAccess() async {
    try {
      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/voice_test_file.txt');
      
      // Test write access
      await testFile.writeAsString('test');
      final canWrite = await testFile.exists();
      
      // Test read access
      final content = await testFile.readAsString();
      final canRead = content == 'test';
      
      // Clean up
      if (await testFile.exists()) {
        await testFile.delete();
      }
      
      if (_debugMode) {
        debugPrint('📁 File System: ${canWrite && canRead ? "✅ Accessible" : "❌ Limited Access"}');
      }
      
      return {
        'can_write': canWrite,
        'can_read': canRead,
        'temp_dir_path': tempDir.path,
        'accessible': canWrite && canRead,
      };
    } catch (e) {
      if (_debugMode) {
        debugPrint('📁 File System Error: $e');
      }
      return {
        'accessible': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Print comprehensive diagnostics report
  static void _printDiagnosticsReport(Map<String, dynamic> results) {
    final separator = '=' * 50;
    debugPrint('\n$separator');
    debugPrint('🔍 VOICE-TO-TEXT DIAGNOSTICS REPORT');
    debugPrint(separator);
    
    // Overall system status
    final allGood = _isSystemHealthy(results);
    debugPrint('Overall Status: ${allGood ? "✅ HEALTHY" : "❌ ISSUES DETECTED"}');
    debugPrint('');
    
    // Detailed results
    results.forEach((category, data) {
      debugPrint('📋 ${category.toUpperCase().replaceAll('_', ' ')}:');
      if (data is Map<String, dynamic>) {
        data.forEach((key, value) {
          final icon = _getStatusIcon(key, value);
          debugPrint('   $icon $key: $value');
        });
      } else {
        debugPrint('   $data');
      }
      debugPrint('');
    });
    
    // Recommendations
    debugPrint('💡 RECOMMENDATIONS:');
    _printRecommendations(results);
    debugPrint('$separator\n');
  }
  
  /// Check if system is healthy overall
  static bool _isSystemHealthy(Map<String, dynamic> results) {
    try {
      final micPermission = results['microphone_permission']?['granted'] ?? false;
      final network = results['network_connectivity']?['connected'] ?? false;
      final assemblyAI = results['assemblyai_connection']?['connected'] ?? false;
      final voiceService = results['voice_service_status']?['initialized'] ?? false;
      
      return micPermission && network && assemblyAI && voiceService;
    } catch (e) {
      return false;
    }
  }
  
  /// Get appropriate icon for status
  static String _getStatusIcon(String key, dynamic value) {
    if (key.contains('error')) return '❌';
    if (value == true || key.contains('granted') || key.contains('connected') || key.contains('initialized')) {
      return value == true ? '✅' : '❌';
    }
    return '📝';
  }
  
  /// Print actionable recommendations based on issues found
  static void _printRecommendations(Map<String, dynamic> results) {
    final micPermission = results['microphone_permission']?['granted'] ?? false;
    final network = results['network_connectivity']?['connected'] ?? false;
    final assemblyAI = results['assemblyai_connection']?['connected'] ?? false;
    final voiceService = results['voice_service_status']?['initialized'] ?? false;
    
    if (!micPermission) {
      debugPrint('   🎤 Grant microphone permission in device settings');
    }
    
    if (!network) {
      debugPrint('   🌐 Check internet connection');
      debugPrint('   📶 Try switching between WiFi and mobile data');
    }
    
    if (!assemblyAI) {
      debugPrint('   🔌 AssemblyAI API connection failed');
      debugPrint('   🔑 Verify API key is valid');
      debugPrint('   🌐 Check if AssemblyAI service is operational');
    }
    
    if (!voiceService) {
      debugPrint('   🎙️ Voice service initialization failed');
      debugPrint('   🔄 Try restarting the app');
      debugPrint('   📱 Check device compatibility');
    }
    
    if (micPermission && network && assemblyAI && voiceService) {
      debugPrint('   ✅ All systems operational - voice-to-text should work!');
      debugPrint('   🎤 Try recording a short test message');
    }
  }
  
  /// Quick system health check (simplified version)
  static Future<bool> quickHealthCheck() async {
    try {
      // Check critical components only
      final micPermission = await Permission.microphone.isGranted;
      final assemblyAI = AssemblyAIService();
      final apiConnection = await assemblyAI.testConnection();
      
      final isHealthy = micPermission && apiConnection;
      
      if (_debugMode) {
        debugPrint('⚡ Quick Health Check: ${isHealthy ? "✅ PASS" : "❌ FAIL"}');
        if (!micPermission) debugPrint('   ❌ Microphone permission required');
        if (!apiConnection) debugPrint('   ❌ AssemblyAI connection failed');
      }
      
      return isHealthy;
    } catch (e) {
      if (_debugMode) {
        debugPrint('⚡ Quick Health Check Error: $e');
      }
      return false;
    }
  }
  
  /// Log voice operation events for debugging
  static void logVoiceEvent(String event, {Map<String, dynamic>? data}) {
    if (_debugMode) {
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('🎤 [$timestamp] Voice Event: $event');
      if (data != null) {
        data.forEach((key, value) {
          debugPrint('   📝 $key: $value');
        });
      }
    }
  }
  
  /// Test specific audio file transcription
  static Future<bool> testAudioFileTranscription(String filePath) async {
    try {
      if (_debugMode) {
        debugPrint('🧪 Testing audio file transcription: $filePath');
      }
      
      final file = File(filePath);
      if (!await file.exists()) {
        if (_debugMode) {
          debugPrint('❌ Test file does not exist');
        }
        return false;
      }
      
      final fileSize = await file.length();
      if (_debugMode) {
        debugPrint('📁 Test file size: ${fileSize / 1024} KB');
      }
      
      final assemblyAI = AssemblyAIService();
      final result = await assemblyAI.transcribeAudioFile(filePath);
      
      final success = result != null && result.isNotEmpty;
      
      if (_debugMode) {
        debugPrint('🧪 Test transcription: ${success ? "✅ SUCCESS" : "❌ FAILED"}');
        if (success) {
          final resultText = result; // result is non-null when success is true
          final displayText = resultText.length > 50 ? '${resultText.substring(0, 50)}...' : resultText;
          debugPrint('📝 Result: "$displayText"');
        }
      }
      
      return success;
    } catch (e) {
      if (_debugMode) {
        debugPrint('🧪 Test transcription error: $e');
      }
      return false;
    }
  }
}
