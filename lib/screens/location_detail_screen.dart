// File: lib/screens/location_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:setscene/models/location_model.dart';
import 'package:setscene/services/location_service.dart';
import 'package:setscene/screens/profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class LocationDetailScreen extends StatefulWidget {
  final LocationModel location;

  const LocationDetailScreen({super.key, required this.location});

  @override
  _LocationDetailScreenState createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen>
    with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLiked = false;
  bool _isSaved = false;
  int _likesCount = 0;
  int _savesCount = 0;
  int _currentImageIndex = 0;
  bool _isPlayingAudio = false;
  bool _isLoadingAction = false;

  // Weather data (In a real app, this would come from an API)
  final Map<String, dynamic> _weatherData = {
    'temperature': '24°C',
    'condition': 'Sunny',
    'humidity': '65%',
    'wind': '5 km/h',
    'bestTime': 'Golden Hour (5-7 PM)',
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _isLiked = widget.location.isLiked;
    _isSaved = widget.location.isSaved;
    _likesCount = widget.location.likesCount;
    _savesCount = widget.location.savesCount;

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Toggle like status
  Future<void> _toggleLike() async {
    if (_isLoadingAction) return;

    setState(() {
      _isLoadingAction = true;
    });

    try {
      if (_isLiked) {
        await _locationService.unlikeLocation(widget.location.id);
      } else {
        await _locationService.likeLocation(widget.location.id);
      }

      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
        _isLoadingAction = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAction = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update like status')),
      );
    }
  }

  // Toggle save status
  Future<void> _toggleSave() async {
    if (_isLoadingAction) return;

    setState(() {
      _isLoadingAction = true;
    });

    try {
      if (_isSaved) {
        await _locationService.unsaveLocation(widget.location.id);
      } else {
        await _locationService.saveLocation(widget.location.id);
      }

      setState(() {
        _isSaved = !_isSaved;
        _savesCount += _isSaved ? 1 : -1;
        _isLoadingAction = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAction = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update save status')),
      );
    }
  }

  // Share location
  void _shareLocation() {
    final String text =
        "Check out ${widget.location.name} on SetScene!\n"
        "Address: ${widget.location.address}\n"
        "Visual rating: ${widget.location.visualRating}/5.0\n"
        "Audio rating: ${widget.location.audioRating}/5.0";

    Share.share(text);
  }

  // Open Maps app with location
  Future<void> _openMaps() async {
    final lat = widget.location.latitude;
    final lng = widget.location.longitude;
    final url = 'https://maps.google.com/maps?q=$lat,$lng';

    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
    }
  }

  // Copy address to clipboard
  void _copyAddress() {
    Clipboard.setData(ClipboardData(text: widget.location.address));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Address copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blue[700],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  // Toggle audio playback
  void _toggleAudio() {
    if (widget.location.audioUrl == null) return;

    setState(() {
      _isPlayingAudio = !_isPlayingAudio;
    });

    // TODO: Implement actual audio playback logic

    if (_isPlayingAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Started playing audio'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Navigate to creator profile
  void _navigateToCreatorProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: widget.location.creatorId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // App Bar with Image Carousel
            SliverAppBar(
              expandedHeight: 350.0,
              pinned: true,
              backgroundColor: Colors.black,
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(
                  tag: 'location-${widget.location.id}',
                  child: Material(
                    // Fixes yellow line issue
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        // Image carousel using PageView
                        SizedBox(
                          height: 350,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: widget.location.imageUrls.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return CachedNetworkImage(
                                imageUrl: widget.location.imageUrls[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder:
                                    (context, url) => Container(
                                      color: Colors.grey[900],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      color: Colors.grey[900],
                                      child: const Icon(
                                        Icons.error,
                                        color: Colors.white,
                                      ),
                                    ),
                              );
                            },
                          ),
                        ),

                        // Image pagination indicators
                        if (widget.location.imageUrls.length > 1)
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                widget.location.imageUrls.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: _currentImageIndex == index ? 24 : 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color:
                                        _currentImageIndex == index
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.5),
                                    boxShadow:
                                        _currentImageIndex == index
                                            ? [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.3,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                            : null,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Gradient overlay
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 150,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                                stops: const [0.0, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // Creator info top-left
                        Positioned(
                          top: 16,
                          left: 80, // Position after the back button
                          child: GestureDetector(
                            onTap: _navigateToCreatorProfile,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  ClipOval(
                                    child:
                                        widget.location.creatorPhotoUrl != null
                                            ? CachedNetworkImage(
                                              imageUrl:
                                                  widget
                                                      .location
                                                      .creatorPhotoUrl!,
                                              width: 24,
                                              height: 24,
                                              fit: BoxFit.cover,
                                              placeholder:
                                                  (context, url) => Container(
                                                    color: Colors.grey[850],
                                                    width: 24,
                                                    height: 24,
                                                    child: const Icon(
                                                      Icons.person,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                            )
                                            : Container(
                                              color: Colors.grey[850],
                                              width: 24,
                                              height: 24,
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '@${widget.location.creatorUsername}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                // Share button
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: _shareLocation,
                  ),
                ),
              ],
            ),

            // Location Content
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and location with shadow for visibility
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[900]?.withOpacity(0.7),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.location.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Categories as pills
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children:
                                        widget.location.categories.take(2).map((
                                          category,
                                        ) {
                                          return Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getCategoryColor(
                                                category,
                                              ).withOpacity(0.8),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              category,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: _copyAddress,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.white70,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        widget.location.address,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.copy,
                                      color: Colors.white54,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Like button
                        Expanded(
                          child: _buildActionButton(
                            icon:
                                _isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                            label:
                                '$_likesCount ${_likesCount == 1 ? 'Like' : 'Likes'}',
                            color: _isLiked ? Colors.red : Colors.white,
                            onTap: _toggleLike,
                            isLoading:
                                _isLoadingAction &&
                                _isLiked != widget.location.isLiked,
                          ),
                        ),

                        // Divider
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey[800],
                        ),

                        // Save button
                        Expanded(
                          child: _buildActionButton(
                            icon:
                                _isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                            label:
                                '$_savesCount ${_savesCount == 1 ? 'Save' : 'Saves'}',
                            color:
                                _isSaved ? Colors.yellow[700]! : Colors.white,
                            onTap: _toggleSave,
                            isLoading:
                                _isLoadingAction &&
                                _isSaved != widget.location.isSaved,
                          ),
                        ),

                        // Divider
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey[800],
                        ),

                        // Map button
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.map_outlined,
                            label: 'Map',
                            color: Colors.white,
                            onTap: _openMaps,
                          ),
                        ),

                        // Audio button (if available)
                        if (widget.location.audioUrl != null) ...[
                          // Divider
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.grey[800],
                          ),
                          Expanded(
                            child: _buildActionButton(
                              icon:
                                  _isPlayingAudio
                                      ? Icons.pause
                                      : Icons.play_arrow,
                              label: 'Audio',
                              color:
                                  _isPlayingAudio ? Colors.green : Colors.white,
                              onTap: _toggleAudio,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Ratings section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildRatingCard(
                            title: 'Visual Quality',
                            rating: widget.location.visualRating,
                            icon: Icons.visibility,
                            primaryColor: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRatingCard(
                            title: 'Audio Quality',
                            rating: widget.location.audioRating,
                            icon: Icons.volume_up,
                            primaryColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Description
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.description,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'About This Location',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.location.description,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.date_range,
                              color: Colors.grey[400],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Added on ${DateFormat('MMM d, yyyy').format(widget.location.createdAt)}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Weather and shooting conditions
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.wb_sunny, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Shooting Conditions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _buildWeatherInfoItem(
                              icon: Icons.thermostat_outlined,
                              label: 'Temperature',
                              value: _weatherData['temperature'],
                            ),
                            _buildWeatherInfoItem(
                              icon: Icons.water_drop_outlined,
                              label: 'Humidity',
                              value: _weatherData['humidity'],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildWeatherInfoItem(
                              icon: Icons.air,
                              label: 'Wind',
                              value: _weatherData['wind'],
                            ),
                            _buildWeatherInfoItem(
                              icon: Icons.access_time,
                              label: 'Best Time',
                              value: _weatherData['bestTime'],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Map preview
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.place, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Map Location',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(16),
                            image: const DecorationImage(
                              image: AssetImage(
                                'assets/images/map_placeholder.png',
                              ),
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
                          alignment: Alignment.center,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Map pin
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.place,
                                  color: Colors.red,
                                  size: 16,
                                ),
                              ),

                              // Open in Maps button
                              Positioned(
                                bottom: 16,
                                child: ElevatedButton.icon(
                                  onPressed: _openMaps,
                                  icon: const Icon(Icons.map),
                                  label: const Text('Open in Maps'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Coordinates
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.my_location,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Lat: ${widget.location.latitude.toStringAsFixed(6)}, Lng: ${widget.location.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text:
                                          '${widget.location.latitude.toStringAsFixed(6)}, ${widget.location.longitude.toStringAsFixed(6)}',
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Coordinates copied to clipboard',
                                      ),
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.copy,
                                  color: Colors.white54,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.blue[700]!.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _openMaps,
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          icon: const Icon(Icons.navigation),
          label: const Text('Navigate'),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeWidth: 2,
                  ),
                )
                : Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard({
    required String title,
    required double rating,
    required IconData icon,
    required Color primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[900]!, Colors.grey[850]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _buildRatingStars(rating, primaryColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars(double rating, Color starColor) {
    final fullStars = rating.floor();
    final halfStar = (rating - fullStars) >= 0.5;

    return Row(
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, color: starColor, size: 16);
        } else if (index == fullStars && halfStar) {
          return Icon(Icons.star_half, color: starColor, size: 16);
        } else {
          return Icon(Icons.star_border, color: starColor, size: 16);
        }
      }),
    );
  }

  Widget _buildWeatherInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.blue[400], size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
