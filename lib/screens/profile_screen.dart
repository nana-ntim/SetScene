// File: lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:setscene/models/user_model.dart';
import 'package:setscene/models/location_model.dart';
import 'package:setscene/services/auth_service.dart';
import 'package:setscene/services/user_service.dart';
import 'package:setscene/services/location_service.dart';
import 'package:setscene/screens/location_detail_screen.dart';
import 'package:setscene/screens/login_screen.dart';
import 'package:setscene/screens/profile/edit_profile_screen.dart';
import 'package:setscene/screens/profile/follow_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // If null, shows current user profile

  const ProfileScreen({super.key, this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final LocationService _locationService = LocationService();

  // User data
  UserModel? _user;
  bool _isLoading = true;
  bool _isMyProfile = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isFollowing = false;

  // Content data
  List<LocationModel> _userLocations = [];
  List<LocationModel> _savedLocations = [];
  List<LocationModel> _likedLocations = [];
  int _followersCount = 0;
  int _followingCount = 0;

  // UI controllers
  late TabController _tabController;
  final List<String> _tabs = ['Posts', 'Saved', 'Liked'];
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Ensure we load data properly after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  // Handle tab changes
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });

      // Load liked locations when switching to that tab
      if (_currentTabIndex == 2 && _likedLocations.isEmpty && _isMyProfile) {
        _loadLikedLocations();
      }
    }
  }

  // Load all user data
  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Check if there's a current user
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Please sign in to view profiles';
        });
        return;
      }

      // Determine if this is the current user's profile or someone else's
      _isMyProfile = widget.userId == null || widget.userId == currentUser.id;

      // Get user data - using an optimistic approach to avoid "user not found" errors
      UserModel? userFromDb;
      String targetUserId = _isMyProfile ? currentUser.id : widget.userId!;

      try {
        userFromDb = await _userService.getUserById(targetUserId);
      } catch (e) {
        print("ProfileScreen: Error fetching user: $e");
        // If there's an error and it's the current user, create a fallback model
        if (_isMyProfile) {
          userFromDb = UserModel(
            uid: currentUser.id,
            email: currentUser.email ?? '',
            fullName:
                currentUser.userMetadata?['full_name'] as String? ?? 'User',
            username:
                currentUser.userMetadata?['username'] as String? ??
                'user_${currentUser.id.substring(0, 6)}',
            createdAt: DateTime.now(),
          );
        }
      }

      if (userFromDb == null) {
        // Create a fallback user model for own profile
        if (_isMyProfile) {
          userFromDb = UserModel(
            uid: currentUser.id,
            email: currentUser.email ?? '',
            fullName:
                currentUser.userMetadata?['full_name'] as String? ?? 'User',
            username:
                currentUser.userMetadata?['username'] as String? ??
                'user_${currentUser.id.substring(0, 6)}',
            createdAt: DateTime.now(),
          );
        } else {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'User not found';
          });
          return;
        }
      }

      _user = userFromDb;

      // Load user counts and check follow status - handle errors gracefully for each call
      try {
        await _loadLocationData();
      } catch (e) {
        print("ProfileScreen: Error loading location data: $e");
      }

      try {
        await _loadFollowCounts();
      } catch (e) {
        print("ProfileScreen: Error loading follow counts: $e");
      }

      if (!_isMyProfile) {
        try {
          await _checkFollowStatus();
        } catch (e) {
          print("ProfileScreen: Error checking follow status: $e");
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("ProfileScreen: General error in _loadData: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Error loading profile. Please try again.';
        });
      }
    }
  }

  // Load user's locations and saved locations
  Future<void> _loadLocationData() async {
    try {
      if (_user != null) {
        // Load user's created locations
        _userLocations = await _locationService.getUserLocations(_user!.uid);

        // Load saved locations if viewing own profile
        if (_isMyProfile) {
          _savedLocations = await _locationService.getSavedLocations();
        }
      }
    } catch (e) {
      // Handle error silently
      print('Error loading location data: $e');
    }
  }

  // Load liked locations
  Future<void> _loadLikedLocations() async {
    try {
      if (_user != null && _isMyProfile) {
        setState(() {
          _isLoading = true;
        });

        _likedLocations = await _locationService.getLikedLocations();

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Load follower and following counts
  Future<void> _loadFollowCounts() async {
    try {
      if (_user != null) {
        final counts = await _userService.getFollowCounts(_user!.uid);
        _followersCount = counts['followers'] ?? 0;
        _followingCount = counts['following'] ?? 0;
      }
    } catch (e) {
      // Handle error silently
      print('Error loading follow counts: $e');
    }
  }

  // Check if current user is following the profile user
  Future<void> _checkFollowStatus() async {
    try {
      if (_user != null && !_isMyProfile) {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (currentUserId != null) {
          _isFollowing = await _userService.isFollowing(
            currentUserId,
            _user!.uid,
          );
        }
      }
    } catch (e) {
      // Handle error silently
      print('Error checking follow status: $e');
    }
  }

  // Handle follow/unfollow
  Future<void> _toggleFollow() async {
    if (_user == null || _isMyProfile) return;

    try {
      setState(() {
        // Optimistically update UI
        _isFollowing = !_isFollowing;
        _followersCount += _isFollowing ? 1 : -1;
      });

      final bool success =
          _isFollowing
              ? await _userService.followUser(_user!.uid)
              : await _userService.unfollowUser(_user!.uid);

      if (!success && mounted) {
        // Revert on failure
        setState(() {
          _isFollowing = !_isFollowing;
          _followersCount += _isFollowing ? 1 : -1;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating follow status')),
        );
      }
    } catch (e) {
      if (mounted) {
        // Revert on error
        setState(() {
          _isFollowing = !_isFollowing;
          _followersCount += _isFollowing ? 1 : -1;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating follow status')),
        );
      }
    }
  }

  // Delete a location
  Future<void> _deleteLocation(LocationModel location) async {
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Delete Location',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Are you sure you want to delete this location? This action cannot be undone.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
      );

      if (confirm != true) return;

      // Show loading
      setState(() {
        _isLoading = true;
      });

      // Delete the location
      final success = await _locationService.deleteLocation(location.id);

      if (success) {
        // Reload data
        await _loadLocationData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location deleted successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete location'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Navigate to location edit screen
  Future<void> _editLocation(LocationModel location) async {
    // Show a snackbar that this feature is coming soon
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Edit feature coming soon')));
  }

  // Navigate to followers or following list
  void _navigateToFollowList(FollowScreenType type) {
    if (_user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FollowListScreen(
              userId: _user!.uid,
              type: type,
              username: _user!.username,
            ),
      ),
    ).then((_) => _loadFollowCounts());
  }

  // Navigate to edit profile screen
  Future<void> _navigateToEditProfile() async {
    if (_user == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(user: _user!)),
    );

    if (result == true) {
      _loadData(); // Reload data if profile was updated
    }
  }

  // Handle sign out
  Future<void> _signOut() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _authService.signOut();

      // Navigate to login screen
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error signing out'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorScreen();
    }

    if (_user == null) {
      return _buildNoUserScreen();
    }

    // Use SafeArea to prevent the bottom overflow
    return Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 450.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.black,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildProfileHeader(),
              ),
              actions: [
                if (_isMyProfile)
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              backgroundColor: Colors.grey[900],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text(
                                'Sign Out',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                'Are you sure you want to sign out?',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _signOut();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Sign Out'),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                if (!_isMyProfile)
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white),
                    onPressed: () {
                      // Share profile functionality
                    },
                  ),
              ],
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorWeight: 3,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                  tabs:
                      _isMyProfile
                          ? _tabs.map((tab) => Tab(text: tab)).toList()
                          : [Tab(text: _tabs[0])],
                ),
                color: Colors.black,
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Posts Tab
            _buildLocationsGrid(_userLocations, canDelete: _isMyProfile),

            // Saved Tab (only for current user)
            if (_isMyProfile) _buildLocationsGrid(_savedLocations),

            // Liked Tab (only for current user)
            if (_isMyProfile) _buildLocationsGrid(_likedLocations),
          ],
        ),
      ),
      floatingActionButton:
          _isMyProfile
              ? FloatingActionButton(
                onPressed: _navigateToEditProfile,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.edit, color: Colors.black),
              )
              : null,
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[900]!.withOpacity(0.6), Colors.black],
          stops: const [0.2, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Profile picture
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[850],
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child:
                    _user?.photoUrl != null && _user!.photoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: _user!.photoUrl!,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                color: Colors.grey[850],
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white70,
                                  size: 50,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: Colors.grey[850],
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white70,
                                  size: 50,
                                ),
                              ),
                        )
                        : Container(
                          color: Colors.grey[850],
                          child: const Icon(
                            Icons.person,
                            color: Colors.white70,
                            size: 50,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 16),

            // User name
            Text(
              _user!.fullName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            // Username with badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '@${_user!.username}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 15),
                  ),
                  if (_isMyProfile) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'YOU',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Bio if available
            if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _user!.bio!,
                  style: TextStyle(color: Colors.grey[300], fontSize: 15),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[900]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      label: 'Spots',
                      value: _user!.postsCount.toString(),
                    ),
                    _buildVerticalDivider(),
                    _buildStatItem(
                      label: 'Followers',
                      value: _followersCount.toString(),
                      onTap:
                          () =>
                              _navigateToFollowList(FollowScreenType.followers),
                    ),
                    _buildVerticalDivider(),
                    _buildStatItem(
                      label: 'Following',
                      value: _followingCount.toString(),
                      onTap:
                          () =>
                              _navigateToFollowList(FollowScreenType.following),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action button for other profiles
            if (!_isMyProfile)
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: _toggleFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isFollowing ? Colors.grey[800] : Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    _isFollowing ? 'Following' : 'Follow',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: Colors.grey[800]);
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationsGrid(
    List<LocationModel> locations, {
    bool canDelete = false,
  }) {
    if (locations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _currentTabIndex == 0
                  ? Icons.photo_camera_outlined
                  : (_currentTabIndex == 1
                      ? Icons.bookmark_outline
                      : Icons.favorite_outline),
              size: 70,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              _currentTabIndex == 0
                  ? 'No posts yet'
                  : (_currentTabIndex == 1
                      ? 'No saved locations'
                      : 'No liked locations'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _currentTabIndex == 0
                    ? 'Share your favorite filming spots with the community'
                    : (_currentTabIndex == 1
                        ? 'Save locations for easy access later'
                        : 'Like locations you enjoy'),
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            if (_currentTabIndex == 0 && _isMyProfile) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Switch to create tab
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  // Navigate to create tab (index 2)
                },
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Add Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: GridView.builder(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 100, // Add extra bottom padding to avoid overlapping nav bar
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: locations.length,
        itemBuilder: (context, index) {
          final location = locations[index];
          return GestureDetector(
            onTap: () => _navigateToLocation(location),
            onLongPress:
                canDelete && location.creatorId == _user?.uid
                    ? () => _showLocationOptions(location)
                    : null,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Location image
                    CachedNetworkImage(
                      imageUrl: location.imageUrls.first,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: Colors.grey[850],
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white60,
                                  ),
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Colors.grey[850],
                            child: const Icon(
                              Icons.error_outline,
                              color: Colors.white54,
                            ),
                          ),
                    ),

                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            stops: const [0.7, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Rating info at bottom
                    Positioned(
                      bottom: 6,
                      left: 6,
                      right: 6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.visibility,
                            color: Colors.white70,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            location.visualRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),

                          const SizedBox(width: 8),

                          if (location.audioUrl != null) ...[
                            const Icon(
                              Icons.volume_up,
                              color: Colors.white70,
                              size: 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              location.audioRating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Edit/Delete hint if user can modify this location
                    if (canDelete && location.creatorId == _user?.uid)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[900]!.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.more_horiz,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLocationOptions(LocationModel location) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              // Location name header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  location.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Edit option
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: const Text(
                  'Edit Location',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _editLocation(location);
                },
              ),

              // Delete option
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Location',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteLocation(location);
                },
              ),

              const SizedBox(height: 16),

              // Cancel button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _navigateToLocation(LocationModel location) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationDetailScreen(location: location),
      ),
    ).then((_) => _loadData());
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading profile...',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoUserScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile'),
      ),
      body: _buildEmptyState(
        Icons.account_circle,
        'No user found',
        'Please sign in again to view your profile',
        'Sign Out',
        _signOut,
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile'),
      ),
      body: _buildEmptyState(
        Icons.error_outline,
        'Error loading profile',
        _errorMessage,
        'Try Again',
        _loadData,
      ),
    );
  }

  Widget _buildEmptyState(
    IconData icon,
    String title,
    String message,
    String actionLabel,
    VoidCallback onAction,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900]!.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class for sticky tab bar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color color;

  _SliverAppBarDelegate(this._tabBar, {this.color = Colors.black});

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: color, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
