import 'package:flutter/material.dart';
import 'package:setscene/screens/feed_screen.dart';
import 'package:setscene/screens/create_screen.dart';
import 'package:setscene/screens/map_screen.dart';
import 'package:setscene/screens/saved_screen.dart';
import 'package:setscene/screens/profile_screen.dart';
import 'package:setscene/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // List of screen widgets
  late final List<Widget> _screens;

  // Tabs data with icons
  final List<Map<String, dynamic>> _tabs = [
    {
      'icon': Icons.explore_outlined,
      'activeIcon': Icons.explore,
      'label': 'Explore',
    },
    {'icon': Icons.map_outlined, 'activeIcon': Icons.map, 'label': 'Map'},
    {
      'icon': Icons.add_circle_outline,
      'activeIcon': Icons.add_circle,
      'label': 'Create',
    },
    {
      'icon': Icons.bookmark_border,
      'activeIcon': Icons.bookmark,
      'label': 'Saved',
    },
    {
      'icon': Icons.person_outline,
      'activeIcon': Icons.person,
      'label': 'Profile',
    },
  ];

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    // Initialize screens
    _screens = [
      const FeedScreen(),
      const MapScreen(),
      const CreateScreen(),
      const SavedScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Handle tab change
  void _onTabTapped(int index) {
    if (index == 2) {
      // Special handling for Create tab
      _showCreateOptions();
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    // Animate to the selected page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Handle page change from swipe
  void _onPageChanged(int index) {
    if (index != 2) {
      // Skip center Create button from swipe
      setState(() {
        _currentIndex = index;
      });
    }
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
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
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
        onPageChanged: _onPageChanged,
        physics:
            const NeverScrollableScrollPhysics(), // Disable swipe to improve performance
        children: [
          _screens[0], // Feed
          _screens[1], // Map
          Container(), // Empty container for create (modal instead)
          _screens[3], // Saved
          _screens[4], // Profile
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[900]!, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.black,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: Colors.blue[400],
          unselectedItemColor: Colors.grey[700],
          elevation: 0,
          items:
              _tabs.map((tab) {
                // Special styling for center item
                final bool isCreateButton = tab['label'] == 'Create';

                return BottomNavigationBarItem(
                  icon: Icon(
                    _currentIndex == _tabs.indexOf(tab)
                        ? tab['activeIcon']
                        : tab['icon'],
                    size: isCreateButton ? 32 : 26,
                  ),
                  label: tab['label'],
                );
              }).toList(),
        ),
      ),
    );
  }
}
