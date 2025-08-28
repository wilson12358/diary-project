import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

// Only import record package on supported platforms
import 'package:record/record.dart' if (dart.library.js) 'voice_service_web.dart';
import 'assemblyai_service.dart';

class VoiceService {
  AudioRecorder? _audioRecorder;
  bool _isRecording = false;
  String? _recordedFilePath;
  final _amplitudes = <Amplitude>[];
  bool _isSupported = true;

  // AssemblyAI service for speech-to-text
  final _assemblyAIService = AssemblyAIService();

  // Stream controllers for UI updates
  final _recordingStateController = StreamController<bool>.broadcast();
  final _amplitudeController = StreamController<List<Amplitude>>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _transcriptionStatusController = StreamController<TranscriptionStatus>.broadcast();
  final _audioFileReadyController = StreamController<String>.broadcast();

  // Expose streams for UI to listen to
  Stream<bool> get onRecordingStateChanged => _recordingStateController.stream;
  Stream<List<Amplitude>> get onAmplitudeChanged => _amplitudeController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<TranscriptionStatus> get onTranscriptionStatusChanged => _transcriptionStatusController.stream;
  Stream<String> get onAudioFileReady => _audioFileReadyController.stream;

  bool get isRecording => _isRecording;
  String? get recordedFilePath => _recordedFilePath;
  
