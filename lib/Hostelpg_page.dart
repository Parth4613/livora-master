import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'display pages/hostelpg_details.dart';
import 'services/search_cache_service.dart';

class HostelpgPage extends StatefulWidget {
  const HostelpgPage({Key? key}) : super(key: key);

  @override
  State<HostelpgPage> createState() => _HostelpgPageState();
}

class _HostelpgPageState extends State<HostelpgPage> {
  String _selectedLocation = 'All Cities';
  String _selectedPriceRange = 'All Prices';
  String _selectedRoomType = 'All Types';
  String _searchQuery = '';

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
    'All Types',
    'Single Room',
    'Double Room',
    'Triple Room',
    'Dormitory',
  ];

  final TextEditingController _searchController = TextEditingController();
  final SearchCacheService _cacheService = SearchCacheService();

  List<Map<String, dynamic>> _hostels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedLocation = 'All Cities';
    _fetchHostels();
  }

  Future<void> _fetchHostels() async {
    setState(() => _isLoading = true);
    try {
      // Use cached data instead of direct Firestore query
      final loadedHostels = await _cacheService.getHostelsWithCache();
      
      // Extract unique locations from cached data
      final Set<String> dynamicLocations = {'All Cities'};
      for (final hostel in loadedHostels) {
        if (hostel['location'] != null &&
            hostel['location'].toString().isNotEmpty) {
          dynamicLocations.add(hostel['location'].toString());
        }
      }

      setState(() {
        _hostels = loadedHostels;
        _locations = dynamicLocations.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hostels = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load hostels: $e')),
        );
      }
    }
  }

  bool _priceInRange(String priceStr, String range) {
    try {
      final price =
          int.tryParse(priceStr.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      if (range == 'All Prices') return true;
      if (range.contains('+')) {
        // e.g., '12000+'
        final min =
            int.tryParse(RegExp(r'(\d+)').firstMatch(range)?.group(1) ?? '0') ??
            0;
        return price > min;
      } else {
        // e.g., '< 6000', '< 7500', etc.
        final max =
            int.tryParse(RegExp(r'(\d+)').firstMatch(range)?.group(1) ?? '0') ??
            0;
        return price <= max;
      }
    } catch (_) {}
    return true;
  }

  List<Map<String, dynamic>> get _filteredHostels {
    return _hostels.where((hostel) {
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch =
          query.isEmpty ||
          (hostel['title']?.toString().toLowerCase().contains(query) ??
              false) ||
          (hostel['location']?.toString().toLowerCase().contains(query) ??
              false) ||
          ((hostel['amenities'] is List)
              ? (hostel['amenities'] as List).any(
                (a) => a.toString().toLowerCase().contains(query),
              )
              : false);
      final matchesLocation =
          _selectedLocation == 'All Cities' ||
          (hostel['location']?.toString().toLowerCase().trim().contains(
                _selectedLocation.toLowerCase().trim(),
              ) ??
              false);
      final matchesType =
          _selectedRoomType == 'All Types' ||
          ((hostel['roomTypes'] is Map &&
                  (hostel['roomTypes'] as Map)[_selectedRoomType] == true) ||
              (hostel['roomTypes'] is List &&
                  (hostel['roomTypes'] as List).contains(_selectedRoomType)));
      final matchesPrice =
          _selectedPriceRange == 'All Prices' ||
          _priceInRange(
            hostel['startingAt']?.toString() ?? '',
            _selectedPriceRange,
          );
      return matchesSearch && matchesLocation && matchesType && matchesPrice;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor =
        isDark ? const Color(0xFF90CAF9) : const Color(0xFF2D3748);
    final Color accentColor =
        isDark ? const Color(0xFF64B5F6) : const Color(0xFF4299E1);
    final Color cardColor = isDark ? const Color(0xFF23262F) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF2D3748);
    final Color textSecondary =
        isDark ? Colors.white70 : const Color(0xFF718096);
    final Color textLight = isDark ? Colors.white38 : const Color(0xFFA0AEC0);
    final Color borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final Color successColor =
        isDark ? const Color(0xFF81C784) : const Color(0xFF48BB78);
    final Color warningColor =
        isDark ? const Color(0xFFFFB74D) : const Color(0xFFED8936);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 2));
          },
          color: BuddyTheme.primaryColor,
          child: SingleChildScrollView(
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
                    textLight,
                    textPrimary,
                    accentColor,
                    borderColor,
                  ),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  _buildSectionHeader(
                    'Available Hostels / PG',
                    textPrimary,
                    accentColor,
                  ),
                  const SizedBox(height: BuddyTheme.spacingMd),
                  if (_isLoading)
                    Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          BuddyTheme.primaryColor,
                        ),
                      ),
                    )
                  else
                    _buildHostelsGrid(),
                  SizedBox(height: BuddyTheme.spacingMd + MediaQuery.of(context).padding.bottom),
                ],
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
          ).textTheme.displaySmall!.copyWith(color: labelColor),
        ),
        Text(
          'Perfect Hostel / PG',
          style: Theme.of(context).textTheme.displayMedium!.copyWith(
            fontWeight: FontWeight.bold,
            color: BuddyTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection(
    Color cardColor,
    Color textLight,
    Color textPrimary,
    Color accentColor,
    Color borderColor,
  ) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search hostels, amenities, or locations...',
              hintStyle: TextStyle(
                color: textLight,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.search_outlined,
                color: textLight,
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(18),
            ),
            style: TextStyle(color: textPrimary),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                'Location',
                _selectedLocation,
                _locations,
                (value) {
                  setState(() => _selectedLocation = value);
                },
                cardColor,
                textPrimary,
                borderColor,
              ),
              const SizedBox(width: BuddyTheme.spacingXs),
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
            ],
          ),
        ),
      ],
    );
  }

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
            onChanged,
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

  Widget _buildHostelsGrid() {
    if (kIsWeb) {
      // Optimized card size for web
      const double cardSpacing = 20.0;
      const double cardHeight = 220.0;
      const double gridHeight = (cardHeight * 2) + cardSpacing;
      const double cardAspectRatio = 0.8;

      return SizedBox(
        height: gridHeight,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: cardAspectRatio,
            crossAxisSpacing: cardSpacing,
            mainAxisSpacing: cardSpacing,
          ),
          itemCount: 6, // Always show 6 slots
          itemBuilder: (context, index) {
            if (index < _filteredHostels.length) {
              final hostel = _filteredHostels[index];
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final Color cardColor = isDark ? const Color(0xFF23262F) : Colors.white;
              final Color textPrimary = isDark ? Colors.white : const Color(0xFF2D3748);
              final Color textSecondary = isDark ? Colors.white70 : const Color(0xFF718096);
              final Color textLight = isDark ? Colors.white38 : const Color(0xFFA0AEC0);
              final Color borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
              final Color accentColor = isDark ? const Color(0xFF64B5F6) : const Color(0xFF4299E1);
              final Color primaryColor = isDark ? const Color(0xFF90CAF9) : const Color(0xFF2D3748);
              final Color successColor = isDark ? const Color(0xFF81C784) : const Color(0xFF48BB78);
              final Color warningColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFED8936);
              return _buildHostelCard(
                hostel,
                cardColor,
                borderColor,
                textLight,
                textPrimary,
                textSecondary,
                accentColor,
                primaryColor,
                Theme.of(context).scaffoldBackgroundColor,
                successColor,
                warningColor,
              );
            } else {
              // Reserve space for empty slot
              return Container();
            }
          },
        ),
      );
    } else {
      // Mobile layout: single column
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final Color cardColor = isDark ? const Color(0xFF23262F) : Colors.white;
      final Color textPrimary = isDark ? Colors.white : const Color(0xFF2D3748);
      final Color textSecondary = isDark ? Colors.white70 : const Color(0xFF718096);
      final Color textLight = isDark ? Colors.white38 : const Color(0xFFA0AEC0);
      final Color borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
      final Color accentColor = isDark ? const Color(0xFF64B5F6) : const Color(0xFF4299E1);
      final Color primaryColor = isDark ? const Color(0xFF90CAF9) : const Color(0xFF2D3748);
      final Color successColor = isDark ? const Color(0xFF81C784) : const Color(0xFF48BB78);
      final Color warningColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFED8936);
      return Column(
        children: _filteredHostels
            .map(
              (hostel) => Padding(
                padding: const EdgeInsets.only(
                  bottom: BuddyTheme.spacingMd,
                ),
                child: _buildHostelCard(
                  hostel,
                  cardColor,
                  borderColor,
                  textLight,
                  textPrimary,
                  textSecondary,
                  accentColor,
                  primaryColor,
                  Theme.of(context).scaffoldBackgroundColor,
                  successColor,
                  warningColor,
                ),
              ),
            )
            .toList(),
      );
    }
  }

  Widget _buildHostelCard(
    Map<String, dynamic> hostel,
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
    final double addressFontSize = isWeb ? 13.0 : 16.0;
    final double buttonFontSize = isWeb ? 14.0 : 16.0;
    final double buttonPadding = isWeb ? 10.0 : 14.0;
    final double spacing = isWeb ? 6.0 : 10.0;
    final double buttonSpacing = isWeb ? 12.0 : 18.0;
    final double iconSize = isWeb ? 16.0 : 20.0;

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
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: hostel['imageUrl'] ?? '',
                  height: imageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Shimmer.fromColors(
                        baseColor: borderColor,
                        highlightColor: cardColor,
                        child: Container(color: borderColor),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: borderColor,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: textLight,
                          size: isWeb ? 40 : 56,
                        ),
                      ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hostel['title'] ?? '',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    height: 1.2,
                  ),
                  maxLines: isWeb ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: spacing),
                Text(
                  hostel['address'] ?? '',
                  style: TextStyle(
                    fontSize: addressFontSize,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: isWeb ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: buttonSpacing),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/hostelpg_details',
                            arguments: {'hostelId': hostel['key']},
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: buttonPadding),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostelPlaceholderCard() {
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
              size: isWeb ? 40 : 56,
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
                  width: 150,
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
                    borderRadius: BorderRadius.circular(10),
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
