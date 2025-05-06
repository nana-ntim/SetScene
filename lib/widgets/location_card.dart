import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:setscene/models/location_model.dart';
import 'package:setscene/screens/location_detail_screen.dart';

class LocationCard extends StatelessWidget {
  final LocationModel location;
  final bool isActive;

  const LocationCard({super.key, required this.location, this.isActive = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          isActive
              ? () {
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
                      const begin = Offset(0.0, 1.0);
                      const end = Offset.zero;
                      const curve = Curves.easeOutQuint;

                      var tween = Tween(
                        begin: begin,
                        end: end,
                      ).chain(CurveTween(curve: curve));

                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                );
              }
              : null,
      child: Hero(
        tag: 'location-${location.id}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ]
                    : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Image
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: location.imageUrls.first,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          color: Colors.grey[850],
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white70,
                              ),
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          color: Colors.grey[850],
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

                // Gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.6, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),

                // Location info
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location name
                        Text(
                          location.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Location details
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              location.address,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Rating and categories
                        Row(
                          children: [
                            // Visual rating
                            _buildRatingBadge(
                              icon: Icons.visibility,
                              rating: location.visualRating,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 12),

                            // Audio rating
                            _buildRatingBadge(
                              icon: Icons.volume_up,
                              rating: location.audioRating,
                              color: Colors.green,
                            ),

                            const Spacer(),

                            // Distance (if available)
                            if (location.distance != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.near_me,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${location.distance?.toStringAsFixed(1) ?? "?"} km',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Action indicators (only shown when swiping)
                if (isActive) ...[
                  Positioned(
                    top: 20,
                    left: 20,
                    child: IgnorePointer(
                      child: _buildActionIndicator(
                        label: 'SKIP',
                        color: Colors.red,
                        opacity: 0, // Initially hidden
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: IgnorePointer(
                      child: _buildActionIndicator(
                        label: 'LIKE',
                        color: Colors.green,
                        opacity: 0, // Initially hidden
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBadge({
    required IconData icon,
    required double rating,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
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
      ),
    );
  }

  Widget _buildActionIndicator({
    required String label,
    required Color color,
    required double opacity,
  }) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
