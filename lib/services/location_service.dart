// File location: lib/services/location_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:setscene/models/location_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:setscene/services/cloudinary_service.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _cloudinary = CloudinaryService.instance;

  // Collection references
  CollectionReference get _locationsRef => _firestore.collection('locations');
  CollectionReference get _savedLocationsRef =>
      _firestore.collection('savedLocations');
  CollectionReference get _likedLocationsRef =>
      _firestore.collection('likedLocations');

  // Get all locations
  Future<List<LocationModel>> getLocations() async {
    try {
      final QuerySnapshot snapshot =
          await _locationsRef
              .orderBy('createdAt', descending: true)
              .limit(50) // Limit for performance
              .get();

      return snapshot.docs
          .map((doc) => LocationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting locations: $e');
      return [];
    }
  }

  // Get locations by user
  Future<List<LocationModel>> getUserLocations(String userId) async {
    try {
      final QuerySnapshot snapshot =
          await _locationsRef
              .where('creatorId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => LocationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user locations: $e');
      return [];
    }
  }

  // Create a new location - Enhanced with detailed logging
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
      print('Name: $name');
      print(
        'Description: ${description.substring(0, description.length > 20 ? 20 : description.length)}...',
      );
      print('Address: $address');
      print('Coordinates: $latitude, $longitude');
      print('Images count: ${images.length}');
      print('Audio file: ${audioFile?.path}');
      print('Visual rating: $visualRating');
      print('Audio rating: $audioRating');
      print('Categories: $categories');

      // Check if user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        print('ERROR: User not logged in');
        throw Exception('User not logged in');
      }

      print('User authenticated: ${user.uid}');

      // Generate a unique folder name for this location
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String folderPath = 'setscene/${user.uid}/locations/$timestamp';

      print('Folder path for uploads: $folderPath');
      print('Starting image uploads...');

      // Upload images to Cloudinary one by one with detailed logging
      final List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        try {
          print('Uploading image ${i + 1}/${images.length}...');
          final file = images[i];
          print('Image path: ${file.path}');
          print('Image size: ${await file.length()} bytes');

          final url = await _cloudinary.uploadFile(file, '$folderPath/images');

          if (url != null) {
            print('Image ${i + 1} uploaded successfully: $url');
            imageUrls.add(url);
          } else {
            print('ERROR: Image ${i + 1} upload returned null URL');
          }
        } catch (e) {
          print('ERROR: Failed to upload image ${i + 1}: $e');
          // Continue with other images even if one fails
        }
      }

      print(
        'Uploaded ${imageUrls.length}/${images.length} images successfully',
      );

      // Upload audio file if provided
      String? audioUrl;
      if (audioFile != null) {
        try {
          print('Uploading audio file...');
          print('Audio path: ${audioFile.path}');
          print('Audio size: ${await audioFile.length()} bytes');

          audioUrl = await _cloudinary.uploadFile(
            audioFile,
            '$folderPath/audio',
          );

          if (audioUrl != null) {
            print('Audio upload successful: $audioUrl');
          } else {
            print('ERROR: Audio upload returned null URL');
          }
        } catch (e) {
          print('ERROR: Failed to upload audio: $e');
          // Continue without audio if it fails
        }
      }

      // Create location document
      print('Creating Firestore document...');
      final locationData = {
        'name': name,
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'imageUrls': imageUrls,
        'audioUrl': audioUrl,
        'visualRating': visualRating,
        'audioRating': audioRating,
        'categories': categories,
        'creatorId': user.uid,
        'creatorName': user.displayName ?? 'Anonymous',
        'creatorPhotoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      };

      print('Location data prepared, saving to Firestore...');
      // Add to Firestore
      final DocumentReference docRef = await _locationsRef.add(locationData);

      print('Location created successfully with ID: ${docRef.id}');
      print('=== LOCATION CREATION PROCESS COMPLETED ===');
      return docRef.id;
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
      // Get all locations (in a real app, you would use geolocation queries)
      final QuerySnapshot snapshot = await _locationsRef.get();

      // Filter and calculate distances
      final locations =
          snapshot.docs.map((doc) {
            final location = LocationModel.fromFirestore(doc);

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
      final DocumentSnapshot doc = await _locationsRef.doc(id).get();

      if (doc.exists) {
        return LocationModel.fromFirestore(doc);
      }

      return null;
    } catch (e) {
      print('Error getting location by ID: $e');
      return null;
    }
  }

  // Get saved locations for current user
  Future<List<LocationModel>> getSavedLocations() async {
    try {
      // Check if user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      // Get saved location IDs
      final QuerySnapshot snapshot =
          await _savedLocationsRef.where('userId', isEqualTo: user.uid).get();

      // Get location details for each saved location
      final List<LocationModel> locations = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final locationId = data['locationId'];
        final savedAt = (data['savedAt'] as Timestamp).toDate();

        final location = await getLocationById(locationId);
        if (location != null) {
          // Check if location is liked
          final isLiked = await isLocationLiked(locationId);

          // Add to list with saved date
          locations.add(location.copyWith(savedAt: savedAt, isLiked: isLiked));
        }
      }

      return locations;
    } catch (e) {
      print('Error getting saved locations: $e');
      return [];
    }
  }

  // Save a location
  Future<void> saveLocation(String locationId) async {
    try {
      // Check if user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Save location
      await _savedLocationsRef.add({
        'userId': user.uid,
        'locationId': locationId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving location: $e');
      rethrow;
    }
  }

  // Unsave a location
  Future<void> unsaveLocation(String locationId) async {
    try {
      // Check if user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get saved location document
      final QuerySnapshot snapshot =
          await _savedLocationsRef
              .where('userId', isEqualTo: user.uid)
              .where('locationId', isEqualTo: locationId)
              .get();

      // Delete document
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error unsaving location: $e');
      rethrow;
    }
  }

  // Check if a location is saved
  Future<bool> isLocationSaved(String locationId) async {
    try {
      // Check if user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      // Check if location is saved
      final QuerySnapshot snapshot =
          await _savedLocationsRef
              .where('userId', isEqualTo: user.uid)
              .where('locationId', isEqualTo: locationId)
              .limit(1)
              .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if location is saved: $e');
      return false;
    }
  }

  // Like a location
  Future<void> likeLocation(String locationId) async {
    try {
      // Check if user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Like location
      await _likedLocationsRef.add({
        'userId': user.uid,
        'locationId': locationId,
        'likedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error liking location: $e');
      rethrow;
    }
  }

  // Unlike a location
  Future<void> unlikeLocation(String locationId) async {
    try {
      // Check if user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get liked location document
      final QuerySnapshot snapshot =
          await _likedLocationsRef
              .where('userId', isEqualTo: user.uid)
              .where('locationId', isEqualTo: locationId)
              .get();

      // Delete document
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error unliking location: $e');
      rethrow;
    }
  }

  // Check if a location is liked
  Future<bool> isLocationLiked(String locationId) async {
    try {
      // Check if user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      // Check if location is liked
      final QuerySnapshot snapshot =
          await _likedLocationsRef
              .where('userId', isEqualTo: user.uid)
              .where('locationId', isEqualTo: locationId)
              .limit(1)
              .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if location is liked: $e');
      return false;
    }
  }
}
