import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../chat_screen.dart';
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

class ServiceData {
  final String acStatus;
  final List<String> additionalPhotos;
  final String chargeType;
  final String charges;
  final String closingTime;
  final String contact;
  final String coverPhoto;
  final String createdAt;
  final String description;
  final String email;
  final String expiryDate;
  final bool hasInternet;
  final bool hasStudyCabin;
  final String libraryType;
  final String location;
  final String offDay;
  final String openingTime;
  final int seatingCapacity;
  final String selectedPlan;
  final String serviceName;
  final String serviceType;
  final String serviceTypeOther; // Added for Other type
  final String userId;
  final bool visibility;
  final String priceRange; // Added for cafe
  final bool hasSeating; // Added for cafe
  final String pricing; // Added for other service type
  final String cuisineType; // Added for cafe
  final bool hasWifi; // Added for cafe
  final bool hasPowerSockets; // Added for cafe
  final bool hasHomeDelivery; // Added for mess
  final bool hasTiffinService; // Added for mess
  final String foodType; // Added for mess
  final bool breakfast; // Added for mess meal timings
  final bool lunch; // Added for mess meal timings
  final bool dinner; // Added for mess meal timings
  final String usefulness;
  final double? latitude;
  final double? longitude;

  ServiceData({
    required this.serviceName,
    required this.serviceType,
    required this.location,
    required this.description,
    required this.contact,
    required this.email,
    required this.openingTime,
    required this.closingTime,
    required this.selectedPlan,
    required this.userId,
    required this.visibility,
    required this.createdAt,
    required this.expiryDate,
    required this.acStatus,
    required this.additionalPhotos,
    required this.chargeType,
    required this.charges,
    required this.coverPhoto,
    required this.hasInternet,
    required this.hasStudyCabin,
    required this.libraryType,
    required this.offDay,
    required this.seatingCapacity,
    this.usefulness = '', // Default value
    this.priceRange = '', // Default value
    this.hasSeating = false, // Default value
    this.serviceTypeOther = '', // Default value
    this.pricing = '', // Default value
    this.cuisineType = '', // Default value for cafe
    required this.hasWifi, // Default value for cafe
    required this.hasPowerSockets, // Default value for cafe,
    this.hasHomeDelivery = false, // Default value for mess
    this.hasTiffinService = false, // Default value for mess
    this.foodType = '', // Added for mess
    this.breakfast = false, // Added for mess meal timings
    this.lunch = false, // Added for mess meal timings
    this.dinner = false, // Added for mess meal timings
    this.latitude,
    this.longitude,
  });

