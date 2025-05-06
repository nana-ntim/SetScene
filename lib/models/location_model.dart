// File location: lib/models/location_model.dart

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
  final String creatorUsername;
  final String? creatorPhotoUrl;
  final DateTime createdAt;
  final DateTime? savedAt;
  final DateTime? likedAt;
  final int likesCount;
  final int savesCount;
  bool isLiked;
  bool isSaved;
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
    required this.creatorUsername,
    this.creatorPhotoUrl,
    required this.createdAt,
    this.savedAt,
    this.likedAt,
    this.likesCount = 0,
    this.savesCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.distance,
  });

  // Format the saved date to a readable string
  String get savedAtFormatted {
    if (savedAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(savedAt!);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return 'Just now';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(savedAt!);
    }
  }

  // Format the created date to a readable string
  String get createdAtFormatted {
    return DateFormat('MMM d, yyyy').format(createdAt);
  }

  // Format the time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        if (difference.inMinutes < 1) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }

  // Factory constructor from Supabase
  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      imageUrls: List<String>.from(map['image_urls'] ?? []),
      audioUrl: map['audio_url'],
      visualRating: (map['visual_rating'] ?? 0.0).toDouble(),
      audioRating: (map['audio_rating'] ?? 0.0).toDouble(),
      categories: List<String>.from(map['categories'] ?? []),
      creatorId: map['creator_id'] ?? '',
      creatorName: map['creator_name'] ?? '',
      creatorUsername: map['creator_username'] ?? '',
      creatorPhotoUrl: map['creator_photo_url'],
      createdAt:
          map['created_at'] != null
              ? DateTime.parse(map['created_at'])
              : DateTime.now(),
      savedAt: map['saved_at'] != null ? DateTime.parse(map['saved_at']) : null,
      likedAt: map['liked_at'] != null ? DateTime.parse(map['liked_at']) : null,
      likesCount: (map['likes_count'] ?? 0),
      savesCount: (map['saves_count'] ?? 0),
      isLiked: map['is_liked'] ?? false,
      isSaved: map['is_saved'] ?? false,
    );
  }

  // Convert to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
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
      'creator_id': creatorId,
      'creator_name': creatorName,
      'creator_username': creatorUsername,
      'creator_photo_url': creatorPhotoUrl,
      'likes_count': likesCount,
      'saves_count': savesCount,
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
    String? creatorUsername,
    String? creatorPhotoUrl,
    DateTime? createdAt,
    DateTime? savedAt,
    DateTime? likedAt,
    int? likesCount,
    int? savesCount,
    bool? isLiked,
    bool? isSaved,
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
      creatorUsername: creatorUsername ?? this.creatorUsername,
      creatorPhotoUrl: creatorPhotoUrl ?? this.creatorPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      savedAt: savedAt ?? this.savedAt,
      likedAt: likedAt ?? this.likedAt,
      likesCount: likesCount ?? this.likesCount,
      savesCount: savesCount ?? this.savesCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      distance: distance ?? this.distance,
    );
  }
}
