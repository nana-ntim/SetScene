// File location: lib/services/location_service.dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:setscene/models/location_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:setscene/services/storage_service.dart';
import 'package:setscene/services/user_service.dart';

class LocationService {
  final _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();
  final UserService _userService = UserService();

  // Get all locations
  Future<List<LocationModel>> getLocations({int limit = 50}) async {
    try {
      final response = await _supabase
          .from('locations')
          .select('*, users!creator_id(full_name, username, photo_url)')
          .order('created_at', ascending: false)
          .limit(limit);

      // Get current user to check like/save status
      final currentUser = _supabase.auth.currentUser;

      // Transform the response
      final locations =
          response.map<LocationModel>((data) {
            // Extract creator info from the joined users table
            final userData = data['users'] as Map<String, dynamic>;

            // Merge location data with creator info
            final Map<String, dynamic> locationData = {
              ...data,
              'creator_name': userData['full_name'],
              'creator_username': userData['username'],
              'creator_photo_url': userData['photo_url'],
            };

            return LocationModel.fromMap(locationData);
          }).toList();

      // Check if current user has liked/saved each location
      if (currentUser != null) {
        for (var location in locations) {
          location.isLiked = await isLocationLiked(location.id);
          location.isSaved = await isLocationSaved(location.id);
        }
      }

      return locations;
    } catch (e) {
      print('Error getting locations: $e');
      return [];
    }
  }

  // Get locations by user
  Future<List<LocationModel>> getUserLocations(String userId) async {
    try {
      final response = await _supabase
          .from('locations')
          .select('*, users!creator_id(full_name, username, photo_url)')
          .eq('creator_id', userId)
          .order('created_at', ascending: false);

      // Get current user to check like status
      final currentUser = _supabase.auth.currentUser;

      // Transform the response
      final locations =
          response.map<LocationModel>((data) {
            // Extract creator info from the joined users table
            final userData = data['users'] as Map<String, dynamic>;

            // Merge location data with creator info
            final Map<String, dynamic> locationData = {
              ...data,
              'creator_name': userData['full_name'],
              'creator_username': userData['username'],
              'creator_photo_url': userData['photo_url'],
            };

            return LocationModel.fromMap(locationData);
          }).toList();

      // Check like/save status for each location if current user is logged in
      if (currentUser != null) {
        for (var location in locations) {
          location.isLiked = await isLocationLiked(location.id);
          location.isSaved = await isLocationSaved(location.id);
        }
      }

      return locations;
    } catch (e) {
      print('Error getting user locations: $e');
      return [];
    }
  }

