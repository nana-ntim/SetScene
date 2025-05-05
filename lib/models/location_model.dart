import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LocationModel {
  final String id;
  final String name;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final String? audioUrl;
  final double visualRating;
  final double audioRating;
  final List<String> categories;
  final String creatorId;
  final String creatorName;
  final String? creatorPhotoUrl;
  final DateTime createdAt;
  final DateTime savedAt;
  bool isLiked;
  double? distance;

  LocationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    this.audioUrl,
    required this.visualRating,
    required this.audioRating,
    required this.categories,
    required this.creatorId,
    required this.creatorName,
    this.creatorPhotoUrl,
    required this.createdAt,
    required this.savedAt,
    this.isLiked = false,
    this.distance,
  });

  // Format the saved date to a readable string
  String get savedAtFormatted {
    final now = DateTime.now();
    final difference = now.difference(savedAt);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return 'Just now';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(savedAt);
    }
  }

  // Format the created date to a readable string
  String get createdAt45 {
    return DateFormat('MMM d, yyyy').format(createdAt);
  }

  // Factory constructor from Firestore
  factory LocationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return LocationModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      audioUrl: data['audioUrl'],
      visualRating: (data['visualRating'] ?? 0.0).toDouble(),
      audioRating: (data['audioRating'] ?? 0.0).toDouble(),
      categories: List<String>.from(data['categories'] ?? []),
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      creatorPhotoUrl: data['creatorPhotoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      savedAt: (data['savedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isLiked: data['isLiked'] ?? false,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
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
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorPhotoUrl': creatorPhotoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'savedAt': Timestamp.fromDate(savedAt),
      'isLiked': isLiked,
    };
  }

  // Copy with method for updating fields
  LocationModel copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
    String? audioUrl,
    double? visualRating,
    double? audioRating,
    List<String>? categories,
    String? creatorId,
    String? creatorName,
    String? creatorPhotoUrl,
    DateTime? createdAt,
    DateTime? savedAt,
    bool? isLiked,
    double? distance,
  }) {
    return LocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrls: imageUrls ?? this.imageUrls,
      audioUrl: audioUrl ?? this.audioUrl,
      visualRating: visualRating ?? this.visualRating,
      audioRating: audioRating ?? this.audioRating,
      categories: categories ?? this.categories,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorPhotoUrl: creatorPhotoUrl ?? this.creatorPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      savedAt: savedAt ?? this.savedAt,
      isLiked: isLiked ?? this.isLiked,
      distance: distance ?? this.distance,
    );
  }
}
