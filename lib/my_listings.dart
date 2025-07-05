import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'display pages/property_details.dart';
import 'display pages/hostelpg_details.dart';
import 'display pages/service_details.dart';
import 'display pages/flatmate_details.dart';
import 'edit_flatmate.dart';
import 'widgets/action_sheet.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({Key? key}) : super(key: key);

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _listings = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _filterOptions = [
    'All',
    'Room',
    'Hostel/PG',
    'Service',
    'Flatmate',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fetchMyListings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyListings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final uid = user.uid;
      // Room listings
      final roomSnap =
          await FirebaseFirestore.instance
              .collection('room_listings')
              .where('userId', isEqualTo: uid)
              .get();
      // Hostel listings
          final hostelSnap =
          await FirebaseFirestore.instance
              .collection('hostel_listings')
              .where('uid', isEqualTo: uid)
              .get();
      // Service listings
      final serviceSnap =
          await FirebaseFirestore.instance
              .collection('service_listings')
              .where('userId', isEqualTo: uid)
              .get();
      // Flatmate listings (roomRequests)
      final flatmateSnap =
          await FirebaseFirestore.instance
              .collection('roomRequests')
              .where('userId', isEqualTo: uid)
              .get();

      final List<Map<String, dynamic>> all = [];
      // Room
      for (var doc in roomSnap.docs) {
        final data = doc.data();
        data['key'] = doc.id;
        data['listingType'] = 'Room';
        data['title'] = data['title'] ?? 'Room Listing';
        data['location'] = data['location'] ?? data['address'] ?? '';
        data['imageUrl'] =
            (data['uploadedPhotos'] is Map &&
                    (data['uploadedPhotos'] as Map).values.any(
                      (v) => v != null && v.toString().isNotEmpty,
                    ))
                ? (data['uploadedPhotos'] as Map).values.firstWhere(
                  (v) => v != null && v.toString().isNotEmpty,
                  orElse: () => '',
                )
                : (data['imageUrl'] ?? '');
        all.add(data);
      }
      // Hostel
      for (var doc in hostelSnap.docs) {
        final raw = doc.data();
        // Convert DocumentSnapshot data to a clean Map with no Timestamp objects
        final Map<String, dynamic> data = {};
        raw.forEach((key, value) {
          if (value is Timestamp) {
            // Convert Timestamp to ISO string
            data[key] = value.toDate().toIso8601String();
          } else if (value is Map) {
            // Deep copy for nested maps
            data[key] = Map<String, dynamic>.from(value);
          } else if (value is List) {
            // Deep copy for lists
            data[key] = List.from(value);
          } else {
            data[key] = value;
          }
        });
        
        data['key'] = doc.id;
        data['listingType'] = 'Hostel/PG';
        data['title'] = data['hostelName'] ?? data['title'] ?? 'Hostel/PG Listing';
        data['location'] = data['address'] ?? data['location'] ?? '';
        data['imageUrl'] =
            (data['uploadedPhotos'] is Map &&
                    (data['uploadedPhotos'] as Map).isNotEmpty)
                ? (data['uploadedPhotos'] as Map).values.firstWhere(
                  (v) => v != null && v.toString().isNotEmpty,
                  orElse: () => '',
                )
                : (data['imageUrl'] ?? '');

        print('Debug - Raw Hostel Data: ${data.toString()}');
        all.add(data);
      }
      // Service
      for (var doc in serviceSnap.docs) {
        final data = doc.data();
        data['key'] = doc.id;
        data['listingType'] = 'Service';
        data['title'] = data['serviceName'] ?? 'Service Listing';
        data['location'] = data['location'] ?? '';
        data['imageUrl'] =
            data['coverPhoto'] ??
            (data['additionalPhotos'] is List &&
                    (data['additionalPhotos'] as List).isNotEmpty
                ? data['additionalPhotos'][0]
                : (data['imageUrl'] ?? ''));
        all.add(data);
      }
      // Flatmate
      for (var doc in flatmateSnap.docs) {
        final data = doc.data();
        data['key'] = doc.id;
        data['listingType'] = 'Flatmate';
        data['title'] = data['title'] ?? data['name'] ?? 'Flatmate Listing';
        data['location'] = data['location'] ?? '';
        data['imageUrl'] = data['profilePhotoUrl'] ?? '';
        all.add(data);
      }

      setState(() {
        _listings = all;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _listings = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load listings: $e'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredListings {
    if (_selectedFilter == 'All') return _listings;
    return _listings
        .where((listing) => listing['listingType'] == _selectedFilter)
        .toList();
  }

  Color _getListingTypeColor(String type) {
    switch (type) {
      case 'Room':
        return const Color(0xFF4285F4);
      case 'Hostel/PG':
        return const Color(0xFF34A853);
      case 'Service':
        return const Color(0xFF9C27B0);
      case 'Flatmate':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF4285F4);
    }
  }

  IconData _getListingTypeIcon(String type) {
    switch (type) {
      case 'Room':
        return Icons.bed_rounded;
      case 'Hostel/PG':
        return Icons.apartment_rounded;
      case 'Service':
        return Icons.build_rounded;
      case 'Flatmate':
        return Icons.people_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'My Listings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_filteredListings.length} items',
                    style: const TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Filter section
            if (!_isLoading && _listings.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.filter_list_rounded,
                          color: Color(0xFF4285F4),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Filter Categories',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Single row filter options
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filterOptions.map((option) {
                          final isSelected = _selectedFilter == option;
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedFilter = option;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? const Color(0xFF4285F4) 
                                      : const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected 
                                        ? const Color(0xFF4285F4)
                                        : Colors.grey[700]!,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    color: isSelected 
                                        ? Colors.white 
                                        : Colors.grey[300],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            // Content section
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF4285F4),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading your listings...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredListings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.home_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'No listings found',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedFilter == 'All'
                                    ? 'Start creating your first listing'
                                    : 'No ${_selectedFilter.toLowerCase()} listings found',
                                style: const TextStyle(
                                  fontSize: 16, 
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: _filteredListings.length,
                          itemBuilder: (context, index) {
                            final listing = _filteredListings[index];
                            return _buildListingCard(listing, index);
                          },
                        ),
            ),
            // Bottom button
            if (!_isLoading)
              Container(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      _showActionSheet(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Add New Listing',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing, int index) {
    final image = listing['imageUrl'] ?? '';
    final listingType = listing['listingType'] ?? '';
    final color = _getListingTypeColor(listingType);
    final icon = _getListingTypeIcon(listingType);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey[800]!,
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  // Navigate to property details
                },
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Section
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            if (listingType == 'Flatmate')
                              Center(
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: color,
                                      width: 3,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: image.isNotEmpty
                                      ? Image.network(
                                          image,
                                          width: 140,
                                          height: 140,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                              color: color.withOpacity(0.2),
                                              child: Icon(
                                                icon,
                                                size: 48,
                                                color: color,
                                              ),
                                            ),
                                        )
                                      : Container(
                                          color: color.withOpacity(0.2),
                                          child: Icon(
                                            icon,
                                            size: 48,
                                            color: color,
                                          ),
                                        ),
                                  ),
                                ),
                              )
                            else if (image.isNotEmpty)
                              Image.network(
                                image,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                    Container(
                                      color: color.withOpacity(0.2),
                                      child: Center(
                                        child: Icon(
                                          icon,
                                          size: 48,
                                          color: color,
                                        ),
                                      ),
                                    ),
                              )
                            else
                              Container(
                                color: color.withOpacity(0.2),
                                child: Center(
                                  child: Icon(
                                    icon,
                                    size: 48,
                                    color: color,
                                  ),
                                ),
                              ),
                            // Type badge
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  listingType,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            // More options
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    _showOptionsBottomSheet(listing);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Content Section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing['title'] ?? 'No Title',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (listing['location']?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    listing['location'],
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (listing['visibility'] == false) 
                                      ? Colors.red.withOpacity(0.2)
                                      : Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  (listing['visibility'] == false) ? 'Inactive' : 'Active',
                                  style: TextStyle(
                                    color: (listing['visibility'] == false) 
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
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
            ),
          ),
        );
      },
    );
  }

  void _showOptionsBottomSheet(Map<String, dynamic> listing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bool canEdit =
            listing['visibility'] == false || listing['visibility'] == null;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2A2A2A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _buildOptionTile(
                icon: Icons.visibility_rounded,
                title: 'View Details',
                iconColor: Colors.white,
                textColor: Colors.white,
                onTap: () {
                  Navigator.pop(context);
                  final type = listing['listingType'];
                  if (type == 'Room') {
                    Navigator.pushNamed(
                      context,
                      '/propertyDetails',
                      arguments: {'propertyId': listing['key']},
                    );
                  } else if (type == 'Hostel/PG') {
                    Navigator.pushNamed(
                      context,
                      '/hostelpg_details',
                      arguments: {'hostelId': listing['key']},
                    );
                  } else if (type == 'Service') {
                    // Implement Service Details navigation if needed
                  } else if (type == 'Flatmate') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                FlatmateDetailsPage(flatmateData: listing),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Unknown listing type')),
                    );
                  }
                },
              ),
              if (canEdit)
                _buildOptionTile(
                  icon: Icons.edit_rounded,
                  title: 'Edit Details',
                  iconColor: const Color(0xFF4285F4),
                  textColor: const Color(0xFF4285F4),
                  onTap: () {
                    _navigateToEditPage(listing);
                  },
                ),
              _buildOptionTile(
                icon: Icons.share_rounded,
                title: 'Share',
                iconColor: Colors.white,
                textColor: Colors.white,
                onTap: () {
                  Navigator.pop(context);
                  // Share functionality
                },
              ),
              _buildOptionTile(
                icon: Icons.delete_rounded,
                title: 'Delete',
                iconColor: Colors.red,
                textColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(listing);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _navigateToEditPage(Map<String, dynamic> listing) async {
    final type = listing['listingType'];
    final id = listing['key'];

    Navigator.pop(context); // Close bottom sheet
    
    switch (type) {
      case 'Room':
        await Navigator.pushNamed(
          context,
          '/editProperty',
          arguments: {
            'propertyId': id,
            'propertyData': listing,
            'isEditing': true
          },
        );
        break;
      case 'Hostel/PG':
        print('Debug - Navigation Hostel Data: ${listing.toString()}');
        // Create a clean copy of the data
        final Map<String, dynamic> cleanData = {};
        listing.forEach((key, value) {
          // Skip null values and ensure all values are of basic types
          if (value != null) {
            if (value is Map) {
              cleanData[key] = Map<String, dynamic>.from(value);
            } else if (value is List) {
              cleanData[key] = List.from(value);
            } else if (value is DateTime) {
              cleanData[key] = value.toIso8601String();
            } else if (value is String || value is num || value is bool) {
              cleanData[key] = value;
            }
          }
        });
        print('Debug - Clean Hostel Data: ${cleanData.toString()}');
        await Navigator.pushNamed(
          context,
          '/editHostelPG',
          arguments: {
            'id': id,
            'hostelData': cleanData,
          },
        );
        break;
      case 'Service':
        await Navigator.pushNamed(
          context,
          '/editService',
          arguments: {
            'serviceId': id,
            'serviceData': listing,
            'isEditing': true
          },
        );
        break;
      case 'Flatmate':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditFlatmatePage(
              flatmateId: id,
              flatmateData: listing,
            ),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unknown listing type'),
            backgroundColor: Colors.red,
          ),
        );
        return;
    }
    
    // Refresh listings after returning from edit page
    await _fetchMyListings();
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> listing) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Listing',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this listing? This action cannot be undone.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteListing(listing);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showActionSheet(BuildContext context) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ActionBottomSheet(),
    );

    if (result != null && mounted) {
      // Handle the selected option from action sheet
      switch (result) {
        case 0: // Hostel/PG
          Navigator.pushNamed(context, '/listHostel');
          break;
        case 1: // Room
          Navigator.pushNamed(context, '/listRoom');
          break;
        case 2: // Service
          Navigator.pushNamed(context, '/listService');
          break;
        case 3: // Flatmate
          Navigator.pushNamed(context, '/listFlatmate');
          break;
        default:
          break;
      }
    }
  }

  Future<void> _deleteListing(Map<String, dynamic> listing) async {
    try {
      final type = listing['listingType'];
      final id = listing['key'];
      List<String> photoUrls = [];

      // Collect photo URLs/paths based on listing type
      switch (type) {
        case 'Room':
          if (listing['uploadedPhotos'] is Map) {
            photoUrls.addAll((listing['uploadedPhotos'] as Map).values
                .where((v) => v != null && v.toString().isNotEmpty)
                .map((v) => v.toString()));
          } else if (listing['imageUrl'] != null && listing['imageUrl'].toString().isNotEmpty) {
            photoUrls.add(listing['imageUrl']);
          }
          await FirebaseFirestore.instance
              .collection('room_listings')
              .doc(id)
              .delete();
          break;
        case 'Hostel/PG':
          if (listing['uploadedPhotos'] is Map) {
            photoUrls.addAll((listing['uploadedPhotos'] as Map).values
                .where((v) => v != null && v.toString().isNotEmpty)
                .map((v) => v.toString()));
          } else if (listing['imageUrl'] != null && listing['imageUrl'].toString().isNotEmpty) {
            photoUrls.add(listing['imageUrl']);
          }
          await FirebaseFirestore.instance
              .collection('hostel_listings')
              .doc(id)
              .delete();
          break;
        case 'Service':
          if (listing['coverPhoto'] != null && listing['coverPhoto'].toString().isNotEmpty) {
            photoUrls.add(listing['coverPhoto']);
          }
          if (listing['additionalPhotos'] is List) {
            photoUrls.addAll((listing['additionalPhotos'] as List)
                .where((v) => v != null && v.toString().isNotEmpty)
                .map((v) => v.toString()));
          }
          await FirebaseFirestore.instance
              .collection('service_listings')
              .doc(id)
              .delete();
          break;
        case 'Flatmate':
          if (listing['profilePhotoUrl'] != null && listing['profilePhotoUrl'].toString().isNotEmpty) {
            photoUrls.add(listing['profilePhotoUrl']);
          }
          await FirebaseFirestore.instance
              .collection('roomRequests')
              .doc(id)
              .delete();
          break;
        default:
          throw Exception('Unknown listing type: $type');
      }

      // Delete photos from Firebase Storage using refFromURL
      for (final url in photoUrls) {
        try {
          await FirebaseStorage.instance.refFromURL(url).delete();
        } catch (e) {
          debugPrint('Failed to delete photo: $url, error: $e');
        }
      }

      // Remove the listing from local state
      setState(() {
        _listings.removeWhere((item) => item['key'] == id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Listing deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete listing: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
    }