// File location: lib/services/cloudinary_service.dart

import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  static CloudinaryService? _instance;
  late CloudinaryPublic cloudinary;

  // Replace these with your actual Cloudinary credentials
  final String cloudName = 'dapg8sn3e';
  final String uploadPreset = 'setscene_preset';

  CloudinaryService._() {
    cloudinary = CloudinaryPublic(cloudName, uploadPreset);
  }

  static CloudinaryService get instance {
    _instance ??= CloudinaryService._();
    return _instance!;
  }

  // Upload a single file to Cloudinary
  Future<String?> uploadFile(File file, String folder) async {
    try {
      print('Starting file upload to Cloudinary: ${file.path}');

      final CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: folder,
          resourceType: _getResourceType(file.path),
        ),
      );

      print('File uploaded successfully. URL: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  // Upload multiple files to Cloudinary
  Future<List<String>> uploadFiles(List<File> files, String folder) async {
    final List<String> urls = [];

    for (final file in files) {
      try {
        final url = await uploadFile(file, folder);
        if (url != null) {
          urls.add(url);
        }
      } catch (e) {
        print('Error uploading file: $e');
      }
    }

    return urls;
  }

  // Determine resource type (image or audio)
  CloudinaryResourceType _getResourceType(String path) {
    final extension = path.split('.').last.toLowerCase();

    // Audio files
    if (['mp3', 'wav', 'aac', 'm4a'].contains(extension)) {
      return CloudinaryResourceType.Auto;
    }

    return CloudinaryResourceType.Image;
  }
}
