// File location: lib/screens/create/photo_step.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PhotoStep extends StatefulWidget {
  final List<File> images;
  final Function(List<File>) onImagesChanged;

  const PhotoStep({
    super.key,
    required this.images,
    required this.onImagesChanged,
  });

  @override
  _PhotoStepState createState() => _PhotoStepState();
}

class _PhotoStepState extends State<PhotoStep> {
  // Pick images from gallery
  Future<void> _pickImages() async {
    final picker = ImagePicker();

    try {
      final pickedFiles = await picker.pickMultiImage(
        maxWidth: 1200, // Reduced from 1920 for better performance
        maxHeight: 800, // Reduced from 1080 for better performance
        imageQuality: 70, // Reduced from 80 for better performance
      );

      if (pickedFiles.isNotEmpty) {
        // Create a new list to avoid modifying the original
        final newImages = List<File>.from(widget.images);

        // Add new images (up to 5 total)
        for (final file in pickedFiles) {
          if (newImages.length < 5) {
            newImages.add(File(file.path));
          }
        }

        widget.onImagesChanged(newImages);
      }
    } catch (e) {
      print('Error picking images: $e');
    }
  }

  // Take photo with camera
  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200, // Reduced for better performance
        maxHeight: 800, // Reduced for better performance
        imageQuality: 70, // Reduced for better performance
      );

      if (pickedFile != null) {
        if (widget.images.length < 5) {
          final newImages = List<File>.from(widget.images);
          newImages.add(File(pickedFile.path));
          widget.onImagesChanged(newImages);
        }
      }
    } catch (e) {
      print('Error taking photo: $e');
    }
  }

  // Remove image
  void _removeImage(int index) {
    final newImages = List<File>.from(widget.images);
    newImages.removeAt(index);
    widget.onImagesChanged(newImages);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image grid
        if (widget.images.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      widget.images[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      // Using low quality for preview to avoid OpenGL issues
                      cacheWidth: 300,
                      cacheHeight: 300,
                      filterQuality: FilterQuality.low,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        if (widget.images.isEmpty)
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!, width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library, color: Colors.grey[600], size: 48),
                const SizedBox(height: 12),
                Text(
                  'Add at least one photo',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // Add Photo buttons
        if (widget.images.length < 5)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[850],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[850],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

        // Image count
        if (widget.images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
              '${widget.images.length}/5 photos added',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ),
      ],
    );
  }
}
