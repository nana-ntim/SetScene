// File location: lib/utils/cloudinary_test.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:setscene/services/cloudinary_service.dart';

class CloudinaryTestScreen extends StatefulWidget {
  const CloudinaryTestScreen({super.key});

  @override
  _CloudinaryTestScreenState createState() => _CloudinaryTestScreenState();
}

class _CloudinaryTestScreenState extends State<CloudinaryTestScreen> {
  String _uploadStatus = 'No upload started';
  String? _imageUrl;
  File? _imageFile;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _uploadStatus = 'Image selected, ready to upload';
        _imageUrl = null;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      setState(() {
        _uploadStatus = 'No image selected';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadStatus = 'Uploading...';
    });

    try {
      // First, print info about the Cloudinary service
      final cloudinaryService = CloudinaryService.instance;
      print('Cloudinary service info:');
      print('- Cloud Name: ${cloudinaryService.cloudName}');
      print('- Upload Preset: ${cloudinaryService.uploadPreset}');

      // Upload the image
      final result = await cloudinaryService.uploadFile(
        _imageFile!,
        'test_upload',
      );

      setState(() {
        if (result != null) {
          _imageUrl = result;
          _uploadStatus = 'Upload successful';
        } else {
          _uploadStatus = 'Upload failed - no URL returned';
        }
        _isUploading = false;
      });
    } catch (e) {
      print('Error during upload: $e');
      setState(() {
        _uploadStatus = 'Error: ${e.toString()}';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cloudinary Test')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: $_uploadStatus',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_imageFile != null) ...[
              Center(
                child: Image.file(_imageFile!, height: 200, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
            ],
            if (_imageUrl != null) ...[
              const Text('Uploaded Image URL:'),
              SelectableText(_imageUrl!),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Select Image'),
                ),
                ElevatedButton(
                  onPressed: _isUploading ? null : _uploadImage,
                  child:
                      _isUploading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Upload to Cloudinary'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Debug Tips:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              '1. Check if your Cloudinary credentials are correct\n'
              '2. Verify that your upload preset is set to "unsigned"\n'
              '3. Look at the console logs for detailed error messages\n'
              '4. Make sure your internet connection is stable',
            ),
          ],
        ),
      ),
    );
  }
}
