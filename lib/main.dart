// File location: lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:setscene/screens/home_screen.dart';
import 'package:setscene/screens/login_screen.dart';
import 'package:setscene/screens/splash_screen.dart';
import 'package:setscene/services/auth_service.dart';
import 'package:setscene/services/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Set preferred orientations for better performance
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Set system UI overlay style for a more immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Supabase
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  print("main: Initializing Supabase with URL: $supabaseUrl");
  print(
    "main: Anon key starts with: ${supabaseKey.isNotEmpty ? supabaseKey.substring(0, 5) + '...' : 'empty'}",
  );

  await SupabaseService.initialize(supabaseUrl, supabaseKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SetScene',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: Colors.blue[600],
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue[600]!,
          secondary: Colors.blue[400]!,
          surface: Colors.grey[900]!,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[900],
          labelStyle: TextStyle(color: Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[800]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[800]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[400]!),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.blue[400]),
        ),
      ),
      home: const InitialScreen(),
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  _InitialScreenState createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate after a short delay for the splash screen
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        print("InitialScreen: Navigating to AuthWrapper after splash");
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const AuthWrapper(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

// AuthWrapper class for main.dart

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String? _error;
  int _retryCount = 0;
  final int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    // Initialize auth check
    print("AuthWrapper: Initializing");
    _checkAuthState();
  }

  // Check authentication state and verify user profile
  Future<void> _checkAuthState() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print("AuthWrapper: Checking auth state");

      // Get the current user directly from Supabase
      final user = SupabaseService.client.auth.currentUser;

      if (user != null) {
        print("AuthWrapper: User is logged in (ID: ${user.id})");

        try {
          // Check if user profile exists in database
          final profileCheck =
              await SupabaseService.client
                  .from('users')
                  .select()
                  .eq('id', user.id)
                  .maybeSingle();

          if (profileCheck == null) {
            // Profile doesn't exist, try to create it
            print("AuthWrapper: User profile doesn't exist, creating it");

            // Use the AuthService to ensure profile creation with proper fallback
            final userProfile = await _authService.getCurrentUser();

            if (userProfile == null && _retryCount < _maxRetries) {
              // Profile still doesn't exist, retry
              _retryCount++;
              print(
                "AuthWrapper: Profile creation failed, retrying (attempt $_retryCount)",
              );
              await Future.delayed(const Duration(seconds: 1));
              return _checkAuthState();
            } else if (userProfile == null) {
              // Max retries reached, show error
              throw Exception(
                "Failed to create user profile after $_maxRetries attempts",
              );
            }
          }

          // At this point, we're confident the profile exists or we have a fallback
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        } catch (profileError) {
          print("AuthWrapper: Error with user profile: $profileError");

          // Allow proceeding to home screen even with profile error
          // This is a key change to prevent login loops
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        print("AuthWrapper: No user logged in");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('AuthWrapper: Error in auth state check: $e');
      if (mounted) {
        setState(() {
          _error = 'Something went wrong. Please try signing in again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while initially checking auth
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      );
    }

    // Check if user is authenticated
    final user = SupabaseService.client.auth.currentUser;
    print(
      "AuthWrapper build: Current user is ${user != null ? 'logged in' : 'not logged in'}",
    );

    // If there's no authenticated user, show login screen
    if (user == null) {
      print("AuthWrapper: Showing login screen");
      // If there was an error, pass it to login screen
      if (_error != null) {
        return LoginScreen(initialError: _error);
      }

      return const LoginScreen();
    }

    // If user is authenticated, show home screen
    // Even if profile has issues, we'll proceed to home screen
    print("AuthWrapper: Showing home screen for user: ${user.id}");
    return const HomeScreen();
  }
}
