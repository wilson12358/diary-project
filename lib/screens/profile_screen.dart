import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/theme_service.dart';
import '../utils/app_theme.dart';
import '../utils/validators.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> 
    with TickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.white,
                        AppColors.secondaryColor,
                        AppColors.primaryColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(height: 16),
                                              Text(
                          authService.user?.email ?? 'User',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Voice Diary User',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 30),
                
                // Stats Section - Streaks and Total Entries
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Diary Journey',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentColor,
                          ),
                        ),
                        SizedBox(height: 20),
                        
                        // Stats Row
                        Row(
                          children: [
                            // Streaks
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.primaryColor.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      size: 32,
                                      color: AppColors.primaryColor,
                                    ),
                                    SizedBox(height: 8),
                                    FutureBuilder<int>(
                                      future: _getCurrentStreak(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                                          );
                                        }
                                        return Text(
                                          '${snapshot.data ?? 0}',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryColor,
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Day Streak',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            SizedBox(width: 16),
                            
                            // Total Entries
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.secondaryColor.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.book,
                                      size: 32,
                                      color: AppColors.secondaryColor,
                                    ),
                                    SizedBox(height: 8),
                                    FutureBuilder<int>(
                                      future: _getTotalEntries(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryColor),
                                          );
                                        }
                                        return Text(
                                          '${snapshot.data ?? 0}',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.secondaryColor,
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Total Entries',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.secondaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Streak Info
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accentColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: AppColors.accentColor,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Keep writing daily to maintain your streak!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.accentColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Mood Analysis Dashboard
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mood Analysis Dashboard',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentColor,
                          ),
                        ),
                        SizedBox(height: 20),
                        
                        // Mood Distribution Chart
                        Container(
                          height: 200,
                          child: FutureBuilder<Map<String, dynamic>>(
                            future: _getMoodAnalysis(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                                  ),
                                );
                              }
                              
                              if (snapshot.hasError || !snapshot.hasData) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.mood_bad,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'No mood data available',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              
                              final moodData = snapshot.data!;
                              return _buildMoodChart(moodData);
                            },
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Mood Statistics
                        Row(
                          children: [
                            Expanded(
                              child: _buildMoodStat(
                                'Most Common Mood',
                                _getMostCommonMood(),
                                Icons.emoji_emotions,
                                AppColors.primaryColor,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildMoodStat(
                                'Average Mood',
                                _getAverageMood(),
                                Icons.trending_up,
                                AppColors.secondaryColor,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Mood Trend
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accentColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.insights,
                                    size: 20,
                                    color: AppColors.accentColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Mood Insights',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accentColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              FutureBuilder<String>(
                                future: _getMoodInsights(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Text(
                                      'Analyzing your mood patterns...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.accentColor.withValues(alpha: 0.7),
                                      ),
                                    );
                                  }
                                  return Text(
                                    snapshot.data ?? 'No insights available',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.accentColor.withValues(alpha: 0.8),
                                      height: 1.4,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Theme Selection Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Compact Header
                        Row(
                          children: [
                            Icon(
                              Icons.palette,
                              size: 20,
                              color: AppColors.primaryColor,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Theme Selection',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Compact Current Theme Display
                        Consumer<ThemeService>(
                          builder: (context, themeService, child) {
                            final currentTheme = themeService.currentTheme;
                            return Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryColor.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      AppColors.getThemeIcon(currentTheme),
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppColors.getThemeName(currentTheme),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryColor,
                                          ),
                                        ),
                                        Text(
                                          AppColors.getThemeDescription(currentTheme),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primaryColor.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Compact Theme Grid
                        Consumer<ThemeService>(
                          builder: (context, themeService, child) {
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.9,
                              ),
                              itemCount: AppThemeType.values.length,
                              itemBuilder: (context, index) {
                                final theme = AppThemeType.values[index];
                                final isSelected = themeService.isThemeSelected(theme);
                                
                                return _buildCompactThemeCard(theme, isSelected);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Settings Section
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentColor,
                          ),
                        ),
                        SizedBox(height: 20),
                        
                        // Change Password
                        ListTile(
                          leading: Icon(Icons.lock, color: AppColors.primaryColor),
                          title: Text('Change Password'),
                          subtitle: Text('Update your password'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            _showChangePasswordDialog();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await authService.signOut();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                        (route) => false,
                      );
                    },
                    icon: Icon(Icons.logout),
                    label: Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  void _showChangePasswordDialog() {
    // Clear previous password input
    _passwordController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your new password below. Make sure it\'s strong and secure.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'If you get an authentication error, try signing out and signing back in first.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                hintText: 'Enter new password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isPasswordVisible,
              validator: Validators.validatePassword,
              autofocus: true,
            ),
            SizedBox(height: 12),
            Text(
              'Password must be at least 6 characters long',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _passwordController.clear();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () async {
              await _changePassword();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text('Change Password'),
          ),
        ],
      ),
    );
  }
  
  /// Change user password
  Future<void> _changePassword() async {
    // Validate password
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a new password'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password must be at least 6 characters long'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Debug: Check user status
      if (kDebugMode) {
        print('🔐 Change Password Debug:');
        print('   User ID: ${authService.userId}');
        print('   User Email: ${authService.userEmail}');
        print('   Is Authenticated: ${authService.isAuthenticated}');
        print('   Needs Re-auth: ${authService.needsReauthentication}');
      }
      
      final result = await authService.updatePassword(_passwordController.text);
      
      if (kDebugMode) {
        print('🔐 Password Update Result: $result');
      }
      
      if (result == null) {
        // Success
        if (mounted) {
          Navigator.pop(context);
          _passwordController.clear();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Password changed successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        // Error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: Duration(seconds: 5), // Show longer for errors
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔐 Change Password Error: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  /// Get current streak of consecutive days with diary entries
  Future<int> _getCurrentStreak() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.user?.uid;
      if (userId == null) return 0;

      final firestoreService = FirestoreService();
      final now = DateTime.now();
      int streak = 0;
      DateTime currentDate = DateTime(now.year, now.month, now.day);

      // Check consecutive days backwards from today
      // Limit to 365 days to prevent infinite loops
      int daysChecked = 0;
      while (daysChecked < 365) {
        final entries = await firestoreService.getEntriesForDate(userId, currentDate);
        if (entries.isEmpty) {
          break; // Streak broken
        }
        streak++;
        currentDate = currentDate.subtract(Duration(days: 1));
        daysChecked++;
      }

      return streak;
    } catch (e) {
      print('Error calculating streak: $e');
      return 0;
    }
  }

  /// Get total number of diary entries for the user
  Future<int> _getTotalEntries() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.user?.uid;
      if (userId == null) return 0;

      final firestoreService = FirestoreService();
      final count = await firestoreService.getEntriesCount(userId);
      return count;
    } catch (e) {
      print('Error getting total entries: $e');
      return 0;
    }
  }

  /// Get the longest streak achieved by the user
  Future<int> _getLongestStreak() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.user?.uid;
      if (userId == null) return 0;

      final firestoreService = FirestoreService();
      final now = DateTime.now();
      int longestStreak = 0;
      int currentStreak = 0;
      
      // Check the last 365 days for the longest streak
      for (int i = 0; i < 365; i++) {
        final date = now.subtract(Duration(days: i));
        final entries = await firestoreService.getEntriesForDate(userId, date);
        
        if (entries.isNotEmpty) {
          currentStreak++;
          if (currentStreak > longestStreak) {
            longestStreak = currentStreak;
          }
        } else {
          currentStreak = 0;
        }
      }

      return longestStreak;
    } catch (e) {
      print('Error calculating longest streak: $e');
      return 0;
    }
  }

  /// Get mood analysis data for the user
  Future<Map<String, dynamic>> _getMoodAnalysis() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.user?.uid;
      if (userId == null) return {};

      final firestoreService = FirestoreService();
      final entries = await firestoreService.getRecentEntriesForSuggestions(userId, limit: 100); // Get last 100 entries
      
      if (entries.isEmpty) return {};

      // Count mood occurrences
      Map<int, int> moodCounts = {};
      for (int i = 1; i <= 5; i++) {
        moodCounts[i] = 0;
      }
      
      for (final entry in entries) {
        if (entry.emotionalRating != null && entry.emotionalRating! > 0) {
          moodCounts[entry.emotionalRating!] = (moodCounts[entry.emotionalRating!] ?? 0) + 1;
        }
      }

      return {
        'moodCounts': moodCounts,
        'totalEntries': entries.length,
        'entriesWithMood': entries.where((e) => e.emotionalRating != null && e.emotionalRating! > 0).length,
      };
    } catch (e) {
      print('Error getting mood analysis: $e');
      return {};
    }
  }

  /// Build mood chart widget
  Widget _buildMoodChart(Map<String, dynamic> moodData) {
    final moodCounts = moodData['moodCounts'] as Map<int, int>?;
    final totalEntries = moodData['entriesWithMood'] as int? ?? 0;
    
    if (totalEntries == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mood_bad, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No mood data available', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final moodLabels = ['Very Happy 😄', 'Happy 🙂', 'Neutral 😐', 'Sad 😔', 'Very Sad 😢'];
    final moodColors = [
      Colors.green,
      Colors.lightGreen,
      Colors.orange,
      Colors.orangeAccent,
      Colors.red,
    ];

    return Column(
      children: [
        Text(
          'Mood Distribution (Last 100 Entries)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.accentColor,
          ),
        ),
        SizedBox(height: 16),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final moodRating = index + 1;
              final count = moodCounts?[moodRating] ?? 0;
              final percentage = totalEntries > 0 ? (count / totalEntries) : 0.0;
              final height = percentage * 120; // Max height 120
              
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 30,
                    height: height.clamp(4.0, 120.0),
                    decoration: BoxDecoration(
                      color: moodColors[index],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${count}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    moodLabels[index],
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  /// Build mood statistic widget
  Widget _buildMoodStat(String title, Future<String> valueFuture, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          SizedBox(height: 8),
          FutureBuilder<String>(
            future: valueFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                );
              }
              return Text(
                snapshot.data ?? 'N/A',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Get most common mood
  Future<String> _getMostCommonMood() async {
    try {
      final moodData = await _getMoodAnalysis();
      final moodCounts = moodData['moodCounts'] as Map<int, int>?;
      
      if (moodCounts == null || moodCounts.isEmpty) return 'N/A';
      
      int maxCount = 0;
      int mostCommonMood = 0;
      
      moodCounts.forEach((mood, count) {
        if (count > maxCount) {
          maxCount = count;
          mostCommonMood = mood;
        }
      });
      
      if (mostCommonMood == 0) return 'N/A';
      
      final moodLabels = ['', 'Very Happy 😄', 'Happy 🙂', 'Neutral 😐', 'Sad 😔', 'Very Sad 😢'];
      return moodLabels[mostCommonMood];
    } catch (e) {
      print('Error getting most common mood: $e');
      return 'N/A';
    }
  }

  /// Get average mood
  Future<String> _getAverageMood() async {
    try {
      final moodData = await _getMoodAnalysis();
      final moodCounts = moodData['moodCounts'] as Map<int, int>?;
      
      if (moodCounts == null || moodCounts.isEmpty) return 'N/A';
      
      int totalMood = 0;
      int totalCount = 0;
      
      moodCounts.forEach((mood, count) {
        totalMood += mood * count;
        totalCount += count;
      });
      
      if (totalCount == 0) return 'N/A';
      
      final average = totalMood / totalCount;
      return average.toStringAsFixed(1);
    } catch (e) {
      print('Error getting average mood: $e');
      return 'N/A';
    }
  }

  /// Get mood insights
  Future<String> _getMoodInsights() async {
    try {
      final moodData = await _getMoodAnalysis();
      final moodCounts = moodData['moodCounts'] as Map<int, int>?;
      final totalEntries = moodData['entriesWithMood'] as int? ?? 0;
      
      if (totalEntries == 0) return 'Start rating your mood to see insights!';
      
      if (moodCounts == null || moodCounts.isEmpty) return 'No mood data available';
      
      // Calculate insights
      int positiveMoods = (moodCounts[1] ?? 0) + (moodCounts[2] ?? 0);
      int negativeMoods = (moodCounts[4] ?? 0) + (moodCounts[5] ?? 0);
      int neutralMoods = moodCounts[3] ?? 0;
      
      final positivePercentage = (positiveMoods / totalEntries * 100).round();
      final negativePercentage = (negativeMoods / totalEntries * 100).round();
      final neutralPercentage = (neutralMoods / totalEntries * 100).round();
      
      List<String> insights = [];
      
      if (positivePercentage > 50) {
        insights.add('You\'re mostly positive (${positivePercentage}%)');
      } else if (negativePercentage > 50) {
        insights.add('You\'re experiencing more negative emotions (${negativePercentage}%)');
      } else {
        insights.add('You have a balanced emotional state');
      }
      
      if (positivePercentage > negativePercentage) {
        insights.add('Keep up the positive energy!');
      } else if (negativePercentage > positivePercentage) {
        insights.add('Consider activities that boost your mood');
      }
      
      if (neutralPercentage > 40) {
        insights.add('You often feel neutral - try new experiences');
      }
      
      return insights.join('. ');
    } catch (e) {
      print('Error getting mood insights: $e');
      return 'Unable to analyze mood patterns';
    }
    }
  
  /// Build compact theme selection card
  Widget _buildCompactThemeCard(AppThemeType theme, bool isSelected) {
    final themeColors = AppColors.themeColors[theme]!;
    final primaryColor = themeColors['primary']!;
    final secondaryColor = themeColors['secondary']!;
    final accentColor = themeColors['accent']!;
    
    return GestureDetector(
      onTap: () => _changeTheme(theme),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? primaryColor.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Theme icon
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppColors.getThemeIcon(theme),
                size: 18,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            
            // Color preview bar
            Container(
              height: 6,
              margin: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor, accentColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            SizedBox(height: 8),
            
            // Theme name
            Text(
              AppColors.getThemeName(theme),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? primaryColor : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Selection indicator
            if (isSelected) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build theme selection card
  Widget _buildThemeCard(AppThemeType theme, bool isSelected) {
    final themeColors = AppColors.themeColors[theme]!;
    final primaryColor = themeColors['primary']!;
    final secondaryColor = themeColors['secondary']!;
    final accentColor = themeColors['accent']!;
    
    return GestureDetector(
      onTap: () => _changeTheme(theme),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? primaryColor.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Theme icon
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppColors.getThemeIcon(theme),
                size: 24,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            
            // Color preview bar
            Container(
              height: 8,
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor, accentColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            SizedBox(height: 12),
            
            // Theme name
            Text(
              AppColors.getThemeName(theme),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? primaryColor : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            
            // Theme description
            Text(
              AppColors.getThemeDescription(theme),
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? primaryColor.withValues(alpha: 0.7) : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Selection indicator
            if (isSelected) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Selected',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Change application theme
  void _changeTheme(AppThemeType newTheme) async {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    await themeService.changeTheme(newTheme);
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Theme changed to ${AppColors.getThemeName(newTheme)}'),
        backgroundColor: AppColors.primaryColor,
        duration: Duration(seconds: 2),
      ),
    );
    
    // Auto-navigate to home page after theme change
    // Use a small delay to allow the SnackBar to show briefly
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        // Navigate to home page (index 0) and reset to home tab
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => MainNavigationScreen(),
          ),
          (route) => false,
        );
      }
    });
  }
  
  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}