import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'theme.dart';
import 'display pages/flatmate_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/search_cache_service.dart';

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

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black, // true black
        statusBarIconBrightness: Brightness.light, // white icons
        statusBarBrightness: Brightness.dark, // for iOS
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
    // Force dark mode UI for all themes
    const Color scaffoldBackground = Colors.black; // changed to true black
    const Color cardColor = Color(0xFF23262F);
    const Color textPrimary = Colors.white;
    const Color borderColor = Colors.white12;
    const Color inputFillColor = Color(0xFF23262F);
    const Color labelColor = Colors.white;
    const Color hintColor = Colors.white38;

    return Scaffold(
      backgroundColor: scaffoldBackground,
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
                  _buildHeader(context, textPrimary),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  _buildSearchSection(
                    context,
                    cardColor,
                    inputFillColor,
                    labelColor,
                    hintColor,
                    borderColor,
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
    Color inputFillColor,
    Color labelColor,
    Color hintColor,
    Color borderColor,
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
                borderColor,
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
                borderColor,
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
            if (index < _filteredFlatmates.length) {
              final flatmate = _filteredFlatmates[index];
              return _buildFlatmateCard(context, flatmate, cardColor, labelColor);
            } else {
              // Reserve space for empty slot
              return Container();
            }
          },
        ),
      );
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
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: cardColor,
                  backgroundImage:
                      flatmate['profilePhotoUrl'] != null
                          ? NetworkImage(flatmate['profilePhotoUrl'])
                          : null,
                  child:
                      flatmate['profilePhotoUrl'] == null
                          ? Icon(
                            Icons.person,
                            color: Colors.white,
                            size: isWeb ? 24 : 28,
                          )
                          : null,
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
}
