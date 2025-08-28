import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/diary_entry.dart';

class SearchService {
  final CollectionReference<Map<String, dynamic>> entries = 
      FirebaseFirestore.instance.collection('entries');
  
  // Search result cache
  static final Map<String, List<DiaryEntry>> _searchCache = {};
  static final Map<String, DateTime> _searchCacheTimestamps = {};
  static const Duration _searchCacheExpiry = Duration(minutes: 10);
  
  // Debounce timer for search queries
  static final Map<String, DateTime> _lastSearchTime = {};
  static const Duration _searchDebounce = Duration(milliseconds: 300);

  /// Perform optimized search with multiple strategies
  Future<List<DiaryEntry>> searchEntries(
    String userId, 
    String query, {
    SearchStrategy strategy = SearchStrategy.smart,
    int limit = 50,
    bool useCache = true,
  }) async {
    if (query.trim().isEmpty) return [];
    
    final queryKey = query.toLowerCase().trim();
    final cacheKey = '${userId}_$queryKey';
    
    // Check debounce
    if (_isSearchThrottled(userId)) {
      return _getCachedSearchResults(cacheKey);
    }
    
    // Check cache first
    if (useCache) {
      final cachedResults = _getCachedSearchResults(cacheKey);
      if (cachedResults.isNotEmpty) {
        return cachedResults;
      }
    }
    
    // Update last search time
    _lastSearchTime[userId] = DateTime.now();
    
    List<DiaryEntry> results;
    
    switch (strategy) {
      case SearchStrategy.smart:
        results = await _smartSearch(userId, queryKey, limit);
        break;
      case SearchStrategy.title:
        results = await _titleSearch(userId, queryKey, limit);
        break;
      case SearchStrategy.content:
        results = await _contentSearch(userId, queryKey, limit);
        break;
      case SearchStrategy.tags:
        results = await _tagsSearch(userId, queryKey, limit);
        break;
      case SearchStrategy.fullText:
        results = await _fullTextSearch(userId, queryKey, limit);
        break;
    }
    
    // Cache results
    _cacheSearchResults(cacheKey, results);
    
    return results;
  }

  /// Smart search that tries multiple strategies and combines results
  Future<List<DiaryEntry>> _smartSearch(String userId, String query, int limit) async {
    try {
      // Use optimized Firestore search
      return await _optimizedFirestoreSearch(userId, query, limit);
    } catch (e) {
      print('Error in smart search: $e');
      return [];
    }
  }