  factory ServiceData.fromFirestore(Map<String, dynamic> data) {
    // Get mealTimings map and extract boolean values, default to false if not present
    Map<String, dynamic> mealTimings = data['mealTimings'] ?? {};

    return ServiceData(
      acStatus: data['acStatus'] ?? '',
      additionalPhotos: List<String>.from(data['additionalPhotos'] ?? []),
      chargeType: data['chargeType'] ?? '',
      charges: data['charges'] ?? '',
      closingTime: data['closingTime'] ?? '',
      contact: data['contact'] ?? '',
      coverPhoto: data['coverPhoto'] ?? '',
      createdAt:
          data['createdAt'] != null ? _formatDate(data['createdAt']) : '',
      description: data['description'] ?? '',
      email: data['email'] ?? '',
      expiryDate: data['expiryDate'] ?? '',
      hasInternet: data['hasInternet'] ?? false,
      hasStudyCabin: data['hasStudyCabin'] ?? false,
      libraryType: data['libraryType'] ?? '',
      location: data['location'] ?? '',
      offDay: data['offDay'] ?? '',
      openingTime: data['openingTime'] ?? '',
      seatingCapacity:
          data['seatingCapacity'] is String
              ? int.tryParse(data['seatingCapacity']) ?? 0
              : data['seatingCapacity'] ?? 0,
      selectedPlan: data['selectedPlan'] ?? '',
      serviceName: data['serviceName'] ?? '',
      serviceType: data['serviceType'] ?? '',
      userId: data['userId'] ?? '',
      hasHomeDelivery: data['hasHomeDelivery'] ?? false,
      hasTiffinService: data['hasTiffinService'] ?? false,
      visibility: data['visibility'] ?? false,
      priceRange: data['priceRange'] ?? '',
      hasSeating: data['hasSeating'] ?? false,
      serviceTypeOther: data['serviceTypeOther'] ?? '',
      pricing: data['pricing'] ?? '',
      cuisineType: data['cuisineType'] ?? '',
      hasPowerSockets: data['hasPowerSockets'] ?? false,
      hasWifi: data['hasWifi'] ?? false,
      foodType: data['foodType'] ?? '', // Added for mess
      breakfast:
          mealTimings['Breakfast'] ?? false, // Added for mess meal timings
      lunch: mealTimings['Lunch'] ?? false, // Added for mess meal timings
      dinner: mealTimings['Dinner'] ?? false, // Added for mess meal timings
      usefulness: data['usefulness'] ?? '', // Added for other service type
      latitude: data['latitude'] as double?,
      longitude: data['longitude'] as double?,
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

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;

  const ServiceDetailsScreen({Key? key, required this.serviceId})
    : super(key: key);

  @override
  _ServiceDetailsScreenState createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late ServiceData serviceData;
  bool isBookmarked = false;
  int currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchServiceDetails();
    _checkIfBookmarked();
  }

  Future<void> _toggleBookmark() async {
    // You may want to use FirebaseAuth to get the current user
    final user = await FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final bookmarks =
        (userDoc.data()?['bookmarkedServices'] as List?)?.cast<String>() ?? [];
    final isBookmarkedNow = bookmarks.contains(widget.serviceId);
    if (isBookmarkedNow) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'bookmarkedServices': FieldValue.arrayRemove([widget.serviceId]),
        },
      );
    } else {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'bookmarkedServices': FieldValue.arrayUnion([widget.serviceId]),
      }, SetOptions(merge: true));
    }
    setState(() {
      isBookmarked = !isBookmarked;
    });
  }

  Future<void> _checkIfBookmarked() async {
    final user = await FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final bookmarks =
        (userDoc.data()?['bookmarkedServices'] as List?)?.cast<String>() ?? [];
    setState(() {
      isBookmarked = bookmarks.contains(widget.serviceId);
    });
  }

  Future<void> _shareService() async {
    final String shareText =
        'Check out this service: ${serviceData.serviceName}\nLocation: ${serviceData.location}\n\nDescription: ${serviceData.description}\n';
    await Share.share(shareText, subject: serviceData.serviceName);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchServiceDetails() async {
    try {
      final serviceDoc =
          await _firestore
              .collection('service_listings')
              .doc(widget.serviceId)
              .get();

      if (serviceDoc.exists) {
        final data = serviceDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            serviceData = ServiceData.fromFirestore(data);
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'Service not found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error loading service details: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _openGoogleMaps() async {
    String url;
    
    // Use coordinates if available, otherwise fall back to location text
    if (serviceData.latitude != null && serviceData.longitude != null) {
      url = 'https://www.google.com/maps/search/?api=1&query=${serviceData.latitude},${serviceData.longitude}';
    } else {
      url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(serviceData.location)}';
    }

    try {
      final Uri mapsUri = Uri.parse(url);
      bool launched = await launchUrl(
        mapsUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Fallback to web version
        final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(serviceData.location)}';
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

  List<String> get serviceImages =>
      [
        serviceData.coverPhoto,
        ...serviceData.additionalPhotos,
      ].where((url) => url.isNotEmpty).toList();

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
                  _fetchServiceDetails();
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
                  _buildServiceHeader(),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  _buildPricingInfo(),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  if (serviceData.libraryType.isNotEmpty) ...[
                    _buildLibraryType(),
                    const SizedBox(height: BuddyTheme.spacingLg),
                  ],
                  if (serviceData.serviceType.toLowerCase() == 'mess') ...[
                    _buildMessInfo(),
                    const SizedBox(height: BuddyTheme.spacingLg),
                  ],
                  if (serviceData.serviceType.toLowerCase() == 'café' ||
                      serviceData.serviceType.toLowerCase() == 'cafe') ...[
                    _buildCafeInfo(),
                    const SizedBox(height: BuddyTheme.spacingLg),
                  ],
                  if (serviceData.serviceType.toLowerCase() == 'other') ...[
                    _buildOtherInfo(),
                    const SizedBox(height: BuddyTheme.spacingLg),
                  ],
                  if (serviceData.description.isNotEmpty) ...[
                    _buildDescription(),
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
            onPressed: () async {
              await _toggleBookmark();
              HapticFeedback.lightImpact();
            },
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
            onPressed: _shareService,
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
                          images: serviceImages,
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
                itemCount: serviceImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(serviceImages[index]),
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
                    serviceImages.asMap().entries.map((entry) {
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

  Widget _buildServiceHeader() {
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
            serviceData.serviceName,
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
                  '${serviceData.location}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                    fontSize: BuddyTheme.fontSizeMd,
                  ),
                ),
              ),
              if (serviceData.latitude != null && serviceData.longitude != null)
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
                    serviceData.createdAt.isEmpty
                        ? 'Available Now'
                        : 'Available from ${serviceData.createdAt}',
                    style: TextStyle(
                      fontSize: BuddyTheme.fontSizeSm,
                      color: BuddyTheme.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (serviceData.latitude != null && serviceData.longitude != null) ...[
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

    String leftCardTitle;
    String leftCardValue;
    String rightCardTitle;
    String rightCardValue;

    switch (serviceData.serviceType.toLowerCase()) {
      case 'library':
        leftCardTitle = 'Monthly Charges';
        leftCardValue = '₹${serviceData.charges}';
        rightCardTitle = 'Seating Capacity';
        rightCardValue = serviceData.seatingCapacity.toString();
        break;
      case 'café':
        leftCardTitle = 'Price Range (₹ per person)';
        leftCardValue = '₹${serviceData.priceRange}';
        rightCardTitle = 'Seating';
        rightCardValue = serviceData.hasSeating ? 'Available' : 'Unavailable';
        break;
      case 'mess':
        leftCardTitle = 'Monthly Charges';
        leftCardValue = '₹${serviceData.charges}';
        rightCardTitle = 'Seating Capacity';
        rightCardValue = serviceData.seatingCapacity.toString();
        break;
      case 'other':
        leftCardTitle = 'Charges';
        leftCardValue = '₹${serviceData.pricing}';
        rightCardTitle = 'Type of Service';
        rightCardValue = serviceData.serviceTypeOther;
        break;
      default:
        leftCardTitle = 'Charges';
        leftCardValue = '₹${serviceData.charges}';
        rightCardTitle = 'Seating Capacity';
        rightCardValue = serviceData.seatingCapacity.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pricing Details',
          style: TextStyle(
            fontSize: BuddyTheme.fontSizeLg,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color ?? Colors.black,
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
                    Text(
                      leftCardTitle,
                      style: const TextStyle(
                        fontSize: BuddyTheme.fontSizeSm,
                        color: BuddyTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: BuddyTheme.spacingXs),
                    Text(
                      leftCardValue,
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
                    Text(
                      rightCardTitle,
                      style: const TextStyle(
                        fontSize: BuddyTheme.fontSizeSm,
                        color: BuddyTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: BuddyTheme.spacingXs),
                    Text(
                      rightCardValue,
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
        // Add Timings section for all service types
        if (serviceData.openingTime.isNotEmpty ||
            serviceData.closingTime.isNotEmpty) ...[
          const SizedBox(height: BuddyTheme.spacingLg),
          Text(
            'Timings',
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeLg,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color ?? Colors.black,
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
                        'Opening Time',
                        style: TextStyle(
                          fontSize: BuddyTheme.fontSizeSm,
                          color: BuddyTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: BuddyTheme.spacingXs),
                      Text(
                        serviceData.openingTime,
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
                        'Closing Time',
                        style: TextStyle(
                          fontSize: BuddyTheme.fontSizeSm,
                          color: BuddyTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: BuddyTheme.spacingXs),
                      Text(
                        serviceData.closingTime,
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
        ], // Add Facilities section after Timings section
        if ([
          'library',
          'café',
          'cafe',
          'mess',
        ].contains(serviceData.serviceType.toLowerCase())) ...[
          const SizedBox(height: BuddyTheme.spacingLg),
          _buildFacilities(),
        ],
      ],
    );
  }

  Widget _buildLibraryType() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(Colors.white.withOpacity(0.06), theme.cardColor)
            : Color.alphaBlend(Colors.black.withOpacity(0.04), theme.cardColor);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return serviceData.serviceType.toLowerCase() == 'library'
        ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Library Information',
              style: theme.textTheme.titleLarge?.copyWith(
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
                          'Library Type',
                          style: TextStyle(
                            fontSize: BuddyTheme.fontSizeSm,
                            color: BuddyTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: BuddyTheme.spacingXs),
                        Text(
                          serviceData.libraryType,
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
                          'AC Status',
                          style: TextStyle(
                            fontSize: BuddyTheme.fontSizeSm,
                            color: BuddyTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: BuddyTheme.spacingXs),
                        Text(
                          serviceData.acStatus,
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
            if (serviceData.offDay.isNotEmpty) ...[
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
                            'Off Day',
                            style: TextStyle(
                              fontSize: BuddyTheme.fontSizeSm,
                              color: BuddyTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: BuddyTheme.spacingXs),
                          Text(
                            serviceData.offDay,
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
                ],
              ),
            ],
          ],
        )
        : const SizedBox.shrink(); // Don't show this section for non-library services
  }

  Widget _buildFacilities() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(Colors.white.withOpacity(0.06), theme.cardColor)
            : Color.alphaBlend(Colors.black.withOpacity(0.04), theme.cardColor);

    List<Widget> facilityChips = [];

    // Add service-specific facilities based on lowercase service type
    final serviceType = serviceData.serviceType.toLowerCase();
    if (serviceType == 'library') {
      if (serviceData.hasInternet) {
        facilityChips.add(_buildFacilityChip('Internet', Icons.wifi));
      }
      if (serviceData.hasStudyCabin) {
        facilityChips.add(_buildFacilityChip('Study Cabin', Icons.book));
      }
    } else if (serviceType == 'café') {
      // Only show wifi if hasWifi is true
      if (serviceData.hasWifi) {
        facilityChips.add(_buildFacilityChip('Wi-Fi', Icons.wifi));
      }
      // Only show power sockets if hasPowerSockets is true
      if (serviceData.hasPowerSockets) {
        facilityChips.add(_buildFacilityChip('Power Sockets', Icons.power));
      }
      if (serviceData.hasSeating) {
        facilityChips.add(_buildFacilityChip('Seating Available', Icons.chair));
      }
    } else if (serviceType == 'mess') {
      if (serviceData.hasHomeDelivery) {
        facilityChips.add(
          _buildFacilityChip('Home Delivery', Icons.delivery_dining),
        );
      }
      if (serviceData.hasTiffinService) {
        facilityChips.add(
          _buildFacilityChip('Tiffin Service', Icons.lunch_dining),
        );
      }
    }

    // If no facilities, don't show the section
    if (facilityChips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Facilities & Amenities',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
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
            children: facilityChips,
          ),
        ),
      ],
    );
  }

  Widget _buildFacilityChip(String label, IconData icon) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BuddyTheme.spacingSm,
        vertical: BuddyTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: BuddyTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
        border: Border.all(color: BuddyTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: BuddyTheme.iconSizeSm,
            color: BuddyTheme.primaryColor,
          ),
          const SizedBox(width: BuddyTheme.spacingXs),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: BuddyTheme.fontSizeSm,
              color: BuddyTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    // Don't show the section if description is empty
    if (serviceData.description.isEmpty) {
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
            serviceData.description,
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
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: BuddyTheme.primaryColor.withOpacity(0.1),
                child: Icon(Icons.person, color: BuddyTheme.primaryColor),
              ),
              const SizedBox(width: BuddyTheme.spacingMd),
              Text(
                serviceData.serviceName ?? 'Unknown',
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: BuddyTheme.primaryColor),
          const SizedBox(width: BuddyTheme.spacingSm),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: BuddyTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: SafeArea(
        child: Row(
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
                    path: serviceData.contact,
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
                  final otherUserId = serviceData.userId;
                  final otherUserName = serviceData.serviceName ?? 'User';
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
        ),
      ),
    );
  }

  Widget _buildCafeInfo() {
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;

    final serviceType = serviceData.serviceType.toLowerCase();
    return serviceType == 'café' || serviceType == 'cafe'
        ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Café Information',
              style: theme.textTheme.titleLarge?.copyWith(
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
                          'Cuisine Type',
                          style: TextStyle(
                            fontSize: BuddyTheme.fontSizeSm,
                            color: BuddyTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: BuddyTheme.spacingXs),
                        Text(
                          serviceData.cuisineType.isNotEmpty
                              ? serviceData.cuisineType
                              : 'Not specified',
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
                          'Off Day',
                          style: TextStyle(
                            fontSize: BuddyTheme.fontSizeSm,
                            color: BuddyTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: BuddyTheme.spacingXs),
                        Text(
                          serviceData.offDay.isNotEmpty
                              ? serviceData.offDay
                              : 'Not specified',
                          style: TextStyle(
                            fontSize: BuddyTheme.fontSizeLg,
                            fontWeight: FontWeight.bold,
                            color: BuddyTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        )
        : const SizedBox.shrink(); // Don't show this section for non-cafe services
  }

  Widget _buildMessInfo() {
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mess Information',
          style: theme.textTheme.titleLarge?.copyWith(
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
                    Text(
                      'Food Type',
                      style: TextStyle(
                        fontSize: BuddyTheme.fontSizeSm,
                        color: BuddyTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: BuddyTheme.spacingXs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        serviceData.foodType.isEmpty
                            ? 'Not Specified'
                            : serviceData.foodType,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: BuddyTheme.fontSizeLg,
                          color: BuddyTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
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
                    Text(
                      'Off Day',
                      style: TextStyle(
                        fontSize: BuddyTheme.fontSizeSm,
                        color: BuddyTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: BuddyTheme.spacingXs),
                    Text(
                      serviceData.offDay.isEmpty
                          ? 'Not Specified'
                          : serviceData.offDay,
                      style: TextStyle(
                        fontSize: BuddyTheme.fontSizeMd,
                        fontWeight: FontWeight.w500,
                        color: BuddyTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        Text(
          'Meals Provided',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Wrap(
          spacing: BuddyTheme.spacingSm,
          runSpacing: BuddyTheme.spacingSm,
          children: [
            if (serviceData.breakfast)
              _buildFacilityChip('Breakfast', Icons.free_breakfast),
            if (serviceData.lunch)
              _buildFacilityChip('Lunch', Icons.lunch_dining),
            if (serviceData.dinner)
              _buildFacilityChip('Dinner', Icons.dinner_dining),
          ],
        ),
      ],
    );
  }

  Widget _buildOtherInfo() {
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;

    if (serviceData.serviceType.toLowerCase() != 'other') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Other Information',
          style: TextStyle(
            fontSize: BuddyTheme.fontSizeLg,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (serviceData.offDay.isNotEmpty && serviceData.offDay != 'None')
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.45,
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
                        'Off Day',
                        style: TextStyle(
                          fontSize: BuddyTheme.fontSizeSm,
                          color: BuddyTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: BuddyTheme.spacingXs),
                      Text(
                        serviceData.offDay,
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
            if (serviceData.usefulness.isNotEmpty) ...[
              const SizedBox(height: BuddyTheme.spacingMd),
              Container(
                width: double.infinity,
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
                      'Usefulness',
                      style: TextStyle(
                        fontSize: BuddyTheme.fontSizeSm,
                        color: BuddyTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: BuddyTheme.spacingXs),
                    Text(
                      serviceData.usefulness,
                      style: const TextStyle(
                        fontSize: BuddyTheme.fontSizeLg,
                        fontWeight: FontWeight.bold,
                        color: BuddyTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}