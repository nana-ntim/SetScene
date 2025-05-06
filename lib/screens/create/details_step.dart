// File location: lib/screens/create/details_step.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class DetailsStep extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController addressController;
  final double? latitude;
  final double? longitude;
  final Function(double, double) onLocationChanged;

  const DetailsStep({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.addressController,
    this.latitude,
    this.longitude,
    required this.onLocationChanged,
  });

  @override
  _DetailsStepState createState() => _DetailsStepState();
}

class _DetailsStepState extends State<DetailsStep> {
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.latitude == null || widget.longitude == null) {
      _getCurrentLocation();
    }
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        final LocationPermission requested =
            await Geolocator.requestPermission();
        if (requested == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      final Position position = await Geolocator.getCurrentPosition();

      widget.onLocationChanged(position.latitude, position.longitude);

      setState(() {
        _isLoadingLocation = false;
      });

      // Try to get address
      // In a real app, use reverse geocoding here
    } catch (e) {
      print('Error getting location: $e');

      setState(() {
        _isLoadingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name field
        TextFormField(
          controller: widget.nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Location Name',
            labelStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[400]!),
            ),
            filled: true,
            fillColor: Colors.grey[900],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Description field
        TextFormField(
          controller: widget.descriptionController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Description',
            labelStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[400]!),
            ),
            filled: true,
            fillColor: Colors.grey[900],
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Address field
        TextFormField(
          controller: widget.addressController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Address',
            labelStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[400]!),
            ),
            filled: true,
            fillColor: Colors.grey[900],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an address';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Location
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[800]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              _isLoadingLocation
                  ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                  : widget.latitude != null && widget.longitude != null
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latitude: ${widget.latitude!.toStringAsFixed(6)}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Longitude: ${widget.longitude!.toStringAsFixed(6)}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  )
                  : const Text(
                    'Location not available',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Get Current Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
