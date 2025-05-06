// File location: lib/services/storage_service.dart

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // Upload a single image to Supabase Storage
  Future<String?> uploadImage(File file, String folder) async {
    try {
      print('Starting image upload: ${file.path}');

      // Create a unique file name with original extension
      final fileExt = path.extension(file.path);
      final fileName = '${_uuid.v4()}$fileExt';
      final filePath = '$folder/$fileName';

      // Get file bytes
      final bytes = await file.readAsBytes();

      // Upload to Supabase Storage
      final response = await _supabase.storage
          .from('location-images')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get public URL
      final imageUrl = _supabase.storage
          .from('location-images')
          .getPublicUrl(filePath);

      print('Image uploaded successfully: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Upload multiple images
  Future<List<String>> uploadImages(List<File> files, String folder) async {
    final List<String> urls = [];

    for (final file in files) {
      try {
        final url = await uploadImage(file, folder);
        if (url != null) {
          urls.add(url);
        }
      } catch (e) {
        print('Error uploading file: $e');
      }
    }

    return urls;
  }

  // Upload audio file
  Future<String?> uploadAudio(File file, String folder) async {
    try {
      print('Starting audio upload: ${file.path}');

      // Create a unique file name with original extension
      final fileExt = path.extension(file.path);
      final fileName = '${_uuid.v4()}$fileExt';
      final filePath = '$folder/$fileName';

      // Get file bytes
      final bytes = await file.readAsBytes();

      // Upload to Supabase Storage
      final response = await _supabase.storage
          .from('audio-recordings')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get public URL
      final audioUrl = _supabase.storage
          .from('audio-recordings')
          .getPublicUrl(filePath);

      print('Audio uploaded successfully: $audioUrl');
      return audioUrl;
    } catch (e) {
      print('Error uploading audio: $e');
      return null;
    }
  }

  // Upload profile image
  Future<String?> uploadProfileImage(File file, String userId) async {
    try {
      print('Starting profile image upload: ${file.path}');

      // Create a unique file name with original extension
      final fileExt = path.extension(file.path);
      final fileName = 'profile$fileExt';
      final filePath = '$userId/$fileName';

      // Get file bytes
      final bytes = await file.readAsBytes();

      // Upload to Supabase Storage
      final response = await _supabase.storage
          .from('profile-images')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true, // Overwrite existing file
            ),
          );

      // Get public URL
      final imageUrl = _supabase.storage
          .from('profile-images')
          .getPublicUrl(filePath);

      print('Profile image uploaded successfully: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Delete a file
  Future<bool> deleteFile(String bucket, String filePath) async {
    try {
      await _supabase.storage.from(bucket).remove([filePath]);
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }
}
