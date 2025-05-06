// File location: lib/services/user_service.dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:setscene/models/user_model.dart';
import 'package:setscene/services/storage_service.dart';

class UserService {
  final _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();

  // Get current user ID (helper method)
  String? getCurrentUserId() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print("UserService: No current user found");
      return null;
    }
    print("UserService: Current user ID: ${user.id}");
    return user.id;
  }

  // Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      if (uid.isEmpty) {
        print("UserService: Empty UID provided to getUserById");
        return null;
      }

      print("UserService: Fetching user with ID: $uid");

      // First try to fetch from the database
      final response =
          await _supabase.from('users').select().eq('id', uid).maybeSingle();

      if (response == null) {
        // User not found in database, but might exist in auth
        print("UserService: User not found in database, checking auth");

        // If this is the current user, try to fix the profile
        final currentUser = _supabase.auth.currentUser;
        if (currentUser != null && currentUser.id == uid) {
          print(
            "UserService: Trying to create missing profile for current user",
          );

          // Create a profile for this user
          return await _createMissingUserProfile(currentUser);
        }

        return null;
      }

      print("UserService: User found with ID: $uid");
      return UserModel.fromMap(response, uid);
    } catch (e) {
      print("UserService: Error getting user by ID: $e");
      return null;
    }
  }

  // Create a missing user profile
  Future<UserModel?> _createMissingUserProfile(User user) async {
    try {
      // Get user metadata
      final metadata = user.userMetadata;
      final fullName = metadata?['full_name'] as String? ?? 'User';
      var username =
          metadata?['username'] as String? ?? 'user_${user.id.substring(0, 6)}';

      // Make sure username is unique
      bool isUnique = false;
      int attempt = 0;
      while (!isUnique && attempt < 5) {
        final usernameCheck =
            await _supabase
                .from('users')
                .select('username')
                .eq('username', username)
                .maybeSingle();

        if (usernameCheck == null) {
          isUnique = true;
        } else {
          username = '${username}_${attempt + 1}';
        }
        attempt++;
      }

      // Create user profile
      await _supabase.from('users').insert({
        'id': user.id,
        'email': user.email,
        'full_name': fullName,
        'username': username,
        'created_at': DateTime.now().toIso8601String(),
      });

      print("UserService: Created missing user profile for ${user.id}");

      // Fetch the newly created profile
      final response =
          await _supabase.from('users').select().eq('id', user.id).single();

      return UserModel.fromMap(response, user.id);
    } catch (e) {
      print("UserService: Error creating missing user profile: $e");
      return null;
    }
  }

  // Get user by username
  Future<UserModel?> getUserByUsername(String username) async {
    try {
      print("UserService: Fetching user with username: $username");

      final response =
          await _supabase
              .from('users')
              .select()
              .eq('username', username)
              .single();

      print("UserService: User found with username: $username");
      return UserModel.fromMap(response, response['id']);
    } catch (e) {
      print("UserService: Error getting user by username: $e");
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    required String userId,
    String? fullName,
    String? username,
    String? bio,
    String? photoUrl,
  }) async {
    try {
      print("UserService: Updating user profile for UID: $userId");

      // Create update data
      Map<String, dynamic> updateData = {};
      if (fullName != null) updateData['full_name'] = fullName;
      if (username != null) updateData['username'] = username;
      if (bio != null) updateData['bio'] = bio;
      if (photoUrl != null) updateData['photo_url'] = photoUrl;

      // Update profile
      await _supabase.from('users').update(updateData).eq('id', userId);

      print("UserService: User profile updated successfully");
      return true;
    } catch (e) {
      print("UserService: Error updating user profile: $e");
      return false;
    }
  }

  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      print("UserService: No current user found in Auth");
      return null;
    }

    return await getUserById(currentUserId);
  }

  // Upload profile image
  Future<String?> uploadProfileImage(File imageFile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }

    try {
      // Upload image to storage
      final imageUrl = await _storageService.uploadProfileImage(
        imageFile,
        userId,
      );

      if (imageUrl != null) {
        // Update user profile with new photo URL
        await updateUserProfile(userId: userId, photoUrl: imageUrl);
      }

      return imageUrl;
    } catch (e) {
      print('UserService: Error uploading profile image: $e');
      return null;
    }
  }

  // Follow a user
  Future<bool> followUser(String targetUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      // Check if already following
      final checkResponse =
          await _supabase
              .from('follows')
              .select()
              .eq('follower_id', currentUserId)
              .eq('following_id', targetUserId)
              .maybeSingle();

      if (checkResponse != null) {
        // Already following
        return true;
      }

      // Insert follow record
      await _supabase.from('follows').insert({
        'follower_id': currentUserId,
        'following_id': targetUserId,
      });

      // Update follower's following count
      await _supabase.rpc(
        'increment_following_count',
        params: {'user_id_param': currentUserId},
      );

      // Update target's followers count
      await _supabase.rpc(
        'increment_followers_count',
        params: {'user_id_param': targetUserId},
      );

      return true;
    } catch (e) {
      print('UserService: Error following user: $e');
      return false;
    }
  }

  // Unfollow a user
  Future<bool> unfollowUser(String targetUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      // Check if actually following
      final checkResponse =
          await _supabase
              .from('follows')
              .select()
              .eq('follower_id', currentUserId)
              .eq('following_id', targetUserId)
              .maybeSingle();

      if (checkResponse == null) {
        // Not following
        return true;
      }

      // Delete follow record
      await _supabase
          .from('follows')
          .delete()
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId);

      // Update follower's following count
      await _supabase.rpc(
        'decrement_following_count',
        params: {'user_id_param': currentUserId},
      );

      // Update target's followers count
      await _supabase.rpc(
        'decrement_followers_count',
        params: {'user_id_param': targetUserId},
      );

      return true;
    } catch (e) {
      print('UserService: Error unfollowing user: $e');
      return false;
    }
  }

  // Check if current user is following another user
  Future<bool> isFollowing(String followerId, String targetUserId) async {
    try {
      // Handle empty IDs gracefully
      if (followerId.isEmpty || targetUserId.isEmpty) {
        return false;
      }

      final response =
          await _supabase
              .from('follows')
              .select()
              .eq('follower_id', followerId)
              .eq('following_id', targetUserId)
              .maybeSingle();

      return response != null;
    } catch (e) {
      print('UserService: Error checking follow status: $e');
      return false;
    }
  }

  // Get followers of a user
  Future<List<UserModel>> getFollowers(String userId) async {
    try {
      if (userId.isEmpty) {
        return [];
      }

      final response = await _supabase
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId);

      List<UserModel> followers = [];

      for (var item in response) {
        final followerId = item['follower_id'] as String;
        try {
          final userResponse =
              await _supabase
                  .from('users')
                  .select()
                  .eq('id', followerId)
                  .single();

          final userModel = UserModel.fromMap(userResponse, followerId);

          // Check if current user is following this user
          final currentUserId = _supabase.auth.currentUser?.id;
          if (currentUserId != null) {
            final isFollowing = await this.isFollowing(
              currentUserId,
              followerId,
            );
            followers.add(userModel.copyWith(isFollowing: isFollowing));
          } else {
            followers.add(userModel);
          }
        } catch (e) {
          print('UserService: Error getting follower $followerId: $e');
          // Skip this user and continue
        }
      }

      return followers;
    } catch (e) {
      print('UserService: Error getting followers: $e');
      return [];
    }
  }

  // Get users that a user is following
  Future<List<UserModel>> getFollowing(String userId) async {
    try {
      if (userId.isEmpty) {
        return [];
      }

      final response = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);

      List<UserModel> following = [];

      for (var item in response) {
        final followingId = item['following_id'] as String;
        try {
          final userResponse =
              await _supabase
                  .from('users')
                  .select()
                  .eq('id', followingId)
                  .single();

          final userModel = UserModel.fromMap(userResponse, followingId);

          // Set isFollowing to true since the user is following them
          following.add(userModel.copyWith(isFollowing: true));
        } catch (e) {
          print('UserService: Error getting following $followingId: $e');
          // Skip this user and continue
        }
      }

      return following;
    } catch (e) {
      print('UserService: Error getting following users: $e');
      return [];
    }
  }

  // Get follower and following counts for a user
  Future<Map<String, int>> getFollowCounts(String userId) async {
    try {
      if (userId.isEmpty) {
        return {'followers': 0, 'following': 0};
      }

      final response =
          await _supabase
              .from('users')
              .select('followers_count, following_count')
              .eq('id', userId)
              .single();

      return {
        'followers': response['followers_count'] ?? 0,
        'following': response['following_count'] ?? 0,
      };
    } catch (e) {
      print('UserService: Error getting follow counts: $e');
      return {'followers': 0, 'following': 0};
    }
  }
}
