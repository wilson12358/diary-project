import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/diary_entry.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/voice_service.dart';
import '../services/assemblyai_service.dart';
import '../services/theme_service.dart';
import '../widgets/tag_chip_input.dart';
import '../widgets/voice_recorder_button.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/emotional_rating_widget.dart';
import '../widgets/location_weather_widget.dart';
import '../utils/app_theme.dart';

import 'package:path/path.dart' as path;

enum MediaType {
  image,
  video,
  audio,
  unknown,
}

/// Result of file validation
class FileValidationResult {
  final bool isValid;
  final String errorMessage;
  
  const FileValidationResult({
    required this.isValid,
    required this.errorMessage,
  });
}

class NewEntryScreen extends StatefulWidget {
  final DiaryEntry? entry; // For editing existing entries

  NewEntryScreen({this.entry});

  @override
  _NewEntryScreenState createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();
  final _voiceService = VoiceService();
  
  DateTime _selectedDate = DateTime.now();
  List<String> _tags = [];
  List<File> _selectedFiles = [];
  List<String> _existingMediaUrls = [];
  List<String> _recordedAudioFiles = []; // Store recorded audio file paths
  int _emotionalRating = 3; // Default to neutral
  bool _isSaving = false; // Add this to prevent multiple saves
  Map<String, dynamic>? _location;
  Map<String, dynamic>? _weather;


