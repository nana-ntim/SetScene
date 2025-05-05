import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:setscene/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reference to users collection
  CollectionReference get _usersRef => _firestore.collection('users');

  // Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      print("Fetching user with ID: $uid");
      DocumentSnapshot doc = await _usersRef.doc(uid).get();

      if (doc.exists && doc.data() != null) {
        print("User found with ID: $uid");
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      print("User not found with ID: $uid");
      return null;
    } catch (e) {
      print("Error getting user by ID: $e");
      return null;
    }
  }

  // Get user by username
  Future<UserModel?> getUserByUsername(String username) async {
    try {
      print("Fetching user with username: $username");
      QuerySnapshot querySnapshot =
          await _usersRef.where('username', isEqualTo: username).limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        print("User found with username: $username");
        return UserModel.fromMap(
          querySnapshot.docs.first.data() as Map<String, dynamic>,
          querySnapshot.docs.first.id,
        );
      }

      print("User not found with username: $username");
      return null;
    } catch (e) {
      print("Error getting user by username: $e");
      return null;
    }
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      print("Checking if username is available: $username");
      QuerySnapshot querySnapshot =
          await _usersRef.where('username', isEqualTo: username).limit(1).get();

      bool isAvailable = querySnapshot.docs.isEmpty;
      print("Username '$username' availability: $isAvailable");
      return isAvailable;
    } catch (e) {
      print("Error checking username availability: $e");
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      print("Updating user profile for UID: $uid with data: $data");
      await _usersRef.doc(uid).update(data);
      print("User profile updated successfully");
      return true;
    } catch (e) {
      print("Error updating user profile: $e");
      return false;
    }
  }

  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      print("Getting profile for current user: ${currentUser.uid}");
      return getUserById(currentUser.uid);
    }
    print("No current user found");
    return null;
  }

  // Create or update user data in Firestore
  Future<bool> createOrUpdateUser({
    required String uid,
    required String email,
    required String fullName,
    required String username,
    String? photoUrl,
  }) async {
    try {
      print("Creating/updating user: $uid, $email, $fullName, $username");

      // Check if username is taken by another user
      if (await isUsernameAvailable(username) == false) {
        // Check if it's the same user updating their profile
        UserModel? existingUserWithName = await getUserByUsername(username);
        if (existingUserWithName != null && existingUserWithName.uid != uid) {
          print("Username is already taken by another user");
          return false;
        }
      }

      Map<String, dynamic> userData = {
        'email': email,
        'fullName': fullName,
        'username': username,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (photoUrl != null) {
        userData['photoUrl'] = photoUrl;
      }

      // Check if user document exists
      DocumentSnapshot doc = await _usersRef.doc(uid).get();

      if (doc.exists) {
        // Update existing user
        print("Updating existing user document");
        await _usersRef.doc(uid).update(userData);
      } else {
        // Create new user
        print("Creating new user document");
        userData['createdAt'] = FieldValue.serverTimestamp();
        await _usersRef.doc(uid).set(userData);
      }

      print("User created/updated successfully");
      return true;
    } catch (e) {
      print("Error creating/updating user: $e");
      return false;
    }
  }
}
