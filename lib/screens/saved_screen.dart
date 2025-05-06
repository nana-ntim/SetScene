// File location: lib/screens/saved_screen.dart

import 'package:flutter/material.dart';
import 'package:setscene/models/location_model.dart';
import 'package:setscene/services/location_service.dart';
import 'package:setscene/screens/location_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  _SavedScreenState createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen>
    with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  List<LocationModel> _savedLocations = [];
  List<LocationModel> _filteredLocations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  late TabController _tabController;
  final List<String> _tabs = ['All', 'Favorites', 'Recent'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadSavedLocations();

    // Listen for tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _filterLocations();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLocations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locations = await _locationService.getSavedLocations();

      if (mounted) {
        setState(() {
          _savedLocations = locations;
          _filterLocations();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading saved locations: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading saved locations: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  void _filterLocations() {
    setState(() {
      // Filter by tab
      List<LocationModel> tabFiltered = [];

      switch (_tabController.index) {
        case 0: // All
          tabFiltered = List.from(_savedLocations);
          break;
        case 1: // Favorites
          tabFiltered =
              _savedLocations.where((location) => location.isLiked).toList();
          break;
        case 2: // Recent
          tabFiltered = List.from(_savedLocations);
          tabFiltered.sort((a, b) {
            // If both dates are null, consider them equal
            if (a.savedAt == null && b.savedAt == null) {
              return 0;
            }
            // If only a's date is null, consider it earlier
            if (a.savedAt == null) {
              return 1;
            }
            // If only b's date is null, consider it earlier
            if (b.savedAt == null) {
              return -1;
            }
            // If both dates exist, compare normally
            return b.savedAt!.compareTo(a.savedAt!);
          });
          break;
      }

      // Filter by category
      if (_selectedCategory != 'All') {
        tabFiltered =
            tabFiltered
                .where(
                  (location) => location.categories.contains(_selectedCategory),
                )
                .toList();
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        tabFiltered =
            tabFiltered
                .where(
                  (location) =>
                      location.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      location.address.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                )
                .toList();
      }

      _filteredLocations = tabFiltered;
    });
  }

  Future<void> _removeLocation(LocationModel location) async {
    try {
      await _locationService.unsaveLocation(location.id);

      setState(() {
        _savedLocations.removeWhere((l) => l.id == location.id);
        _filterLocations();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location removed from saved'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await _locationService.saveLocation(location.id);

              setState(() {
                _savedLocations.add(location);
                _filterLocations();
              });
            },
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    } catch (e) {
      print('Error removing location: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing location: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get all unique categories
    final categories = <String>{'All'};
    for (final location in _savedLocations) {
      categories.addAll(location.categories);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Saved Locations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.grey[900]!.withOpacity(0.2), Colors.black],
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.blue[400],
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
              onTap: (_) => _filterLocations(),
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
              : _savedLocations.isEmpty
              ? _buildEmptyState()
              : Column(
                children: [
                  // Search bar
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search saved locations',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _filterLocations();
                        });
                      },
                    ),
                  ),

                  // Category filter
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[900]!.withOpacity(0.3),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      children:
                          categories.map((category) {
                            final bool isSelected =
                                _selectedCategory == category;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category;
                                  _filterLocations();
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? _getCategoryColor(category)
                                          : Colors.grey[900],
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow:
                                      isSelected
                                          ? [
                                            BoxShadow(
                                              color: _getCategoryColor(
                                                category,
                                              ).withOpacity(0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                          : null,
                                  border:
                                      isSelected
                                          ? null
                                          : Border.all(
                                            color: Colors.grey[800]!,
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
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                  // Results count
                  if (_filteredLocations.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_filteredLocations.length} ${_filteredLocations.length != 1 ? 'locations' : 'location'}',
                              style: TextStyle(
                                color: Colors.blue[300],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.sort, color: Colors.grey[400]),
                            onPressed: () {
                              // Could implement sorting options
                            },
                          ),
                        ],
                      ),
                    ),

                  // Location list
                  Expanded(
                    child:
                        _filteredLocations.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 60,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No locations match your filters',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _selectedCategory = 'All';
                                        _filterLocations();
                                      });
                                    },
                                    child: const Text('Clear Filters'),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.only(
                                top: 0,
                                bottom:
                                    100, // Extra padding at bottom to prevent overlap with nav bar
                              ),
                              itemCount: _filteredLocations.length,
                              itemBuilder: (context, index) {
                                final location = _filteredLocations[index];
                                return _buildLocationTile(location);
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildLocationTile(LocationModel location) {
    return Dismissible(
      key: Key(location.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red[800],
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _removeLocation(location);
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LocationDetailScreen(location: location),
            ),
          ).then((_) => _loadSavedLocations());
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Image on the left
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: location.imageUrls.first,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey[850],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white54,
                            ),
                          ),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.grey[850],
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.white54,
                        ),
                      ),
                ),
              ),

              // Location details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location name and address
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
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location.address,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Categories as chips
                      SizedBox(
                        height: 24,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children:
                              location.categories.take(2).map((category) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(
                                      category,
                                    ).withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Ratings and saved date
                      Row(
                        children: [
                          // Visual rating
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.visibility,
                                  color: Colors.blue,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  location.visualRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Audio rating
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.volume_up,
                                  color: Colors.green,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  location.audioRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // Saved date
                          if (location.savedAt != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                location.savedAtFormatted,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Like button
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Like button
                  IconButton(
                    icon: Icon(
                      location.isLiked ? Icons.favorite : Icons.favorite_border,
                      color:
                          location.isLiked ? Colors.red[400] : Colors.grey[600],
                      size: 26,
                    ),
                    onPressed: () async {
                      try {
                        setState(() {
                          // Optimistically update UI
                          location.isLiked = !location.isLiked;
                        });

                        if (location.isLiked) {
                          await _locationService.likeLocation(location.id);
                        } else {
                          await _locationService.unlikeLocation(location.id);
                        }
                      } catch (e) {
                        // Revert on error
                        setState(() {
                          location.isLiked = !location.isLiked;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    padding: EdgeInsets.zero,
                  ),

                  // More options button
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white70,
                      size: 26,
                    ),
                    onPressed: () => _showLocationOptions(location),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),

              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.bookmark_border,
              size: 50,
              color: Colors.amber[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No saved locations yet',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Save interesting filming locations to access them later',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to explore tab (index 0)
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.explore),
            label: const Text('Explore Locations'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: Colors.blue.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    // Return different colors based on category name
    switch (category.toLowerCase()) {
      case 'all':
        return Colors.blue[600]!;
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

  void _showLocationOptions(LocationModel location) {
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
          (context) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with location name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          location.imageUrls.first,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          location.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Colors.white24),

                // Options
                _buildOptionTile(
                  icon: Icons.share,
                  title: 'Share Location',
                  onTap: () {
                    Navigator.pop(context);
                    // Share location
                  },
                ),
                _buildOptionTile(
                  icon: Icons.map,
                  title: 'Open in Maps',
                  onTap: () {
                    Navigator.pop(context);
                    // Open in maps
                  },
                ),
                _buildOptionTile(
                  icon: Icons.delete,
                  title: 'Remove from Saved',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    _removeLocation(location);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.white70),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : Colors.white),
      ),
      onTap: onTap,
    );
  }
}