  // Create a new location
  Future<String> createLocation({
    required String name,
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    required List<File> images,
    File? audioFile,
    required double visualRating,
    required double audioRating,
    required List<String> categories,
  }) async {
    try {
      print('=== STARTING LOCATION CREATION PROCESS ===');

      // Check if user is logged in
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('ERROR: User not logged in');
        throw Exception('User not logged in');
      }

      print('User authenticated: ${user.id}');

      // Get the user profile to ensure we have the latest info
      final userProfile = await _userService.getUserById(user.id);
      if (userProfile == null) {
        print('ERROR: User profile not found');
        throw Exception('User profile not found');
      }

      // Generate a unique folder name for this location
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String folderPath = '${user.id}/$timestamp';

      print('Folder path for uploads: $folderPath');
      print('Starting image uploads...');

      // Upload images to Supabase Storage
      final List<String> imageUrls = await _storageService.uploadImages(
        images,
        folderPath,
      );

      print(
        'Uploaded ${imageUrls.length}/${images.length} images successfully',
      );

      // Upload audio file if provided
      String? audioUrl;
      if (audioFile != null) {
        try {
          print('Uploading audio file...');
          audioUrl = await _storageService.uploadAudio(audioFile, folderPath);
          if (audioUrl != null) {
            print('Audio upload successful: $audioUrl');
          } else {
            print('ERROR: Audio upload returned null URL');
          }
        } catch (e) {
          print('ERROR: Failed to upload audio: $e');
        }
      }

      // Create location in database
      print('Creating location in database...');

      final locationData = {
        'name': name,
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'image_urls': imageUrls,
        'audio_url': audioUrl,
        'visual_rating': visualRating,
        'audio_rating': audioRating,
        'categories': categories,
        'creator_id': user.id,
      };

      // Insert location
      final response =
          await _supabase
              .from('locations')
              .insert(locationData)
              .select('id')
              .single();

      final locationId = response['id'];

      // Increment user's post count
      await _supabase
          .from('users')
          .update({'posts_count': userProfile.postsCount + 1})
          .eq('id', user.id);

      print('Location created successfully with ID: $locationId');
      print('=== LOCATION CREATION PROCESS COMPLETED ===');

      return locationId;
    } catch (e) {
      print('=== ERROR CREATING LOCATION: $e ===');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Get nearby locations with distance calculation
  Future<List<LocationModel>> getNearbyLocations({
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    try {
      // Get all locations
      final response = await _supabase
          .from('locations')
          .select('*, users!creator_id(full_name, username, photo_url)');

      // Get current user to check like/save status
      final currentUser = _supabase.auth.currentUser;

      // Transform the response
      final locations =
          response.map<LocationModel>((data) {
            // Extract creator info from the joined users table
            final userData = data['users'] as Map<String, dynamic>;

            // Merge location data with creator info
            final Map<String, dynamic> locationData = {
              ...data,
              'creator_name': userData['full_name'],
              'creator_username': userData['username'],
              'creator_photo_url': userData['photo_url'],
            };

            final location = LocationModel.fromMap(locationData);

            // Calculate distance
            final distance =
                Geolocator.distanceBetween(
                  latitude,
                  longitude,
                  location.latitude,
                  location.longitude,
                ) /
                1000; // Convert to kilometers

            // Add distance to location
            return location.copyWith(distance: distance);
          }).toList();

      // Check like/save status for each location if current user is logged in
      if (currentUser != null) {
        for (var location in locations) {
          location.isLiked = await isLocationLiked(location.id);
          location.isSaved = await isLocationSaved(location.id);
        }
      }

      // Filter by radius and sort by distance
      return locations
          .where((location) => location.distance! <= radius)
          .toList()
        ..sort((a, b) => a.distance!.compareTo(b.distance!));
    } catch (e) {
      print('Error getting nearby locations: $e');
      return [];
    }
  }

  // Get location by ID
  Future<LocationModel?> getLocationById(String id) async {
    try {
      final response =
          await _supabase
              .from('locations')
              .select('*, users!creator_id(full_name, username, photo_url)')
              .eq('id', id)
              .single();

      // Extract creator info from the joined users table
      final userData = response['users'] as Map<String, dynamic>;

      // Merge location data with creator info
      final Map<String, dynamic> locationData = {
        ...response,
        'creator_name': userData['full_name'],
        'creator_username': userData['username'],
        'creator_photo_url': userData['photo_url'],
      };

      final location = LocationModel.fromMap(locationData);

      // Check if current user has liked/saved this location
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        location.isLiked = await isLocationLiked(id);
        location.isSaved = await isLocationSaved(id);
      }

      return location;
    } catch (e) {
      print('Error getting location by ID: $e');
      return null;
    }
  }

  // Get saved locations for current user
  Future<List<LocationModel>> getSavedLocations() async {
    try {
      // Check if user is logged in
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      // Get saved location IDs
      final savedResponse = await _supabase
          .from('saved_locations')
          .select('location_id, saved_at')
          .eq('user_id', user.id)
          .order('saved_at', ascending: false);

      // Get location details for each saved location
      final List<LocationModel> locations = [];

      for (final savedItem in savedResponse) {
        final locationId = savedItem['location_id'];
        final savedAt = DateTime.parse(savedItem['saved_at']);

        try {
          final locationResponse =
              await _supabase
                  .from('locations')
                  .select('*, users!creator_id(full_name, username, photo_url)')
                  .eq('id', locationId)
                  .single();

          // Extract creator info from the joined users table
          final userData = locationResponse['users'] as Map<String, dynamic>;

          // Merge location data with creator info
          final Map<String, dynamic> locationData = {
            ...locationResponse,
            'creator_name': userData['full_name'],
            'creator_username': userData['username'],
            'creator_photo_url': userData['photo_url'],
          };

          final location = LocationModel.fromMap(locationData);

          // Check if location is liked
          final isLiked = await isLocationLiked(locationId);

          // Add to list with saved date
          locations.add(
            location.copyWith(
              savedAt: savedAt,
              isLiked: isLiked,
              isSaved: true,
            ),
          );
        } catch (e) {
          print('Error getting location $locationId: $e');
          // Skip this location and continue
        }
      }

      return locations;
    } catch (e) {
      print('Error getting saved locations: $e');
      return [];
    }
  }

  // Get liked locations for current user
  Future<List<LocationModel>> getLikedLocations() async {
    try {
      // Check if user is logged in
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      // Get liked location IDs
      final likedResponse = await _supabase
          .from('liked_locations')
          .select('location_id, liked_at')
          .eq('user_id', user.id)
          .order('liked_at', ascending: false);

      // Get location details for each liked location
      final List<LocationModel> locations = [];

      for (final likedItem in likedResponse) {
        final locationId = likedItem['location_id'];
        final likedAt = DateTime.parse(likedItem['liked_at']);

        try {
          final locationResponse =
              await _supabase
                  .from('locations')
                  .select('*, users!creator_id(full_name, username, photo_url)')
                  .eq('id', locationId)
                  .single();

          // Extract creator info from the joined users table
          final userData = locationResponse['users'] as Map<String, dynamic>;

          // Merge location data with creator info
          final Map<String, dynamic> locationData = {
            ...locationResponse,
            'creator_name': userData['full_name'],
            'creator_username': userData['username'],
            'creator_photo_url': userData['photo_url'],
          };

          final location = LocationModel.fromMap(locationData);

          // Check if location is saved
          final isSaved = await isLocationSaved(locationId);

          // Add to list with liked date
          locations.add(
            location.copyWith(
              likedAt: likedAt,
              isLiked: true,
              isSaved: isSaved,
            ),
          );
        } catch (e) {
          print('Error getting location $locationId: $e');
          // Skip this location and continue
        }
      }

      return locations;
    } catch (e) {
      print('Error getting liked locations: $e');
      return [];
    }
  }

  // Like a location using RPC function to bypass RLS
  Future<void> likeLocation(String locationId) async {
    try {
      // Check if user is logged in
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      print('Attempting to like location: $locationId for user: ${user.id}');

      // Check if already liked using RPC function
      final bool isAlreadyLiked =
          await _supabase.rpc(
            'check_if_liked',
            params: {'user_id_param': user.id, 'location_id_param': locationId},
          ) ??
          false;

      print('Is location already liked: $isAlreadyLiked');

      if (isAlreadyLiked) {
        print('Location already liked, skipping');
        return; // Already liked, no need to do anything
      }

      // Insert like record using RPC function
      await _supabase.rpc(
        'insert_like',
        params: {'user_id_param': user.id, 'location_id_param': locationId},
      );

      print('Like record inserted successfully');

      // Update location's likes count
      await _supabase.rpc(
        'increment_likes_count',
        params: {'location_id_param': locationId},
      );

      print('Location liked successfully');
    } catch (e) {
      print('Error liking location: $e');
      rethrow;
    }
  }

  // Unlike a location using RPC function to bypass RLS
  Future<void> unlikeLocation(String locationId) async {
    try {
      // Check if user is logged in
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      print('Attempting to unlike location: $locationId for user: ${user.id}');

      // Check if actually liked using RPC function
      final bool isLiked =
          await _supabase.rpc(
            'check_if_liked',
            params: {'user_id_param': user.id, 'location_id_param': locationId},
          ) ??
          false;

      print('Is location currently liked: $isLiked');

      if (!isLiked) {
        print('Location not liked, nothing to unlike');
        return; // Not liked, nothing to do
      }

      // Delete like record using RPC function
      await _supabase.rpc(
        'delete_like',
        params: {'user_id_param': user.id, 'location_id_param': locationId},
      );

      print('Like record deleted successfully');

      // Decrement likes count
      await _supabase.rpc(
        'decrement_likes_count',
        params: {'location_id_param': locationId},
      );

      print('Location unliked successfully');
    } catch (e) {
      print('Error unliking location: $e');
      rethrow;
    }
  }

  // Check if a location is liked using RPC function
  Future<bool> isLocationLiked(String locationId) async {
    try {
      // Check if user is logged in
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      // Use RPC function to bypass RLS
      final result = await _supabase.rpc(
        'check_if_liked',
        params: {'user_id_param': user.id, 'location_id_param': locationId},
      );

      return result ?? false;
    } catch (e) {
      print('Error checking if location is liked: $e');
      return false;
    }
  }

  // Save a location using RPC function to bypass RLS
  Future<void> saveLocation(String locationId) async {
    try {
      // Check if user is logged in
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      print('Attempting to save location: $locationId for user: ${user.id}');

      // Check if already saved using RPC function
      final bool isAlreadySaved =
          await _supabase.rpc(
            'check_if_saved',
            params: {'user_id_param': user.id, 'location_id_param': locationId},
          ) ??
          false;

      print('Is location already saved: $isAlreadySaved');

      if (isAlreadySaved) {
        print('Location already saved, skipping');
        return; // Already saved, no need to do anything
      }

      // Insert save record using RPC function
      await _supabase.rpc(
        'insert_save',
        params: {'user_id_param': user.id, 'location_id_param': locationId},
      );

      print('Save record inserted successfully');

      // Update location's saves count
      await _supabase.rpc(
        'increment_saves_count',
        params: {'location_id_param': locationId},
      );

      print('Location saved successfully');
    } catch (e) {
      print('Error saving location: $e');
      rethrow;
    }
  }

  // Unsave a location using RPC function to bypass RLS
  Future<void> unsaveLocation(String locationId) async {
    try {
      // Check if user is logged in
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      print('Attempting to unsave location: $locationId for user: ${user.id}');

      // Check if actually saved using RPC function
      final bool isSaved =
          await _supabase.rpc(
            'check_if_saved',
            params: {'user_id_param': user.id, 'location_id_param': locationId},
          ) ??
          false;

      print('Is location currently saved: $isSaved');

      if (!isSaved) {
        print('Location not saved, nothing to unsave');
        return; // Not saved, nothing to do
      }

      // Delete save record using RPC function
      await _supabase.rpc(
        'delete_save',
        params: {'user_id_param': user.id, 'location_id_param': locationId},
      );

      print('Save record deleted successfully');

      // Decrement saves count
      await _supabase.rpc(
        'decrement_saves_count',
        params: {'location_id_param': locationId},
      );

      print('Location unsaved successfully');
    } catch (e) {
      print('Error unsaving location: $e');
      rethrow;
    }
  }

  // Check if a location is saved using RPC function
  Future<bool> isLocationSaved(String locationId) async {
    try {
      // Check if user is logged in
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      // Use RPC function to bypass RLS
      final result = await _supabase.rpc(
        'check_if_saved',
        params: {'user_id_param': user.id, 'location_id_param': locationId},
      );

      return result ?? false;
    } catch (e) {
      print('Error checking if location is saved: $e');
      return false;
    }
  }

  // Delete a location
  Future<bool> deleteLocation(String locationId) async {
    try {
      // Check if user is logged in
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Check if the user is the creator of the location
      final response =
          await _supabase
              .from('locations')
              .select('creator_id')
              .eq('id', locationId)
              .single();

      if (response['creator_id'] != user.id) {
        throw Exception('You can only delete your own locations');
      }

      // Get user's post count
      final userResponse =
          await _supabase
              .from('users')
              .select('posts_count')
              .eq('id', user.id)
              .single();

      final postsCount = userResponse['posts_count'] as int;

      // Delete location
      await _supabase.from('locations').delete().eq('id', locationId);

      // Update user's post count, ensuring it doesn't go below 0
      await _supabase
          .from('users')
          .update({'posts_count': postsCount > 0 ? postsCount - 1 : 0})
          .eq('id', user.id);

      return true;
    } catch (e) {
      print('Error deleting location: $e');
      return false;
    }
  }
}
