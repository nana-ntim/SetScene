import 'package:flutter/material.dart';
import 'package:setscene/models/location_model.dart';
import 'package:setscene/widgets/location_card.dart';
import 'package:setscene/services/location_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  List<LocationModel> _locations = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final double _rotationAngle = 0.0;
  final double _opacity = 1.0;
  Offset _dragPosition = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Added delay to ensure widget is properly mounted
    Future.delayed(Duration.zero, () {
      _loadLocations();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Simulate and handle empty state for testing
      // Remove the mock data and use real data from your service
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay

      // TESTING: Uncomment to test empty state
      // final locations = <LocationModel>[];

      // REAL IMPLEMENTATION:
      final locations = await _locationService.getLocations();

      if (mounted) {
        setState(() {
          _locations = locations;
          _isLoading = false;
        });

        // Start animation if there are locations
        if (_locations.isNotEmpty) {
          _animationController.forward();
        }
      }
    } catch (e) {
      print('Error loading locations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load locations. Please try again.';
        });
      }
    }
  }

  void _onSwipeLeft() {
    // Skip/dislike location
    if (_currentIndex < _locations.length - 1) {
      setState(() {
        _currentIndex++;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  void _onSwipeRight() {
    // Like location
    if (_currentIndex < _locations.length - 1) {
      // Here you would typically save the liked location
      _locationService.likeLocation(_locations[_currentIndex].id);

      setState(() {
        _currentIndex++;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragPosition = Offset.zero;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragPosition += details.delta;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    // Calculate the swipe direction based on drag position
    final double swipeThreshold = 100.0;

    if (_dragPosition.dx > swipeThreshold) {
      _onSwipeRight();
    } else if (_dragPosition.dx < -swipeThreshold) {
      _onSwipeLeft();
    }

    setState(() {
      _isDragging = false;
      _dragPosition = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'FilmSpots',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              // Show filter options
            },
          ),
          // Add refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadLocations,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
              : _hasError
              ? _buildErrorState()
              : _locations.isEmpty
              ? _buildEmptyState()
              : Column(
                children: [
                  Expanded(
                    child:
                        _currentIndex < _locations.length
                            ? GestureDetector(
                              onHorizontalDragStart: _onDragStart,
                              onHorizontalDragUpdate: _onDragUpdate,
                              onHorizontalDragEnd: _onDragEnd,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Next card (shown behind current)
                                  if (_currentIndex < _locations.length - 1)
                                    Positioned(
                                      top: 40,
                                      left: 20,
                                      right: 20,
                                      bottom: 90,
                                      child: Transform.scale(
                                        scale: 0.95,
                                        child: LocationCard(
                                          location:
                                              _locations[_currentIndex + 1],
                                          isActive: false,
                                        ),
                                      ),
                                    ),

                                  // Current card
                                  Positioned(
                                    top: 20,
                                    left: 20,
                                    right: 20,
                                    bottom: 90,
                                    child: AnimatedBuilder(
                                      animation: _animationController,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset:
                                              _isDragging
                                                  ? _dragPosition
                                                  : Offset.zero,
                                          child: Transform.rotate(
                                            angle:
                                                _isDragging
                                                    ? _dragPosition.dx / 1000
                                                    : _rotationAngle,
                                            child: Opacity(
                                              opacity:
                                                  _isDragging
                                                      ? 1.0 -
                                                          (_dragPosition.dx
                                                                      .abs() /
                                                                  1000)
                                                              .clamp(0.0, 0.2)
                                                      : _opacity,
                                              child: Transform.scale(
                                                scale: _scaleAnimation.value,
                                                child: child,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: LocationCard(
                                        location: _locations[_currentIndex],
                                        isActive: true,
                                      ),
                                    ),
                                  ),

                                  // Action buttons
                                  Positioned(
                                    bottom: 20,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _buildActionButton(
                                          icon: Icons.close,
                                          color: Colors.red,
                                          onTap: _onSwipeLeft,
                                        ),
                                        const SizedBox(width: 20),
                                        _buildActionButton(
                                          icon: Icons.bookmark_border,
                                          color: Colors.amber,
                                          onTap: () {
                                            // Save current location
                                            _locationService.saveLocation(
                                              _locations[_currentIndex].id,
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                  'Location saved',
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                backgroundColor:
                                                    Colors.green[700],
                                                duration: const Duration(
                                                  seconds: 1,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 20),
                                        _buildActionButton(
                                          icon: Icons.favorite_border,
                                          color: Colors.green,
                                          onTap: _onSwipeRight,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : _buildEndOfLocationsState(),
                  ),
                ],
              ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900]!.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off,
                size: 64,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No locations found',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Be the first to add a filming location!',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to create screen or trigger create modal
                final int createIndex = 2; // Index of create tab in bottom nav
                Navigator.of(context).popUntil((route) => route.isFirst);
                // Notify parent to switch to create tab - this would need to be implemented in home_screen.dart
              },
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Add Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: _loadLocations, child: const Text('Refresh')),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadLocations,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndOfLocationsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            'You\'ve seen all locations',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _currentIndex = 0;
                _animationController.reset();
                _animationController.forward();
              });
            },
            child: Text(
              'Start over',
              style: TextStyle(
                color: Colors.blue[400],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
