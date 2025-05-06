// File location: lib/models/user_model.dart

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String username;
  final String? photoUrl;
  final String? bio;
  final DateTime? createdAt;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final bool isFollowing; // Whether the current user is following this user

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.username,
    this.photoUrl,
    this.bio,
    this.createdAt,
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      fullName: map['full_name'] ?? '',
      username: map['username'] ?? '',
      photoUrl: map['photo_url'],
      bio: map['bio'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      postsCount: map['posts_count'] ?? 0,
      followersCount: map['followers_count'] ?? 0,
      followingCount: map['following_count'] ?? 0,
      isFollowing: map['is_following'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'full_name': fullName,
      'username': username,
      'photo_url': photoUrl,
      'bio': bio,
      'posts_count': postsCount,
      'followers_count': followersCount,
      'following_count': followingCount,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? username,
    String? photoUrl,
    String? bio,
    DateTime? createdAt,
    int? postsCount,
    int? followersCount,
    int? followingCount,
    bool? isFollowing,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      postsCount: postsCount ?? this.postsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}
