import 'package:flutter/material.dart';
import 'package:setscene/models/location_model.dart';
import 'package:setscene/services/location_service.dart';
import 'package:setscene/screens/location_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({Key? key}) : super(key: key);

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
          tabFiltered.sort((a, b) => b.savedAt.compareTo(a.savedAt));
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
        ),
      );
    } catch (e) {
      print('Error removing location: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing location: ${e.toString()}'),
          backgroundColor: Colors.red,
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
          'ShotLock',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue[400],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[600],
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          onTap: (_) => _filterLocations(),
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
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search saved locations',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
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
                  SizedBox(
                    height: 40,
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
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? Colors.blue[700]
                                          : Colors.grey[900],
                                  borderRadius: BorderRadius.circular(20),
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
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                  // Results count
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Text(
                          '${_filteredLocations.length} location${_filteredLocations.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Location list
                  Expanded(
                    child:
                        _filteredLocations.isEmpty
                            ? Center(
                              child: Text(
                                'No locations match your filters',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 16,
                                ),
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
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
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
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
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Location image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: location.imageUrls.first,
                  width: 100,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white54,
                              ),
                            ),
                          ),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.grey[800],
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

                      // Address
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white54,
                            size: 12,
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
                      const SizedBox(height: 8),

                      // Ratings
                      Row(
                        children: [
                          // Visual rating
                          const Icon(
                            Icons.visibility,
                            color: Colors.blue,
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
                            color: Colors.green,
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
                          const Spacer(),

                          // Saved date
                          Text(
                            location.savedAtFormatted,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      location.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: location.isLiked ? Colors.red : Colors.white54,
                    ),
                    onPressed: () async {
                      if (location.isLiked) {
                        await _locationService.unlikeLocation(location.id);
                      } else {
                        await _locationService.likeLocation(location.id);
                      }

                      setState(() {
                        location.isLiked = !location.isLiked;
                      });
                    },
                    iconSize: 22,
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white54),
                    onPressed: () {
                      _showLocationOptions(location);
                    },
                    iconSize: 22,
                  ),
                ],
              ),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900]!.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_border,
              size: 70,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No saved locations yet',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Locations you save will appear here',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to feed screen
            },
            icon: const Icon(Icons.explore),
            label: const Text('Explore Locations'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
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
