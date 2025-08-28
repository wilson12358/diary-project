import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/diary_entry.dart';

class FirestoreService {
  final CollectionReference<Map<String, dynamic>> entries = 
      FirebaseFirestore.instance.collection('entries');
  
  // Advanced cache for better performance
  static final Map<String, List<DiaryEntry>> _entriesCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static final Map<String, List<DiaryEntry>> _searchCache = {};
  static final Map<String, DateTime> _searchCacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 10); // Increased cache time
  static const Duration _searchCacheExpiry = Duration(minutes: 15); // Longer search cache
  
  // Pagination settings
  static const int _pageSize = 15; // Reduced for faster loading
  static const int _searchLimit = 100; // Optimized search limit

  Future<String> addEntry(DiaryEntry entry) async {
    try {
      DocumentReference docRef = await entries.add(entry.toFirestore());
      
      // Invalidate cache when adding new entry
      _invalidateCache(entry.userId);
      
      return docRef.id;
    } catch (e) {
      print('Error adding entry: $e');
      rethrow;
    }
  }

  Future<void> updateEntry(DiaryEntry entry) async {
    try {
      await entries.doc(entry.id).update(entry.toFirestore());
      
      // Invalidate cache when updating entry
      _invalidateCache(entry.userId);
    } catch (e) {
      print('Error updating entry: $e');
      rethrow;
    }
  }

  Future<DiaryEntry> deleteEntry(String entryId) async {
    try {
      // First get the entry to access its media URLs
      DocumentSnapshot<Map<String, dynamic>> doc = await entries.doc(entryId).get();
      if (doc.exists) {
        DiaryEntry entry = DiaryEntry.fromFirestore(doc);
        // Delete the entry from Firestore
        await entries.doc(entryId).delete();
        
        // Invalidate cache when deleting entry
        _invalidateCache(entry.userId);
        
        return entry;
      } else {
        throw Exception('Entry not found');
      }
    } catch (e) {
      print('Error deleting entry: $e');
      rethrow;
    }
  }

  // Batch operations for better performance
  Future<void> addMultipleEntries(List<DiaryEntry> entries) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      
      for (DiaryEntry entry in entries) {
        DocumentReference docRef = this.entries.doc();
        batch.set(docRef, entry.toFirestore());
      }
      
      await batch.commit();
      
      // Invalidate cache for all affected users
      for (DiaryEntry entry in entries) {
        _invalidateCache(entry.userId);
      }
    } catch (e) {
      print('Error adding multiple entries: $e');
      rethrow;
    }
  }

  Future<List<DiaryEntry>> deleteMultipleEntries(List<String> entryIds) async {
    try {
      // First get all entries to access their media URLs
      List<DiaryEntry> deletedEntries = [];
      Set<String> affectedUsers = {};
      
      for (String entryId in entryIds) {
        try {
          DocumentSnapshot<Map<String, dynamic>> doc = await entries.doc(entryId).get();
          if (doc.exists) {
            DiaryEntry entry = DiaryEntry.fromFirestore(doc);
            deletedEntries.add(entry);
            affectedUsers.add(entry.userId);
          }
        } catch (e) {
          print('Error getting entry $entryId: $e');
        }
      }
      
      // Delete entries in a batch
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (String entryId in entryIds) {
        DocumentReference docRef = entries.doc(entryId);
        batch.delete(docRef);
      }
      await batch.commit();
      
      // Invalidate cache for all affected users
      for (String userId in affectedUsers) {
        _invalidateCache(userId);
      }
      
      return deletedEntries;
    } catch (e) {
      print('Error deleting multiple entries: $e');
      rethrow;
    }
  }

  Stream<List<DiaryEntry>> getEntriesForUser(String userId) {
    try {
      print('🔥 Firestore Debug: Setting up stream for user: $userId');
      print('🔥 Firestore Debug: Collection path: ${entries.path}');
      print('🔥 Firestore Debug: User ID being queried: $userId');
      
      return entries
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(_pageSize) // Limit results for better performance
          .snapshots()
          .map((snapshot) {
            print('🔥 Firestore Debug: Received snapshot with ${snapshot.docs.length} documents');
            List<DiaryEntry> entries = snapshot.docs
                .map((doc) => DiaryEntry.fromFirestore(doc))
                .toList();
            
            // Update cache
            _entriesCache[userId] = entries;
            _cacheTimestamps[userId] = DateTime.now();
            
            return entries;
          })
          .handleError((error) {
            print('🔥 Firestore Debug: Stream error: $error');
            throw error;
          });
    } catch (e) {
      print('🔥 Firestore Debug: Error setting up stream: $e');
      throw e;
    }
  }

  // Get entries with pagination for better performance
  Future<List<DiaryEntry>> getEntriesForUserPaginated(
    String userId, {
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    int limit = _pageSize,
  }) async {
    try {
      Query<Map<String, dynamic>> query = entries
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
      
      List<DiaryEntry> resultEntries = snapshot.docs
          .map((doc) => DiaryEntry.fromFirestore(doc))
          .toList();
      
      return resultEntries;
    } catch (e) {
      print('Error getting paginated entries for user: $e');
      rethrow;
    }
  }

  // Get cached entries if available and not expired
  List<DiaryEntry>? getCachedEntries(String userId) {
    if (_entriesCache.containsKey(userId)) {
      DateTime? timestamp = _cacheTimestamps[userId];
      if (timestamp != null && 
          DateTime.now().difference(timestamp) < _cacheExpiry) {
        return _entriesCache[userId];
      }
    }
    return null;
  }

  // Invalidate cache for a specific user
  void _invalidateCache(String userId) {
    _entriesCache.remove(userId);
    _cacheTimestamps.remove(userId);
  }

  // Clear all cache
  void clearCache() {
    _entriesCache.clear();
    _cacheTimestamps.clear();
  }

  /// Fast calendar loading with caching
  Future<List<DiaryEntry>> getEntriesForDate(String userId, DateTime date) async {
    try {
      // Check cache first
      String cacheKey = '${userId}_${date.year}_${date.month}_${date.day}';
      if (_entriesCache.containsKey(cacheKey)) {
        DateTime? timestamp = _cacheTimestamps[cacheKey];
        if (timestamp != null && 
            DateTime.now().difference(timestamp) < _cacheExpiry) {
          return _entriesCache[cacheKey]!;
        }
      }

      DateTime startOfDay = DateTime(date.year, date.month, date.day);
      DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Use a more efficient query that works with existing indexes
      QuerySnapshot<Map<String, dynamic>> snapshot = await entries
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(_pageSize)
          .get();

      // Filter results in memory for the specific date range
      List<DiaryEntry> results = snapshot.docs
          .map((doc) => DiaryEntry.fromFirestore(doc))
          .where((entry) => 
              entry.date.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
              entry.date.isBefore(endOfDay.add(const Duration(seconds: 1)))
          )
          .toList();
      
      // Cache results
      _entriesCache[cacheKey] = results;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      return results;
    } catch (e) {
      print('Error getting entries for date: $e');
      rethrow;
    }
  }

  /// Get entries for month (optimized for calendar view)
  Future<List<DiaryEntry>> getEntriesForMonth(String userId, DateTime month) async {
    try {
      // Check cache first
      String cacheKey = '${userId}_${month.year}_${month.month}';
      if (_entriesCache.containsKey(cacheKey)) {
        DateTime? timestamp = _cacheTimestamps[cacheKey];
        if (timestamp != null && 
            DateTime.now().difference(timestamp) < _cacheExpiry) {
          return _entriesCache[cacheKey]!;
        }
      }

      DateTime startOfMonth = DateTime(month.year, month.month, 1);
      DateTime endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      // Use a more efficient query that works with existing indexes
      // For calendar view, we need a higher limit to ensure we get all month entries
      QuerySnapshot<Map<String, dynamic>> snapshot = await entries
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(1000) // Higher limit for calendar view
          .get();

      // Filter results in memory for the specific month range
      List<DiaryEntry> results = snapshot.docs
          .map((doc) => DiaryEntry.fromFirestore(doc))
          .where((entry) => 
              entry.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
              entry.date.isBefore(endOfMonth.add(const Duration(seconds: 1)))
          )
          .toList();
      
      // Cache results
      _entriesCache[cacheKey] = results;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      return results;
    } catch (e) {
      print('Error getting entries for month: $e');
      return [];
    }
  }

  // Get entries count for a user (useful for pagination)
  Future<int> getEntriesCount(String userId) async {
    try {
      AggregateQuerySnapshot snapshot = await entries
          .where('userId', isEqualTo: userId)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting entries count: $e');
      return 0;
    }
  }

  /// Fast search with caching and indexing
  Future<List<DiaryEntry>> searchEntries(String userId, String query, {int limit = 50}) async {
    try {
      // Check cache first
      String cacheKey = '${userId}_${query.toLowerCase().trim()}';
      if (_searchCache.containsKey(cacheKey)) {
        DateTime? timestamp = _searchCacheTimestamps[cacheKey];
        if (timestamp != null && 
            DateTime.now().difference(timestamp) < _searchCacheExpiry) {
          return _searchCache[cacheKey]!;
        }
      }

      // Optimized search query
      final snapshot = await entries
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      
      // Filter results in memory for better performance
      List<DiaryEntry> results = snapshot.docs
          .map((doc) => DiaryEntry.fromFirestore(doc))
          .where((entry) {
            final searchText = query.toLowerCase();
            return entry.title.toLowerCase().contains(searchText) ||
                   entry.content.toLowerCase().contains(searchText) ||
                   entry.tags.any((tag) => tag.toLowerCase().contains(searchText));
          })
          .toList();
      
      // Cache results
      _searchCache[cacheKey] = results;
      _searchCacheTimestamps[cacheKey] = DateTime.now();
      
      return results;
    } catch (e) {
      print('Error searching entries: $e');
      return [];
    }
  }

  /// Get entries for search indexing (optimized for search operations)
  Future<List<DiaryEntry>> getEntriesForSearchIndex(String userId, {int limit = 1000}) async {
    try {
      final snapshot = await entries
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => DiaryEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting entries for search index: $e');
      return [];
    }
  }

  /// Get recent entries for quick search suggestions
  Future<List<DiaryEntry>> getRecentEntriesForSuggestions(String userId, {int limit = 50}) async {
    try {
      final snapshot = await entries
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => DiaryEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting recent entries for suggestions: $e');
      return [];
    }
  }

  /// Get most recently used tags for a user
  Future<List<String>> getRecentTags(String userId, {int limit = 10}) async {
    try {
      // Get recent entries to extract tags
      final recentEntries = await getRecentEntriesForSuggestions(userId, limit: 100);
      
      // Extract all tags from recent entries
      Map<String, DateTime> tagUsageMap = {};
      
      for (DiaryEntry entry in recentEntries) {
        for (String tag in entry.tags) {
          // Use the entry date as the tag usage date
          // If tag was used multiple times, keep the most recent date
          if (!tagUsageMap.containsKey(tag) || 
              entry.date.isAfter(tagUsageMap[tag]!)) {
            tagUsageMap[tag] = entry.date;
          }
        }
      }
      
      // Sort tags by most recent usage and return top tags
      List<String> recentTags = tagUsageMap.keys.toList()
        ..sort((a, b) => tagUsageMap[b]!.compareTo(tagUsageMap[a]!));
      
      return recentTags.take(limit).toList();
    } catch (e) {
      print('Error getting recent tags: $e');
      return [];
    }
  }
}
