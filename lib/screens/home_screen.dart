import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/diary_entry.dart';
import '../widgets/entry_card.dart';
import '../widgets/animated_greeting.dart';
import '../widgets/modern_fab.dart';
import '../utils/app_theme.dart';
import 'new_entry_screen.dart';
import 'calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  // Advanced cache for entries to avoid unnecessary rebuilds
  List<DiaryEntry>? _cachedEntries;
  String? _lastUserId;
  bool _isLoading = false;
  String? _lastError;
  
  // Performance optimization flags
  static const Duration _cacheTimeout = Duration(seconds: 3);
  static const int _maxDisplayEntries = 8; // Increased for better UX

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600), // Reduced duration
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Reduced offset
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              // Add physics for better scrolling performance
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Enhanced Modern App Bar
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                                    colors: [
              AppColors.primaryColor,
              AppColors.secondaryColor.withValues(alpha: 0.3),
              AppColors.white,
            ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AnimatedGreeting(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                      ],
                    ),
                  ),
                ),
                
                // Recent Entries Section
                SliverToBoxAdapter(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.history, color: AppColors.accentColor),
                          const SizedBox(width: 8),
                          Text(
                            'Recent Entries',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Entries List with Performance Optimizations
                _buildEntriesList(authService.user!.uid),
                
                SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
            // Modern Floating Action Button
            Positioned(
              right: 20,
              bottom: 20,
              child: ModernFAB(
                onPressed: _navigateToNewEntry,
                icon: Icons.add,
                tooltip: 'Add New Entry',
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList(String userId) {
    // Check if we can use cached data
    if (_cachedEntries != null && _lastUserId == userId) {
      return _buildCachedEntriesList();
    }

    // Show cached data immediately if available (for instant loading)
    if (_cachedEntries != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFreshData(userId);
      });
      return _buildCachedEntriesList();
    }

    return FutureBuilder<List<DiaryEntry>>(
      future: _loadEntriesWithTimeout(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          _lastError = snapshot.error.toString();
          return SliverToBoxAdapter(
            child: _buildErrorState(_lastError!),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: _buildLoadingState(),
          );
        }

        List<DiaryEntry> entries = snapshot.data ?? [];
        
        // Cache the entries
        _cachedEntries = entries;
        _lastUserId = userId;
        _lastError = null;

        if (entries.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(),
          );
        }

        return SliverList.builder(
          itemCount: entries.length > _maxDisplayEntries ? _maxDisplayEntries : entries.length,
          itemBuilder: (context, index) {
            return _buildEntryCard(entries[index], index);
          },
        );
      },
    );
  }

  Widget _buildCachedEntriesList() {
    if (_cachedEntries == null || _cachedEntries!.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(),
      );
    }

    return SliverList.builder(
      itemCount: _cachedEntries!.length > _maxDisplayEntries ? _maxDisplayEntries : _cachedEntries!.length,
      itemBuilder: (context, index) {
        return _buildEntryCard(_cachedEntries![index], index);
      },
    );
  }

  /// Load entries with timeout for fast loading
  Future<List<DiaryEntry>> _loadEntriesWithTimeout(String userId) async {
    try {
      print('🏠 Home Debug: Loading entries for user: $userId');
      // Use timeout to ensure fast loading
      return await _firestoreService
          .getEntriesForUser(userId)
          .first
          .timeout(_cacheTimeout, onTimeout: () {
            print('🏠 Home Debug: Loading timeout, returning cached data');
            // Return cached data if timeout occurs
            if (_cachedEntries != null) {
              return _cachedEntries!;
            }
            throw TimeoutException('Loading timeout', _cacheTimeout);
          });
    } catch (e) {
      print('🏠 Home Debug: Error loading entries: $e');
      // Return cached data if available
      if (_cachedEntries != null) {
        print('🏠 Home Debug: Returning cached entries due to error');
        return _cachedEntries!;
      }
      rethrow;
    }
  }

  /// Load fresh data in background
  Future<void> _loadFreshData(String userId) async {
    try {
      final freshEntries = await _firestoreService.getEntriesForUser(userId).first;
      if (mounted && freshEntries.isNotEmpty) {
        setState(() {
          _cachedEntries = freshEntries;
          _lastUserId = userId;
        });
      }
    } catch (e) {
      // Silently handle background refresh errors
      if (mounted) {
        print('Background refresh error: $e');
      }
    }
  }

  Widget _buildEntryCard(DiaryEntry entry, int index) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.2, 0), // Reduced offset
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Interval(
          (index * 0.08).clamp(0.0, 1.0), // Reduced interval
          ((index * 0.08) + 0.25).clamp(0.0, 1.0), // Reduced duration
          curve: Curves.easeOutCubic,
        ),
      )),
      child: EntryCard(
        entry: entry,
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      height: 140,
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              'New Entry',
              Icons.edit_note,
              _navigateToNewEntry,
              AppColors.white,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey[50]!],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionCard(
              'View Calendar',
              Icons.calendar_month,
              () => _navigateToCalendar(),
              AppColors.white,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.blue[50]!],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title, 
    IconData icon, 
    VoidCallback onTap, 
    Color bgColor, {
    LinearGradient? gradient,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 30,
              offset: const Offset(0, 16),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon, 
                size: 28, 
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.accentColor,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCalendar() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CalendarScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 800), // Reduced duration
            child: Icon(
              Icons.book_outlined,
              size: 80,
              color: AppColors.secondaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Start Your Journey',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.accentColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your first diary entry is waiting to be written',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _navigateToNewEntry,
            icon: const Icon(Icons.create),
            label: const Text('Write First Entry'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          CircularProgressIndicator(color: AppColors.primaryColor),
          const SizedBox(height: 20),
          Text(
            'Loading your memories...',
            style: TextStyle(color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 20),
          const Text(
            'Something went wrong',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(error, style: TextStyle(color: AppColors.grey)),
        ],
      ),
    );
  }

  void _navigateToNewEntry() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => NewEntryScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300), // Reduced duration
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }
}
