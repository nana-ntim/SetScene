// File location: lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:setscene/models/user_model.dart';
import 'package:setscene/models/location_model.dart';
import 'package:setscene/services/auth_service.dart';
import 'package:setscene/services/user_service.dart';
import 'package:setscene/services/location_service.dart';
import 'package:setscene/screens/location_detail_screen.dart';
import 'package:setscene/screens/login_screen.dart';

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

  UserModel? _user;
  List<LocationModel> _userLocations = [];
  List<LocationModel> _savedLocations = [];
  bool _isLoading = true;
  bool _isMyProfile = true;
  bool _hasError = false;
  String _errorMessage = '';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Check if there's a current user
      final currentUser = _authService.currentUser;

      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Please sign in to view your profile';
        });
        return;
      }

      // Determine if this is the current user's profile or someone else's
      _isMyProfile = widget.userId == null || widget.userId == currentUser.uid;

      // Get user data
      UserModel? userFromDb;
      if (_isMyProfile) {
        userFromDb = await _userService.getCurrentUserProfile();
      } else if (widget.userId != null) {
        userFromDb = await _userService.getUserById(widget.userId!);
      }

      if (userFromDb == null) {
        // Create a fallback user model
        userFromDb = UserModel(
          uid: currentUser.uid,
          email: currentUser.email ?? 'No email',
          fullName: currentUser.displayName ?? 'SetScene User',
          username: currentUser.email?.split('@').first ?? 'user',
          photoUrl: currentUser.photoURL,
          createdAt: DateTime.now(),
        );
      }

      _user = userFromDb;

      // Load user's created locations
      if (_user != null) {
        _userLocations = await _locationService.getUserLocations(_user!.uid);

        // Load saved locations if viewing own profile
        if (_isMyProfile) {
          _savedLocations = await _locationService.getSavedLocations();
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile data: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Error loading profile. Please try again.';
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();

      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error signing out. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: Colors.blue[400],
        backgroundColor: Colors.grey[900],
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App bar with user info
            SliverAppBar(
              expandedHeight: 280,
              backgroundColor: Colors.black,
              pinned: true,
              elevation: 0,
              stretch: true,
              actions:
                  _isMyProfile
                      ? [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            // Navigate to edit profile screen
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.logout_outlined,
                            color: Colors.white,
                          ),
                          onPressed: _signOut,
                        ),
                      ]
                      : [
                        IconButton(
                          icon: const Icon(
                            Icons.share_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            // Share profile
                          },
                        ),
                      ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildProfileHeader(),
              ),
            ),

            // Tab bar
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 2,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[500],
                  tabs: const [Tab(text: 'Spots'), Tab(text: 'Saved')],
                ),
              ),
              pinned: true,
            ),

            // Tab content
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Uploaded locations
                  _userLocations.isEmpty
                      ? _buildEmptyState(
                        icon: Icons.location_off,
                        message: 'No locations uploaded',
                        actionLabel: _isMyProfile ? 'Upload a Location' : null,
                        action: _isMyProfile ? () {} : null,
                      )
                      : _buildLocationGrid(_userLocations),

                  // Saved/Liked locations
                  _isMyProfile
                      ? (_savedLocations.isEmpty
                          ? _buildEmptyState(
                            icon: Icons.bookmark_border,
                            message: 'No saved locations',
                            actionLabel: 'Explore Locations',
                            action: () {},
                          )
                          : _buildLocationGrid(_savedLocations))
                      : _buildEmptyState(
                        icon: Icons.favorite_border,
                        message: 'Liked locations not available',
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        image:
            _user?.photoUrl != null
                ? DecorationImage(
                  image: NetworkImage(_user!.photoUrl!),
                  fit: BoxFit.cover,
                  opacity: 0.1,
                )
                : null,
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),

            // Profile picture
            Hero(
              tag: 'profile-${_user!.uid}',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child:
                      _user?.photoUrl != null
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
            ),
            const SizedBox(height: 16),

            // User name
            Text(
              _user?.fullName ?? 'User',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            // Username
            Text(
              '@${_user?.username}',
              style: TextStyle(color: Colors.grey[300], fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    label: 'Spots',
                    value: _userLocations.length.toString(),
                  ),
                  _buildStatDivider(),
                  _buildStatItem(label: 'Followers', value: '0'),
                  _buildStatDivider(),
                  _buildStatItem(label: 'Following', value: '0'),
                ],
              ),
            ),

            // Action button for non-self profiles
            if (!_isMyProfile)
              Container(
                margin: const EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  onPressed: () {
                    // Follow/Unfollow user
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'Follow',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 30, width: 1, color: Colors.grey[800]);
  }

  Widget _buildLocationGrid(List<LocationModel> locations) {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final location = locations[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LocationDetailScreen(location: location),
              ),
            ).then((_) => _loadData());
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Location image
              Hero(
                tag: 'location-grid-${location.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: location.imageUrls.first,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(color: Colors.grey[900]),
                    errorWidget:
                        (context, url, error) => Container(
                          color: Colors.grey[900],
                          child: const Icon(
                            Icons.error_outline,
                            color: Colors.white54,
                          ),
                        ),
                  ),
                ),
              ),

              // Distance badge
              if (location.distance != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${location.distance!.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                        Colors.black.withOpacity(0.8),
                      ],
                      stops: const [0.6, 0.8, 1.0],
                    ),
                  ),
                ),
              ),

              // Location info at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Location name
                      Text(
                        location.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Rating
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            location.visualRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && action != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: action,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_circle, size: 80, color: Colors.grey[700]),
            const SizedBox(height: 24),
            Text(
              'No User Found',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'There seems to be an issue with your account. Please sign out and sign in again.',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _signOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
            const SizedBox(height: 24),
            Text(
              'Something Went Wrong',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tab bar delegate for scrolling behavior
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

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
    return Container(color: Colors.black, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
