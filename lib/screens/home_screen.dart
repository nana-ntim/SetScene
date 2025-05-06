// File: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:setscene/screens/feed_screen.dart';
import 'package:setscene/screens/create_screen.dart';
import 'package:setscene/screens/saved_screen.dart';
import 'package:setscene/screens/profile_screen.dart';
import 'package:setscene/services/auth_service.dart';
import 'package:setscene/components/custom_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  late PageController _pageController;
  late AnimationController _animationController;

  // List of screen widgets (removed map screen)
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // Initialize page controller
    _pageController = PageController();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Initialize screens (without map screen)
    _screens = [
      const FeedScreen(),
      const SavedScreen(),
      Container(), // Empty container for create (modal instead)
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Handle tab change
  void _onTabTapped(int index) {
    // Adjust index for removed map tab
    if (index == 2) {
      // Special handling for Create tab
      _showCreateOptions();
      return;
    }

    setState(() {
      _currentIndex = index;
      _pageController.jumpToPage(index);
    });

    // Play animation for feedback
    _animationController.reset();
    _animationController.forward();
  }

  // Show create options modal
  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: CreateScreen(onClose: () => Navigator.pop(context)),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Disable swiping between pages
        children: _screens,
        onPageChanged: (index) {
          if (index != 2) {
            // Skip the create page in page view
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
      extendBody: true, // Important to prevent bottom overflow
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            bottom: 0,
          ), // Extra padding to prevent overlap issues
          child: CustomBottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
          ),
        ),
      ),
    );
  }
}
