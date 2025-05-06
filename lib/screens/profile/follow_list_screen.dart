// File location: lib/screens/profile/follow_list_screen.dart

import 'package:flutter/material.dart';
import 'package:setscene/models/user_model.dart';
import 'package:setscene/services/user_service.dart';
import 'package:setscene/services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:setscene/screens/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum FollowScreenType { followers, following }

class FollowListScreen extends StatefulWidget {
  final String userId;
  final FollowScreenType type;
  final String username;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.type,
    required this.username,
  });

  @override
  _FollowListScreenState createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  List<UserModel> _users = [];
  bool _isLoading = true;
  bool _isError = false;
  Map<String, bool> _followStatusMap = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      List<UserModel> users;

      // Load either followers or following based on screen type
      if (widget.type == FollowScreenType.followers) {
        users = await _userService.getFollowers(widget.userId);
      } else {
        users = await _userService.getFollowing(widget.userId);
      }

      // Check follow status for each user if current user is logged in
      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null) {
        for (final user in users) {
          if (user.uid == currentUser.uid) {
            // Current user can't follow themselves
            _followStatusMap[user.uid] = false;
          } else {
            // Check if current user is following this user
            final isFollowing = await _userService.isFollowing(
              currentUser.uid,
              user.uid,
            );
            _followStatusMap[user.uid] = isFollowing;
          }
        }
      }

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _isLoading = false;
        _isError = true;
      });
    }
  }

  Future<void> _toggleFollow(UserModel user) async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null || user.uid == currentUser.uid) {
      return;
    }

    final isCurrentlyFollowing = _followStatusMap[user.uid] ?? false;

    setState(() {
      // Optimistically update UI
      _followStatusMap[user.uid] = !isCurrentlyFollowing;
    });

    try {
      bool success;

      if (isCurrentlyFollowing) {
        success = await _userService.unfollowUser(user.uid);
      } else {
        success = await _userService.followUser(user.uid);
      }

      if (!success) {
        // Revert on failure
        setState(() {
          _followStatusMap[user.uid] = isCurrentlyFollowing;
        });
      }
    } catch (e) {
      print('Error toggling follow: $e');

      // Revert on error
      setState(() {
        _followStatusMap[user.uid] = isCurrentlyFollowing;
      });

      // Show error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          widget.type == FollowScreenType.followers
              ? "${widget.username}'s Followers"
              : "${widget.username}'s Following",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
              : _isError
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading users',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadUsers,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : _users.isEmpty
              ? Center(
                child: Text(
                  widget.type == FollowScreenType.followers
                      ? "No followers yet"
                      : "Not following anyone yet",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
              : ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final isFollowing = _followStatusMap[user.uid] ?? false;

                  // Check if this is the current user
                  final isCurrentUser =
                      user.uid == Supabase.instance.client.auth.currentUser?.id;

                  return _buildUserListItem(user, isFollowing, isCurrentUser);
                },
              ),
    );
  }

  Widget _buildUserListItem(
    UserModel user,
    bool isFollowing,
    bool isCurrentUser,
  ) {
    return ListTile(
      onTap: () {
        // Navigate to user profile
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: user.uid),
              ),
            )
            .then((_) => _loadUsers()); // Refresh after returning
      },
      leading: CircleAvatar(
        backgroundColor: Colors.grey[900],
        radius: 22,
        backgroundImage:
            user.photoUrl != null
                ? CachedNetworkImageProvider(user.photoUrl!)
                : null,
        child:
            user.photoUrl == null
                ? const Icon(Icons.person, color: Colors.white70)
                : null,
      ),
      title: Text(
        user.fullName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '@${user.username}',
        style: TextStyle(color: Colors.grey[400]),
      ),
      trailing:
          isCurrentUser
              ? const Text('You', style: TextStyle(color: Colors.white70))
              : OutlinedButton(
                onPressed: () => _toggleFollow(user),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      isFollowing ? Colors.transparent : Colors.blue[600],
                  foregroundColor: isFollowing ? Colors.white : Colors.white,
                  side: BorderSide(
                    color: isFollowing ? Colors.grey[700]! : Colors.transparent,
                  ),
                  minimumSize: const Size(90, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isFollowing ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ),
    );
  }
}
