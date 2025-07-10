import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'theme.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart'; // Add this import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/search_cache_service.dart';
import 'package:shimmer/shimmer.dart';

class NeedRoomPage extends StatefulWidget {
  const NeedRoomPage({Key? key}) : super(key: key);

  @override
  State<NeedRoomPage> createState() => _NeedRoomPageState();
}

class _NeedRoomPageState extends State<NeedRoomPage> with RouteAware {
  late String _selectedLocation;
  String _selectedPriceRange = 'All Prices';
  String _selectedRoomType = 'All Types';
  String _selectedFlatSize = 'All Sizes';
  String _selectedGenderPreference = 'All';
  String _searchQuery = '';

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    final parts = dateString.split('T')[0].split('-');
    if (parts.length != 3) return dateString;
    return '${parts[2]}-${parts[1]}-${parts[0]}'; // DD-MM-YYYY
  }

  List<String> _locations = ['All Cities'];

  final List<String> _priceRanges = [
    'All Prices',
    '< \₹3000',
    '< \₹5000',
    '< \₹7000',
    '< \₹9000',
    '\₹9000+',
  ];

  final List<String> _roomTypes = [
    'All Types', // Add this for proper filtering
    'Private',
    'Shared Room',
  ];

  final List<String> _flatSizes = [
    '1RK',
    '1BHK',
    '2BHK',
    '3BHK',
    '4BHK',
    '5BHK',
  ];

  final List<String> _genderPreferences = ['Male Only', 'Female Only', 'Mixed'];

  final TextEditingController _searchController = TextEditingController();
  final SearchCacheService _cacheService = SearchCacheService();

  List<Map<String, dynamic>> _rooms = []; // <-- Now fetched from Firebase
  bool _isLoading = true;
  int? _hoveredRoomCardIndex;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _fetchRooms();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    // Do not reset filters here
  }

  void _initializeFilters() {
    if (mounted) {
      setState(() {
        _selectedLocation = 'All Cities';
        _selectedPriceRange = 'All Prices';
        _selectedRoomType = 'All Types';
        _selectedFlatSize = 'All Sizes';
        _selectedGenderPreference = 'All';
        _searchQuery = '';
        if (_searchController.text.isNotEmpty) {
          _searchController.clear();
        }
      });
    }
  }

  Future<void> _fetchRooms() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Use cached data instead of direct Firestore query
      final loadedRooms = await _cacheService.getRoomsWithCache();
      
      // Extract unique locations from cached data
      final Set<String> dynamicLocations = {'All Cities'};
      for (final room in loadedRooms) {
        if (room['location'] != null &&
            room['location'].toString().isNotEmpty) {
          dynamicLocations.add(room['location'].toString());
        }
      }

      setState(() {
        _rooms = loadedRooms;
        _locations = dynamicLocations.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _rooms = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load rooms: $e')));
    }
  }

  List<Map<String, dynamic>> get _filteredRooms {
    return _rooms.where((room) {
      final query = _searchQuery.toLowerCase().trim();

      final matchesSearch =
          query.isEmpty ||
          (room['title']?.toString().toLowerCase().contains(query) ?? false) ||
          (room['location']?.toString().toLowerCase().contains(query) ??
              false) ||
          ((room['facilities'] is Map)
              ? (room['facilities'] as Map).keys.any(
                (a) => a.toString().toLowerCase().contains(query),
              )
              : false);

      final matchesLocation =
          _selectedLocation == 'All Cities' ||
          (room['location']?.toString().toLowerCase().trim().contains(
                _selectedLocation.toLowerCase().trim(),
              ) ??
              false);

      final matchesType =
          _selectedRoomType == 'All Types' ||
          (room['roomType']?.toString().toLowerCase().trim() ==
              _selectedRoomType.toLowerCase().trim());

      final matchesFlatSize =
          _selectedFlatSize == 'All Sizes' ||
          (room['flatSize']?.toString().toLowerCase().trim() ==
              _selectedFlatSize.toLowerCase().trim());

      final matchesGender =
          _selectedGenderPreference == 'All' ||
          (room['genderComposition']?.toString().toLowerCase().trim() ==
              _selectedGenderPreference.toLowerCase().trim());

      final matchesPrice =
          _selectedPriceRange == 'All Prices' ||
          _priceInRange(room['rent']?.toString() ?? '', _selectedPriceRange);

      return matchesSearch &&
          matchesLocation &&
          matchesType &&
          matchesFlatSize &&
          matchesGender &&
          matchesPrice;
    }).toList();
  }

  bool _priceInRange(String priceStr, String range) {
    double price = 0;
    try {
      price = double.tryParse(priceStr.toString()) ?? 0;
    } catch (_) {}
    if (range == 'All Prices') return true;
    if (range == '< \₹3000') return price < 3000;
    if (range == '< \₹5000') return price < 5000;
    if (range == '< \₹7000') return price < 7000;
    if (range == '< \₹9000') return price < 9000;
    if (range == '\₹9000+') return price >= 9000;
    return true;
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    // Do not reset filters here
  }

  @override
  Widget build(BuildContext context) {
    // Always use dark mode colors
    final Color primaryColor = const Color(0xFF90CAF9);
    final Color accentColor = const Color(0xFF64B5F6);
    final Color cardColor = const Color(0xFF23262F);
    final Color textPrimary = Colors.white;
    final Color textSecondary = Colors.white70;
    final Color textLight = Colors.white38;
    final Color borderColor = Colors.white12;
    final Color successColor = const Color(0xFF81C784);
    final Color warningColor = const Color(0xFFFFB74D);
    final Color inputFillColor = const Color(0xFF23262F);
    final Color labelColor = textPrimary;
    final Color hintColor = Colors.white38;

    // Set status bar and navigation bar to pure black
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        systemNavigationBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black, // Changed to pure black
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              print('Refreshing room listings...');
              await _fetchRooms();
              return;
            },
            color: BuddyTheme.primaryColor,
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context, textPrimary),
                            const SizedBox(height: BuddyTheme.spacingLg),
                            _buildSearchSection(
                              cardColor,
                              inputFillColor,
                              labelColor,
                              hintColor,
                              textLight,
                              textPrimary,
                              accentColor,
                              borderColor,
                            ),
                            const SizedBox(height: BuddyTheme.spacingLg),
                            _buildSectionHeader(
                              'Available Properties',
                              textPrimary,
                              accentColor,
                            ),
                            const SizedBox(height: BuddyTheme.spacingMd),
                            if (_filteredRooms.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 40,
                                  ),
                                  child: Text(
                                    'No rooms found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: textPrimary.withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                            else
                              _buildRoomsGrid(),
                            SizedBox(height: BuddyTheme.spacingMd + MediaQuery.of(context).padding.bottom),
                          ],
                        ),
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find Your',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.copyWith(color: labelColor),
        ),
        Text(
          'Dream Room',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: BuddyTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection(
    Color cardColor,
    Color inputFillColor,
    Color hintColor,
    Color labelColor,
    Color textLight,
    Color textPrimary,
    Color accentColor,
    Color borderColor,
  ) {
    return Column(
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF23262F), // Modern dark search bar
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(color: Colors.white12),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white70,
            decoration: const InputDecoration(
              hintText: 'Search neighborhoods, amenities, or landmarks...',
              hintStyle: TextStyle(color: Colors.white), // Make hint white
              prefixIcon: Icon(Icons.search, color: Colors.white38),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(BuddyTheme.spacingMd),
              filled: false,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Removed Location filter chip from UI
              _buildFilterChip(
                'Budget',
                _selectedPriceRange,
                _priceRanges,
                (value) {
                  setState(() => _selectedPriceRange = value);
                },
                cardColor,
                textPrimary,
                borderColor,
              ),
              const SizedBox(width: BuddyTheme.spacingXs),
              _buildFilterChip(
                'Room Type',
                _selectedRoomType,
                _roomTypes,
                (value) {
                  setState(() => _selectedRoomType = value);
                },
                cardColor,
                textPrimary,
                borderColor,
              ),
              const SizedBox(width: BuddyTheme.spacingXs),
              _buildFilterChip(
                'Flat Size',
                _selectedFlatSize,
                ['All Sizes', ..._flatSizes],
                (value) {
                  setState(() => _selectedFlatSize = value);
                },
                cardColor,
                textPrimary,
                borderColor,
              ),
              const SizedBox(width: BuddyTheme.spacingXs),
              _buildFilterChip(
                'Gender',
                _selectedGenderPreference,
                ['All', ..._genderPreferences],
                (value) {
                  setState(() => _selectedGenderPreference = value);
                },
                cardColor,
                textPrimary,
                borderColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
  // Remove unused method
  // Widget _buildRoomListings() { ... }

  Widget _buildFilterChip(
    String label,
    String value,
    List<String> options,
    Function(String) onChanged,
    Color cardColor,
    Color labelColor,
    Color borderColor,
  ) {
    final isSelected = value != options.first;
    return GestureDetector(
      onTap:
          () => _showFilterBottomSheet(
            context,
            label,
            options,
            value,
            (selected) {
              if (selected != value) {
                onChanged(
                  selected,
                ); // Only call onChanged, let parent handle setState
              }
            },
            cardColor,
            labelColor,
            borderColor,
          ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BuddyTheme.spacingSm,
          vertical: BuddyTheme.spacingXs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? BuddyTheme.primaryColor : cardColor,
          borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
          border: Border.all(
            color: isSelected ? BuddyTheme.primaryColor : borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value == options.first ? label : value,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: isSelected ? BuddyTheme.textLightColor : labelColor,
              ),
            ),
            const SizedBox(width: BuddyTheme.spacingXxs),
            Icon(
              Icons.keyboard_arrow_down,
              size: BuddyTheme.iconSizeSm,
              color: isSelected ? BuddyTheme.textLightColor : labelColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    Color textPrimary,
    Color accentColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
  // Removed unused _buildRoomListings method

  Widget _buildRoomsGrid() {
    if (kIsWeb) {
      const double cardSpacing = 20.0;
      const int crossAxisCount = 3;
      final double gridWidth = MediaQuery.of(context).size.width - (BuddyTheme.spacingMd * 2);
      final double cardSize = (gridWidth - (cardSpacing * (crossAxisCount - 1))) / crossAxisCount;
      if (_filteredRooms.length < 3) {
        // Left-align 1 or 2 cards
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(_filteredRooms.length, (index) {
              final room = _filteredRooms[index];
              return Padding(
                padding: EdgeInsets.only(right: index < _filteredRooms.length - 1 ? cardSpacing : 0),
                child: _buildRoomCardWeb(room, index, cardSize),
              );
            }),
          ),
        );
      } else {
        // 3 or more: use grid
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 320 / 200,
            crossAxisSpacing: cardSpacing,
            mainAxisSpacing: cardSpacing,
          ),
          itemCount: _filteredRooms.length,
          itemBuilder: (context, index) {
            final room = _filteredRooms[index];
            return _buildRoomCardWeb(room, index, cardSize);
          },
        );
      }
    } else {
      // Mobile layout: single column
      return Column(
        children: _filteredRooms
            .map(
              (room) => Padding(
                padding: const EdgeInsets.only(
                  bottom: BuddyTheme.spacingMd,
                ),
                child: _buildRoomCard(
                  room,
                  const Color(0xFF23262F),
                  Colors.white12,
                  Colors.white38,
                  Colors.white,
                  Colors.white70,
                  const Color(0xFF64B5F6),
                  const Color(0xFF90CAF9),
                  const Color(0xFF181A20),
                  const Color(0xFF81C784),
                  const Color(0xFFFFB74D),
                ),
              ),
            )
            .toList(),
      );
    }
  }

  Widget _buildPlaceholderCard() {
    // Optimized sizes for web and mobile
    final isWeb = kIsWeb;
    final double imageHeight = isWeb ? 140.0 : 240.0;
    final double padding = isWeb ? 16.0 : 20.0;
    final double titleHeight = isWeb ? 18.0 : 22.0;
    final double addressHeight = isWeb ? 14.0 : 18.0;
    final double buttonHeight = isWeb ? 36.0 : 44.0;
    final double spacing = isWeb ? 6.0 : 10.0;
    final double buttonSpacing = isWeb ? 12.0 : 18.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF23262F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder image
          Container(
            height: imageHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Icon(
              Icons.image_outlined,
              color: Colors.white38,
              size: isWeb ? 32 : 48,
            ),
          ),
          // Placeholder content
          Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: titleHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: spacing),
                Container(
                  height: addressHeight,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: buttonSpacing),
                Container(
                  height: buttonHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCardWeb(Map<String, dynamic> room, int index, double cardSize) {
    final double cardWidth = 320.0;
    final double imageHeight = 140.0;
    // Get the image URL from the firstPhoto field or try to find one from uploadedPhotos
    String? imageUrl = room['firstPhoto'] as String?;
    if (imageUrl == null && room['uploadedPhotos'] != null) {
      final photos = room['uploadedPhotos'];
      if (photos is Map<String, dynamic>) {
        for (final categoryPhotos in photos.values) {
          if (categoryPhotos is List && categoryPhotos.isNotEmpty) {
            imageUrl = categoryPhotos[0] as String;
            break;
          }
        }
      } else if (photos is List) {
        if (photos.isNotEmpty) {
          imageUrl = photos[0].toString();
        }
      }
    }
    if (imageUrl == null && room['imageUrl'] != null && room['imageUrl'].toString().isNotEmpty) {
      imageUrl = room['imageUrl'].toString();
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRoomCardIndex = index),
      onExit: (_) => setState(() => _hoveredRoomCardIndex = null),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/propertyDetails',
            arguments: {'propertyId': room['id']},
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: _hoveredRoomCardIndex == index ? (Matrix4.identity()..scale(1.04)) : Matrix4.identity(),
          decoration: BoxDecoration(
            color: const Color(0xFF23262F),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: _hoveredRoomCardIndex == index ? 32 : 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          width: cardWidth,
          margin: const EdgeInsets.only(bottom: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                child: CachedNetworkImage(
                  imageUrl: imageUrl ?? '',
                  height: imageHeight,
                  width: cardWidth,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.white12,
                    highlightColor: const Color(0xFF23262F),
                    child: Container(color: Colors.white12, height: imageHeight, width: cardWidth),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.white12,
                    height: imageHeight,
                    width: cardWidth,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white38,
                      size: 40,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      room['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 17.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      room['location'] ?? '',
                      style: const TextStyle(
                        fontSize: 13.0,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCard(
    Map<String, dynamic> room,
    Color cardColor,
    Color borderColor,
    Color textLight,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
    Color primaryColor,
    Color backgroundColor,
    Color successColor,
    Color warningColor,
  ) {
    // Optimized sizes for web and mobile
    final isWeb = kIsWeb;
    final double imageHeight = isWeb ? 140.0 : 240.0;
    final double padding = isWeb ? 16.0 : 20.0;
    final double titleFontSize = isWeb ? 18.0 : 22.0;
    final double priceFontSize = isWeb ? 16.0 : 20.0;
    final double addressFontSize = isWeb ? 13.0 : 16.0;
    final double buttonFontSize = isWeb ? 14.0 : 16.0;
    final double buttonPadding = isWeb ? 10.0 : 14.0;
    final double spacing = isWeb ? 6.0 : 10.0;
    final double buttonSpacing = isWeb ? 12.0 : 18.0;
    final double iconSize = isWeb ? 16.0 : 20.0;
    final double badgePadding = isWeb ? 6.0 : 8.0;

    // Get the image URL from the firstPhoto field or try to find one from uploadedPhotos
    String? imageUrl = room['firstPhoto'] as String?;
    if (imageUrl == null && room['uploadedPhotos'] != null) {
      final photos = room['uploadedPhotos'];
      if (photos is Map<String, dynamic>) {
        // New format with categories
        for (final categoryPhotos in photos.values) {
          if (categoryPhotos is List && categoryPhotos.isNotEmpty) {
            imageUrl = categoryPhotos[0] as String;
            break;
          }
        }
      } else if (photos is List) {
        // Old format - direct list of photos
        if (photos.isNotEmpty) {
          imageUrl = photos[0].toString();
        }
      }
    }
    // Fallback to imageUrl field if no photos found
    if (imageUrl == null &&
        room['imageUrl'] != null &&
        room['imageUrl'].toString().isNotEmpty) {
      imageUrl = room['imageUrl'];
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section with availability badge
          Stack(
            children: [
              // Property image
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          height: imageHeight,
                          color: borderColor,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: accentColor,
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          height: imageHeight,
                          color: borderColor,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: textLight,
                            size: isWeb ? 40 : 56,
                          ),
                        ),
                  ),
                )
              else
                Container(
                  height: imageHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Icon(Icons.image, color: textLight, size: isWeb ? 40 : 56),
                ),

              // Available Now badge
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: badgePadding,
                    vertical: badgePadding / 2,
                  ),
                ),
              ),
            ],
          ),

          // Content section
          Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Price row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property name
                    Expanded(
                      child: Text(
                        room['title'] ?? 'Property Name',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          height: 1.2,
                        ),
                        maxLines: isWeb ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: isWeb ? 8 : 12),
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '\₹${room['rent'] ?? '120'}',
                                style: TextStyle(
                                  fontSize: priceFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              TextSpan(
                                text: '/mo',
                                style: TextStyle(
                                  fontSize: isWeb ? 12.0 : 16.0,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: spacing),

                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: textSecondary,
                      size: iconSize,
                    ),
                    SizedBox(width: spacing / 2),
                    Expanded(
                      child: Text(
                        room['location'] ?? 'Location',
                        style: TextStyle(
                          fontSize: addressFontSize,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: isWeb ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: buttonSpacing),

                Row(
                  children: [
                    // Room type tag
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: badgePadding,
                        vertical: badgePadding / 2,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(
                          4,
                        ), // Changed from 16 to 4 for rectangular shape
                      ),
                      child: Text(
                        room['roomType'] ?? 'Shared',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isWeb ? 12 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    SizedBox(width: spacing),

                    // Flat size tag
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: badgePadding,
                        vertical: badgePadding / 2,
                      ),
                      decoration: BoxDecoration(
                        color: textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          4,
                        ), // Changed from 16 to 4 for rectangular shape
                        border: Border.all(
                          color: textSecondary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        room['flatSize'] ?? '2 Beds',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: isWeb ? 12 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: buttonSpacing),

                // View Details button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/propertyDetails',
                        arguments: {'propertyId': room['id']},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: buttonPadding),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(
    BuildContext context,
    String title,
    List<String> options,
    String currentValue,
    Function(String) onChanged,
    Color cardColor,
    Color labelColor,
    Color borderColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Select $title',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: labelColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: labelColor),
                      ),
                    ],
                  ),
                ),
                ...options.map(
                  (option) => ListTile(
                    title: Text(
                      option,
                      style: TextStyle(
                        color: labelColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing:
                        currentValue == option
                            ? Icon(
                              Icons.check_rounded,
                              color: BuddyTheme.primaryColor,
                            )
                            : null,
                    onTap: () {
                      onChanged(option);
                      Navigator.pop(context);
                    },
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
              ],
            ),
          ),
    );
  }
}

class PropertyDetailsPage extends StatefulWidget {
  final String propertyKey;
  const PropertyDetailsPage({Key? key, required this.propertyKey})
    : super(key: key);

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  Map<String, dynamic>? _roomDetails;
  bool _isLoading = true;

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    final parts = dateString.split('T')[0].split('-');
    if (parts.length != 3) return dateString;
    return '${parts[2]}-${parts[1]}-${parts[0]}'; // DD-MM-YYYY
  }

  @override
  void initState() {
    super.initState();
    _fetchRoomDetails();
  }

  Future<void> _fetchRoomDetails() async {
    final ref = FirebaseDatabase.instance
        .ref()
        .child('room_listings')
        .child(widget.propertyKey);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      setState(() {
        _roomDetails = Map<String, dynamic>.from(snapshot.value as Map);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always use dark mode colors
    final Color primaryColor = const Color(0xFF90CAF9);
    final Color accentColor = const Color(0xFF64B5F6);
    final Color cardColor = const Color(0xFF23262F);
    final Color textPrimary = Colors.white;
    final Color textSecondary = Colors.white70;
    final Color textLight = Colors.white38;
    final Color borderColor = Colors.white12;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black, // Set status bar to pure black
        systemNavigationBarColor:
            Colors.black, // Also set nav bar to black if needed
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black, // Make topmost layer black
      appBar: AppBar(
        title: const Text('Property Details'),
        backgroundColor: BuddyTheme.primaryColor,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _roomDetails != null
              ? SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_roomDetails!['title']?.isNotEmpty ?? false)
                            Text(
                              _roomDetails!['title']!,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          if (_roomDetails!['location']?.isNotEmpty ??
                              false) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: textLight,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _roomDetails!['location']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_roomDetails!['availableFromDate']?.isNotEmpty ??
                              false) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Available from ${_formatDate(_roomDetails!['availableFromDate'].toString())}',
                              style: TextStyle(
                                fontSize: 13,
                                color: textLight,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (_roomDetails!['rent']?.isNotEmpty ?? false)
                                Text(
                                  '₹${_roomDetails!['rent']}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: primaryColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              if (_roomDetails!['roomType']?.isNotEmpty ??
                                  false) ...[
                                const SizedBox(width: 16),
                                Text(
                                  _roomDetails!['roomType']!,
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (_roomDetails!['flatSize']?.isNotEmpty ??
                                  false) ...[
                                const SizedBox(width: 16),
                                Text(
                                  _roomDetails!['flatSize']!,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (_roomDetails!['facilities'] != null &&
                              (_roomDetails!['facilities'] as Map).entries
                                  .where((e) => e.value == true)
                                  .isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  (_roomDetails!['facilities'] as Map).entries
                                      .where((e) => e.value == true)
                                      .map(
                                        (e) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: BuddyTheme.primaryColor
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: borderColor,
                                            ),
                                          ),
                                          child: Text(
                                            e.key,
                                            style: TextStyle(
                                              color: textSecondary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ],
                          if (_roomDetails!['description']?.isNotEmpty ??
                              false) ...[
                            const SizedBox(height: 20),
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _roomDetails!['description']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Handle booking action
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Book Now',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              : Center(
                child: Text(
                  'Property not found.',
                  style: TextStyle(fontSize: 18, color: textPrimary),
                ),
              ),
    ); // <-- Close Scaffold
  }
}
