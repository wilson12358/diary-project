import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Service for speech-to-text conversion using AssemblyAI API
class AssemblyAIService {
  static const String _apiKey = '54dc223b6bc341bcad6bdd894928e82f';
  static const String _baseUrl = 'https://api.assemblyai.com/v2';
  static const String _streamingUrl = 'wss://api.assemblyai.com/v2/realtime/ws';
  
  // Stream controllers for events
  final _transcriptionController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _statusController = StreamController<TranscriptionStatus>.broadcast();
  
  // Expose streams
  Stream<String> get onTranscription => _transcriptionController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<TranscriptionStatus> get onStatusChanged => _statusController.stream;
  
  // WebSocket for real-time streaming
  WebSocketChannel? _webSocketChannel;
  bool _isConnected = false;
  
  /// Upload audio file and get transcription (optimized for speed)
  Future<String?> transcribeAudioFile(String filePath) async {
    final startTime = DateTime.now();
    
    try {
      if (kDebugMode) {
        debugPrint('AssemblyAI: Starting fast transcription for file: $filePath');
      }
      
      // Validate file exists and is readable
      final file = File(filePath);
      if (!await file.exists()) {
        final errorMsg = 'Audio file does not exist: $filePath';
        debugPrint('AssemblyAI: $errorMsg');
        _errorController.add(errorMsg);
        _statusController.add(TranscriptionStatus.error);
        return null;
      }
      
      final fileSize = await file.length();
      if (fileSize == 0) {
        final errorMsg = 'Audio file is empty: $filePath';
        debugPrint('AssemblyAI: $errorMsg');
        _errorController.add(errorMsg);
        _statusController.add(TranscriptionStatus.error);
        return null;
      }
      
      if (kDebugMode) {
        debugPrint('AssemblyAI: File validation passed. Size: ${fileSize / 1024} KB');
      }
      
      _statusController.add(TranscriptionStatus.uploading);
      
      // Step 1: Upload the audio file (optimized)
      final uploadUrl = await _uploadAudioFile(filePath);
      if (uploadUrl == null) {
        _errorController.add('Failed to upload audio file - check network connection and API key');
        _statusController.add(TranscriptionStatus.error);
        return null;
      }
      
      final uploadTime = DateTime.now().difference(startTime).inMilliseconds;
      if (kDebugMode) {
        debugPrint('AssemblyAI: File uploaded in ${uploadTime}ms');
      }
      _statusController.add(TranscriptionStatus.processing);
      
      // Step 2: Request transcription (with speed optimizations)
      final transcriptId = await _requestTranscription(uploadUrl);
      if (transcriptId == null) {
        _errorController.add('Failed to request transcription');
        _statusController.add(TranscriptionStatus.error);
        return null;
      }
      
      if (kDebugMode) {
        debugPrint('AssemblyAI: Transcription requested, ID: $transcriptId');
      }
      
      // Step 3: Fast polling for results
      final transcription = await _pollForTranscription(transcriptId);
      if (transcription != null && transcription.trim().isNotEmpty) {
        final totalTime = DateTime.now().difference(startTime).inSeconds;
        _statusController.add(TranscriptionStatus.completed);
        _transcriptionController.add(transcription);
        
        if (kDebugMode) {
          debugPrint('AssemblyAI: Transcription completed in ${totalTime}s');
          debugPrint('AssemblyAI: Final transcription: "${transcription.length > 50 ? transcription.substring(0, 50) + "..." : transcription}"');
        }
      } else {
        _statusController.add(TranscriptionStatus.error);
        
        // Provide more specific error messages
        if (transcription == null) {
          _errorController.add('Transcription failed - check audio quality and try again');
        } else if (transcription.trim().isEmpty) {
          _errorController.add('No speech detected - please speak louder and try again');
        } else {
          _errorController.add('Transcription returned empty result - please try again');
        }
        
        if (kDebugMode) {
          debugPrint('AssemblyAI: Transcription failed - result: "$transcription"');
        }
      }
      
      return transcription;
    } catch (e) {
      debugPrint('AssemblyAI: Error in transcribeAudioFile: $e');
      _errorController.add('Transcription error: ${e.toString()}');
      _statusController.add(TranscriptionStatus.error);
      return null;
    }
  }
  
