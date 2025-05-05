import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:setscene/models/location_model.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      // Check if user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Upload images
      final List<String> imageUrls = await _uploadFiles(
        images,
        'locations/${DateTime.now().millisecondsSinceEpoch}/images',
      );

      // Upload audio file if provided
      String? audioUrl;
      if (audioFile != null) {
        final urls = await _uploadFiles([
          audioFile,
        ], 'locations/${DateTime.now().millisecondsSinceEpoch}/audio');
        audioUrl = urls.isNotEmpty ? urls.first : null;
      }

      // Create location document
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

      // Add to Firestore
      final DocumentReference docRef = await _locationsRef.add(locationData);

      return docRef.id;
    } catch (e) {
      print('Error creating location: $e');
      rethrow;
    }
  }

  // Upload files to Firebase Storage
  Future<List<String>> _uploadFiles(List<File> files, String path) async {
    final List<String> urls = [];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$i${_getFileExtension(file.path)}';
      final Reference ref = _storage.ref().child('$path/$fileName');

      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String url = await snapshot.ref.getDownloadURL();

      urls.add(url);
    }

    return urls;
  }

  // Get file extension
  String _getFileExtension(String path) {
    return path.split('.').last;
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
