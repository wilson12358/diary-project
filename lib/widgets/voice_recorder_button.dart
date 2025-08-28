import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import '../services/voice_service.dart';
import '../services/assemblyai_service.dart';

class VoiceRecorderButton extends StatefulWidget {
  final Function(String) onRecordingComplete;
  final Function(String)? onTranscriptionComplete;
  final VoiceService voiceService;

  const VoiceRecorderButton({
    Key? key,
    required this.onRecordingComplete,
    this.onTranscriptionComplete,
    required this.voiceService,
  }) : super(key: key);

  @override
  _VoiceRecorderButtonState createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton> with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _isInitialized = false;
  List<Amplitude> _amplitudes = [];
  late AnimationController _animationController;
  String? _errorMessage;
  TranscriptionStatus _transcriptionStatus = TranscriptionStatus.idle;
  
  // Stream subscriptions for proper disposal
  late StreamSubscription<bool> _recordingStateSubscription;
  late StreamSubscription<List<Amplitude>> _amplitudeSubscription;
  late StreamSubscription<String> _errorSubscription;
  late StreamSubscription<String> _transcriptionSubscription;
  late StreamSubscription<TranscriptionStatus> _transcriptionStatusSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _initializeRecorder();

    // Listen to recording state changes with proper subscription management
    _recordingStateSubscription = widget.voiceService.onRecordingStateChanged.listen((isRecording) {
      if (mounted) {
        setState(() {
          _isRecording = isRecording;
        });
      }
    });

    // Listen to amplitude changes with proper subscription management
    _amplitudeSubscription = widget.voiceService.onAmplitudeChanged.listen((amplitudes) {
      if (mounted) {
        setState(() {
          _amplitudes = amplitudes;
        });
      }
    });

    // Listen to errors with proper subscription management
    _errorSubscription = widget.voiceService.onError.listen((error) {
      if (mounted) {
        setState(() {
          _errorMessage = error;
        });
        _showErrorSnackBar(error);
      }
    });

    // Listen to transcription results directly from AssemblyAI service
    _transcriptionSubscription = widget.voiceService.assemblyAIService.onTranscription.listen((transcription) {
      if (mounted) {
        debugPrint('VoiceRecorderButton: Received transcription: $transcription');
        // Call the callback if provided
        widget.onTranscriptionComplete?.call(transcription);
        
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transcription completed: ${transcription.length > 50 ? transcription.substring(0, 50) + "..." : transcription}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });

    // Listen to transcription status changes directly from AssemblyAI service
    _transcriptionStatusSubscription = widget.voiceService.assemblyAIService.onStatusChanged.listen((status) {
      if (mounted) {
        setState(() {
          _transcriptionStatus = status;
        });
        
        // Show status updates for processing states
        if (status == TranscriptionStatus.processing || status == TranscriptionStatus.uploading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(status.displayName),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  Future<void> _initializeRecorder() async {
    try {
      await widget.voiceService.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to initialize recorder: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      // Parse and provide user-friendly error messages
      String userMessage = message;
      
      if (message.toLowerCase().contains('permission')) {
        userMessage = 'Microphone permission is required for voice recording';
      } else if (message.toLowerCase().contains('network') || message.toLowerCase().contains('connection')) {
        userMessage = 'Check your internet connection and try again';
      } else if (message.toLowerCase().contains('api key') || message.toLowerCase().contains('unauthorized')) {
        userMessage = 'Voice transcription service is temporarily unavailable';
      } else if (message.toLowerCase().contains('file') && message.toLowerCase().contains('empty')) {
        userMessage = 'No audio was recorded. Please try speaking louder';
      } else if (message.toLowerCase().contains('timeout')) {
        userMessage = 'Voice transcription is taking too long. Please try again with a shorter recording';
      } else if (message.toLowerCase().contains('large') || message.toLowerCase().contains('size')) {
        userMessage = 'Audio recording is too long. Please try a shorter recording';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              // Clear current state and allow retry
              setState(() {
                _isRecording = false;
              });
            },
          ),
        ),
      );
    }
  }

  Future<void> _toggleRecording() async {
    if (!_isInitialized) {
      _showErrorSnackBar('Recorder not initialized');
      return;
    }

    try {
      if (_isRecording) {
        final path = await widget.voiceService.stopRecording();
        if (mounted && path != null) {
          widget.onRecordingComplete(path);
        }
      } else {
        await widget.voiceService.startRecording();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Recording error: $e');
      }
    }
  }

  Future<void> _cancelRecording() async {
    if (_isRecording) {
      try {
        await widget.voiceService.cancelRecording();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recording canceled')),
          );
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Failed to cancel recording: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions to prevent setState after dispose
    _recordingStateSubscription.cancel();
    _amplitudeSubscription.cancel();
    _errorSubscription.cancel();
    _transcriptionSubscription.cancel();
    _transcriptionStatusSubscription.cancel();
    
    // Dispose animation controller
    _animationController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isRecording) ...[  
          // Cancel button
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: _cancelRecording,
          ),
          const SizedBox(width: 8),
          // Visualization of recording
          Container(
            width: 150,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                5,
                (index) {
                  double height = 10.0;
                  if (_amplitudes.isNotEmpty && index < _amplitudes.length) {
                    // Scale the height based on amplitude
                    height = (_amplitudes[index].current / -160) * 30;
                    height = height.clamp(5.0, 30.0);
                  }
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 50),
                    width: 4,
                    height: height,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        // Main recording button
        GestureDetector(
          onTap: _toggleRecording,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording ? Colors.red : Colors.blue,
              boxShadow: [
                BoxShadow(
                  color: _isRecording 
                      ? Colors.red.withValues(alpha: 0.5)
                      : Colors.blue.withValues(alpha: 0.5),
                  spreadRadius: _isRecording ? 2 : 0,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }
}