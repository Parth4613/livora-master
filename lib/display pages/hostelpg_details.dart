import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../models/hostel_data.dart';
import '../chat_screen.dart';
import '../utils/user_utils.dart';
import '../services/user_service.dart';
import '../widgets/premium_plan_prompt_sheet.dart';

class FullScreenImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageGallery({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  _FullScreenImageGalleryState createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<FullScreenImageGallery> {
  late PageController _pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                Navigator.pop(context);
              }
            },
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.white,
                                size: 48,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Failed to load image',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                '${currentIndex + 1}/${widget.images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: BuddyTheme.fontSizeMd,
                ),
              ),
              centerTitle: true,
            ),
          ),
          // Navigation arrows for web
          if (widget.images.length > 1) ...[
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: currentIndex > 0
                      ? () {
                          _pageController.previousPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: currentIndex < widget.images.length - 1
                      ? () {
                          _pageController.nextPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class HostelData {
  final String title;
  final String address;
  final String availableFromDate;
  final String bookingMode;
  final String contactPerson;
  final String description;
  final String? email;
  final Map<String, bool> facilities;
  final String foodType;
  final bool hasEntryTimings;
  final String hostelFor;
  final String hostelType;
  final String landmark;
  final String minimumStay;
  final String offers;
  final String? phone;
  final Map<String, bool> roomTypes;
  final Map<String, String> preferences;
  final String selectedPlan;
  final String specialFeatures;
  final double startingAt;
  final Map<String, String> uploadedPhotos;
  final bool visibility;
  final String uid;
  final bool sharePhoneNumber;
  final double? latitude;
  final double? longitude;

  HostelData({
    required this.title,
    required this.address,
    required this.availableFromDate,
    required this.bookingMode,
    required this.contactPerson,
    required this.description,
    required this.email,
    required this.facilities,
    required this.foodType,
    required this.hasEntryTimings,
    required this.hostelFor,
    required this.hostelType,
    required this.landmark,
    required this.minimumStay,
    required this.offers,
    required this.phone,
    required this.roomTypes,
    required this.selectedPlan,
    required this.specialFeatures,
    required this.startingAt,
    required this.preferences,
    required this.uploadedPhotos,
    required this.visibility,
    required this.uid,
    required this.sharePhoneNumber,
    required this.latitude,
    required this.longitude,
  });

  factory HostelData.fromFirestore(Map<String, dynamic> data) {
    return HostelData(
      title: data['title'] ?? '',
      address: data['address'] ?? '',
      availableFromDate:
          data['availableFromDate'] != null
              ? _formatDate(data['availableFromDate'])
              : '',
      bookingMode: data['bookingMode'] ?? '',
      contactPerson: data['contactPerson'] ?? '',
      description: data['description'] ?? '',
      email: data['email'] as String?,
      facilities:
          (data['facilities'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as bool),
          ) ??
          {},
      foodType: data['foodType'] ?? '',
      hasEntryTimings: data['hasEntryTimings'] ?? false,
      hostelFor: data['hostelFor'] ?? '',
      hostelType: data['hostelType'] ?? '',
      landmark: data['landmark'] ?? '',
      minimumStay: data['minimumStay'] ?? '',
      offers: data['offers'] ?? '',
      phone: data['phone'] as String?,
      roomTypes:
          (data['roomTypes'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as bool),
          ) ??
          {},
      selectedPlan: data['selectedPlan'] ?? '',
      specialFeatures: data['specialFeatures'] ?? '',
      preferences: {
        'hostelFor': data['hostelFor']?.toString() ?? '',
        'foodType': data['foodType']?.toString() ?? '',
        'smokingPolicy': data['smokingPolicy']?.toString() ?? '',
        'drinkingPolicy': data['drinkingPolicy']?.toString() ?? '',
        'guestPolicy': data['guestsPolicy']?.toString() ?? '',
        'entryTime': data['entryTime']?.toString() ?? '',
      },
      startingAt: (data['startingAt'] ?? 0).toDouble(),
      uploadedPhotos:
          (data['uploadedPhotos'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ??
          {},
      visibility: data['visibility'] ?? false,
      uid: data['uid'] ?? '',
      sharePhoneNumber: data['sharePhoneNumber'] ?? false,
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
    );
  }
}

String _formatDate(dynamic date) {
  if (date == null) return '';

  try {
    DateTime dateTime;
    if (date is DateTime) {
      dateTime = date;
    } else if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is String) {
      // Try to parse the string as a DateTime
      dateTime = DateTime.parse(date);
    } else {
      return '';
    }

    // Format as DD-MM-YYYY
    return '${dateTime.day.toString().padLeft(2, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.year}';
  } catch (e) {
    return '';
  }
}

class HostelDetailsScreen extends StatefulWidget {
  final String propertyId;

  const HostelDetailsScreen({Key? key, required this.propertyId})
    : super(key: key);

  @override
  _HostelDetailsScreenState createState() => _HostelDetailsScreenState();
}

class _HostelDetailsScreenState extends State<HostelDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late HostelData hostelData;
  bool isBookmarked = false;
  int currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool isLoading = true;
  String? error;
  
  // User contact information
  String? userPhone;
  String? userEmail;
  bool isLoadingUserData = false;

  @override
  void initState() {
    super.initState();
    _fetchHostelDetails();
    _checkIfBookmarked();
  }

  Future<void> _checkIfBookmarked() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final bookmarks =
          userDoc.data()?['bookmarkedProperties'] as List<dynamic>?;
      if (bookmarks != null && bookmarks.contains(widget.propertyId)) {
        setState(() {
          isBookmarked = true;
        });
      } else {
        setState(() {
          isBookmarked = false;
        });
      }
    } catch (e) {
      // Optionally handle error
    }
  }

  Future<void> _toggleBookmark() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to bookmark properties.')),
      );
      return;
    }
    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();
      final bookmarks =
          userDoc.data()?['bookmarkedProperties'] as List<dynamic>? ?? [];
      if (isBookmarked) {
        // Remove
        await userRef.update({
          'bookmarkedProperties': FieldValue.arrayRemove([widget.propertyId]),
        });
        setState(() {
          isBookmarked = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from wishlist.')),
        );
      } else {
        // Add
        await userRef.set({
          'bookmarkedProperties': FieldValue.arrayUnion([widget.propertyId]),
        }, SetOptions(merge: true));
        setState(() {
          isBookmarked = true;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Added to wishlist!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating bookmark: \\${e.toString()}')),
      );
    }
  }

  Future<void> _fetchHostelDetails() async {
    try {
      final hostelDoc =
          await _firestore
              .collection('hostel_listings')
              .doc(widget.propertyId)
              .get();
      if (hostelDoc.exists) {
        final data = hostelDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            hostelData = HostelData.fromFirestore(data);
            isLoading = false;
          });
          
          // Fetch user contact information if they chose to share phone number
          if (hostelData.sharePhoneNumber && hostelData.uid.isNotEmpty) {
            await _fetchUserContactInfo(hostelData.uid);
          }
        } else {
          setState(() {
            error = 'Hostel/PG not found';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        error = 'Error loading hostel details: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUserContactInfo(String userId) async {
    setState(() {
      isLoadingUserData = true;
    });

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          userPhone = userData['phone']?.toString();
          userEmail = userData['email']?.toString();
          isLoadingUserData = false;
        });
      } else {
        setState(() {
          isLoadingUserData = false;
        });
      }
    } catch (e) {
      print('Error fetching user contact info: $e');
      setState(() {
        isLoadingUserData = false;
      });
    }
  }

  Future<void> _openGoogleMaps() async {
    String url;
    
    // Use coordinates if available, otherwise fall back to address and landmark
    if (hostelData.latitude != null && hostelData.longitude != null) {
      url = 'https://www.google.com/maps/search/?api=1&query=${hostelData.latitude},${hostelData.longitude}';
    } else {
      url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${hostelData.address}, ${hostelData.landmark}')}';
    }

    try {
      final Uri mapsUri = Uri.parse(url);
      bool launched = await launchUrl(
        mapsUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Fallback to web version
        final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${hostelData.address}, ${hostelData.landmark}')}';
        final Uri gmapsUri = Uri.parse(googleMapsUrl);
        launched = await launchUrl(
          gmapsUri,
          mode: LaunchMode.externalApplication,
        );
      }

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open maps. URL: $url'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening maps: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  List<String> get hostelImages => hostelData.uploadedPhotos.values.toList();

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    error = null;
                  });
                  _fetchHostelDetails();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(BuddyTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHostelHeader(),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  _buildPricingInfo(),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  if (hostelData.facilities.entries
                      .where((e) => e.value)
                      .isNotEmpty) ...[
                    _buildFacilities(),
                    const SizedBox(height: BuddyTheme.spacingLg),
                  ],
                  if (hostelData.roomTypes.entries
                      .where((e) => e.value)
                      .isNotEmpty) ...[
                    _buildRoomTypes(),
                    const SizedBox(height: BuddyTheme.spacingLg),
                  ],
                  if (hostelData.preferences.entries
                      .where((e) => e.value?.isNotEmpty ?? false)
                      .isNotEmpty) ...[
                    _buildLifestylePreferences(),
                    const SizedBox(height: BuddyTheme.spacingLg),
                  ],
                  if (hostelData.landmark.isNotEmpty) ...[
                    _buildLandmark(),
                    const SizedBox(height: BuddyTheme.spacingLg),
                  ],
                  if (hostelData.description.isNotEmpty) ...[
                    _buildDescription(),
                    const SizedBox(height: BuddyTheme.spacingLg),
                  ],
                  if (hostelData.offers.isNotEmpty) ...[
                    _buildOffers(),
                    const SizedBox(height: BuddyTheme.spacingLg),
                  ],
                  if (hostelData.specialFeatures.isNotEmpty) ...[
                    _buildSpecialFeatures(),
                    const SizedBox(height: BuddyTheme.spacingLg),
                  ],
                  _buildOwnerInfo(),
                  const SizedBox(height: BuddyTheme.spacingXl),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(Colors.white.withOpacity(0.06), theme.cardColor)
            : Color.alphaBlend(Colors.black.withOpacity(0.04), theme.cardColor);

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: cardColor,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(BuddyTheme.spacingXs),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: BuddyTheme.textPrimaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(BuddyTheme.spacingXs),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color:
                  isBookmarked
                      ? BuddyTheme.primaryColor
                      : BuddyTheme.textPrimaryColor,
            ),
            onPressed: _toggleBookmark,
          ),
        ),
        Container(
          margin: const EdgeInsets.all(BuddyTheme.spacingXs),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: BuddyTheme.textPrimaryColor),
            onPressed: () async {
              // Replace with your actual dynamic link or deep link logic
              final String propertyId = widget.propertyId;
              final String appLink =
                  'https://buddyapp.page.link/property?type=hostel&id=$propertyId';
              final String playStoreUrl =
                  'https://play.google.com/store/apps/details?id=com.yourcompany.buddy';
              final String shareText =
                  'Check out this hostel/PG: ${hostelData.title}\nAddress: ${hostelData.address}, ${hostelData.landmark}\n\nView details: $appLink\n\nDon\'t have the app? Download here: $playStoreUrl';
              await Share.share(shareText, subject: hostelData.title);
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => FullScreenImageGallery(
                          images: hostelImages,
                          initialIndex: currentImageIndex,
                        ),
                  ),
                );
              },
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentImageIndex = index;
                  });
                },
                itemCount: hostelImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(hostelImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: BuddyTheme.spacingMd,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    hostelImages.asMap().entries.map((entry) {
                      return Container(
                        width: 8.0,
                        height: 8.0,
                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              currentImageIndex == entry.key
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostelHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(Colors.white.withOpacity(0.06), theme.cardColor)
            : Color.alphaBlend(Colors.black.withOpacity(0.04), theme.cardColor);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.black54;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hostelData.title,
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeXl,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingXs),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: BuddyTheme.iconSizeSm,
                color: textSecondary,
              ),
              const SizedBox(width: BuddyTheme.spacingXs),
              Expanded(
                child: Text(
                  '${hostelData.address}, ${hostelData.landmark}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                    fontSize: BuddyTheme.fontSizeMd,
                  ),
                ),
              ),
              if (hostelData.latitude != null && hostelData.longitude != null) ...[
                GestureDetector(
                  onTap: _openGoogleMaps,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BuddyTheme.spacingSm,
                      vertical: BuddyTheme.spacingXs,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: BuddyTheme.spacingSm),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BuddyTheme.spacingSm,
                    vertical: BuddyTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: BuddyTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      BuddyTheme.borderRadiusSm,
                    ),
                  ),
                  child: Text(
                    hostelData.availableFromDate.isEmpty
                        ? 'Available Now'
                        : 'Available from ${hostelData.availableFromDate}',
                    style: TextStyle(
                      fontSize: BuddyTheme.fontSizeSm,
                      color: BuddyTheme.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (hostelData.latitude != null && hostelData.longitude != null) ...[
                const SizedBox(width: BuddyTheme.spacingMd),
                GestureDetector(
                  onTap: _openGoogleMaps,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BuddyTheme.spacingSm,
                      vertical: BuddyTheme.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: BuddyTheme.primaryColor,
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusSm,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.map,
                          size: BuddyTheme.iconSizeSm,
                          color: Colors.white,
                        ),
                        const SizedBox(width: BuddyTheme.spacingXs),
                        const Text(
                          'View on Map',
                          style: TextStyle(
                            fontSize: BuddyTheme.fontSizeXs,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingInfo() {
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pricing Details',
          style: TextStyle(
            fontSize: BuddyTheme.fontSizeLg,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: BuddyTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    BuddyTheme.borderRadiusMd,
                  ),
                ),
                padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Starting At',
                      style: TextStyle(
                        fontSize: BuddyTheme.fontSizeSm,
                        color: BuddyTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: BuddyTheme.spacingXs),
                    Text(
                      '₹${hostelData.startingAt.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: BuddyTheme.fontSizeLg,
                        fontWeight: FontWeight.bold,
                        color: BuddyTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: BuddyTheme.spacingMd),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: BuddyTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    BuddyTheme.borderRadiusMd,
                  ),
                ),
                padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Minimum Stay',
                      style: TextStyle(
                        fontSize: BuddyTheme.fontSizeSm,
                        color: BuddyTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: BuddyTheme.spacingXs),
                    Text(
                      hostelData.minimumStay,
                      style: const TextStyle(
                        fontSize: BuddyTheme.fontSizeLg,
                        fontWeight: FontWeight.bold,
                        color: BuddyTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFacilities() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(Colors.white.withOpacity(0.06), theme.cardColor)
            : Color.alphaBlend(Colors.black.withOpacity(0.04), theme.cardColor);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Facilities & Amenities',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          child: Wrap(
            spacing: BuddyTheme.spacingXs,
            runSpacing: BuddyTheme.spacingXs,
            children:
                hostelData.facilities.entries
                    .where((entry) => entry.value)
                    .map((entry) => entry.key)
                    .map((amenity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BuddyTheme.spacingSm,
                          vertical: BuddyTheme.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: BuddyTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            BuddyTheme.borderRadiusSm,
                          ),
                          border: Border.all(
                            color: BuddyTheme.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          amenity,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: BuddyTheme.fontSizeSm,
                            color: BuddyTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    })
                    .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomTypes() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(Colors.white.withOpacity(0.06), theme.cardColor)
            : Color.alphaBlend(Colors.black.withOpacity(0.04), theme.cardColor);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;

    // Define the order of room types
    final orderedRoomTypes = [
      '1 Bed Room (Private)',
      '2 Bed Room',
      '3 Bed Room',
      '4+ Bed Room',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Room Types',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          child: Wrap(
            spacing: BuddyTheme.spacingXs,
            runSpacing: BuddyTheme.spacingXs,
            children:
                orderedRoomTypes
                    .where((roomType) => hostelData.roomTypes[roomType] == true)
                    .map((roomType) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BuddyTheme.spacingSm,
                          vertical: BuddyTheme.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: BuddyTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            BuddyTheme.borderRadiusSm,
                          ),
                          border: Border.all(
                            color: BuddyTheme.accentColor.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          roomType,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: BuddyTheme.fontSizeSm,
                            color: BuddyTheme.accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    })
                    .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLifestylePreferences() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(Colors.white.withOpacity(0.06), theme.cardColor)
            : Color.alphaBlend(Colors.black.withOpacity(0.04), theme.cardColor);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lifestyle Preferences',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          child: Column(
            children: [
              if (hostelData.preferences['hostelFor']?.isNotEmpty ?? false)
                _buildPreferenceRow(
                  Icons.people_alt,
                  'Hostel For',
                  hostelData.preferences['hostelFor']!,
                ),
              if (hostelData.preferences['foodType']?.isNotEmpty ?? false)
                _buildPreferenceRow(
                  Icons.restaurant,
                  'Food Type',
                  hostelData.preferences['foodType']!,
                ),
              if (hostelData.preferences['smokingPolicy']?.isNotEmpty ?? false)
                _buildPreferenceRow(
                  Icons.smoking_rooms,
                  'Smoking Policy',
                  hostelData.preferences['smokingPolicy']!,
                ),
              if (hostelData.preferences['drinkingPolicy']?.isNotEmpty ?? false)
                _buildPreferenceRow(
                  Icons.local_bar,
                  'Drinking Policy',
                  hostelData.preferences['drinkingPolicy']!,
                ),
              if (hostelData.preferences['guestPolicy']?.isNotEmpty ?? false)
                _buildPreferenceRow(
                  Icons.people_outline,
                  'Guest Policy',
                  hostelData.preferences['guestPolicy']!,
                ),
              if (hostelData.preferences['entryTime']?.isNotEmpty ?? false)
                _buildPreferenceRow(
                  Icons.access_time,
                  'Entry Time Limit',
                  hostelData.preferences['entryTime']!,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    // Don't show the section if description is empty
    if (hostelData.description.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(Colors.white.withOpacity(0.06), theme.cardColor)
            : Color.alphaBlend(Colors.black.withOpacity(0.04), theme.cardColor);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          width: double.infinity,
          child: Text(
            hostelData.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: BuddyTheme.fontSizeMd,
              color: textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerInfo() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(Colors.white.withOpacity(0.06), theme.cardColor)
            : Color.alphaBlend(Colors.black.withOpacity(0.04), theme.cardColor);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Listed By',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: BuddyTheme.primaryColor.withOpacity(0.1),
                child: Icon(Icons.person, color: BuddyTheme.primaryColor),
              ),
              const SizedBox(width: BuddyTheme.spacingMd),
              Text(
                hostelData.contactPerson,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String? text) {
    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: BuddyTheme.spacingSm),
      child: Row(
        children: [
          Icon(
            icon,
            size: BuddyTheme.iconSizeSm,
            color: BuddyTheme.primaryColor,
          ),
          const SizedBox(width: BuddyTheme.spacingSm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildPreferenceRow(IconData icon, String title, String value) {
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.black54;

    return Padding(
      padding: const EdgeInsets.only(bottom: BuddyTheme.spacingSm),
      child: Row(
        children: [
          Icon(
            icon,
            color: BuddyTheme.primaryColor,
            size: BuddyTheme.iconSizeMd,
          ),
          const SizedBox(width: BuddyTheme.spacingMd),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(color: textSecondary),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final hasPhone = hostelData.sharePhoneNumber && userPhone != null && userPhone!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: SafeArea(
        child: hasPhone
            ? Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (!await UserService.hasActivePlan()) {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (ctx) => const PremiumPlanPromptSheet(),
                          );
                          return;
                        }
                        final Uri phoneUri = Uri(
                          scheme: 'tel',
                          path: userPhone!,
                        );
                        await launchUrl(phoneUri);
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BuddyTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: BuddyTheme.spacingMd),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!await UserService.hasActivePlan()) {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (ctx) => const PremiumPlanPromptSheet(),
                          );
                          return;
                        }
                        final otherUserId = hostelData.uid;
                        final otherUserName = hostelData.contactPerson ?? 'User';
                        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                        if (otherUserId == null || otherUserId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No user ID found for this user.')),
                          );
                          return;
                        }
                        if (currentUserId == otherUserId) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('You cannot chat with yourself.')),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              otherUserId: otherUserId,
                              otherUserName: otherUserName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('Message'),
                    ),
                  ),
                ],
              )
            : SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (!await UserService.hasActivePlan()) {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (ctx) => const PremiumPlanPromptSheet(),
                      );
                      return;
                    }
                    final otherUserId = hostelData.uid;
                    final otherUserName = hostelData.contactPerson ?? 'User';
                    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                    if (otherUserId == null || otherUserId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No user ID found for this user.')),
                      );
                      return;
                    }
                    if (currentUserId == otherUserId) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You cannot chat with yourself.')),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          otherUserId: otherUserId,
                          otherUserName: otherUserName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Message'),
                ),
              ),
      ),
    );
  }

  Widget _buildLandmark() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(Colors.white.withOpacity(0.06), theme.cardColor)
            : Color.alphaBlend(Colors.black.withOpacity(0.04), theme.cardColor);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Landmark',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          width: double.infinity,
          child: Text(
            hostelData.landmark,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: BuddyTheme.fontSizeMd,
              color: textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOffers() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(Colors.white.withOpacity(0.06), theme.cardColor)
            : Color.alphaBlend(Colors.black.withOpacity(0.04), theme.cardColor);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;

    // Don't show the section if offers is empty
    if (hostelData.offers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Offers',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          width: double.infinity,
          child: Text(
            hostelData.offers,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: BuddyTheme.fontSizeMd,
              color: textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialFeatures() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(Colors.white.withOpacity(0.06), theme.cardColor)
            : Color.alphaBlend(Colors.black.withOpacity(0.04), theme.cardColor);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;

    // Don't show the section if specialFeatures is empty
    if (hostelData.specialFeatures.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special Features',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          width: double.infinity,
          child: Text(
            hostelData.specialFeatures,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: BuddyTheme.fontSizeMd,
              color: textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}