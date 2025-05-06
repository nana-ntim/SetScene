// File: lib/screens/saved_screen.dart

import 'package:flutter/material.dart';
import 'package:setscene/models/location_model.dart';
import 'package:setscene/services/location_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:setscene/screens/location_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  _SavedScreenState createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen>
    with AutomaticKeepAliveClientMixin {
  final LocationService _locationService = LocationService();
  List<LocationModel> _savedLocations = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
  }

  Future<void> _loadSavedLocations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final locations = await _locationService.getSavedLocations();

      if (mounted) {
        setState(() {
          _savedLocations = locations;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading saved locations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load saved locations. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Saved Locations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadSavedLocations,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSavedLocations,
        color: Colors.blue,
        backgroundColor: Colors.grey[900],
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                )
                : _hasError
                ? _buildErrorState()
                : _savedLocations.isEmpty
                ? _buildEmptyState()
                : _buildSavedLocationsList(),
      ),
    );
  }

  Widget _buildSavedLocationsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _savedLocations.length,
      itemBuilder: (context, index) {
        final location = _savedLocations[index];
        return _buildSavedLocationCard(location);
      },
    );
  }

  Widget _buildSavedLocationCard(LocationModel location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      LocationDetailScreen(location: location),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ).then((_) => _loadSavedLocations());
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image container with ClipRRect for proper corner radius
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: location.imageUrls.first,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white70,
                            ),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.white70,
                            size: 30,
                          ),
                        ),
                      ),
                ),
              ),
            ),

            // Content padding
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location name
                  Text(
                    location.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Address with icon
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location.address,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Categories row
                  SizedBox(
                    height: 30,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children:
                          location.categories.map((category) {
                            final color = _getCategoryColor(category);
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: color.withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bottom row with ratings and saved date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Ratings
                      Row(
                        children: [
                          _buildMiniRatingBadge(
                            icon: Icons.visibility,
                            rating: location.visualRating,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _buildMiniRatingBadge(
                            icon: Icons.volume_up,
                            rating: location.audioRating,
                            color: Colors.green,
                          ),
                        ],
                      ),

                      // Saved date
                      Row(
                        children: [
                          Icon(
                            Icons.bookmark,
                            color: Colors.yellow[700],
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Saved ${location.savedAtFormatted}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniRatingBadge({
    required IconData icon,
    required double rating,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900]!.withOpacity(0.5),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.bookmark_outline,
                size: 64,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No saved locations yet',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Locations you save will appear here for easy access.',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to explore page
                final int exploreIndex =
                    0; // Index of explore tab in bottom nav
                // Access the parent widget to switch to explore tab
                // This would need to be implemented in home_screen.dart
              },
              icon: const Icon(Icons.explore),
              label: const Text('Explore Locations'),
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
            ),
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
              onPressed: _loadSavedLocations,
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
