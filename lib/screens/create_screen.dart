// File location: lib/screens/create_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:setscene/services/location_service.dart';
import 'package:setscene/screens/create/photo_step.dart';
import 'package:setscene/screens/create/details_step.dart';
import 'package:setscene/screens/create/sound_step.dart';
import 'package:setscene/screens/create/categories_step.dart';
import 'package:setscene/services/cloudinary_service.dart';

class CreateScreen extends StatefulWidget {
  final VoidCallback? onClose;

  const CreateScreen({super.key, this.onClose});

  @override
  _CreateScreenState createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final LocationService _locationService = LocationService();
  final _formKey = GlobalKey<FormState>();

  // Shared controllers across steps
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  // Shared state across steps
  final List<File> _images = [];
  File? _audioFile;
  final List<String> _selectedCategories = [];
  double _visualRating = 3.0;
  double _audioRating = 3.0;
  double? _latitude;
  double? _longitude;

  // Form progress
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isTestingUpload = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Test Cloudinary upload directly
  Future<void> _testDirectUpload() async {
    setState(() {
      _isTestingUpload = true;
    });

    print("DEBUG: Testing direct Cloudinary upload");
    try {
      final testImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 70,
      );

      if (testImage != null) {
        print("Image selected: ${testImage.path}");
        final file = File(testImage.path);
        final fileSize = await file.length();
        print("File size: $fileSize bytes");

        final cloudinary = CloudinaryService.instance;
        print("Cloudinary info:");
        print("- Cloud name: ${cloudinary.cloudName}");
        print("- Upload preset: ${cloudinary.uploadPreset}");

        final url = await cloudinary.uploadFile(file, 'test_folder');
        print("UPLOAD RESULT: ${url ?? 'NULL RESULT'}");

        if (url != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Upload successful! URL: $url"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Upload returned null URL"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("DIRECT UPLOAD ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isTestingUpload = false;
      });
    }
  }

  // Submit form
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one image'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_latitude == null || _longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location is required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        print('Submitting form with data:');
        print('Name: ${_nameController.text}');
        print('Description: ${_descriptionController.text}');
        print('Address: ${_addressController.text}');
        print('Latitude: $_latitude, Longitude: $_longitude');
        print('Images count: ${_images.length}');
        print('Audio file: ${_audioFile?.path}');
        print('Visual rating: $_visualRating');
        print('Audio rating: $_audioRating');
        print('Categories: $_selectedCategories');

        // Use a temporary list to avoid modifying the original
        final imagesToUpload = List<File>.from(_images);

        final locationId = await _locationService.createLocation(
          name: _nameController.text,
          description: _descriptionController.text,
          address: _addressController.text,
          latitude: _latitude!,
          longitude: _longitude!,
          images: imagesToUpload,
          audioFile: _audioFile,
          visualRating: _visualRating,
          audioRating: _audioRating,
          categories: _selectedCategories,
        );

        print('Location created successfully with ID: $locationId');

        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Close create screen
        if (widget.onClose != null) {
          widget.onClose!();
        }
      } catch (e) {
        print('Error creating location: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Create Shot',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading:
            widget.onClose != null
                ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                )
                : null,
        actions: [
          // Debug button in AppBar
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.orange),
            tooltip: 'Test Upload',
            onPressed: _isTestingUpload ? null : _testDirectUpload,
          ),
        ],
      ),
      body: Column(
        children: [
          // DEBUG BUTTON at the top for easy access
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: _isTestingUpload ? null : _testDirectUpload,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child:
                  _isTestingUpload
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text(
                        'TEST CLOUDINARY UPLOAD DIRECTLY',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
            ),
          ),

          // Main form
          Expanded(
            child: Form(
              key: _formKey,
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: () {
                  setState(() {
                    if (_currentStep < 3) {
                      _currentStep += 1;
                    } else {
                      _submitForm();
                    }
                  });
                },
                onStepCancel: () {
                  setState(() {
                    if (_currentStep > 0) {
                      _currentStep -= 1;
                    }
                  });
                },
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _isSubmitting ? null : details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child:
                                _isSubmitting && _currentStep == 3
                                    ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      _currentStep == 3 ? 'Submit' : 'Continue',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                        if (_currentStep > 0) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  _isSubmitting ? null : details.onStepCancel,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white30),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Back',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                steps: [
                  // Step 1: Photos
                  Step(
                    title: const Text(
                      'Add Photos',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Take or upload up to 5 photos',
                      style: TextStyle(color: Colors.white70),
                    ),
                    content: PhotoStep(
                      images: _images,
                      onImagesChanged: (newImages) {
                        setState(() {
                          _images.clear();
                          _images.addAll(newImages);
                        });
                      },
                    ),
                    isActive: _currentStep == 0,
                  ),

                  // Step 2: Location Details
                  Step(
                    title: const Text(
                      'Location Details',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Name, description and address',
                      style: TextStyle(color: Colors.white70),
                    ),
                    content: DetailsStep(
                      nameController: _nameController,
                      descriptionController: _descriptionController,
                      addressController: _addressController,
                      latitude: _latitude,
                      longitude: _longitude,
                      onLocationChanged: (lat, lng) {
                        setState(() {
                          _latitude = lat;
                          _longitude = lng;
                        });
                      },
                    ),
                    isActive: _currentStep == 1,
                  ),

                  // Step 3: Sound
                  Step(
                    title: const Text(
                      'Sound Check',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Record ambient sound and rate quality',
                      style: TextStyle(color: Colors.white70),
                    ),
                    content: SoundStep(
                      audioFile: _audioFile,
                      audioRating: _audioRating,
                      onAudioFileChanged: (file) {
                        setState(() {
                          _audioFile = file;
                        });
                      },
                      onAudioRatingChanged: (rating) {
                        setState(() {
                          _audioRating = rating;
                        });
                      },
                    ),
                    isActive: _currentStep == 2,
                  ),

                  // Step 4: Categories and Ratings
                  Step(
                    title: const Text(
                      'Categorize',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Add categories and rate visual quality',
                      style: TextStyle(color: Colors.white70),
                    ),
                    content: CategoriesStep(
                      selectedCategories: _selectedCategories,
                      visualRating: _visualRating,
                      onCategoriesChanged: (categories) {
                        setState(() {
                          _selectedCategories.clear();
                          _selectedCategories.addAll(categories);
                        });
                      },
                      onVisualRatingChanged: (rating) {
                        setState(() {
                          _visualRating = rating;
                        });
                      },
                    ),
                    isActive: _currentStep == 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
