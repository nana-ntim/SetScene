import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:setscene/firebase_config.dart';
import 'package:setscene/screens/home_screen.dart';
import 'package:setscene/screens/login_screen.dart';
import 'package:setscene/screens/splash_screen.dart';
import 'package:setscene/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  await FirebaseConfig.initialize();
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          }
          return const HomeScreen();
        }

        // Loading state while checking authentication
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ),
        );
      },
    );
  }
}