  /// Optimized Firestore search with better query structure
  Future<List<DiaryEntry>> _optimizedFirestoreSearch(
    String userId, 
    String query, 
    int limit
  ) async {
    try {
      // Build optimized query
      Query<Map<String, dynamic>> baseQuery = entries
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit * 2); // Get more results for better filtering
      
      final snapshot = await baseQuery.get();
      
      if (snapshot.docs.isEmpty) return [];
      
      // Process results with optimized filtering
      final results = <DiaryEntry>[];
      final queryWords = query.split(' ').where((word) => word.length > 2).toList();
      
      for (final doc in snapshot.docs) {
        if (results.length >= limit) break;
        
        final entry = DiaryEntry.fromFirestore(doc);
        if (_matchesQuery(entry, query, queryWords)) {
          results.add(entry);
        }
      }
      
      return results;
    } catch (e) {
      print('Error in optimized Firestore search: $e');
      return [];
    }
  }

  /// Check if entry matches search query with optimized logic
  bool _matchesQuery(DiaryEntry entry, String query, List<String> queryWords) {
    // Exact match check (highest priority)
    if (entry.title.toLowerCase().contains(query) ||
        entry.content.toLowerCase().contains(query)) {
      return true;
    }
    
    // Multi-word search
    if (queryWords.length > 1) {
      int matchCount = 0;
      for (final word in queryWords) {
        if (entry.title.toLowerCase().contains(word) ||
            entry.content.toLowerCase().contains(word) ||
            entry.tags.any((tag) => tag.toLowerCase().contains(word))) {
          matchCount++;
        }
      }
      // Require at least 50% of words to match
      return matchCount >= (queryWords.length / 2).ceil();
    }
    
    // Single word search
    return entry.title.toLowerCase().contains(query) ||
           entry.content.toLowerCase().contains(query) ||
           entry.tags.any((tag) => tag.toLowerCase().contains(query));
  }

  /// Title-only search
  Future<List<DiaryEntry>> _titleSearch(String userId, String query, int limit) async {
    try {
      final snapshot = await entries
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => DiaryEntry.fromFirestore(doc))
          .where((entry) => entry.title.toLowerCase().contains(query))
          .toList();
    } catch (e) {
      print('Error in title search: $e');
      return [];
    }
  }

  /// Content-only search
  Future<List<DiaryEntry>> _contentSearch(String userId, String query, int limit) async {
    try {
      final snapshot = await entries
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => DiaryEntry.fromFirestore(doc))
          .where((entry) => entry.content.toLowerCase().contains(query))
          .toList();
    } catch (e) {
      print('Error in content search: $e');
      return [];
    }
  }

  /// Tags-only search
  Future<List<DiaryEntry>> _tagsSearch(String userId, String query, int limit) async {
    try {
      final snapshot = await entries
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => DiaryEntry.fromFirestore(doc))
          .where((entry) => entry.tags.any((tag) => tag.toLowerCase().contains(query)))
          .toList();
    } catch (e) {
      print('Error in tags search: $e');
      return [];
    }
  }

  /// Full-text search (most comprehensive but slowest)
  Future<List<DiaryEntry>> _fullTextSearch(String userId, String query, int limit) async {
    try {
      final snapshot = await entries
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => DiaryEntry.fromFirestore(doc))
          .where((entry) =>
              entry.title.toLowerCase().contains(query) ||
              entry.content.toLowerCase().contains(query) ||
              entry.tags.any((tag) => tag.toLowerCase().contains(query)))
          .toList();
    } catch (e) {
      print('Error in full-text search: $e');
      return [];
    }
  }

  /// Check if search is throttled
  bool _isSearchThrottled(String userId) {
    final lastSearch = _lastSearchTime[userId];
    if (lastSearch == null) return false;
    
    return DateTime.now().difference(lastSearch) < _searchDebounce;
  }

  /// Get cached search results
  List<DiaryEntry> _getCachedSearchResults(String cacheKey) {
    if (_searchCache.containsKey(cacheKey)) {
      final timestamp = _searchCacheTimestamps[cacheKey];
      if (timestamp != null && 
          DateTime.now().difference(timestamp) < _searchCacheExpiry) {
        return _searchCache[cacheKey] ?? [];
      }
    }
    return [];
  }

  /// Cache search results
  void _cacheSearchResults(String cacheKey, List<DiaryEntry> results) {
    _searchCache[cacheKey] = results;
    _searchCacheTimestamps[cacheKey] = DateTime.now();
  }

  /// Clear search cache for a user
  void clearSearchCache(String userId) {
    final keysToRemove = _searchCache.keys
        .where((key) => key.startsWith('${userId}_'))
        .toList();
    
    for (final key in keysToRemove) {
      _searchCache.remove(key);
      _searchCacheTimestamps.remove(key);
    }
  }

  /// Get search suggestions based on user's entries
  Future<List<String>> getSearchSuggestions(String userId, String partialQuery) async {
    if (partialQuery.length < 2) return [];
    
    try {
      final snapshot = await entries
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(100)
          .get();
      
      final suggestions = <String>{};
      
      for (final doc in snapshot.docs) {
        try {
          final entry = DiaryEntry.fromFirestore(doc);
          
          // Add title suggestions
          if (entry.title.isNotEmpty && 
              entry.title.toLowerCase().contains(partialQuery.toLowerCase())) {
            suggestions.add(entry.title);
          }
          
          // Add tag suggestions
          for (final tag in entry.tags) {
            if (tag.isNotEmpty && 
                tag.toLowerCase().contains(partialQuery.toLowerCase())) {
              suggestions.add(tag);
            }
          }
          
          // Limit suggestions to avoid performance issues
          if (suggestions.length >= 10) break;
        } catch (e) {
          // Skip malformed entries
          continue;
        }
      }
      
      return suggestions.take(10).toList();
    } catch (e) {
      print('Error getting search suggestions: $e');
      return [];
    }
  }
  
  /// Dispose of any resources (if needed in the future)
  void dispose() {
    // Currently no resources to dispose, but method is here for future use
  }
}

/// Search strategies for different use cases
enum SearchStrategy {
  smart,      // Automatically choose best strategy
  title,      // Search only in titles
  content,    // Search only in content
  tags,       // Search only in tags
  fullText,   // Search everywhere (slowest)
}
