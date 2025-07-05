import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'display pages/service_details.dart';
import 'theme.dart';
import 'services/search_cache_service.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({Key? key}) : super(key: key);

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  String _selectedCategory = 'All Services';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final SearchCacheService _cacheService = SearchCacheService();

  final List<String> _categories = [
    'All Services',
    'Library',
    'Café',
    'Mess',
    'Other',
  ];

  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() => _isLoading = true);
    try {
      // Use cached data instead of direct Firestore query
      final loaded = await _cacheService.getServicesWithCache();
      
      setState(() {
        _services = loaded;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _services = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load services: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get _filteredServices {
    return _services.where((service) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          (service['serviceName']?.toString().toLowerCase().contains(query) ??
              false) ||
          (service['serviceType']?.toString().toLowerCase().contains(query) ??
              false) ||
          (service['description']?.toString().toLowerCase().contains(query) ??
              false);
      final matchesCategory =
          _selectedCategory == 'All Services' ||
          service['serviceType'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  bool _isServiceOpen(Map<String, dynamic> service) {
    final now = TimeOfDay.now();
    final openingTime = _parseTimeString(service['openingTime']);
    final closingTime = _parseTimeString(service['closingTime']);
    final offDay = service['offDay'];

    // Check if today is off day
    final today = DateTime.now().weekday;
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    if (offDay == dayNames[today - 1]) {
      return false;
    }

    if (openingTime != null && closingTime != null) {
      final nowMinutes = now.hour * 60 + now.minute;
      final openMinutes = openingTime.hour * 60 + openingTime.minute;
      final closeMinutes = closingTime.hour * 60 + closingTime.minute;

      return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
    }

    return true; // Default to open if times aren't parsed correctly
  }

  TimeOfDay? _parseTimeString(String? timeString) {
    if (timeString == null) return null;

    try {
      final cleanTime = timeString.replaceAll(RegExp(r'[^\d:]'), '');
      final parts = cleanTime.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        // Handle AM/PM
        if (timeString.toUpperCase().contains('PM') && hour != 12) {
          hour += 12;
        } else if (timeString.toUpperCase().contains('AM') && hour == 12) {
          hour = 0;
        }

        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      print('Error parsing time: $timeString');
    }

    return null;
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
          onRefresh: _fetchServices,
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
                            textLight,
                            textPrimary,
                            borderColor,
                          ),
                          const SizedBox(height: BuddyTheme.spacingMd),
                          _buildCategoryFilter(
                            cardColor,
                            textPrimary,
                            borderColor,
                          ),
                          const SizedBox(height: BuddyTheme.spacingLg),
                          _buildSectionHeader(
                            'Available Services',
                            textPrimary,
                          ),
                          const SizedBox(height: BuddyTheme.spacingMd),
                          if (_filteredServices.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Text(
                                  'No services found.',
                                  style: TextStyle(color: textSecondary),
                                ),
                              ),
                            )
                          else
                            _buildServicesGrid(),
                          const SizedBox(height: BuddyTheme.spacingMd),
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
          'Discover',
          style: Theme.of(
            context,
          ).textTheme.displaySmall!.copyWith(color: labelColor),
        ),
        Text(
          'Local Services',
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
    Color borderColor,
  ) {
    return Container(
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
          hintText: 'Search libraries, cafes, mess, services...',
          hintStyle: TextStyle(
            color: textLight,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(Icons.search_outlined, color: textLight, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
        style: TextStyle(color: textPrimary),
      ),
    );
  }

  Widget _buildCategoryFilter(
    Color cardColor,
    Color textPrimary,
    Color borderColor,
  ) {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: EdgeInsets.only(
              right: index == _categories.length - 1 ? 0 : 12,
            ),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? BuddyTheme.primaryColor : cardColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? BuddyTheme.primaryColor : borderColor,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: BuddyTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : [],
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textPrimary) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
    );
  }

  Widget _buildServicesGrid() {
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
            if (index < _filteredServices.length) {
              final service = _filteredServices[index];
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
              return _buildServiceCard(
                service,
                cardColor,
                borderColor,
                textLight,
                textPrimary,
                textSecondary,
                accentColor,
                primaryColor,
                successColor,
                warningColor,
                Theme.of(context).scaffoldBackgroundColor,
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
        children: _filteredServices
            .map(
              (service) => Padding(
                padding: const EdgeInsets.only(
                  bottom: BuddyTheme.spacingMd,
                ),
                child: _buildServiceCard(
                  service,
                  cardColor,
                  borderColor,
                  textLight,
                  textPrimary,
                  textSecondary,
                  accentColor,
                  primaryColor,
                  successColor,
                  warningColor,
                  Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            )
            .toList(),
      );
    }
  }

  Widget _buildServiceCard(
    Map<String, dynamic> service,
    Color cardColor,
    Color borderColor,
    Color textLight,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
    Color primaryColor,
    Color successColor,
    Color warningColor,
    Color backgroundColor,
  ) {
    // Optimized sizes for web and mobile
    final isWeb = kIsWeb;
    final double imageHeight = isWeb ? 140.0 : 200.0;
    final double padding = isWeb ? 16.0 : 20.0;
    final double titleFontSize = isWeb ? 18.0 : 22.0;
    final double subtitleFontSize = isWeb ? 14.0 : 16.0;
    final double locationFontSize = isWeb ? 12.0 : 14.0;
    final double buttonFontSize = isWeb ? 14.0 : 16.0;
    final double buttonPadding = isWeb ? 10.0 : 14.0;
    final double spacing = isWeb ? 6.0 : 10.0;
    final double buttonSpacing = isWeb ? 12.0 : 18.0;
    final double iconSize = isWeb ? 16.0 : 20.0;
    final double badgePadding = isWeb ? 6.0 : 8.0;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ServiceDetailsScreen(serviceId: service['key']),
          ),
        );
      },
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
                    imageUrl: service['imageUrl'],
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
                            size: 48,
                          ),
                        ),
                  ),
                ),
                // Service type badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: badgePadding,
                      vertical: badgePadding / 2,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      service['serviceType'].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isWeb ? 12 : 14,
                        fontWeight: FontWeight.w700,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service['serviceName'],
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing / 2),
                  Text(
                    service['serviceType'],
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: spacing),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: iconSize,
                        color: textSecondary,
                      ),
                      SizedBox(width: spacing / 2),
                      Expanded(
                        child: Text(
                          service['location'],
                          style: TextStyle(fontSize: locationFontSize, color: textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (service['distance'] != null) ...[
                        SizedBox(width: spacing),
                        Text(
                          service['distance'],
                          style: TextStyle(
                            fontSize: locationFontSize,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: spacing / 2),
                  Row(
                    children: [
                                              Icon(
                          Icons.access_time_outlined,
                          size: iconSize,
                          color: textSecondary,
                        ),
                        SizedBox(width: spacing / 2),
                        Text(
                          '${service['openingTime']} - ${service['closingTime']}',
                          style: TextStyle(fontSize: locationFontSize, color: textSecondary),
                        ),
                        const Spacer(),
                        if (service['reviews'] != null)
                          Text(
                            '(${service['reviews']} reviews)',
                            style: TextStyle(
                              fontSize: locationFontSize,
                              color: textLight,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  if (service['offDay'] != 'None') ...[
                    SizedBox(height: spacing / 2),
                    Row(
                      children: [
                        Icon(
                          Icons.event_busy_outlined,
                          size: iconSize,
                          color: warningColor,
                        ),
                        SizedBox(width: spacing / 2),
                        Text(
                          'Closed on ${service['offDay']}',
                          style: TextStyle(
                            fontSize: locationFontSize,
                            color: warningColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: buttonSpacing),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ServiceDetailsScreen(
                                      serviceId: service['key'],
                                    ),
                              ),
                            );
                          },
                          label: const Text('View Details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }

  Widget _buildServicePlaceholderCard() {
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
            height: 200,
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
              size: 48,
            ),
          ),
          // Placeholder content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 16,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 40,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
