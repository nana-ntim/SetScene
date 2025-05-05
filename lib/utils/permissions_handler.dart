import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionsHandler {
  // Request camera permission
  static Future<bool> requestCameraPermission(BuildContext context) async {
    PermissionStatus status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.camera.request();
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      _showPermissionDialog(
        context,
        'Camera Permission',
        'Camera permission is required to take photos. Please enable it in your device settings.',
      );
      return false;
    }

    return false;
  }

  // Request location permission
  static Future<bool> requestLocationPermission(BuildContext context) async {
    PermissionStatus status = await Permission.location.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.location.request();
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      _showPermissionDialog(
        context,
        'Location Permission',
        'Location permission is required to get your current location. Please enable it in your device settings.',
      );
      return false;
    }

    return false;
  }

  // Request microphone permission
  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    PermissionStatus status = await Permission.microphone.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.microphone.request();
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      _showPermissionDialog(
        context,
        'Microphone Permission',
        'Microphone permission is required to record audio. Please enable it in your device settings.',
      );
      return false;
    }

    return false;
  }

  // Request storage permission
  static Future<bool> requestStoragePermission(BuildContext context) async {
    PermissionStatus status = await Permission.storage.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.storage.request();
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      _showPermissionDialog(
        context,
        'Storage Permission',
        'Storage permission is required to save files. Please enable it in your device settings.',
      );
      return false;
    }

    return false;
  }

  // Show permission dialog
  static void _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(message, style: TextStyle(color: Colors.grey[300])),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                ),
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  // Request all required permissions
  static Future<Map<Permission, bool>> requestAllPermissions(
    BuildContext context,
  ) async {
    final Map<Permission, bool> permissionStatus = {};

    permissionStatus[Permission.camera] = await requestCameraPermission(
      context,
    );
    permissionStatus[Permission.location] = await requestLocationPermission(
      context,
    );
    permissionStatus[Permission.microphone] = await requestMicrophonePermission(
      context,
    );
    permissionStatus[Permission.storage] = await requestStoragePermission(
      context,
    );

    return permissionStatus;
  }
}
