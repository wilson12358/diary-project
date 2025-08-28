import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../models/diary_entry.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/calendar_entry_preview.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/photo_viewer_widget.dart';
import '../widgets/video_player_widget.dart';
import '../screens/new_entry_screen.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<DiaryEntry> _selectedEntries = [];
  Map<DateTime, List<DiaryEntry>> _events = {};
  bool _isDisposed = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Safe setState method
  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadEntriesForSelectedDay();
    _loadEntriesForCurrentMonth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar View'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCalendarData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              TableCalendar<DiaryEntry>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                eventLoader: _getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  markersMaxCount: 3,
                  markerDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                onDaySelected: _onDaySelected,
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                  _loadEntriesForCurrentMonth();
                },
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
              ),
              const SizedBox(height: 8.0),
              Container(
                height: _selectedEntries.isEmpty ? 200 : null,
                child: _selectedEntries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_note, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No entries for this date',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: _selectedEntries.map((entry) => CalendarEntryPreview(
                          entry: entry,
                          onTap: () {
                            _showEntryDetails(entry);
                          },
                        )).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DiaryEntry> _getEventsForDay(DateTime day) {
    DateTime normalizedDate = DateTime(day.year, day.month, day.day);
    List<DiaryEntry> dayEvents = _events[normalizedDate] ?? [];
    
    // Debug: Print events for specific day
    if (dayEvents.isNotEmpty) {
      print('Events for ${normalizedDate.toString().split(' ')[0]}: ${dayEvents.length} entries');
    }
    
    return dayEvents;
  }

  void _showEntryDetails(DiaryEntry entry) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title.isNotEmpty ? entry.title : 'Untitled Entry',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, MMMM dd, yyyy').format(entry.date),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Created at ${DateFormat('HH:mm').format(entry.createdAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Edit button
                      IconButton(
                        onPressed: () => _editEntry(entry),
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Edit Entry',
                      ),
                      // Delete button
                      IconButton(
                        onPressed: () => _deleteEntry(entry),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete Entry',
                      ),
                      // Close button
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Content text
                        if (entry.content.isNotEmpty) ...[
                          Text(
                            'Content:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.content,
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Tags
                        if (entry.tags.isNotEmpty) ...[
                          Text(
                            'Tags:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: entry.tags.map((tag) => Chip(
                              label: Text(tag),
                              backgroundColor: Colors.blue[100],
                            )).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Emotional rating
                        if (entry.emotionalRating != null) ...[
                          Text(
                            'Emotional Rating:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                _getEmotionIcon(entry.emotionalRating!),
                                color: _getEmotionColor(entry.emotionalRating!),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${entry.emotionalRating}/5',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: _getEmotionColor(entry.emotionalRating!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Location and Weather
                        if (entry.location != null || entry.weather != null) ...[
                          Text(
                            'Location & Weather:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildLocationWeatherDisplay(entry.location, entry.weather),
                          const SizedBox(height: 16),
                        ],
                        
                        // Media files
                        if (entry.mediaUrls.isNotEmpty) ...[
                          Text(
                            'Media Files:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDetailMediaDisplay(entry.mediaUrls),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Edit entry functionality
  void _editEntry(DiaryEntry entry) {
    Navigator.of(context).pop(); // Close the detail dialog
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Entry'),
          content: Text(
            'Do you want to edit "${entry.title.isNotEmpty ? entry.title : 'Untitled Entry'}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close confirmation dialog
                _navigateToEditEntry(entry);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  /// Navigate to edit entry screen
  void _navigateToEditEntry(DiaryEntry entry) {
    // Navigate directly to the new entry screen for editing
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewEntryScreen(entry: entry),
      ),
    ).then((_) {
      // Refresh the calendar data after returning from edit
      _loadEntriesForSelectedDay();
      // Also refresh the events map
      _refreshCalendarEvents();
    });
  }

  /// Delete entry functionality
  void _deleteEntry(DiaryEntry entry) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Entry'),
          content: Text(
            'Are you sure you want to delete "${entry.title.isNotEmpty ? entry.title : 'Untitled Entry'}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close confirmation dialog
                await _performDeleteEntry(entry);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  /// Perform the actual deletion
  Future<void> _performDeleteEntry(DiaryEntry entry) async {
    if (!mounted) return;
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Deleting entry...'),
              ],
            ),
          );
        },
      );

      // Delete from Firestore
      await _firestoreService.deleteEntry(entry.id);
      
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Close detail dialog
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entry deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh calendar data
      _loadEntriesForSelectedDay();
      _refreshCalendarEvents();
      
    } catch (e) {
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting entry: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Refresh calendar events after changes
  void _refreshCalendarEvents() {
    if (_selectedDay != null) {
      // Update events map for the selected day
      DateTime normalizedDate = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
      );
      _events[normalizedDate] = _selectedEntries;
      
      // Trigger UI update
      setState(() {});
    }
  }

  /// Refresh all calendar data (for pull-to-refresh)
  Future<void> _refreshCalendarData() async {
    // Clear existing data to force fresh load
    _safeSetState(() {
      _events.clear();
      _selectedEntries.clear();
    });
    
    // Clear Firestore cache to ensure fresh data
    _firestoreService.clearCache();
    
    // Refresh both the selected day entries and the month data
    await Future.wait([
      _loadEntriesForSelectedDay(),
      _loadEntriesForCurrentMonth(),
    ]);
    
    // Update the events map and trigger UI refresh
    if (_selectedDay != null) {
      DateTime normalizedDate = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
      );
      _events[normalizedDate] = _selectedEntries;
    }
    
    // Force calendar rebuild
    setState(() {});
  }

  IconData _getEmotionIcon(int rating) {
    switch (rating) {
      case 1: return Icons.sentiment_very_dissatisfied;
      case 2: return Icons.sentiment_dissatisfied;
      case 3: return Icons.sentiment_neutral;
      case 4: return Icons.sentiment_satisfied;
      case 5: return Icons.sentiment_very_satisfied;
      default: return Icons.sentiment_neutral;
    }
  }

  Color _getEmotionColor(int rating) {
    switch (rating) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.yellow[700]!;
      case 4: return Colors.lightGreen;
      case 5: return Colors.green;
      default: return Colors.grey;
    }
  }

  /// Build media display for detail dialog
  Widget _buildDetailMediaDisplay(List<String> mediaUrls) {
    if (mediaUrls.isEmpty) return const SizedBox.shrink();

    // Separate audio, image, and video files
    List<String> audioUrls = mediaUrls.where((url) => _isAudioFile(url)).toList();
    List<String> imageUrls = mediaUrls.where((url) => _isImageFile(url)).toList();
    List<String> videoUrls = mediaUrls.where((url) => _isVideoFile(url)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Audio files
        if (audioUrls.isNotEmpty) ...[
          Text(
            'Voice Recordings:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 8),
          ...audioUrls.map((url) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: AudioPlayerWidget(
              audioUrl: url,
              title: 'Voice Recording',
              showTitle: true,
            ),
          )),
          const SizedBox(height: 16),
        ],

        // Image files
        if (imageUrls.isNotEmpty) ...[
          Text(
            'Photos:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: imageUrls.map((url) => Container(
              width: 120,
              height: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: PhotoViewerWidget(
                  imageUrl: url,
                  width: 120,
                  height: 120,
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Video files
        if (videoUrls.isNotEmpty) ...[
          Text(
            'Videos:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.purple[700],
            ),
          ),
          const SizedBox(height: 8),
          ...videoUrls.map((url) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: VideoPlayerWidget(
              videoUrl: url,
              fileName: _getFileName(url),
              height: 200,
            ),
          )),
        ],
      ],
    );
  }

  /// Check if a media URL is an audio file
  bool _isAudioFile(String url) {
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
    final urlLower = url.toLowerCase();
    
    // Check for video file extensions in URL
    if (['.mp4', '.avi', '.mov', '.wmv', '.flv', '.3gp', '.mkv', '.webm'].any((ext) => urlLower.contains(ext))) {
      return true;
    }
    
    // Check for video storage path patterns (from StorageService)
    if (urlLower.contains('video_')) {
      return true;
    }
    
    return false;
  }

  /// Get file name from URL
  String _getFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.last.isNotEmpty) {
        return uri.pathSegments.last;
      }
    } catch (e) {
      print('Error parsing URL: $e');
    }
    return 'File';
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      _safeSetState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _loadEntriesForSelectedDay();
    }
  }

  /// Load all entries for the current month to populate calendar markers
  Future<void> _loadEntriesForCurrentMonth() async {
    if (_isDisposed || !mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    String userId = authService.user!.uid;

    try {
      // Get entries for the current month
      List<DiaryEntry> monthEntries = await _firestoreService.getEntriesForMonth(
        userId,
        _focusedDay,
      );
      
      // Check if widget is disposed or unmounted before updating state
      if (_isDisposed || !mounted) return;
      
      // Populate events map for calendar markers
      _safeSetState(() {
        _events.clear(); // Clear existing events
        
        for (DiaryEntry entry in monthEntries) {
          DateTime normalizedDate = DateTime(
            entry.date.year,
            entry.date.month,
            entry.date.day,
          );
          
          if (_events[normalizedDate] == null) {
            _events[normalizedDate] = [];
          }
          _events[normalizedDate]!.add(entry);
        }
        
        // Debug: Print events map
        print('Calendar events loaded: ${_events.length} days with entries');
        _events.forEach((date, entries) {
          print('Date: ${date.toString().split(' ')[0]} - ${entries.length} entries');
        });
      });
      
      // Force calendar to rebuild with new events
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Check if widget is disposed or unmounted before showing error
      if (_isDisposed || !mounted) return;
      
      print('Error loading month entries: $e');
    }
  }

  Future<void> _loadEntriesForSelectedDay() async {
    if (_selectedDay == null) return;

    // Check if widget is disposed or unmounted
    if (_isDisposed || !mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    String userId = authService.user!.uid;

    try {
      List<DiaryEntry> entries = await _firestoreService.getEntriesForDate(
        userId,
        _selectedDay!,
      );
      
      // Check if widget is disposed or unmounted before updating state
      if (_isDisposed || !mounted) return;
      
      _safeSetState(() {
        _selectedEntries = entries;
        // Update events map for calendar markers
        DateTime normalizedDate = DateTime(
          _selectedDay!.year,
          _selectedDay!.month,
          _selectedDay!.day,
        );
        _events[normalizedDate] = entries;
        
        // Debug: Print selected day entries
        print('Selected day ${_selectedDay.toString().split(' ')[0]}: ${entries.length} entries');
      });
    } catch (e) {
      // Check if widget is disposed or unmounted before showing error
      if (_isDisposed || !mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading entries: $e')),
      );
    }
  }

  /// Build location and weather display for calendar entry details
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

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
