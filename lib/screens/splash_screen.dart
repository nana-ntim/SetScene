// File location: lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  // Logo opacity animation
  double _logoOpacity = 0.0;
  double _textOpacity = 0.0;
  double _taglineOpacity = 0.0;
  double _loaderOpacity = 0.0;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Create animations
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Start the staggered animations
    _startAnimations();
  }

  void _startAnimations() {
    // Start the main animation controller
    _animationController.forward();

    // Staggered animations for different elements
    Timer(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _logoOpacity = 1.0);
    });

    Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _textOpacity = 1.0);
    });

    Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _taglineOpacity = 1.0);
    });

    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _loaderOpacity = 1.0);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[900]!.withOpacity(0.3), Colors.black],
            stops: const [0.2, 0.8],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container with animation
                  AnimatedOpacity(
                    opacity: _logoOpacity,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeIn,
                    child: Transform.scale(
                      scale: _scaleAnimation.value * _pulseAnimation.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background gradient for the logo
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(35),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.white, Colors.grey[200]!],
                                ),
                              ),
                            ),
                            // Logo icon
                            const Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                              size: 70,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // App name with animation
                  AnimatedOpacity(
                    opacity: _textOpacity,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeIn,
                    child: const Text(
                      'SETSCENE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tagline with animation
                  AnimatedOpacity(
                    opacity: _taglineOpacity,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeIn,
                    child: Text(
                      'Discover perfect filming locations',
                      style: TextStyle(color: Colors.grey[400], fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Loading indicator with animation
                  AnimatedOpacity(
                    opacity: _loaderOpacity,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeIn,
                    child: Container(
                      width: 50,
                      height: 50,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
