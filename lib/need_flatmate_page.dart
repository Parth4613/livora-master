import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'theme.dart';
import 'display pages/flatmate_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/search_cache_service.dart';
import 'main.dart';
import 'utils/cache_utils.dart';

class NeedFlatmatePage extends StatefulWidget {
  const NeedFlatmatePage({super.key});

  @override
  State<NeedFlatmatePage> createState() => _NeedFlatmatePageState();
}

class _NeedFlatmatePageState extends State<NeedFlatmatePage> {
  final TextEditingController _searchController = TextEditingController();
  final SearchCacheService _cacheService = SearchCacheService();
  String _searchQuery = '';
  String _selectedLocation = 'All Cities';
  String _selectedAge = 'All Ages';
  String _selectedProfession = 'All Professions';
  String _selectedGender = 'All';

  final List<String> _ages = [
    'All Ages',
    '18-25',
    '26-30',
    '31-35',
    '36-40',
    '40+',
  ];

  final List<String> _professions = [
    'All Professions',
    'Student',
    'Software Engineer',
    'Designer',
    'Teacher',
    'Healthcare',
    'Finance',
    'Other',
  ];

  final List<String> _genders = ['All', 'Male', 'Female', 'Non-binary'];

  List<Map<String, dynamic>> _flatmates = [];
  bool _isLoading = true;
  int? _hoveredFlatmateCardIndex;
  bool _showPlaceholdersOnly = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light, 
        statusBarBrightness: Brightness.dark, 
      ),
    );
    _selectedLocation = 'All Cities';
    _fetchFlatmates();
  }

  Future<void> _fetchFlatmates() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Use cached data instead of direct Firestore query
      final loaded = await _cacheService.getFlatmatesWithCache();
      
      setState(() {
        _flatmates = loaded;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _flatmates = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load flatmates: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredFlatmates {
    return _flatmates.where((flatmate) {
      final matchesLocation =
          _selectedLocation == 'All Cities' ||
          (flatmate['preferredLocation']?.toString().toLowerCase().contains(
                _selectedLocation.toLowerCase(),
              ) ??
              false);
      final matchesAge =
          _selectedAge == 'All Ages' ||
          (() {
            final ageStr = flatmate['age']?.toString();
            if (ageStr == null || ageStr.isEmpty) return false;
            final age = int.tryParse(ageStr);
            if (age == null) return false;
            if (_selectedAge == '40+') return age >= 40;
            final parts = _selectedAge.split('-');
            if (parts.length == 2) {
              final min = int.tryParse(parts[0]);
              final max = int.tryParse(parts[1]);
              if (min != null && max != null) {
                return age >= min && age <= max;
              }
            }
            return false;
          })();
      final matchesProfession =
          _selectedProfession == 'All Professions' ||
          (flatmate['occupation']?.toString().toLowerCase() ==
              _selectedProfession.toLowerCase());
      final matchesGender =
          _selectedGender == 'All' ||
          (flatmate['gender']?.toString().toLowerCase() ==
              _selectedGender.toLowerCase());
      return matchesLocation &&
          matchesAge &&
          matchesProfession &&
          matchesGender;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF23262F) : Colors.white;
    final labelColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        elevation: 0,
        title: Text(
          'Find Flatmates',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Debug button for image cleanup (remove in production)
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.cleaning_services),
              onPressed: () async {
                try {
                  await CacheUtils.cleanupCorruptedFlatmateImages();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Image cleanup completed. Check console for details.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Refresh the flatmate list
                    _fetchFlatmates();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Cleanup failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              tooltip: 'Cleanup corrupted images',
            ),
          // Force cleanup button for testing (remove in production)
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () async {
                try {
                  await CacheUtils.forceCleanupAllFlatmateImages();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Force cleanup completed. All images removed.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    // Refresh the flatmate list
                    _fetchFlatmates();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Force cleanup failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              tooltip: 'Force cleanup all images',
            ),
          // Toggle button for image display (remove in production)
          if (kDebugMode)
            IconButton(
              icon: Icon(_showPlaceholdersOnly ? Icons.image : Icons.person),
              onPressed: () {
                setState(() {
                  _showPlaceholdersOnly = !_showPlaceholdersOnly;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_showPlaceholdersOnly 
                        ? 'Showing placeholders only' 
                        : 'Attempting to load actual images'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              tooltip: _showPlaceholdersOnly ? 'Show actual images' : 'Show placeholders only',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 2));
        },
        color: BuddyTheme.primaryColor,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(BuddyTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, labelColor),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  _buildSearchSection(
                    context,
                    cardColor,
                    labelColor,
                  ),
                  const SizedBox(height: BuddyTheme.spacingMd),
                  _buildSectionHeader(
                    context,
                    'All Flatmates',
                    () {},
                    labelColor,
                  ),
                  const SizedBox(height: BuddyTheme.spacingSm),
                  _buildFlatmateGrid(context, cardColor, labelColor),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
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
          ).textTheme.headlineSmall!.copyWith(color: labelColor),
        ),
        Text(
          'Ideal Flatmate',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: BuddyTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection(
    BuildContext context,
    Color cardColor,
    Color labelColor,
  ) {
    return Column(
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF23262F),
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
              hintText: 'Search by name, interests, profession...',
              hintStyle: TextStyle(color: Colors.white),
              prefixIcon: Icon(Icons.search, color: Colors.white38),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(BuddyTheme.spacingMd),
              filled: false,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                'Age',
                _selectedAge,
                _ages,
                (value) {
                  setState(() => _selectedAge = value);
                },
                cardColor,
                Colors.white,
                Colors.white12,
              ),
              const SizedBox(width: BuddyTheme.spacingXs),
              _buildFilterChip(
                'Profession',
                _selectedProfession,
                _professions,
                (value) {
                  setState(() => _selectedProfession = value);
                },
                cardColor,
                Colors.white,
                Colors.white12,
              ),
              const SizedBox(width: BuddyTheme.spacingXs),
              _buildFilterChip(
                'Gender',
                _selectedGender,
                _genders,
                (value) {
                  setState(() => _selectedGender = value);
                },
                cardColor,
                Colors.white,
                Colors.white12,
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
            (selected) {
              if (selected != value) {
                onChanged(selected);
              }
            },
            cardColor,
            labelColor,
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
    BuildContext context,
    String title,
    VoidCallback onTap,
    Color labelColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFlatmateGrid(
    BuildContext context,
    Color cardColor,
    Color labelColor,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_filteredFlatmates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            "No flatmates found.",
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    if (kIsWeb) {
      const double cardSpacing = 20.0;
      const int crossAxisCount = 3;
      final double gridWidth = MediaQuery.of(context).size.width - (BuddyTheme.spacingMd * 2);
      final double cardSize = (gridWidth - (cardSpacing * (crossAxisCount - 1))) / crossAxisCount;
      if (_filteredFlatmates.length < 3) {
        // Left-align 1 or 2 cards
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(_filteredFlatmates.length, (index) {
              final flatmate = _filteredFlatmates[index];
              return Padding(
                padding: EdgeInsets.only(right: index < _filteredFlatmates.length - 1 ? cardSpacing : 0),
                child: _buildFlatmateCardWeb(context, flatmate, index, cardSize),
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
          itemCount: _filteredFlatmates.length,
          itemBuilder: (context, index) {
            final flatmate = _filteredFlatmates[index];
            return _buildFlatmateCardWeb(context, flatmate, index, cardSize);
          },
        );
      }
    } else {
      // Mobile layout: single column
      return Column(
        children: _filteredFlatmates
            .map(
              (flatmate) => Column(
                children: [
                  _buildFlatmateCard(context, flatmate, cardColor, labelColor),
                  const SizedBox(height: BuddyTheme.spacingMd),
                ],
              ),
            )
            .toList(),
      );
    }
  }

  Widget _buildFlatmateCardWeb(BuildContext context, Map<String, dynamic> flatmate, int index, double cardSize) {
    final double cardWidth = 420.0;
    final double padding = 16.0;
    final double avatarRadius = 35.0;
    final double titleFontSize = 20.0;
    final double subtitleFontSize = 15.0;
    final double locationFontSize = 14.0;
    final double iconSize = 20.0;
    final double infoBoxHeight = 54.0;
    final double infoBoxRadius = 16.0;
    final double infoBoxSpacing = 12.0;
    final double buttonFontSize = 16.0;
    final double buttonPadding = 14.0;
    final String? imageUrl = flatmate['profilePhotoUrl'] as String?;
    
    // Debug logging for image URL
    print('Flatmate photo URL: $imageUrl');
    print('Flatmate data: ${flatmate.toString()}');
    
    // Validate and fix the image URL
    final String? validatedImageUrl = CacheUtils.validateImageUrl(imageUrl);
    if (validatedImageUrl != imageUrl) {
      print('Image URL validated/fixed: $validatedImageUrl');
    }
    
    final String name = (flatmate['name'] ?? '').toString();
    final String age = (flatmate['age'] ?? '').toString();
    final String occupation = (flatmate['occupation'] ?? '').toString();
    final String location = (flatmate['location'] ?? flatmate['preferredLocation'] ?? '').toString();
    String budget = '';
    if (flatmate['minBudget'] != null && flatmate['maxBudget'] != null) {
      budget = '₹${flatmate['minBudget']} - ₹${flatmate['maxBudget']}';
    } else if (flatmate['budgetRange'] != null) {
      budget = flatmate['budgetRange'].toString();
    } else if (flatmate['budget'] != null) {
      budget = '₹${flatmate['budget']}';
    }

    String moveIn = '';
    final moveInRaw = flatmate['moveInDate'];
    if (moveInRaw != null) {
      if (moveInRaw is Timestamp) {
        moveIn = _formatDate(moveInRaw.toDate());
      } else if (moveInRaw is DateTime) {
        moveIn = _formatDate(moveInRaw);
      } else if (moveInRaw is String) {
        final parsed = DateTime.tryParse(moveInRaw);
        if (parsed != null) {
          moveIn = _formatDate(parsed);
        } else {
          moveIn = moveInRaw;
        }
      } else {
        moveIn = moveInRaw.toString();
      }
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredFlatmateCardIndex = index),
      onExit: (_) => setState(() => _hoveredFlatmateCardIndex = null),
      child: GestureDetector(
        onTap: () {
          _viewFlatmateDetails(flatmate);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: _hoveredFlatmateCardIndex == index ? (Matrix4.identity()..scale(1.04)) : Matrix4.identity(),
          decoration: BoxDecoration(
            color: const Color(0xFF23262F),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: _hoveredFlatmateCardIndex == index ? 32 : 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          width: cardWidth,
          margin: const EdgeInsets.only(bottom: 32.0),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with photo and basic info
                Row(
                  children: [
                    validatedImageUrl != null && validatedImageUrl.isNotEmpty && !_showPlaceholdersOnly
                        ? FutureBuilder<bool>(
                            future: CacheUtils.isImageUrlAccessible(validatedImageUrl),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Container(
                                  width: avatarRadius * 2,
                                  height: avatarRadius * 2,
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              
                              final isAccessible = snapshot.data ?? false;
                              if (!isAccessible) {
                                print('Image not accessible, showing placeholder');
                                return CircleAvatar(
                                  radius: avatarRadius,
                                  backgroundColor: Colors.white12,
                                  child: Icon(Icons.person_outline, color: Colors.white38, size: avatarRadius),
                                );
                              }
                              
                              return ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: validatedImageUrl,
                                  width: avatarRadius * 2,
                                  height: avatarRadius * 2,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: avatarRadius * 2,
                                    height: avatarRadius * 2,
                                    color: Colors.white12,
                                    child: Icon(Icons.person_outline, color: Colors.white38, size: avatarRadius),
                                  ),
                                  errorWidget: (context, url, error) {
                                    print('CachedNetworkImage error for URL: $url');
                                    print('Error: $error');
                                    // Mark this image as inaccessible for future reference
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      _markImageAsInaccessible(validatedImageUrl);
                                    });
                                    return Container(
                                      width: avatarRadius * 2,
                                      height: avatarRadius * 2,
                                      color: Colors.white12,
                                      child: Icon(Icons.person_outline, color: Colors.white38, size: avatarRadius),
                                    );
                                  },
                                ),
                              );
                            },
                          )
                        : CircleAvatar(
                            radius: avatarRadius,
                            backgroundColor: Colors.white12,
                            child: Icon(Icons.person_outline, color: Colors.white38, size: avatarRadius),
                          ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '$age • $occupation',
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.white.withOpacity(0.7), size: iconSize),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: TextStyle(
                                  fontSize: locationFontSize,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: infoBoxHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFF232B3A),
                          borderRadius: BorderRadius.circular(infoBoxRadius),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Budget Range',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              budget,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF4F8CFF),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: infoBoxHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2C25),
                          borderRadius: BorderRadius.circular(infoBoxRadius),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Move-in Date',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              moveIn,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF3DDC97),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _viewFlatmateDetails(flatmate);
                    },
                    icon: const Icon(Icons.remove_red_eye, color: Colors.white),
                    label: const Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64B5F6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlatmatePlaceholderCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF23262F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BuddyTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with photo and basic info
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white12,
                  child: Icon(
                    Icons.person_outline,
                    color: Colors.white38,
                    size: BuddyTheme.iconSizeLg,
                  ),
                ),
                const SizedBox(width: BuddyTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 20,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 16,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: BuddyTheme.spacingMd),
            // Budget and Move-in info
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
                    ),
                  ),
                ),
                const SizedBox(width: BuddyTheme.spacingXs),
                Expanded(
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BuddyTheme.spacingMd),
            // Bio placeholder
            Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: BuddyTheme.spacingSm),
            Container(
              height: 16,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: BuddyTheme.spacingMd),
            // Button placeholder
            Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlatmateCard(
    BuildContext context,
    Map<String, dynamic> flatmate,
    Color cardColor,
    Color labelColor,
  ) {
    // Optimized sizes for web and mobile
    final isWeb = kIsWeb;
    final double padding = isWeb ? 16.0 : 20.0;
    final double avatarRadius = isWeb ? 30.0 : 35.0;
    final double titleFontSize = isWeb ? 18.0 : 22.0;
    final double subtitleFontSize = isWeb ? 14.0 : 16.0;
    final double locationFontSize = isWeb ? 12.0 : 14.0;
    final double buttonFontSize = isWeb ? 14.0 : 16.0;
    final double buttonPadding = isWeb ? 10.0 : 14.0;
    final double spacing = isWeb ? 6.0 : 10.0;
    final double buttonSpacing = isWeb ? 12.0 : 18.0;
    final double iconSize = isWeb ? 16.0 : 20.0;
    final double badgePadding = isWeb ? 6.0 : 8.0;
    
    final Color accentColor = const Color(0xFF64B5F6);
    
    // Debug logging for image URL
    final String? imageUrl = flatmate['profilePhotoUrl'] as String?;
    print('Mobile Flatmate photo URL: $imageUrl');
    
    // Validate and fix the image URL
    final String? validatedImageUrl = CacheUtils.validateImageUrl(imageUrl);
    if (validatedImageUrl != imageUrl) {
      print('Mobile Image URL validated/fixed: $validatedImageUrl');
    }
    
    return Container(
      decoration: BuddyTheme.cardDecoration.copyWith(color: cardColor),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with photo and basic info
            Row(
              children: [
                validatedImageUrl != null && validatedImageUrl.isNotEmpty
                    ? FutureBuilder<bool>(
                        future: CacheUtils.isImageUrlAccessible(validatedImageUrl),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              width: avatarRadius * 2,
                              height: avatarRadius * 2,
                              decoration: BoxDecoration(
                                color: cardColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                            );
                          }
                          
                          final isAccessible = snapshot.data ?? false;
                          if (!isAccessible) {
                            print('Mobile image not accessible, showing placeholder');
                            return CircleAvatar(
                              radius: avatarRadius,
                              backgroundColor: cardColor,
                              child: Icon(Icons.person, color: Colors.white, size: isWeb ? 24 : 28),
                            );
                          }
                          
                          return ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: validatedImageUrl,
                              width: avatarRadius * 2,
                              height: avatarRadius * 2,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: avatarRadius * 2,
                                height: avatarRadius * 2,
                                color: cardColor,
                                child: Icon(Icons.person, color: Colors.white, size: isWeb ? 24 : 28),
                              ),
                              errorWidget: (context, url, error) {
                                print('Mobile CachedNetworkImage error for URL: $url');
                                print('Error: $error');
                                return Container(
                                  width: avatarRadius * 2,
                                  height: avatarRadius * 2,
                                  color: cardColor,
                                  child: Icon(Icons.person, color: Colors.white, size: isWeb ? 24 : 28),
                                );
                              },
                            ),
                          );
                        },
                      )
                    : CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: cardColor,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: isWeb ? 24 : 28,
                        ),
                      ),
                SizedBox(width: spacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flatmate['name'] ?? 'No Name',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${flatmate['age'] ?? ''} • ${flatmate['occupation'] ?? ''}',
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: spacing / 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.white.withOpacity(0.7),
                            size: iconSize,
                          ),
                          SizedBox(width: spacing / 2),
                          Text(
                            flatmate['location'] ?? '',
                            style: TextStyle(
                              fontSize: locationFontSize,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: BuddyTheme.spacingMd),
            // Budget and Move-in info
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(BuddyTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: BuddyTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusSm,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Budget Range',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          '₹${flatmate['minBudget'] ?? ''} - ₹${flatmate['maxBudget'] ?? ''}',
                          style: TextStyle(
                            fontSize: 16,
                            color: BuddyTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: BuddyTheme.spacingXs),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(BuddyTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: BuddyTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusSm,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Move-in Date',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          flatmate['moveInDate'] != null
                              ? (flatmate['moveInDate'] is Timestamp
                                  ? _formatDate(
                                    (flatmate['moveInDate'] as Timestamp)
                                        .toDate(),
                                  )
                                  : (DateTime.tryParse(
                                            flatmate['moveInDate'].toString(),
                                          ) !=
                                          null
                                      ? _formatDate(
                                        DateTime.parse(
                                          flatmate['moveInDate'].toString(),
                                        ),
                                      )
                                      : ''))
                              : '',
                          style: TextStyle(
                            fontSize: 16,
                            color: BuddyTheme.successColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BuddyTheme.spacingMd),
            // Bio only if available
            if (flatmate['bio']?.isNotEmpty ?? false) ...[
              Text(
                flatmate['bio']!,
                style: TextStyle(fontSize: 16, color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: BuddyTheme.spacingSm),
            ],
            // Interests (if you store them as a list)
            if (flatmate['interests'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interests',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: BuddyTheme.spacingXs),
                  Wrap(
                    spacing: BuddyTheme.spacingXs,
                    runSpacing: BuddyTheme.spacingXs,
                    children:
                        (flatmate['interests'] as List)
                            .map<Widget>(
                              (interest) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: BuddyTheme.spacingXs,
                                  vertical: BuddyTheme.spacingXxs,
                                ),
                                decoration: BoxDecoration(
                                  color: BuddyTheme.accentColor.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    BuddyTheme.borderRadiusXs,
                                  ),
                                  border: Border.all(
                                    color: BuddyTheme.accentColor.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  interest,
                                  style: TextStyle(
                                    color: BuddyTheme.accentColor,
                                    fontSize: BuddyTheme.fontSizeXs,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: BuddyTheme.spacingMd),
                ],
              ),
            const SizedBox(height: BuddyTheme.spacingSm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _viewFlatmateDetails(flatmate),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: BuddyTheme.spacingSm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      BuddyTheme.borderRadiusSm,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.visibility,
                      size: BuddyTheme.iconSizeSm,
                      color: Colors.white,
                    ),
                    const SizedBox(width: BuddyTheme.spacingXs),
                    Text(
                      'View Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
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

  void _viewFlatmateDetails(Map<String, dynamic> flatmate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlatmateDetailsPage(flatmateData: flatmate),
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
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF23262F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BuddyTheme.borderRadiusMd),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(BuddyTheme.spacingMd),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select $title',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          color: Colors.white.withOpacity(0.7),
                          size: BuddyTheme.iconSizeMd,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BuddyTheme.spacingMd),
                  ...options
                      .map(
                        (option) => ListTile(
                          title: Text(
                            option,
                            style: TextStyle(
                              color:
                                  option == currentValue
                                      ? BuddyTheme.primaryColor
                                      : Colors.white,
                              fontWeight:
                                  option == currentValue
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                          trailing:
                              option == currentValue
                                  ? Icon(
                                    Icons.check,
                                    color: BuddyTheme.primaryColor,
                                  )
                                  : null,
                          onTap: () {
                            onChanged(option);
                            Navigator.pop(context);
                          },
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  void _markImageAsInaccessible(String? imageUrl) {
    if (imageUrl != null) {
      CacheUtils.markImageAsInaccessible(imageUrl);
    }
  }
}