  /// Upload audio file to AssemblyAI
  Future<String?> _uploadAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('AssemblyAI: File does not exist: $filePath');
        return null;
      }
      
      final bytes = await file.readAsBytes();
      final fileSizeKB = bytes.length / 1024;
      
      if (kDebugMode) {
        debugPrint('AssemblyAI: Uploading file of size: ${fileSizeKB.toStringAsFixed(1)} KB');
      }
      
      // For very large files, consider compression (future enhancement)
      if (fileSizeKB > 5000) { // 5MB threshold
        debugPrint('AssemblyAI: Large file detected, this may take longer to process');
      }
      
      // Check file format compatibility
      final fileExtension = filePath.split('.').last.toLowerCase();
      final supportedFormats = ['m4a', 'mp3', 'wav', 'flac', 'aac'];
      
      if (!supportedFormats.contains(fileExtension)) {
        debugPrint('AssemblyAI: Unsupported file format: $fileExtension');
        _errorController.add('Audio format not supported. Please use M4A, MP3, WAV, FLAC, or AAC.');
        return null;
      }
      
      if (kDebugMode) {
        debugPrint('AssemblyAI: File format: $fileExtension (supported: ${supportedFormats.contains(fileExtension)})');
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/upload'),
        headers: {
          'authorization': _apiKey,
          'content-type': 'application/octet-stream',
        },
        body: bytes,
      ).timeout(const Duration(seconds: 30)); // Add timeout
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final uploadUrl = responseData['upload_url'];
        
        if (kDebugMode) {
          debugPrint('AssemblyAI: Upload successful');
          debugPrint('AssemblyAI: Upload response: $responseData');
          debugPrint('AssemblyAI: Upload URL: $uploadUrl');
        }
        
        if (uploadUrl == null || uploadUrl.toString().isEmpty) {
          debugPrint('AssemblyAI: Upload response missing upload_url');
          return null;
        }
        
        return uploadUrl;
      } else {
        debugPrint('AssemblyAI: Upload failed with status: ${response.statusCode}');
        debugPrint('AssemblyAI: Upload response: ${response.body}');
        
        // Provide specific error messages based on status code
        switch (response.statusCode) {
          case 401:
            debugPrint('AssemblyAI: Unauthorized - check API key');
            break;
          case 413:
            debugPrint('AssemblyAI: File too large');
            break;
          case 429:
            debugPrint('AssemblyAI: Rate limit exceeded');
            break;
          case 500:
            debugPrint('AssemblyAI: Server error - try again later');
            break;
        }
        return null;
      }
    } catch (e) {
      debugPrint('AssemblyAI: Error uploading file: $e');
      return null;
    }
  }
  
  /// Request transcription for uploaded audio
  Future<String?> _requestTranscription(String audioUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transcript'),
        headers: {
          'authorization': _apiKey,
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'audio_url': audioUrl,
          'language_code': 'en', // Default to English
          'punctuate': true,
          'format_text': true,
          'auto_highlights': false,
          'speaker_labels': false,
          'word_boost': [], // No custom vocabulary for speed
          'boost_param': 'default', // Default boost for speed
          'redact_pii': false, // Disable PII redaction for speed
          'filter_profanity': false, // Disable profanity filter for speed
          'dual_channel': false, // Single channel for speed
          'speech_model': 'best', // Use best model for accuracy vs speed balance
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final transcriptId = responseData['id'];
        
        if (kDebugMode) {
          debugPrint('AssemblyAI: Transcription request successful');
          debugPrint('AssemblyAI: Response data: $responseData');
          debugPrint('AssemblyAI: Transcript ID: $transcriptId');
        }
        
        if (transcriptId == null || transcriptId.toString().isEmpty) {
          debugPrint('AssemblyAI: Missing transcript ID in response');
          return null;
        }
        
        return transcriptId;
      } else {
        debugPrint('AssemblyAI: Transcription request failed with status: ${response.statusCode}');
        debugPrint('AssemblyAI: Transcription response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('AssemblyAI: Error requesting transcription: $e');
      return null;
    }
  }
  
  /// Poll for transcription results
  Future<String?> _pollForTranscription(String transcriptId) async {
    const maxAttempts = 120; // 6 minutes maximum with adaptive intervals
    
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      // Adaptive polling: faster initially, then slower
      Duration pollInterval;
      if (attempt < 10) {
        pollInterval = Duration(seconds: 1); // Fast polling for first 10 seconds
      } else if (attempt < 30) {
        pollInterval = Duration(seconds: 2); // Medium polling for next 40 seconds
      } else {
        pollInterval = Duration(seconds: 4); // Slower polling afterwards
      }
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/transcript/$transcriptId'),
          headers: {
            'authorization': _apiKey,
          },
        );
        
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final status = responseData['status'];
          
          if (kDebugMode) {
            debugPrint('AssemblyAI: Polling attempt $attempt, status: $status');
            debugPrint('AssemblyAI: Response keys: ${responseData.keys.toList()}');
            
            // Log the full response for debugging on first attempt
            if (attempt == 0) {
              debugPrint('AssemblyAI: Full response data: $responseData');
            }
          }
          
          switch (status) {
            case 'completed':
              final transcriptionText = responseData['text'] ?? '';
              if (kDebugMode) {
                debugPrint('AssemblyAI: Transcription completed in ${attempt + 1} attempts');
                debugPrint('AssemblyAI: Raw response data: ${responseData.keys.toList()}');
                debugPrint('AssemblyAI: Text field value: "$transcriptionText"');
                debugPrint('AssemblyAI: Text field length: ${transcriptionText.length}');
              }
              
              // Check if transcription is actually empty or just whitespace
              if (transcriptionText.trim().isEmpty) {
                debugPrint('AssemblyAI: Transcription text is empty or only whitespace');
                // Check for alternative text fields
                final alternativeText = responseData['transcript'] ?? 
                                      responseData['transcription'] ?? 
                                      responseData['result'] ?? 
                                      '';
                
                if (alternativeText.isNotEmpty) {
                  debugPrint('AssemblyAI: Found alternative text field: "$alternativeText"');
                  return alternativeText;
                }
                
                debugPrint('AssemblyAI: No transcription text found in any field');
                return null;
              }
              
              return transcriptionText;
            case 'error':
              final errorMessage = responseData['error'] ?? 'Unknown transcription error';
              debugPrint('AssemblyAI: Transcription error: $errorMessage');
              return null;
            case 'processing':
            case 'queued':
              // Continue polling - but don't wait on first few attempts
              if (attempt < 3) {
                continue; // No delay for first 3 attempts
              }
              break;
            default:
              debugPrint('AssemblyAI: Unknown status: $status');
          }
        } else {
          debugPrint('AssemblyAI: Polling failed with status: ${response.statusCode}');
        }
        
        // Wait before next poll (skip delay for first 3 attempts)
        if (attempt >= 3 && attempt < maxAttempts - 1) {
          await Future.delayed(pollInterval);
        }
      } catch (e) {
        debugPrint('AssemblyAI: Error polling transcription: $e');
      }
    }
    
    debugPrint('AssemblyAI: Transcription polling timed out');
    return null;
  }
  
  /// Connect to real-time streaming API (for future use)
  Future<bool> connectRealTimeStreaming() async {
    try {
      if (_isConnected) {
        debugPrint('AssemblyAI: Already connected to streaming');
        return true;
      }
      
      final uri = Uri.parse('$_streamingUrl?token=$_apiKey');
      _webSocketChannel = WebSocketChannel.connect(uri);
      
      // Listen for messages
      _webSocketChannel!.stream.listen(
        (message) {
          _handleStreamingMessage(message);
        },
        onError: (error) {
          debugPrint('AssemblyAI: Streaming error: $error');
          _errorController.add('Streaming error: ${error.toString()}');
          _isConnected = false;
        },
        onDone: () {
          debugPrint('AssemblyAI: Streaming connection closed');
          _isConnected = false;
        },
      );
      
      // Send initial configuration
      _webSocketChannel!.sink.add(jsonEncode({
        'sample_rate': 16000,
        'format_turns': true,
        'language_code': 'en',
      }));
      
      _isConnected = true;
      debugPrint('AssemblyAI: Connected to real-time streaming');
      return true;
    } catch (e) {
      debugPrint('AssemblyAI: Error connecting to streaming: $e');
      _errorController.add('Streaming connection error: ${e.toString()}');
      return false;
    }
  }
  
  /// Send audio data to streaming API
  void streamAudioData(Uint8List audioData) {
    if (_isConnected && _webSocketChannel != null) {
      _webSocketChannel!.sink.add(audioData);
    }
  }
  
  /// Handle streaming messages
  void _handleStreamingMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      
      if (data['message_type'] == 'PartialTranscript') {
        final text = data['text'] ?? '';
        if (text.isNotEmpty) {
          _transcriptionController.add(text);
        }
      } else if (data['message_type'] == 'FinalTranscript') {
        final text = data['text'] ?? '';
        if (text.isNotEmpty) {
          _transcriptionController.add(text);
        }
      } else if (data['message_type'] == 'SessionBegins') {
        debugPrint('AssemblyAI: Streaming session began');
      } else if (data['message_type'] == 'SessionTerminated') {
        debugPrint('AssemblyAI: Streaming session terminated');
        _isConnected = false;
      }
    } catch (e) {
      debugPrint('AssemblyAI: Error handling streaming message: $e');
    }
  }
  
  /// Disconnect from streaming API
  void disconnectRealTimeStreaming() {
    if (_isConnected && _webSocketChannel != null) {
      _webSocketChannel!.sink.close();
      _webSocketChannel = null;
      _isConnected = false;
      debugPrint('AssemblyAI: Disconnected from streaming');
    }
  }
  
  /// Check if streaming is connected
  bool get isStreamingConnected => _isConnected;
  
  /// Get supported languages (basic list, can be expanded)
  static List<String> getSupportedLanguages() {
    return [
      'en', // English
      'es', // Spanish
      'fr', // French
      'de', // German
      'it', // Italian
      'pt', // Portuguese
      'nl', // Dutch
      'ja', // Japanese
      'zh', // Chinese
      'ko', // Korean
      'ar', // Arabic
      'hi', // Hindi
      'ru', // Russian
    ];
  }
  
  /// Test API connection
  Future<bool> testConnection() async {
    try {
      debugPrint('AssemblyAI: Testing API connection...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/transcript'),
        headers: {
          'authorization': _apiKey,
        },
      ).timeout(const Duration(seconds: 10));
      
      if (kDebugMode) {
        debugPrint('AssemblyAI: Connection test - Status: ${response.statusCode}');
      }
      
      // Check for proper authentication and API access
      if (response.statusCode == 401) {
        debugPrint('AssemblyAI: Connection test failed - Invalid API key');
        _errorController.add('Invalid AssemblyAI API key');
        return false;
      } else if (response.statusCode == 403) {
        debugPrint('AssemblyAI: Connection test failed - Access denied');
        _errorController.add('AssemblyAI access denied');
        return false;
      } else if (response.statusCode >= 200 && response.statusCode < 500) {
        debugPrint('AssemblyAI: Connection test successful');
        return true;
      } else {
        debugPrint('AssemblyAI: Connection test failed - Server error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('AssemblyAI: Connection test failed: $e');
      _errorController.add('Network connection failed: ${e.toString()}');
      return false;
    }
  }
  
  /// Dispose resources
  void dispose() {
    disconnectRealTimeStreaming();
    _transcriptionController.close();
    _errorController.close();
    _statusController.close();
  }
}

/// Transcription status enum
enum TranscriptionStatus {
  idle,
  uploading,
  processing,
  completed,
  error,
}

/// Extension to get user-friendly status messages
extension TranscriptionStatusExtension on TranscriptionStatus {
  String get displayName {
    switch (this) {
      case TranscriptionStatus.idle:
        return 'Ready';
      case TranscriptionStatus.uploading:
        return 'Uploading audio...';
      case TranscriptionStatus.processing:
        return 'Processing transcription...';
      case TranscriptionStatus.completed:
        return 'Transcription completed';
      case TranscriptionStatus.error:
        return 'Error occurred';
    }
  }
}
