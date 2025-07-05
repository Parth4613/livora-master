import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'display pages/service_details.dart';

class WishlistPage extends StatefulWidget {
  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _wishlist = [];
  bool _isLoading = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late AnimationController _heartController;

  // Theme colors
  Color get primaryBlue => Theme.of(context).brightness == Brightness.light 
      ? const Color(0xFF2196F3) 
      : const Color(0xFF42A5F5);
  
  Color get secondaryBlue => Theme.of(context).brightness == Brightness.light 
      ? const Color(0xFF1976D2) 
      : const Color(0xFF1E88E5);
  
  Color get lightBlue => Theme.of(context).brightness == Brightness.light 
      ? const Color(0xFFE3F2FD) 
      : const Color(0xFF1A237E).withOpacity(0.3);
  
  Color get backgroundColor => Theme.of(context).brightness == Brightness.light 
      ? const Color(0xFFF8FAFE) 
      : const Color(0xFF121212);
  
  Color get cardColor => Theme.of(context).brightness == Brightness.light 
      ? Colors.white 
      : const Color(0xFF1E1E1E);
  
  Color get textPrimary => Theme.of(context).brightness == Brightness.light 
      ? const Color(0xFF1A1A1A) 
      : Colors.white;
  
  Color get textSecondary => Theme.of(context).brightness == Brightness.light 
      ? const Color(0xFF757575) 
      : Colors.white70;
  
