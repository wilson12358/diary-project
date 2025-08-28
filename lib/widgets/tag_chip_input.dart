import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';

class TagChipInput extends StatefulWidget {
  final List<String> tags;
  final Function(List<String>) onTagsChanged;

  const TagChipInput({
    super.key,
    required this.tags,
    required this.onTagsChanged,
  });

  @override
  _TagChipInputState createState() => _TagChipInputState();
}

class _TagChipInputState extends State<TagChipInput> {
  final TextEditingController _controller = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  
  List<String> _recentTags = [];
  bool _isLoadingRecentTags = false;

  @override
  void initState() {
    super.initState();
    _loadRecentTags();
  }

  Future<void> _loadRecentTags() async {
    try {
      setState(() {
        _isLoadingRecentTags = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.user != null) {
        final recentTags = await _firestoreService.getRecentTags(
          authService.user!.uid,
          limit: 10, // Get more than 3 to filter out already used tags
        );
        
        if (mounted) {
          setState(() {
            _recentTags = recentTags;
            _isLoadingRecentTags = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRecentTags = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current tags
        if (widget.tags.isNotEmpty) ...[
          Text(
            'Current Tags:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: [
              ...widget.tags.map((tag) => Chip(
                label: Text(tag),
                onDeleted: () => _removeTag(tag),
                backgroundColor: Colors.blue[100],
                deleteIconColor: Colors.blue[700],
              )).toList(),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Recent tags section
        if (_recentTags.isNotEmpty) ...[
          Text(
            'Recent Tags:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoadingRecentTags)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                // Show top 3 recent tags that are not already used
                ..._recentTags
                    .where((tag) => !widget.tags.contains(tag))
                    .take(3)
                    .map((tag) => ActionChip(
                      label: Text(tag),
                      onPressed: () => _addRecentTag(tag),
                      backgroundColor: Colors.grey[100],
                      labelStyle: TextStyle(color: Colors.grey[700]),
                    ))
                    .toList(),
              ],
            ),
          const SizedBox(height: 16),
        ],

        // Add new tag button
        ActionChip(
          label: const Text('+ Add New Tag'),
          onPressed: _showAddTagDialog,
          backgroundColor: Colors.green[100],
          labelStyle: const TextStyle(color: Colors.green),
        ),
      ],
    );
  }

  void _removeTag(String tag) {
    List<String> updatedTags = List.from(widget.tags);
    updatedTags.remove(tag);
    widget.onTagsChanged(updatedTags);
  }

  void _addRecentTag(String tag) {
    if (!widget.tags.contains(tag)) {
      List<String> updatedTags = List.from(widget.tags);
      updatedTags.add(tag);
      widget.onTagsChanged(updatedTags);
    }
  }

  void _showAddTagDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Tag'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Enter tag name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => _addTag(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _controller.clear();
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: _addTag,
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addTag() {
    String newTag = _controller.text.trim().toLowerCase();
    if (newTag.isNotEmpty && !widget.tags.contains(newTag)) {
      List<String> updatedTags = List.from(widget.tags);
      updatedTags.add(newTag);
      widget.onTagsChanged(updatedTags);
    }
    _controller.clear();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
