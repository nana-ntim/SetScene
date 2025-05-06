// File location: lib/services/auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:setscene/models/user_model.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Get current user from Supabase
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print("AuthService: No current user found");
        return null;
      }

      print("AuthService: Current user found with ID: ${user.id}");

      // Fetch user profile from database
      final response =
          await _supabase
              .from('users')
              .select()
              .eq('id', user.id)
              .maybeSingle();

      if (response == null) {
        print("AuthService: User profile not found in database");
        // Try to create the profile using RPC function
        return await _createUserProfileRPC(user);
      }

      return UserModel.fromMap(response, user.id);
    } catch (e) {
      print('AuthService: Error getting current user: $e');
      return null;
    }
  }

  // Create a user profile for an existing auth user using RPC function
  Future<UserModel?> _createUserProfileRPC(User user) async {
    try {
      print(
        "AuthService: Attempting to create missing user profile for ${user.id} using RPC",
      );

      // Call the dedicated RPC function to create the user profile
      final success = await _supabase.rpc(
        'create_missing_user_profile',
        params: {'user_id_param': user.id, 'email_param': user.email ?? ''},
      );

      if (success == true) {
        print("AuthService: Successfully created missing user profile");

        // Fetch the newly created profile
        final userResponse =
            await _supabase.from('users').select().eq('id', user.id).single();

        return UserModel.fromMap(userResponse, user.id);
      } else {
        print("AuthService: Failed to create user profile using RPC function");
        // Fall back to direct creation method
        return await _createUserProfile(user);
      }
    } catch (e) {
      print("AuthService: Error creating user profile with RPC: $e");
      // Fall back to direct creation method
      return await _createUserProfile(user);
    }
  }

  // Legacy method to create a user profile directly
  Future<UserModel?> _createUserProfile(User user) async {
    try {
      print("AuthService: Creating missing user profile for ${user.id}");

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

      print(
        "AuthService: Created missing user profile with username: $username",
      );

      // Return the new user model
      return UserModel(
        uid: user.id,
        email: user.email ?? '',
        fullName: fullName,
        username: username,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print("AuthService: Error creating user profile: $e");
      return null;
    }
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response =
          await _supabase
              .from('users')
              .select('username')
              .eq('username', username)
              .maybeSingle();

      return response == null;
    } catch (e) {
      print('AuthService: Error checking username availability: $e');
      return false;
    }
  }

  // Sign up with email and password - NO email confirmation
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    try {
      print(
        "AuthService: Starting sign up for email: $email, username: $username",
      );

      // Check if username is available
      final isAvailable = await isUsernameAvailable(username);
      if (!isAvailable) {
        print("AuthService: Username already taken: $username");
        throw Exception('Username is already taken');
      }

      // Create user in Supabase Auth without email confirmation
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'username': username},
        // No email confirmation or redirects
        emailRedirectTo: null,
      );

      print(
        "AuthService: Sign up completed. User created: ${response.user?.id}",
      );

      // Wait a moment to allow the trigger to run
      await Future.delayed(const Duration(milliseconds: 1000));

      // If the user was created but the trigger failed to create a profile,
      // let's manually create one
      if (response.user != null) {
        try {
          // Check if user profile was created by trigger
          final profileCheck =
              await _supabase
                  .from('users')
                  .select()
                  .eq('id', response.user!.id)
                  .maybeSingle();

          if (profileCheck == null) {
            print(
              "AuthService: Trigger failed to create user profile, creating manually",
            );

            // Try RPC method first
            final success = await _supabase.rpc(
              'create_missing_user_profile',
              params: {
                'user_id_param': response.user!.id,
                'email_param': email,
              },
            );

            if (success != true) {
              // Fall back to direct creation
              await _supabase.from('users').insert({
                'id': response.user!.id,
                'email': email,
                'full_name': fullName,
                'username': username,
                'created_at': DateTime.now().toIso8601String(),
              });
            }

            print("AuthService: Manually created user profile for new signup");
          } else {
            print("AuthService: User profile was created by trigger");
          }
        } catch (e) {
          print("AuthService: Error checking/creating user profile: $e");
        }
      }

      return response;
    } catch (e) {
      print('AuthService: Error during signup: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print("AuthService: Attempting to sign in with email: $email");

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print("AuthService: Sign in successful for user: ${response.user?.id}");

      // Wait a moment to ensure auth state is updated
      await Future.delayed(const Duration(milliseconds: 500));

      // If login successful but user profile doesn't exist,
      // check again and create it if needed
      if (response.user != null) {
        try {
          final profileCheck =
              await _supabase
                  .from('users')
                  .select()
                  .eq('id', response.user!.id)
                  .maybeSingle();

          if (profileCheck == null) {
            print(
              "AuthService: User profile doesn't exist after login, creating",
            );

            // Try to create the profile using RPC function
            final success = await _supabase.rpc(
              'create_missing_user_profile',
              params: {
                'user_id_param': response.user!.id,
                'email_param': email,
              },
            );

            if (success != true) {
              // Fall back to direct creation method
              await _createUserProfile(response.user!);
            }
          }
        } catch (e) {
          print(
            "AuthService: Error checking/creating user profile after login: $e",
          );
          // We're not throwing an error here to allow login to succeed even if profile creation fails
          // AuthWrapper will handle this case by checking the profile
        }
      }

      return response;
    } catch (e) {
      print('AuthService: Error signing in: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    print("AuthService: Signing out user");
    await _supabase.auth.signOut();
    print("AuthService: User signed out");
  }

  // Update user profile
  Future<bool> updateProfile({
    String? fullName,
    String? username,
    String? bio,
    String? photoUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Check if we're changing username and if so, check availability
      if (username != null) {
        // Get current username to check if it's changed
        final currentUserData =
            await _supabase
                .from('users')
                .select('username')
                .eq('id', user.id)
                .maybeSingle();

        final currentUsername = currentUserData?['username'];

        if (username != currentUsername) {
          final isAvailable = await isUsernameAvailable(username);
          if (!isAvailable) {
            throw Exception('Username is not available');
          }
        }
      }

      // Create update map with only the fields to update
      final Map<String, dynamic> updateData = {};
      if (fullName != null) updateData['full_name'] = fullName;
      if (username != null) updateData['username'] = username;
      if (bio != null) updateData['bio'] = bio;
      if (photoUrl != null) updateData['photo_url'] = photoUrl;

      if (updateData.isNotEmpty) {
        await _supabase.from('users').update(updateData).eq('id', user.id);
        return true;
      }

      return false;
    } catch (e) {
      print('AuthService: Error updating profile: $e');
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Update password
  Future<bool> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || user.email == null) return false;

      // First verify the current password by trying to sign in
      try {
        await _supabase.auth.signInWithPassword(
          email: user.email!,
          password: currentPassword,
        );
      } catch (e) {
        // If sign in fails, the current password is incorrect
        throw Exception('Current password is incorrect');
      }

      // Then update the password
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));

      return true;
    } catch (e) {
      print('AuthService: Error updating password: $e');
      rethrow;
    }
  }
}
