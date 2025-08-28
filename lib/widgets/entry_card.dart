import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart';
import '../screens/new_entry_screen.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/photo_viewer_widget.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/emotional_rating_widget.dart';

class EntryCard extends StatelessWidget {
  final DiaryEntry entry;
  
  // Make services static to avoid recreating them for each card
  static final FirestoreService _firestoreService = FirestoreService();
  static final StorageService _storageService = StorageService();

  const EntryCard({Key? key, required this.entry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showEntryDetails(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                        child: Text(
                          entry.title.isEmpty ? 'Untitled Entry' : entry.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (value) => _handleMenuAction(context, value),
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue[600], size: 20),
                                const SizedBox(width: 12),
                                const Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red[600], size: 20),
                                const SizedBox(width: 12),
                                const Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Enhanced Date Display
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.blue[400],
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Created: ${DateFormat('HH:mm').format(entry.createdAt)}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Enhanced Emotional Rating Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getEmotionColor(entry.emotionalRating).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getEmotionColor(entry.emotionalRating).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getEmotionIcon(entry.emotionalRating),
                        size: 14,
                        color: _getEmotionColor(entry.emotionalRating),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getEmotionLabel(entry.emotionalRating),
                        style: TextStyle(
                          color: _getEmotionColor(entry.emotionalRating),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (entry.content.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    entry.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.2,
                    ),
                  ),
                ],
                if (entry.tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 3,
                    runSpacing: 3,
                    children: entry.tags.take(3).map((tag) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue[200]!,
                          width: 0.5,
                        ),
                      ),
                                              child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[700],
                          ),
                        ),
                    )).toList(),
                  ),
                ],
                // Media indicator (simple text only)
                if (entry.mediaUrls.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.attach_file,
                        size: 12,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.mediaUrls.length} attachment${entry.mediaUrls.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEntryDetails(BuildContext context) {
    // Debug logging to see what data is available
    if (kDebugMode) {
      print('📍 EntryCard: Showing details for entry: ${entry.title}');
      print('📍 EntryCard: Location data: ${entry.location}');
      print('🌤️ EntryCard: Weather data: ${entry.weather}');
      print('📍 EntryCard: Has location: ${entry.location != null}');
      print('🌤️ EntryCard: Has weather: ${entry.weather != null}');
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(entry.title.isEmpty ? 'Untitled Entry' : entry.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Date: ${entry.date.day}/${entry.date.month}/${entry.date.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Emotional Rating Display
                Row(
                  children: [
                    const Icon(Icons.emoji_emotions, size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Mood: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getEmotionColor(entry.emotionalRating).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getEmotionColor(entry.emotionalRating),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getEmotionLabel(entry.emotionalRating),
                        style: TextStyle(
                          color: _getEmotionColor(entry.emotionalRating),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (entry.content.isNotEmpty) ...[
                  Text(entry.content),
                  const SizedBox(height: 16),
                ],
                if (entry.tags.isNotEmpty) ...[
                  const Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: entry.tags.map((tag) => Chip(
                      label: Text(tag),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                // Location and Weather Display
                const Text('Location & Weather:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (entry.location != null || entry.weather != null) ...[
                  _buildLocationWeatherDisplay(entry.location, entry.weather),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'No location or weather data available',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        if (kDebugMode) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Debug Info:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Location: ${entry.location}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                          Text(
                            'Weather: ${entry.weather}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (entry.mediaUrls.isNotEmpty) ...[
                  const Text('Attachments:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildMediaDisplay(entry.mediaUrls),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewEntryScreen(entry: entry),
                  ),
                );
              },
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewEntryScreen(entry: entry),
          ),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }
  
  /// Check if a media URL is an audio file
  bool _isAudioFile(String url) {
    // Check both URL path and query parameters for file type indicators
    final urlLower = url.toLowerCase();
    
    // Check for audio file extensions in URL
    if (['.m4a', '.mp3', '.wav', '.aac', '.ogg'].any((ext) => urlLower.contains(ext))) {
      return true;
    }
    
    // Check for audio storage path patterns (from StorageService)
    if (urlLower.contains('audio_')) {
      return true;
    }
    
    // Check for audio content type in URL
    if (urlLower.contains('audio/')) {
      return true;
    }
    
    return false;
  }

  /// Check if a media URL is an image file
  bool _isImageFile(String url) {
    // Check both URL path and query parameters for file type indicators
    final urlLower = url.toLowerCase();
    
    // Check for image file extensions in URL
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].any((ext) => urlLower.contains(ext))) {
      return true;
    }
    
    // Check for image storage path patterns (from StorageService)
    if (urlLower.contains('image_')) {
      return true;
    }
    
    // Check for image content type in URL
    if (urlLower.contains('image/')) {
      return true;
    }
    
    return false;
  }

  /// Check if a media URL is a video file
  bool _isVideoFile(String url) {
    // Check both URL path and query parameters for file type indicators
    final urlLower = url.toLowerCase();
    
    // Check for video file extensions in URL
    if (['.mp4', '.avi', '.mov', '.wmv', '.flv', '.3gp', '.mkv', '.webm'].any((ext) => urlLower.contains(ext))) {
      return true;
    }
    
    // Check for video storage path patterns (from StorageService)
    if (urlLower.contains('video_')) {
      return true;
    }
    
    // Check for video content type in URL
    if (urlLower.contains('video/')) {
      return true;
    }
    
    return false;
  }

  /// Build location and weather display
  Widget _buildLocationWeatherDisplay(Map<String, dynamic>? location, Map<String, dynamic>? weather) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location Information
          if (location != null) ...[
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Location:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (location['address'] != null) ...[
              Text(
                '${location['address']['city'] ?? ''}, ${location['address']['state'] ?? ''}',
                style: const TextStyle(fontSize: 14),
              ),
              if (location['address']['country'] != null)
                Text(
                  location['address']['country'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ] else ...[
              Text(
                'Coordinates: ${location['latitude']?.toStringAsFixed(4) ?? 'N/A'}, ${location['longitude']?.toStringAsFixed(4) ?? 'N/A'}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            const SizedBox(height: 12),
          ],
          
          // Weather Information
          if (weather != null) ...[
            Row(
              children: [
                Icon(Icons.wb_sunny, size: 16, color: Colors.orange[600]),
                const SizedBox(width: 8),
                Text(
                  'Weather:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (weather['temperature'] != null) ...[
                  Text(
                    '${weather['temperature'].toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (weather['description'] != null)
                  Text(
                    weather['description'],
                    style: const TextStyle(fontSize: 14),
                  ),
              ],
            ),
            if (weather['humidity'] != null || weather['windSpeed'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (weather['humidity'] != null) ...[
                    Text(
                      'Humidity: ${weather['humidity']}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (weather['windSpeed'] != null)
                    Text(
                      'Wind: ${weather['windSpeed'].toStringAsFixed(1)} km/h',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Build media display for audio, image, and video files
  Widget _buildMediaDisplay(List<String> mediaUrls) {
    if (mediaUrls.isEmpty) return const SizedBox.shrink();

    // Separate audio, image, and video files
    List<String> audioUrls = mediaUrls.where((url) => _isAudioFile(url)).toList();
    List<String> imageUrls = mediaUrls.where((url) => _isImageFile(url)).toList();
    List<String> videoUrls = mediaUrls.where((url) => _isVideoFile(url)).toList();

    if (kDebugMode) {
      print('EntryCard: Media URLs: $mediaUrls');
      print('EntryCard: Audio URLs: $audioUrls');
      print('EntryCard: Image URLs: $imageUrls');
      print('EntryCard: Video URLs: $videoUrls');
      
      // Debug each URL individually
      for (int i = 0; i < mediaUrls.length; i++) {
        final url = mediaUrls[i];
        final isAudio = _isAudioFile(url);
        final isImage = _isImageFile(url);
        final isVideo = _isVideoFile(url);
        print('EntryCard: URL $i: $url');
        print('EntryCard:   - Is Audio: $isAudio');
        print('EntryCard:   - Is Image: $isImage');
        print('EntryCard:   - Is Video: $isVideo');
        print('EntryCard:   - File Type: ${_getFileTypeFromUrl(url)}');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Audio files
        if (audioUrls.isNotEmpty) ...[
          Text(
            'Voice Recordings',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...audioUrls.map((url) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: AudioPlayerWidget(
              audioUrl: url,
              title: 'Voice Recording',
              showTitle: true,
            ),
          )),
        ],

        // Video files
        if (videoUrls.isNotEmpty) ...[
          if (audioUrls.isNotEmpty || imageUrls.isNotEmpty) const SizedBox(height: 16),
          Text(
            'Videos',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _buildVideoGrid(videoUrls),
        ],

        // Image files
        if (imageUrls.isNotEmpty) ...[
          if (audioUrls.isNotEmpty || videoUrls.isNotEmpty) const SizedBox(height: 16),
          Text(
            'Photos',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _buildImageGrid(imageUrls),
        ],
      ],
    );
  }

  /// Build video grid for multiple videos
  Widget _buildVideoGrid(List<String> videoUrls) {
    if (videoUrls.length == 1) {
      // Single video - show larger
      return VideoPlayerWidget(
        videoUrl: videoUrls[0],
        fileName: _getFileName(videoUrls[0]),
        height: 200,
      );
    } else if (videoUrls.length == 2) {
      // Two videos - show side by side
      return Row(
        children: [
          Expanded(
            child: VideoPlayerWidget(
              videoUrl: videoUrls[0],
              fileName: _getFileName(videoUrls[0]),
              height: 150,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: VideoPlayerWidget(
              videoUrl: videoUrls[1],
              fileName: _getFileName(videoUrls[1]),
              height: 150,
            ),
          ),
        ],
      );
    } else {
      // Multiple videos - show grid
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 16 / 9, // Video aspect ratio
        ),
        itemCount: videoUrls.length,
        itemBuilder: (context, index) {
          return VideoPlayerWidget(
            videoUrl: videoUrls[index],
            fileName: _getFileName(videoUrls[index]),
            height: 120,
            showFileName: false,
          );
        },
      );
    }
  }

  /// Build image grid for multiple images
  Widget _buildImageGrid(List<String> imageUrls) {
    if (imageUrls.length == 1) {
      // Single image - show larger
      return PhotoViewerWidget(
        imageUrl: imageUrls[0],
        fileName: _getFileName(imageUrls[0]),
        height: 150,
      );
    } else if (imageUrls.length == 2) {
      // Two images - show side by side
      return Row(
        children: [
          Expanded(
            child: PhotoViewerWidget(
              imageUrl: imageUrls[0],
              fileName: _getFileName(imageUrls[0]),
              height: 120,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PhotoViewerWidget(
              imageUrl: imageUrls[1],
              fileName: _getFileName(imageUrls[1]),
              height: 120,
            ),
          ),
        ],
      );
    } else {
      // Multiple images - show grid
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return PhotoViewerWidget(
            imageUrl: imageUrls[index],
            fileName: _getFileName(imageUrls[index]),
            height: 80,
            showFileName: false,
          );
        },
      );
    }
  }

  /// Get filename from URL
  String _getFileName(String url) {
    try {
      return url.split('/').last;
    } catch (e) {
      return 'File';
    }
  }

  /// Get emotion color based on rating
  Color _getEmotionColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.red;
      default:
        return Colors.yellow;
    }
  }

  /// Get emotion label based on rating
  String _getEmotionLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Very Happy';
      case 2:
        return 'Happy';
      case 3:
        return 'Neutral';
      case 4:
        return 'Sad';
      case 5:
        return 'Very Sad';
      default:
        return 'Neutral';
    }
  }

  /// Get emotion icon based on rating
  IconData _getEmotionIcon(int rating) {
    switch (rating) {
      case 1:
        return Icons.sentiment_very_satisfied;
      case 2:
        return Icons.sentiment_satisfied;
      case 3:
        return Icons.sentiment_neutral;
      case 4:
        return Icons.sentiment_dissatisfied;
      case 5:
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  /// Get file type from URL for debugging
  String _getFileTypeFromUrl(String url) {
    final urlLower = url.toLowerCase();
    
    if (_isAudioFile(url)) return 'Audio';
    if (_isImageFile(url)) return 'Image';
    if (_isVideoFile(url)) return 'Video';
    
    // Check for storage path patterns
    if (urlLower.contains('audio_')) return 'Audio (from path)';
    if (urlLower.contains('image_')) return 'Image (from path)';
    if (urlLower.contains('video_')) return 'Video (from path)';
    
    // Check for content types
    if (urlLower.contains('audio/')) return 'Audio (from content type)';
    if (urlLower.contains('image/')) return 'Image (from content type)';
    if (urlLower.contains('video/')) return 'Video (from content type)';
    
    return 'Unknown';
  }

  void _showDeleteConfirmation(BuildContext context) {
    // Store a reference to the scaffold messenger before the dialog is shown
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Entry'),
          content: const Text('Are you sure you want to delete this entry? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Close the dialog first
                Navigator.of(dialogContext).pop();
                
                try {
                  // Show loading indicator using the stored scaffold messenger
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Deleting entry...')),
                  );
                  
                  // Delete entry and get the entry data
                  DiaryEntry deletedEntry = await _firestoreService.deleteEntry(entry.id);
                  
                  // Delete associated media files
                  await _storageService.deleteAllFilesForEntry(deletedEntry);
                  
                  // Show success message using the stored scaffold messenger
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Entry deleted successfully')),
                  );
                } catch (e) {
                  // Show error message using the stored scaffold messenger
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error deleting entry: $e')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
