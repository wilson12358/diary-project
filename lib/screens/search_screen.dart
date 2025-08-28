import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/diary_entry.dart';
import '../widgets/entry_card.dart';
import '../utils/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<DiaryEntry> _searchResults = [];
  List<DiaryEntry> _recentEntries = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String? _lastQuery;
  int? _selectedMood; // Add mood filter
  Timer? _searchDebounceTimer;
  
  // Performance optimization
  static const Duration _searchDebounce = Duration(milliseconds: 300);
  static const Duration _searchTimeout = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _loadRecentEntries();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  /// Load recent entries for quick suggestions
  Future<void> _loadRecentEntries() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.user!.uid;
      
      // Use timeout for fast loading
      final entries = await _firestoreService
          .getRecentEntriesForSuggestions(userId)
          .timeout(_searchTimeout);
      
      if (mounted) {
        setState(() {
          _recentEntries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading recent entries: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle search input changes with debouncing
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    // Cancel previous timer
    _searchDebounceTimer?.cancel();
    
    if (query.isEmpty && _selectedMood == null) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _lastQuery = null;
      });
      return;
    }

    // Debounce search to avoid excessive API calls
    _searchDebounceTimer = Timer(_searchDebounce, () {
      _performSearch(query);
    });
  }
  
  /// Handle mood selection
  void _onMoodSelected(int? mood) {
    setState(() {
      _selectedMood = mood;
    });
    
    // Trigger search with new mood filter
    final query = _searchController.text.trim();
    if (query.isNotEmpty || mood != null) {
      _performSearch(query);
    }
  }

  /// Perform fast search with timeout
  Future<void> _performSearch(String query) async {
    final searchKey = '${query}_${_selectedMood}';
    if (searchKey == _lastQuery) return;
    
    try {
      setState(() {
        _isSearching = true;
        _lastQuery = searchKey;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.user!.uid;
      
      // Use optimized search with timeout
      final results = await _firestoreService
          .searchEntries(userId, query)
          .timeout(_searchTimeout);
      
      // Apply mood filter if selected
      List<DiaryEntry> filteredResults = results;
      if (_selectedMood != null) {
        filteredResults = results.where((entry) => entry.emotionalRating == _selectedMood).toList();
      }
      
      if (mounted) {
        setState(() {
          _searchResults = filteredResults;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search error: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Diary'),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Mood Filter
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Mood:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // All moods option
                    _buildMoodChip(null, 'All Moods'),
                    _buildMoodChip(1, 'Very Happy 😄'),
                    _buildMoodChip(2, 'Happy 🙂'),
                    _buildMoodChip(3, 'Neutral 😐'),
                    _buildMoodChip(4, 'Sad 😔'),
                    _buildMoodChip(5, 'Very Sad 😢'),
                  ],
                ),
              ],
            ),
          ),
          
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search by title, content, or tags...',
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.search, color: Colors.white70),
                suffixIcon: _isSearching
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onTap: () {
                _searchFocusNode.requestFocus();
              },
            ),
          ),
          
          // Search Results or Recent Entries
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
    }
  
  /// Build mood chip widget
  Widget _buildMoodChip(int? mood, String label) {
    final isSelected = _selectedMood == mood;
    return GestureDetector(
      onTap: () => _onMoodSelected(mood),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryColor : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    if (_searchController.text.trim().isNotEmpty || _selectedMood != null) {
      return _buildSearchResults();
    } else {
      return _buildRecentEntries();
    }
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "${_searchController.text.trim()}"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EntryCard(
            entry: _searchResults[index],
          ),
        );
      },
    );
  }

  Widget _buildRecentEntries() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_recentEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No recent entries',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Recent Entries',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.accentColor,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentEntries.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: EntryCard(
                  entry: _recentEntries[index],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}