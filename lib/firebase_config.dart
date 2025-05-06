// File location: lib/firebase_config.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:setscene/services/cloudinary_service.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    // Initialize Cloudinary by just accessing the singleton instance
    // This ensures the service is created without needing a separate initialize method
    CloudinaryService.instance;
  }
}
