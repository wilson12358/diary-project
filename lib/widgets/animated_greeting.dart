import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AnimatedGreeting extends StatefulWidget {
  const AnimatedGreeting({Key? key}) : super(key: key);

  @override
  _AnimatedGreetingState createState() => _AnimatedGreetingState();
}

class _AnimatedGreetingState extends State<AnimatedGreeting> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Cache greeting text to avoid unnecessary rebuilds
  String? _cachedGreeting;
  DateTime? _lastGreetingUpdate;

  @override
  void initState() {
    super.initState();
    
    // Optimize animation durations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600), // Reduced duration
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500), // Reduced duration
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations with staggered timing
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final greeting = _getGreeting(authService.user?.displayName);
        
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome back to your diary',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9), // Updated for new Flutter version
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getGreeting(String? displayName) {
    final now = DateTime.now();
    
    // Check if we can use cached greeting (update every hour)
    if (_cachedGreeting != null && _lastGreetingUpdate != null) {
      if (now.difference(_lastGreetingUpdate!).inHours < 1) {
        return _cachedGreeting!;
      }
    }
    
    final hour = now.hour;
    String timeGreeting;
    
    if (hour < 12) {
      timeGreeting = 'Good Morning';
    } else if (hour < 17) {
      timeGreeting = 'Good Afternoon';
    } else {
      timeGreeting = 'Good Evening';
    }
    
    final greeting = displayName != null && displayName.isNotEmpty
        ? '$timeGreeting, $displayName!'
        : '$timeGreeting!';
    
    // Cache the greeting
    _cachedGreeting = greeting;
    _lastGreetingUpdate = now;
    
    return greeting;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}