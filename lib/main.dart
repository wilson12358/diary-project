import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Error initializing Firebase: $e');
    // Handle Firebase initialization error gracefully
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          // Wait for theme service to be initialized
          if (!themeService.isInitialized) {
            return MaterialApp(
              title: 'Voice Diary',
              theme: AppTheme.getDynamicTheme(AppThemeType.orange), // Default theme while loading
              home: Scaffold(
                backgroundColor: AppColors.primaryColor,
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              debugShowCheckedModeBanner: false,
            );
          }
          
          return MaterialApp(
            title: 'Voice Diary',
            theme: AppTheme.getDynamicTheme(themeService.currentTheme),
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
            routes: {
              '/home': (context) => MainNavigationScreen(),
            },
            // Performance optimizations
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  // Optimize text scaling for better performance
                  textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400), // Reduced duration
          child: authService.user != null 
            ? MainNavigationScreen() 
            : LoginScreen(),
        );
      },
    );
  }
}
