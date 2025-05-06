// File: lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:setscene/models/location_model.dart';
import 'package:setscene/services/location_service.dart';
import 'package:setscene/screens/location_detail_screen.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  bool _isLoading = true;
  bool _isLoadingNearby = false;
  List<LocationModel> _nearbyLocations = [];
  double _maxDistance = 10.0; // kilometers

  // Default center - will be updated with user's location
  LatLng _center = const LatLng(5.6037, -0.1870); // Default to Accra, Ghana

  // Current user location
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndGetCurrentLocation();
    });
  }

  Future<void> _initializeAndGetCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showErrorSnackBar(
            'Location services are disabled. Please enable location services.',
          );
        }
        return;
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _showErrorSnackBar('Location permission denied');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showErrorSnackBar(
            'Location permissions are permanently denied. Please enable them in app settings.',
          );
        }
        return;
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition();

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _center = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });

        // Load nearby locations
        _loadNearbyLocations();
      }
    } catch (e) {
      print('Error getting location: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _showErrorSnackBar('Error getting location: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'RETRY',
            onPressed: _initializeAndGetCurrentLocation,
            textColor: Colors.white,
          ),
        ),
      );
    }
  }

  Future<void> _loadNearbyLocations() async {
    if (!mounted) return;

    double latitude, longitude;

    if (_currentPosition != null) {
      latitude = _currentPosition!.latitude;
      longitude = _currentPosition!.longitude;
    } else {
      // Use the center coordinates if current position is not available
      latitude = _center.latitude;
      longitude = _center.longitude;
    }

    setState(() {
      _isLoadingNearby = true;
    });

    try {
      final locations = await _locationService.getNearbyLocations(
        latitude: latitude,
        longitude: longitude,
        radius: _maxDistance,
      );

      if (mounted) {
        setState(() {
          _nearbyLocations = locations;
          _isLoadingNearby = false;
        });
      }
    } catch (e) {
      print('Error loading nearby locations: $e');

      if (mounted) {
        setState(() {
          _isLoadingNearby = false;
          _nearbyLocations = []; // Set to empty list to handle the UI properly
        });

        _showErrorSnackBar('Error loading nearby locations: ${e.toString()}');
      }
    }
  }

  void _showDistanceFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter Nearby Locations',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Distance slider
                      Row(
                        children: [
                          const Icon(Icons.near_me, color: Colors.white70),
                          const SizedBox(width: 12),
                          const Text(
                            'Maximum Distance',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const Spacer(),
                          Text(
                            '${_maxDistance.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _maxDistance,
                        min: 1.0,
                        max: 50.0,
                        divisions: 49,
                        activeColor: Colors.white,
                        inactiveColor: Colors.grey[700],
                        label: '${_maxDistance.toStringAsFixed(1)} km',
                        onChanged: (value) {
                          setState(() {
                            _maxDistance = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Apply button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            this.setState(() {
                              // Update the main state with the new distance
                              _maxDistance = _maxDistance;
                            });
                            _loadNearbyLocations();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Apply Filter',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the bottom padding for the navigation bar to avoid overlap
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'CloseShot',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadNearbyLocations,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showDistanceFilter,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
              : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 13,
                  backgroundColor: const Color(0xFF242f3e), // Dark theme
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.setscene',
                  ),
                  // Current location marker
                  if (_currentPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            width: 20,
                            height: 20,
                            child: const Center(
                              child: Icon(
                                Icons.my_location,
                                color: Colors.black,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  // Location markers
                  MarkerLayer(
                    markers:
                        _nearbyLocations.map((location) {
                          return Marker(
                            point: LatLng(
                              location.latitude,
                              location.longitude,
                            ),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => LocationDetailScreen(
                                          location: location,
                                        ),
                                  ),
                                ).then((_) => _loadNearbyLocations());
                              },
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.4),
                                          blurRadius: 3,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    width: 30,
                                    height: 30,
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.black,
                                      size: 16,
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      location.name.length > 10
                                          ? '${location.name.substring(0, 10)}...'
                                          : location.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),

          // Loading indicator for nearby locations
          if (_isLoadingNearby)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Loading nearby locations...',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Nearby locations list at bottom (adjusted height to prevent overlap)
          Positioned(
            bottom:
                bottomPadding, // Use calculated bottom padding to prevent overlap
            left: 0,
            right: 0,
            child: Container(
              height: 110,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child:
                  _nearbyLocations.isEmpty
                      ? Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'No locations found within ${_maxDistance.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        scrollDirection: Axis.horizontal,
                        itemCount: _nearbyLocations.length,
                        itemBuilder: (context, index) {
                          final location = _nearbyLocations[index];
                          return _buildLocationCard(location);
                        },
                      ),
            ),
          ),

          // Controls (adjusted position)
          Positioned(
            bottom:
                bottomPadding +
                110 +
                16, // Adjust to be above the nearby locations list
            right: 16,
            child: Column(
              children: [
                // Recenter button
                _buildMapButton(
                  icon: Icons.my_location,
                  onPressed: () {
                    if (_currentPosition != null) {
                      _mapController.move(
                        LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        13,
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Zoom in
                _buildMapButton(
                  icon: Icons.add,
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Zoom out
                _buildMapButton(
                  icon: Icons.remove,
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(LocationModel location) {
    return GestureDetector(
      onTap: () {
        // Focus map on this location
        _mapController.move(LatLng(location.latitude, location.longitude), 15);
      },
      onDoubleTap: () {
        // Navigate to location details on double tap
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LocationDetailScreen(location: location),
          ),
        ).then((_) => _loadNearbyLocations());
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Location image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Image.network(
                location.imageUrls.first,
                width: 80,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      width: 80,
                      color: Colors.grey[850],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white54,
                        ),
                      ),
                    ),
              ),
            ),

            // Location details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      location.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Distance
                    Row(
                      children: [
                        const Icon(
                          Icons.near_me,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${location.distance?.toStringAsFixed(1) ?? "?"} km away',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Ratings
                    Row(
                      children: [
                        // Visual rating
                        const Icon(
                          Icons.visibility,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          location.visualRating.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Audio rating
                        const Icon(
                          Icons.volume_up,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          location.audioRating.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        color: Colors.black,
        iconSize: 20,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
