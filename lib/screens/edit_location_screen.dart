// File: lib/screens/edit_location_screen.dart

import 'package:flutter/material.dart';
import 'package:setscene/models/location_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditLocationScreen extends StatefulWidget {
  final LocationModel location;

  const EditLocationScreen({super.key, required this.location});

  @override
  _EditLocationScreenState createState() => _EditLocationScreenState();
}

class _EditLocationScreenState extends State<EditLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;

  bool _isLoading = false;
  List<String> _selectedCategories = [];
  final List<String> _availableCategories = [
    'Urban',
    'Nature',
    'Indoor',
    'Beach',
    'Sunset',
    'Historic',
    'Modern',
    'Abandoned',
    'Residential',
    'Industrial',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current location data
    _nameController = TextEditingController(text: widget.location.name);
    _descriptionController = TextEditingController(
      text: widget.location.description,
    );
    _addressController = TextEditingController(text: widget.location.address);

    // Set selected categories from location
    _selectedCategories = List.from(widget.location.categories);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _updateLocation() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Check if at least one category is selected
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user for permission check
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to update a location');
      }

      // Check if the user is the creator of the location
      if (user.id != widget.location.creatorId) {
        throw Exception('You can only edit your own locations');
      }

      // Prepare update data
      final updateData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'address': _addressController.text,
        'categories': _selectedCategories,
        // Note: we're not allowing updating coordinates, images, or ratings
      };

      // Update location in database
      await _supabase
          .from('locations')
          .update(updateData)
          .eq('id', widget.location.id);

      // Update local model
      widget.location.name = _nameController.text;
      widget.location.description = _descriptionController.text;
      widget.location.address = _addressController.text;
      widget.location.categories = _selectedCategories;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Return to previous screen with success indicator
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating location: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Edit Location',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isLoading
              ? Container(
                margin: const EdgeInsets.all(16),
                width: 24,
                height: 24,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
              : IconButton(
                icon: const Icon(Icons.check, color: Colors.white),
                onPressed: _updateLocation,
              ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location preview card
                Container(
                  height: 180,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(widget.location.imageUrls.first),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Gradient overlay for text readability
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                              stops: const [0.6, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Location name overlay
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Text(
                          _nameController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main form fields
                const Text(
                  'Name',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter location name',
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLength: 50,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      // Update UI preview
                    });
                  },
                ),

                const SizedBox(height: 16),
                const Text(
                  'Address',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: 'Enter location address',
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.location_on,
                      color: Colors.grey[600],
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),
                const Text(
                  'Categories',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _availableCategories.map((category) {
                        final isSelected = _selectedCategories.contains(
                          category,
                        );
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                if (_selectedCategories.length > 1) {
                                  _selectedCategories.remove(category);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'At least one category is required',
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                if (_selectedCategories.length < 3) {
                                  _selectedCategories.add(category);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Maximum 3 categories allowed',
                                      ),
                                    ),
                                  );
                                }
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? _getCategoryColor(category)
                                      : Colors.grey[800],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? _getCategoryColor(category)
                                        : Colors.grey[700]!,
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : Colors.grey[400],
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Description',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Tell us about this location...',
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 6,
                  maxLength: 500,
                  validator: (value) {
                    if (value == null || value.trim().length < 20) {
                      return 'Please enter a description (minimum 20 characters)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    // Return different colors based on category name
    switch (category.toLowerCase()) {
      case 'urban':
        return Colors.blue[700]!;
      case 'nature':
        return Colors.green[700]!;
      case 'indoor':
        return Colors.purple[700]!;
      case 'beach':
        return Colors.amber[700]!;
      case 'sunset':
        return Colors.orange[700]!;
      case 'historic':
        return Colors.brown[700]!;
      case 'modern':
        return Colors.teal[700]!;
      case 'abandoned':
        return Colors.grey[700]!;
      case 'residential':
        return Colors.red[700]!;
      case 'industrial':
        return Colors.blueGrey[700]!;
      default:
        return Colors.blue[700]!;
    }
  }
}