  Color get accentColor => Theme.of(context).brightness == Brightness.light 
      ? const Color(0xFF1976D2) 
      : const Color(0xFF42A5F5);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _fetchWishlist();
  }

  @override
  void dispose() {
    _controller.dispose();
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _fetchWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    final bookmarkedProperties =
        (userDoc.data()?['bookmarkedProperties'] as List?)?.cast<String>() ??
        [];
    final bookmarkedHostels =
        (userDoc.data()?['bookmarkedHostels'] as List?)?.cast<String>() ?? [];
    final bookmarkedServices =
        (userDoc.data()?['bookmarkedServices'] as List?)?.cast<String>() ?? [];

    String? extractImageUrl(dynamic data) {
      if (data == null) return null;
      if (data is String && data.isNotEmpty) return data;
      if (data is Map && data.isNotEmpty)
        return data.values
            .firstWhere(
              (v) => v != null && v.toString().isNotEmpty,
              orElse: () => null,
            )
            ?.toString();
      if (data is List && data.isNotEmpty) return data.first.toString();
      return null;
    }

    final List<Map<String, dynamic>> allItems = [];

    // Fetch properties and hostels from bookmarkedProperties
    for (final id in bookmarkedProperties) {
      var doc =
          await FirebaseFirestore.instance
              .collection('room_listings')
              .doc(id)
              .get();
      if (doc.exists) {
        final data = doc.data()!;
        data['key'] = doc.id;
        data['listingType'] = 'Room';
        data['title'] = data['title'] ?? 'Room Listing';
        data['location'] = data['location'] ?? data['address'] ?? '';
        data['imageUrl'] =
            extractImageUrl(data['imageUrl']) ??
            extractImageUrl(data['uploadedPhotos']) ??
            '';
        allItems.add(data);
        continue;
      }

      doc =
          await FirebaseFirestore.instance
              .collection('hostel_listings')
              .doc(id)
              .get();
      if (doc.exists) {
        final data = doc.data()!;
        data['key'] = doc.id;
        data['listingType'] = 'Hostel/PG';
        data['title'] = data['title'] ?? 'Hostel/PG Listing';
        data['location'] = data['address'] ?? '';
        data['imageUrl'] =
            extractImageUrl(data['imageUrl']) ??
            extractImageUrl(data['uploadedPhotos']) ??
            '';
        allItems.add(data);
      }
    }

    // Fetch hostels from bookmarkedHostels
    for (final id in bookmarkedHostels) {
      if (allItems.any((item) => item['key'] == id)) continue;
      final doc =
          await FirebaseFirestore.instance
              .collection('hostel_listings')
              .doc(id)
              .get();
      if (doc.exists) {
        final data = doc.data()!;
        data['key'] = doc.id;
        data['listingType'] = 'Hostel/PG';
        data['title'] = data['title'] ?? 'Hostel/PG Listing';
        data['location'] = data['address'] ?? '';
        data['imageUrl'] =
            extractImageUrl(data['imageUrl']) ??
            extractImageUrl(data['uploadedPhotos']) ??
            '';
        allItems.add(data);
      }
    }

    // Fetch services
    for (final id in bookmarkedServices) {
      final doc =
          await FirebaseFirestore.instance
              .collection('service_listings')
              .doc(id)
              .get();
      if (doc.exists) {
        final data = doc.data()!;
        data['key'] = doc.id;
        data['listingType'] = 'Service';
        data['title'] = data['serviceName'] ?? 'Service Listing';
        data['location'] = data['location'] ?? '';
        data['imageUrl'] =
            extractImageUrl(data['imageUrl']) ??
            extractImageUrl(data['uploadedPhotos']) ??
            '';
        allItems.add(data);
      }
    }

    setState(() {
      _wishlist = allItems;
      _isLoading = false;
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          if (_isLoading)
            SliverFillRemaining(child: _buildLoadingState())
          else if (_wishlist.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: _buildListingCard(_wishlist[index], index),
                        ),
                      );
                    },
                  );
                }, childCount: _wishlist.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: primaryBlue.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'My Wishlist',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark 
                ? [const Color(0xFF1A237E).withOpacity(0.3), backgroundColor]
                : [lightBlue, backgroundColor],
            ),
          ),
          child: Positioned.fill(
            child: CustomPaint(
              painter: _WavesPainter(primaryBlue.withOpacity(0.1)),
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: AnimatedBuilder(
              animation: _heartController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + _heartController.value * 0.2,
                  child: Icon(Icons.favorite, color: accentColor),
                );
              },
            ),
            onPressed: () {
              _heartController.forward().then((_) {
                _heartController.reverse();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lightBlue, backgroundColor],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading your favorites...',
              style: TextStyle(
                color: textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lightBlue, backgroundColor],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.favorite_border_rounded,
                  size: 60,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Your Wishlist is Empty',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Start exploring and save your favorite places to see them here!',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  icon: const Icon(Icons.explore_rounded, size: 20),
                  label: const Text('Explore Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing, int index) {
    final image = listing['imageUrl'] ?? '';
    final type = listing['listingType'] ?? '';
    final color = _getTypeColor(type);
    final icon = _getTypeIcon(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.light 
                ? Colors.black.withOpacity(0.08)
                : Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDetails(type, listing['key']),
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: image.isNotEmpty
                          ? Image.network(
                              image,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildImagePlaceholder(color, icon),
                            )
                          : _buildImagePlaceholder(color, icon),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 16, color: color),
                          const SizedBox(width: 6),
                          Text(
                            type,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite,
                        size: 20,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing['title'] ?? 'No Title',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (listing['location']?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: lightBlue,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryBlue.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 18,
                              color: primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                listing['location'],
                                style: TextStyle(
                                  color: secondaryBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, size: 48, color: color),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Hostel/PG':
        return const Color(0xFF9C27B0);
      case 'Service':
        return const Color(0xFF4CAF50);
      default:
        return primaryBlue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Hostel/PG':
        return Icons.apartment_rounded;
      case 'Service':
        return Icons.miscellaneous_services_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  void _navigateToDetails(String type, String key) {
    if (type == 'Room') {
      Navigator.pushNamed(
        context,
        '/propertyDetails',
        arguments: {'propertyId': key},
      );
    } else if (type == 'Hostel/PG') {
      Navigator.pushNamed(
        context,
        '/hostelpg_details',
        arguments: {'hostelId': key},
      );
    } else if (type == 'Service') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceDetailsScreen(serviceId: key),
        ),
      );
    }
  }
}

// Custom painter for decorative waves in the app bar
class _WavesPainter extends CustomPainter {
  final Color color;

  _WavesPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.5,
      size.width * 0.5,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.9,
      size.width,
      size.height * 0.7,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}