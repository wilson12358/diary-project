import 'package:flutter/material.dart';

class EmotionalRatingWidget extends StatefulWidget {
  final int initialRating;
  final Function(int) onRatingChanged;
  final bool isEditable;

  const EmotionalRatingWidget({
    Key? key,
    this.initialRating = 3, // Default to neutral (3)
    required this.onRatingChanged,
    this.isEditable = true,
  }) : super(key: key);

  @override
  State<EmotionalRatingWidget> createState() => _EmotionalRatingWidgetState();
}

class _EmotionalRatingWidgetState extends State<EmotionalRatingWidget> {
  late int _currentRating;
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
    _sliderValue = _currentRating.toDouble();
  }

  void _updateRating(int rating) {
    if (!widget.isEditable) return;
    
    setState(() {
      _currentRating = rating;
      _sliderValue = rating.toDouble();
    });
    widget.onRatingChanged(rating);
  }

  void _updateSlider(double value) {
    if (!widget.isEditable) return;
    
    final rating = value.round();
    setState(() {
      _currentRating = rating;
      _sliderValue = value;
    });
    widget.onRatingChanged(rating);
  }

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

  Widget _buildEmojiFace(int rating, bool isSelected) {
    final color = _getEmotionColor(rating);
    final size = isSelected ? 40.0 : 35.0;
    
    return GestureDetector(
      onTap: () => _updateRating(rating),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected 
            ? Border.all(color: Colors.black, width: 2)
            : null,
          boxShadow: isSelected 
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
        ),
        child: _buildEmojiExpression(rating),
      ),
    );
  }

  Widget _buildEmojiExpression(int rating) {
    switch (rating) {
      case 1: // Very Happy
        return const Icon(
          Icons.sentiment_very_satisfied,
          color: Colors.white,
          size: 24,
        );
      case 2: // Happy
        return const Icon(
          Icons.sentiment_satisfied,
          color: Colors.white,
          size: 24,
        );
      case 3: // Neutral
        return const Icon(
          Icons.sentiment_neutral,
          color: Colors.white,
          size: 24,
        );
      case 4: // Sad
        return const Icon(
          Icons.sentiment_dissatisfied,
          color: Colors.white,
          size: 24,
        );
      case 5: // Very Sad
        return const Icon(
          Icons.sentiment_very_dissatisfied,
          color: Colors.white,
          size: 24,
        );
      default:
        return const Icon(
          Icons.sentiment_neutral,
          color: Colors.white,
          size: 24,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.emoji_emotions,
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'How are you feeling?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Emoji faces row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final rating = index + 1;
              final isSelected = rating == _currentRating;
              return _buildEmojiFace(rating, isSelected);
            }),
          ),
          
          const SizedBox(height: 12),
          
          // Emotion label
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getEmotionColor(_currentRating).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getEmotionColor(_currentRating),
                  width: 1,
                ),
              ),
              child: Text(
                _getEmotionLabel(_currentRating),
                style: TextStyle(
                  color: _getEmotionColor(_currentRating),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Slider
          Column(
            children: [
              // Slider labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Positive',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Negative',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.remove, color: Colors.red, size: 16),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Color-coded slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _getEmotionColor(_currentRating),
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: _getEmotionColor(_currentRating),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(
                  value: _sliderValue,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: widget.isEditable ? _updateSlider : null,
                  onChangeEnd: (value) {
                    // Ensure we snap to exact integer values
                    _updateRating(value.round());
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