  // Get current audio file with validation
  Future<File?> getCurrentAudioFile() async {
    if (_recordedFilePath != null) {
      final file = File(_recordedFilePath!);
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize > 0) {
          return file;
        }
      }
    }
    return null;
  }
  
  // Expose AssemblyAI service for direct access
  AssemblyAIService get assemblyAIService => _assemblyAIService;

  // Initialize the recorder
  Future<void> initialize() async {
    try {
      // Check if platform is Linux
      if (defaultTargetPlatform == TargetPlatform.linux) {
        _isSupported = false;
        _errorController.add('Voice recording is not supported on Linux');
        return;
      }
      
      // Initialize recorder
      _audioRecorder = AudioRecorder();
      
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        _errorController.add('Microphone permission denied');
        return;
      }
      
      // Check encoder support
      if (!await _audioRecorder!.isEncoderSupported(AudioEncoder.aacLc)) {
        _errorController.add('AAC encoder not supported on this device');
        _isSupported = false;
      }
      
      // Initialize AssemblyAI service listeners
      _setupAssemblyAIListeners();
      
      // Test AssemblyAI connection
      final connectionOk = await _assemblyAIService.testConnection();
      if (!connectionOk) {
        debugPrint('Warning: AssemblyAI connection test failed');
      } else {
        debugPrint('AssemblyAI connection test successful');
      }
    } catch (e) {
      _isSupported = false;
      _errorController.add('Error initializing recorder: $e');
    }
  }

  // Start recording
  Future<void> startRecording() async {
    try {
      // Check if recording is supported on this platform
      if (!_isSupported || _audioRecorder == null) {
        _errorController.add('Voice recording is not supported on this platform');
        return;
      }
      
      if (await _audioRecorder!.hasPermission()) {
        // Prepare recording path - use documents directory for more permanent storage
        final documentsDir = await getApplicationDocumentsDirectory();
        final voiceNotesDir = Directory('${documentsDir.path}/voice_notes');
        
        // Create voice notes directory if it doesn't exist
        if (!await voiceNotesDir.exists()) {
          await voiceNotesDir.create(recursive: true);
        }
        
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final filePath = '${voiceNotesDir.path}/voice_note_$timestamp.m4a';
        _recordedFilePath = filePath;

        if (kDebugMode) {
          debugPrint('VoiceService: Recording to path: $filePath');
        }

        // Configure recording for optimal transcription speed
        await _audioRecorder!.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc, // AAC-LC format (fastest for AssemblyAI)
            bitRate: 64000, // Reduced bitrate for faster upload (still good quality)
            sampleRate: 16000, // 16 kHz optimal for speech recognition
          ),
          path: filePath,
        );
        
        // Start amplitude updates
        _startAmplitudeUpdates();
        
        _amplitudes.clear();
        _isRecording = true;
        _recordingStateController.add(_isRecording);
      } else {
        _errorController.add('Microphone permission not granted');
      }
    } catch (e) {
      _errorController.add('Error starting recording: $e');
    }
  }

  // Stop recording
  Future<String?> stopRecording() async {
    try {
      // Check if recording is supported on this platform
      if (!_isSupported || _audioRecorder == null) {
        return null;
      }
      
      _stopAmplitudeUpdates();
      final path = await _audioRecorder!.stop();
      _isRecording = false;
      _recordingStateController.add(_isRecording);
      
      // Start transcription with AssemblyAI if we have a recording
      if (path != null && path.isNotEmpty) {
        _recordedFilePath = path;
        debugPrint('VoiceService: Starting transcription for: $path');
        _startTranscription(path);
        
        // Validate the audio file before notifying
        final audioFile = File(path);
        if (kDebugMode) {
          debugPrint('VoiceService: Validating recorded audio file...');
          debugPrint('VoiceService: File path: $path');
          debugPrint('VoiceService: File exists: ${await audioFile.exists()}');
          if (await audioFile.exists()) {
            final fileSize = await audioFile.length();
            debugPrint('VoiceService: File size: ${fileSize / 1024} KB');
            debugPrint('VoiceService: File absolute path: ${audioFile.absolute.path}');
          }
        }
        
        if (await audioFile.exists()) {
          final fileSize = await audioFile.length();
          if (fileSize > 0) {
            if (kDebugMode) {
              debugPrint('VoiceService: ✅ Audio file ready: $path (${fileSize / 1024} KB)');
              debugPrint('VoiceService: Notifying NewEntryScreen about ready audio file...');
            }
            // Notify that audio file is ready for saving
            _audioFileReadyController.add(path);
            if (kDebugMode) {
              debugPrint('VoiceService: ✅ Audio file notification sent successfully');
            }
          } else {
            debugPrint('VoiceService: ❌ Audio file is empty: $path');
            _errorController.add('Recording failed - audio file is empty');
          }
        } else {
          debugPrint('VoiceService: ❌ Audio file not found: $path');
          debugPrint('VoiceService: File path issue detected');
          _errorController.add('Recording failed - audio file not found');
        }
      }
      
      return path;
    } catch (e) {
      _errorController.add('Error stopping recording: $e');
      return null;
    }
  }

  // Cancel recording
  Future<void> cancelRecording() async {
    try {
      // Check if recording is supported on this platform
      if (!_isSupported || _audioRecorder == null) {
        return;
      }
      
      _stopAmplitudeUpdates();
      await _audioRecorder!.stop();
      _isRecording = false;
      _recordingStateController.add(_isRecording);
      
      // Delete the file if it exists
      if (_recordedFilePath != null) {
        final file = File(_recordedFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
        _recordedFilePath = null;
      }
    } catch (e) {
      _errorController.add('Error canceling recording: $e');
    }
  }
  
  // Timer for amplitude updates
  Timer? _amplitudeTimer;
  
  // Start amplitude updates
  void _startAmplitudeUpdates() {
    // Check if recording is supported on this platform
    if (!_isSupported || _audioRecorder == null) {
      return;
    }
    
    _amplitudes.clear();
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (_isRecording) {
        try {
          final amplitude = await _audioRecorder!.getAmplitude();
          _amplitudes.add(amplitude);
          
          // Keep only the last 5 amplitude values
          if (_amplitudes.length > 5) {
            _amplitudes.removeRange(0, _amplitudes.length - 5);
          }
          
          _amplitudeController.add(List.from(_amplitudes));
        } catch (e) {
          // Ignore amplitude errors
        }
      }
    });
  }
  
  // Stop amplitude updates
  void _stopAmplitudeUpdates() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
  }

  // Setup AssemblyAI service listeners
  void _setupAssemblyAIListeners() {
    // Listen to AssemblyAI errors
    _assemblyAIService.onError.listen((error) {
      debugPrint('VoiceService: AssemblyAI error: $error');
      _errorController.add('Transcription error: $error');
    });
    
    // Listen to AssemblyAI status changes
    _assemblyAIService.onStatusChanged.listen((status) {
      debugPrint('VoiceService: Transcription status: ${status.displayName}');
      _transcriptionStatusController.add(status);
    });
    
    // Note: Transcription results are now handled directly by the VoiceRecorderButton
    // to avoid duplicate forwarding and double transcription display
  }
  
  // Start transcription with AssemblyAI
  void _startTranscription(String audioFilePath) async {
    try {
      debugPrint('VoiceService: Starting AssemblyAI transcription');
      
      // Test connection first
      final connectionTest = await _assemblyAIService.testConnection();
      if (!connectionTest) {
        _errorController.add('No internet connection or AssemblyAI service unavailable');
        return;
      }
      
      await _assemblyAIService.transcribeAudioFile(audioFilePath);
    } catch (e) {
      debugPrint('VoiceService: Error starting transcription: $e');
      _errorController.add('Failed to start transcription: ${e.toString()}');
    }
  }
  
  // Manually transcribe an audio file
  Future<String?> transcribeAudioFile(String filePath) async {
    try {
      debugPrint('VoiceService: Manual transcription request for: $filePath');
      return await _assemblyAIService.transcribeAudioFile(filePath);
    } catch (e) {
      debugPrint('VoiceService: Error in manual transcription: $e');
      _errorController.add('Transcription failed: ${e.toString()}');
      return null;
    }
  }
  
  // Get last transcription status
  TranscriptionStatus get transcriptionStatus => TranscriptionStatus.idle;
  
  // Test AssemblyAI connection
  Future<bool> testAssemblyAIConnection() async {
    return await _assemblyAIService.testConnection();
  }

  // Dispose resources
  void dispose() {
    _stopAmplitudeUpdates();
    _recordingStateController.close();
    _amplitudeController.close();
    _errorController.close();
    _transcriptionStatusController.close();
    _audioFileReadyController.close();
    _assemblyAIService.dispose();
    _audioRecorder?.dispose();
  }
}