  @override
  void initState() {
    super.initState();
    
    // Initialize voice service
    _initializeVoiceService();
    
    // Test Firebase Storage connection
    _testFirebaseConnection();
    
    // Listen to audio file ready events
    _voiceService.onAudioFileReady.listen((audioPath) {
      if (mounted) {
        setState(() {
          // Check if this audio file is already in the list to prevent duplicates
          if (!_recordedAudioFiles.contains(audioPath)) {
            _recordedAudioFiles.add(audioPath);
            debugPrint('NewEntryScreen: Audio file added: $audioPath');
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Voice recording saved successfully'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            debugPrint('NewEntryScreen: Audio file already exists, skipping duplicate: $audioPath');
          }
        });
      }
    });
    
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      _selectedDate = widget.entry!.date;
      _tags = List.from(widget.entry!.tags);
      _existingMediaUrls = List.from(widget.entry!.mediaUrls);
      _emotionalRating = widget.entry!.emotionalRating;
      _location = widget.entry!.location;
      _weather = widget.entry!.weather;
    }
  }
  
  Future<void> _initializeVoiceService() async {
    try {
      await _voiceService.initialize();
      final connectionTest = await _voiceService.testAssemblyAIConnection();
      
      if (kDebugMode) {
        debugPrint('Voice service initialized successfully');
        debugPrint('AssemblyAI connection test: ${connectionTest ? "✅ SUCCESS" : "❌ FAILED"}');
      }
      
      if (!connectionTest) {
        // Show user-friendly warning for connection issues
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Voice transcription may not work - check internet connection'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _initializeVoiceService(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing voice service: $e');
      }
      
      // Show user-friendly warning for connection issues
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Voice recording setup failed. Voice transcription will not be available.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _initializeVoiceService(),
            ),
          ),
        );
      }
    }
  }

  /// Test Firebase Storage connection
  Future<void> _testFirebaseConnection() async {
    try {
      if (kDebugMode) {
        debugPrint('NewEntryScreen: Testing Firebase Storage connection...');
      }
      
      // Initialize storage service first
      await _storageService.initialize();
      
      final connectionTest = await _storageService.testConnection();
      
      if (kDebugMode) {
        debugPrint('NewEntryScreen: Firebase Storage connection test: ${connectionTest ? "✅ SUCCESS" : "❌ FAILED"}');
      }
      
      if (!connectionTest) {
        // Show user-friendly warning for storage issues
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('File storage may not work - check Firebase configuration'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _testFirebaseConnection(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NewEntryScreen: Error testing Firebase Storage connection: $e');
      }
      
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('File storage setup failed. File uploads will not work.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _testFirebaseConnection(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            title: Text(
              widget.entry == null ? 'New Diary Entry' : 'Edit Entry',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              _isSaving
                  ? Container(
                      margin: const EdgeInsets.all(16.0),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: _saveEntry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        ),
                        child: const Text(
                          'SAVE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with Date
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Date Selector
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.edit,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Main Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Section
                  _buildSectionHeader('Title', Icons.title),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _titleController,
                      enabled: true,
                      autofocus: false,
                      enableSuggestions: true,
                      autocorrect: true,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'What would you like to call this entry?',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                      onFieldSubmitted: (text) {
                        FocusScope.of(context).nextFocus();
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Emotional Rating Section
                  _buildSectionHeader('How are you feeling?', Icons.emoji_emotions),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: EmotionalRatingWidget(
                      initialRating: _emotionalRating,
                      onRatingChanged: (rating) {
                        setState(() {
                          _emotionalRating = rating;
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Location & Weather Section
                  _buildSectionHeader('Location & Weather', Icons.location_on),
                  const SizedBox(height: 12),
                  LocationWeatherWidget(
                    location: _location,
                    weather: _weather,
                    onDataChanged: (location, weather) {
                      if (kDebugMode) {
                        debugPrint('📍 Location data updated: $location');
                        debugPrint('🌤️ Weather data updated: $weather');
                      }
                      setState(() {
                        _location = location;
                        _weather = weather;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Content Section
                  _buildSectionHeader('Your Thoughts', Icons.edit_note),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        TextFormField(
                          controller: _contentController,
                          enabled: true,
                          autofocus: false,
                          enableSuggestions: true,
                          autocorrect: true,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          minLines: 8,
                          maxLines: null,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Share your thoughts, feelings, or experiences...',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(20),
                            alignLabelWithHint: true,
                          ),
                        ),
                        // Voice Recorder Button
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCA032),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFCA032).withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: VoiceRecorderButton(
                              voiceService: _voiceService,
                              onRecordingComplete: _handleVoiceRecording,
                              onTranscriptionComplete: _handleTranscription,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Transcription Status
                  StreamBuilder<TranscriptionStatus>(
                    stream: _voiceService.onTranscriptionStatusChanged,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != TranscriptionStatus.idle) {
                        return Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCA032).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFCA032).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFCA032)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                snapshot.data!.displayName,
                                style: const TextStyle(
                                  color: Color(0xFFFCA032),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  
                  // Recorded Audio Files
                  if (_recordedAudioFiles.isNotEmpty && !_isSaving) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('Voice Recordings', Icons.mic),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: _recordedAudioFiles.map((audioPath) => 
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: AudioPlayerWidget(
                              audioPath: audioPath,
                              title: 'Voice Recording',
                              showTitle: true,
                            ),
                          ),
                        ).toList(),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Tags Section
                  _buildSectionHeader('Tags', Icons.label),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TagChipInput(
                      tags: _tags,
                      onTagsChanged: (tags) {
                        setState(() {
                          _tags = tags;
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Media Section
                  if (_selectedFiles.isNotEmpty || _existingMediaUrls.isNotEmpty) ...[
                    _buildSectionHeader('Media Attachments', Icons.attach_file),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ..._existingMediaUrls.map((url) => _buildMediaPreview(url, isExisting: true)),
                            ..._selectedFiles.map((file) => _buildMediaPreview(file.path, isExisting: false)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Add Media Section
                  _buildSectionHeader('Add Media', Icons.add_photo_alternate),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMediaButton(
                          onPressed: _pickImage,
                          icon: Icons.image,
                          label: 'Image',
                          color: Colors.blue[600]!,
                        ),
                        _buildMediaButton(
                          onPressed: _pickVideo,
                          icon: Icons.videocam,
                          label: 'Video',
                          color: Colors.red[600]!,
                        ),
                        _buildMediaButton(
                          onPressed: _pickAudio,
                          icon: Icons.audiotrack,
                          label: 'Audio',
                          color: Colors.green[600]!,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMediaButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview(String path, {required bool isExisting}) {
    return Container(
      width: 80,
      height: 80,
      margin: EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildMediaContent(path, isExisting),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isExisting) {
                    _existingMediaUrls.remove(path);
                  } else {
                    _selectedFiles.removeWhere((file) => file.path == path);
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMediaContent(String path, bool isExisting) {
    final mediaType = _getMediaType(path);
    
    switch (mediaType) {
      case MediaType.image:
        return _buildImagePreview(path, isExisting);
      case MediaType.video:
        return _buildVideoPreview(path, isExisting);
      case MediaType.audio:
        return _buildAudioPreview(path, isExisting);
      default:
        return _buildUnknownPreview(path, isExisting);
    }
  }
  
  Widget _buildImagePreview(String path, bool isExisting) {
    if (isExisting) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: 80,
        height: 80,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading network image: $error');
          return _buildErrorPreview('Image load failed');
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        width: 80,
        height: 80,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading local image: $error');
          return _buildErrorPreview('Invalid image');
        },
      );
    }
  }
  
  Widget _buildVideoPreview(String path, bool isExisting) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_filled, color: Colors.white, size: 32),
          SizedBox(height: 4),
          Text(
            'Video',
            style: TextStyle(color: Colors.white, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAudioPreview(String path, bool isExisting) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.audiotrack, color: Colors.blue, size: 32),
          SizedBox(height: 4),
          Text(
            'Audio',
            style: TextStyle(color: Colors.blue, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildUnknownPreview(String path, bool isExisting) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file, color: Colors.grey, size: 32),
          SizedBox(height: 4),
          Text(
            'File',
            style: TextStyle(color: Colors.grey, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorPreview(String errorMessage) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red, size: 24),
          SizedBox(height: 4),
          Text(
            errorMessage,
            style: TextStyle(color: Colors.red, fontSize: 8),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  MediaType _getMediaType(String path) {
    final extension = path.toLowerCase().split('.').last;
    
    if (_isImageExtension(extension)) {
      return MediaType.image;
    } else if (_isVideoExtension(extension)) {
      return MediaType.video;
    } else if (_isAudioExtension(extension)) {
      return MediaType.audio;
    } else {
      return MediaType.unknown;
    }
  }
  
  bool _isImageExtension(String extension) {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'];
    return imageExtensions.contains(extension);
  }
  
  bool _isVideoExtension(String extension) {
    const videoExtensions = ['mp4', 'avi', 'mov', 'wmv', 'flv', '3gp', 'mkv', 'webm'];
    return videoExtensions.contains(extension);
  }
  
  bool _isAudioExtension(String extension) {
    const audioExtensions = ['mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg', 'wma'];
    return audioExtensions.contains(extension);
  }
  
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      // Show source selection dialog
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return; // User cancelled
      
      // Check and request camera permission if needed
      if (source == ImageSource.camera) {
        final hasPermission = await _checkCameraPermission();
        if (!hasPermission) {
          return; // Permission denied or permanently denied
        }
      }
      
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85, // Good quality with reasonable file size
        maxWidth: 1920, // Max width for better performance
        maxHeight: 1080, // Max height for better performance
      );
      
      if (image != null) {
        // Verify the file exists and is readable
        final file = File(image.path);
        if (await file.exists()) {
          setState(() {
            _selectedFiles.add(file);
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image added successfully'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        } else {
          _showErrorSnackBar('Selected image file not found');
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showErrorSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  /// Show dialog to choose image source (camera or gallery)
  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
                      title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt, color: AppColors.primaryColor, size: 20),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Choose Image Source',
                    style: TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt, color: Colors.blue),
                  title: const Text('Camera'),
                  subtitle: const Text('Take a new photo'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: Colors.green),
                  title: const Text('Gallery'),
                  subtitle: const Text('Choose from existing photos'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// Check and request camera permission with user-friendly messages
  Future<bool> _checkCameraPermission() async {
    // Check current permission status
    PermissionStatus status = await Permission.camera.status;
    
    if (status == PermissionStatus.granted) {
      return true;
    }
    
    if (status == PermissionStatus.denied) {
      // Show explanation dialog before requesting permission
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.camera_alt, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                const Text('Camera Permission'),
              ],
            ),
            content: const Text(
              'This app needs camera permission to take photos for your diary entries. Would you like to grant camera permission?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Not Now'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                ),
                child: const Text('Grant Permission'),
              ),
            ],
          );
        },
      );
      
      if (shouldRequest == true) {
        // Request permission
        status = await Permission.camera.request();
        if (status == PermissionStatus.granted) {
          return true;
        } else if (status == PermissionStatus.denied) {
          // Show message that permission was denied
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Camera permission denied. You can still select photos from gallery.'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    }
    
    if (status == PermissionStatus.permanentlyDenied) {
      // Show dialog to open app settings
      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Camera Permission Required'),
            content: const Text(
              'Camera permission is permanently denied. Please enable it in app settings to take photos.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                ),
                child: const Text('Open Settings'),
              ),
            ],
          );
        },
      );
      
      if (shouldOpenSettings == true) {
        await openAppSettings();
      }
    }
    
    return false;
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        // Verify the file exists and is readable
        final file = File(video.path);
        if (await file.exists()) {
          // Check file size (optional - warn for very large files)
          final fileSizeInBytes = await file.length();
          final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
          
          if (fileSizeInMB > 100) { // 100MB limit
            _showErrorSnackBar('Video file is too large (${fileSizeInMB.toStringAsFixed(1)}MB). Please select a smaller file.');
            return;
          }
          
          setState(() {
            _selectedFiles.add(file);
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Video added successfully (${fileSizeInMB.toStringAsFixed(1)}MB)'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        } else {
          _showErrorSnackBar('Selected video file not found');
        }
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
      _showErrorSnackBar('Failed to pick video: ${e.toString()}');
    }
  }

  Future<void> _pickAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.single.path;
        
        if (filePath != null) {
          final file = File(filePath);
          
          if (await file.exists()) {
            // Check file size
            final fileSizeInBytes = await file.length();
            final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
            
            if (fileSizeInMB > 50) { // 50MB limit for audio
              _showErrorSnackBar('Audio file is too large (${fileSizeInMB.toStringAsFixed(1)}MB). Please select a smaller file.');
              return;
            }
            
            setState(() {
              _selectedFiles.add(file);
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Audio file added successfully (${fileSizeInMB.toStringAsFixed(1)}MB)'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          } else {
            _showErrorSnackBar('Selected audio file not found');
          }
        } else {
          _showErrorSnackBar('Invalid audio file path');
        }
      }
    } catch (e) {
      debugPrint('Error picking audio: $e');
      _showErrorSnackBar('Failed to pick audio file: ${e.toString()}');
    }
  }
  
  // Handle voice recording completion
  void _handleVoiceRecording(String audioPath) {
    // This callback is called by VoiceRecorderButton when recording stops
    // We use it only for UI feedback, not for file management
    // The actual audio file handling is done by the onAudioFileReady stream
    
    if (kDebugMode) {
      debugPrint('VoiceRecording completed: $audioPath');
      debugPrint('Audio will be handled by onAudioFileReady stream');
      debugPrint('Current _recordedAudioFiles count: ${_recordedAudioFiles.length}');
    }
    
    // IMPORTANT: Do NOT add to _selectedFiles here
    // This prevents duplicate file handling and ensures only one upload per recording
    
    // Additional safeguard: Remove any audio files from _selectedFiles that might have been added
    // This ensures voice recordings are only handled by the _recordedAudioFiles system
    setState(() {
      _selectedFiles.removeWhere((file) {
        final isAudioFile = _isAudioExtension(path.extension(file.path).toLowerCase());
        final isSameFile = file.path == audioPath;
        
        if (isAudioFile && isSameFile) {
          if (kDebugMode) {
            debugPrint('🛡️ Safeguard: Removed duplicate audio file from _selectedFiles: $audioPath');
          }
          return true; // Remove this file
        }
        return false; // Keep other files
      });
    });
  }
  
  // Handle transcription completion
  void _handleTranscription(String transcription) {
    if (transcription.isNotEmpty) {
      setState(() {
        // Add transcription immediately to the typing area
        if (_contentController.text.isNotEmpty) {
          // Add a space or line break if there's existing content
          _contentController.text += _contentController.text.endsWith('\n') ? transcription : '\n$transcription';
        } else {
          // If empty, just add the transcription
          _contentController.text = transcription;
        }
        
        // Move cursor to end for continued typing
        _contentController.selection = TextSelection.fromPosition(
          TextPosition(offset: _contentController.text.length),
        );
      });
      
      // Show immediate feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice transcription added: "${transcription.length > 30 ? transcription.substring(0, 30) + "..." : transcription}"'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      if (kDebugMode) {
        debugPrint('Transcription added: ${transcription.length} characters');
      }
    }
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return; // Prevent multiple saves
    
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add a title or content'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    
    // Validate files before saving
    if (_selectedFiles.isNotEmpty) {
      final validationResult = await _validateFiles();
      if (!validationResult.isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validationResult.errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    // No progress dialog - direct save for speed

    try {
      final stopwatch = Stopwatch()..start();
      
      final authService = Provider.of<AuthService>(context, listen: false);
      String userId = authService.user!.uid;
      String entryId = widget.entry?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      if (kDebugMode) {
        debugPrint('🚀 Starting diary save process...');
        debugPrint('📊 Files to process: ${_selectedFiles.length} selected, ${_recordedAudioFiles.length} audio');
      }
      
      // Upload files in parallel with optimized processing
      List<String> newMediaUrls = [];
      if (_selectedFiles.isNotEmpty) {
        // Filter and validate files efficiently
        List<File> nonAudioFiles = _selectedFiles.where((file) {
          return !_isAudioExtension(path.extension(file.path).toLowerCase());
        }).toList();
        
        if (nonAudioFiles.isNotEmpty) {
          try {
            // Batch upload all non-audio files in parallel
            List<Future<String>> uploadFutures = nonAudioFiles.map((file) {
              return _uploadFileWithProgress(file, userId, entryId, 0);
            }).toList();
            
            // Wait for all uploads to complete
            newMediaUrls = await Future.wait(uploadFutures);
            
            // Clear selected files after successful upload
            if (mounted) {
              setState(() {
                _selectedFiles.clear();
              });
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error during file upload: $e');
            }
            
            // Show user-friendly error message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Some files failed to upload. Please try again.'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  action: SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () => _saveEntry(),
                  ),
                ),
              );
            }
            
            newMediaUrls = [];
          }
        }
      }
      
      // Upload recorded audio files with optimized validation
      List<String> audioUrls = [];
      if (_recordedAudioFiles.isNotEmpty) {
        try {
          // Remove duplicates and validate files efficiently
          Set<String> uniqueAudioPaths = _recordedAudioFiles.toSet();
          List<String> uniqueAudioList = uniqueAudioPaths.toList();
          
          if (kDebugMode) {
            debugPrint('Starting upload of ${uniqueAudioList.length} unique audio files');
          }
          
          // Batch validate all audio files at once
          List<Future<MapEntry<String, bool>>> validationFutures = [];
          for (String audioPath in uniqueAudioList) {
            validationFutures.add(_validateAudioFile(audioPath));
          }
          
          // Wait for all validations to complete
          List<MapEntry<String, bool>> validationResults = await Future.wait(validationFutures);
          
          // Filter valid files and create upload futures
          List<Future<String>> audioUploadFutures = [];
          List<String> validAudioFiles = [];
          
          for (MapEntry<String, bool> result in validationResults) {
            if (result.value) {
              validAudioFiles.add(result.key);
              audioUploadFutures.add(_uploadFileWithProgress(File(result.key), userId, entryId, validAudioFiles.length));
            }
          }
          
          if (audioUploadFutures.isNotEmpty) {
            if (kDebugMode) {
              debugPrint('Starting parallel upload of ${audioUploadFutures.length} audio files...');
            }
            
            // Upload all audio files in parallel
            audioUrls = await Future.wait(audioUploadFutures);
            
            if (kDebugMode) {
              debugPrint('✅ Successfully uploaded ${audioUrls.length} audio files');
            }
            
            // Clear recorded audio files after successful upload
            if (mounted) {
              setState(() {
                _recordedAudioFiles.clear();
                _selectedFiles.removeWhere((file) => _isAudioExtension(path.extension(file.path).toLowerCase()));
              });
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Error during audio file upload: $e');
          }
          
          // Show user-friendly error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Some audio files failed to upload. Please try again.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _saveEntry(),
                ),
              ),
            );
          }
          
          audioUrls = [];
        }
      }

      // Combine existing and new media URLs with audio URLs
      List<String> allMediaUrls = [..._existingMediaUrls, ...newMediaUrls, ...audioUrls];

      // Create entry object efficiently
      if (kDebugMode) {
        debugPrint('📍 Location data before saving: $_location');
        debugPrint('🌤️ Weather data before saving: $_weather');
      }
      
      DiaryEntry entry = DiaryEntry(
        id: widget.entry?.id ?? '',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        date: _selectedDate,
        tags: _tags,
        mediaUrls: allMediaUrls,
        emotionalRating: _emotionalRating,
        createdAt: widget.entry?.createdAt ?? DateTime.now(),
        userId: userId,
        location: _location,
        weather: _weather,
      );

      // Save to Firestore with performance monitoring
      final firestoreStopwatch = Stopwatch()..start();
      
      if (widget.entry == null) {
        String entryId = await _firestoreService.addEntry(entry);
        entry = entry.copyWith(id: entryId);
      } else {
        await _firestoreService.updateEntry(entry);
      }
      
      firestoreStopwatch.stop();
      if (kDebugMode) {
        debugPrint('⏱️ Firestore operation completed in: ${firestoreStopwatch.elapsedMilliseconds}ms');
      }

      stopwatch.stop();
      if (kDebugMode) {
        debugPrint('🎉 Diary save process completed in: ${stopwatch.elapsedMilliseconds}ms');
        debugPrint('📈 Performance breakdown:');
        debugPrint('   - File uploads: ${newMediaUrls.length + audioUrls.length} files');
        debugPrint('   - Firestore operation: ${firestoreStopwatch.elapsedMilliseconds}ms');
        debugPrint('   - Total time: ${stopwatch.elapsedMilliseconds}ms');
      }

      setState(() {
        _isSaving = false;
      });

      // Quick success feedback and immediate navigation
      if (mounted) {
        // Show quick success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.entry == null ? 'Entry saved successfully!' : 'Entry updated successfully!',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Immediate navigation to main page for speed
        try {
          // Fast navigation without animations
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/',
            (route) => false,
            arguments: {'fromSave': true},
          );
        } catch (e) {
          // Fallback navigation
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
      
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      // No progress dialog to close
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entry: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _saveEntry(),
            ),
          ),
        );
      }
    }
  }







  Future<String> _uploadFileWithProgress(File file, String userId, String entryId, int fileIndex) async {
    try {
      // Ensure StorageService is initialized (only once)
      if (!_storageService.isInitialized) {
        await _storageService.initialize();
      }
      
      // Use the optimized StorageService with progress tracking
      final downloadUrl = await _storageService.uploadFileWithProgress(
        file, 
        userId, 
        entryId,
        (progress) {
          // Update progress in UI if needed
          if (mounted && kDebugMode) {
            debugPrint('Upload progress for ${path.basename(file.path)}: ${(progress * 100).toStringAsFixed(1)}%');
          }
        },
      );
      
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NewEntryScreen: ❌ File upload failed: $e');
      }
      throw Exception('Failed to upload file ${path.basename(file.path)}: $e');
    }
  }
  

  
  /// Validate audio file efficiently
  Future<MapEntry<String, bool>> _validateAudioFile(String audioPath) async {
    try {
      final audioFile = File(audioPath);
      if (await audioFile.exists()) {
        final fileSize = await audioFile.length();
        return MapEntry(audioPath, fileSize > 0);
      }
      return MapEntry(audioPath, false);
    } catch (e) {
      return MapEntry(audioPath, false);
    }
  }

  /// Validate all selected files before upload
  Future<FileValidationResult> _validateFiles() async {
    for (int i = 0; i < _selectedFiles.length; i++) {
      final file = _selectedFiles[i];
      
      // Check if file exists
      if (!await file.exists()) {
        return FileValidationResult(
          isValid: false,
          errorMessage: 'File no longer exists: ${path.basename(file.path)}',
        );
      }
      
      // Check file size
      try {
        final fileSize = await file.length();
        if (fileSize == 0) {
          return FileValidationResult(
            isValid: false,
            errorMessage: 'File is empty: ${path.basename(file.path)}',
          );
        }
        
        // Check file size limits
        final fileSizeInMB = fileSize / (1024 * 1024);
        final fileName = path.basename(file.path);
        final extension = path.extension(fileName).toLowerCase();
        
        if (extension == '.mp4' || extension == '.mov' || extension == '.avi') {
          if (fileSizeInMB > 100) { // 100MB limit for videos
            return FileValidationResult(
              isValid: false,
              errorMessage: 'Video file too large: ${fileSizeInMB.toStringAsFixed(1)}MB (max 100MB)',
            );
          }
        } else if (extension == '.m4a' || extension == '.mp3' || extension == '.wav') {
          if (fileSizeInMB > 50) { // 50MB limit for audio
            return FileValidationResult(
              isValid: false,
              errorMessage: 'Audio file too large: ${fileSizeInMB.toStringAsFixed(1)}MB (max 50MB)',
            );
          }
        } else if (extension == '.jpg' || extension == '.jpeg' || extension == '.png' || extension == '.gif') {
          if (fileSizeInMB > 10) { // 10MB limit for images
            return FileValidationResult(
              isValid: false,
              errorMessage: 'Image file too large: ${fileSizeInMB.toStringAsFixed(1)}MB (max 10MB)',
            );
          }
        }
      } catch (e) {
        return FileValidationResult(
          isValid: false,
          errorMessage: 'Cannot read file: ${path.basename(file.path)}',
        );
      }
    }
    
    return FileValidationResult(isValid: true, errorMessage: '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _voiceService.dispose();
    super.dispose();
  }
}



