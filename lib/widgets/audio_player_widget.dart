import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as path;

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final String? audioUrl;
  final String? title;
  final bool showTitle;

  const AudioPlayerWidget({
    Key? key,
    this.audioPath = '',
    this.audioUrl,
    this.title,
    this.showTitle = true,
  }) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isLoading = false; // Reset loading when state changes
        });
      }
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Listen to completion
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  Future<void> _playAudio() async {
    try {
      setState(() {
        _errorMessage = null;
        _isLoading = true;
      });

      if (widget.audioPath.isNotEmpty) {
        // Play local file
        await _audioPlayer.play(DeviceFileSource(widget.audioPath));
      } else if (widget.audioUrl != null) {
        // Play from URL
        if (kDebugMode) {
          print('AudioPlayerWidget: Playing audio from URL: ${widget.audioUrl}');
        }
        await _audioPlayer.play(UrlSource(widget.audioUrl!));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to play audio: $e';
          _isLoading = false;
        });
      }
      if (kDebugMode) {
        print('AudioPlayerWidget: Error playing audio: $e');
      }
    }
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      _position = Duration.zero;
    });
  }

  Future<void> _seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  String _getAudioTitle() {
    if (widget.title != null) {
      return widget.title!;
    }
    
    if (widget.audioPath.isNotEmpty) {
      return path.basename(widget.audioPath);
    } else if (widget.audioUrl != null) {
      return path.basename(widget.audioUrl!);
    }
    
    return 'Audio File';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title and error message
          if (widget.showTitle) ...[
            Row(
              children: [
                Icon(
                  Icons.audiotrack,
                  color: Colors.blue[700],
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getAudioTitle(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
          ],
          
          if (_errorMessage != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(height: 8),
          ],

          // Progress bar
          if (_duration > Duration.zero) ...[
            Slider(
              value: _position.inMilliseconds.toDouble(),
              min: 0,
              max: _duration.inMilliseconds.toDouble(),
              onChanged: (value) {
                _seekTo(Duration(milliseconds: value.toInt()));
              },
              activeColor: Colors.blue[600],
              inactiveColor: Colors.grey[300],
            ),
            SizedBox(height: 4),
          ],

          // Time display and controls
          Row(
            children: [
              // Time display
              if (_duration > Duration.zero) ...[
                Text(
                  _formatDuration(_position),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  ' / ${_formatDuration(_duration)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontFamily: 'monospace',
                  ),
                ),
                Spacer(),
              ] else ...[
                Text(
                  'Ready to play',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Spacer(),
              ],

              // Control buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stop button
                  IconButton(
                    onPressed: _isLoading ? null : _stopAudio,
                    icon: Icon(
                      Icons.stop,
                      color: Colors.red[600],
                      size: 20,
                    ),
                    tooltip: 'Stop',
                  ),
                  
                  // Play/Pause button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isLoading ? null : (_isPlaying ? _pauseAudio : _playAudio),
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                      tooltip: _isPlaying ? 'Pause' : 'Play',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Loading indicator
          if (_isLoading) ...[
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Loading audio...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
