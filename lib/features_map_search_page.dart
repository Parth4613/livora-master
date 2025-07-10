import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'theme.dart';

class FeaturesMapSearchPage extends StatefulWidget {
  final LatLng center;
  final double radiusKm;
  const FeaturesMapSearchPage({
    Key? key,
    required this.center,
    required this.radiusKm,
  }) : super(key: key);

  @override
  State<FeaturesMapSearchPage> createState() => _FeaturesMapSearchPageState();
}

class _FeaturesMapSearchPageState extends State<FeaturesMapSearchPage> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _results = [];
  bool _loading = true;
  Map<String, dynamic>? _selectedProperty;

  @override
  void initState() {
    super.initState();
    _fetchNearbyProperties();
  }

  Future<void> _fetchNearbyProperties() async {
    setState(() {
      _loading = true;
      _selectedProperty = null;
    });
    final geo = GeoFlutterFire();
    final centerGeo = geo.point(
      latitude: widget.center.latitude,
      longitude: widget.center.longitude,
    );
    final firestore = FirebaseFirestore.instance;
    final double radius = widget.radiusKm;
    final List<Map<String, dynamic>> allResults = [];
    final Set<Marker> allMarkers = {};

    // Helper for adding markers
    void addMarker({
      required String id,
      required LatLng pos,
      required String type,
      required String title,
      required Map<String, dynamic> data,
    }) {
      BitmapDescriptor icon;
      switch (type) {
        case 'Room':
          icon = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          );
          break;
        case 'Hostel/PG':
          icon = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          );
          break;
        case 'Service':
          icon = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          );
          break;
        default:
          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      }
      allMarkers.add(
        Marker(
          markerId: MarkerId('$type-$id'),
          position: pos,
          icon: icon,
          infoWindow: InfoWindow(title: title, snippet: type),
          onTap: () {
            setState(() {
              _selectedProperty = {...data, 'type': type, 'id': id};
            });
          },
        ),
      );
    }

    // Query rooms
    final roomStream = geo
        .collection(collectionRef: firestore.collection('room_listings'))
        .within(
          center: centerGeo,
          radius: radius,
          field: 'position',
          strictMode: true,
        );
    final roomDocs = await roomStream.first;
    for (final doc in roomDocs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['position'] != null && data['position']['geopoint'] != null) {
        final pos = data['position']['geopoint'];
        addMarker(
          id: doc.id,
          pos: LatLng(pos.latitude, pos.longitude),
          type: 'Room',
          title: data['title'] ?? 'Room',
          data: data,
        );
        allResults.add({...data, 'type': 'Room', 'id': doc.id});
      }
    }
    // Query hostels
    final hostelStream = geo
        .collection(collectionRef: firestore.collection('hostel_listings'))
        .within(
          center: centerGeo,
          radius: radius,
          field: 'position',
          strictMode: true,
        );
    final hostelDocs = await hostelStream.first;
    for (final doc in hostelDocs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['position'] != null && data['position']['geopoint'] != null) {
        final pos = data['position']['geopoint'];
        addMarker(
          id: doc.id,
          pos: LatLng(pos.latitude, pos.longitude),
          type: 'Hostel/PG',
          title: data['title'] ?? 'Hostel/PG',
          data: data,
        );
        allResults.add({...data, 'type': 'Hostel/PG', 'id': doc.id});
      }
    }
    // Query services
    final serviceStream = geo
        .collection(collectionRef: firestore.collection('service_listings'))
        .within(
          center: centerGeo,
          radius: radius,
          field: 'position',
          strictMode: true,
        );
    final serviceDocs = await serviceStream.first;
    for (final doc in serviceDocs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['position'] != null && data['position']['geopoint'] != null) {
        final pos = data['position']['geopoint'];
        addMarker(
          id: doc.id,
          pos: LatLng(pos.latitude, pos.longitude),
          type: 'Service',
          title: data['serviceName'] ?? 'Service',
          data: data,
        );
        allResults.add({...data, 'type': 'Service', 'id': doc.id});
      }
    }
    setState(() {
      _markers = allMarkers;
      _results = allResults;
      _loading = false;
    });
  }

  Widget _buildPropertyCard(Map<String, dynamic> item) {
    String type = item['type'] ?? '';
    String title = item['title'] ?? item['serviceName'] ?? 'Property';
    String location = item['location'] ?? '';
    String? imageUrl =
        item['firstPhoto'] ??
        item['imageUrl'] ??
        (item['uploadedPhotos'] is Map &&
                (item['uploadedPhotos'] as Map).isNotEmpty
            ? (item['uploadedPhotos'] as Map).values.first
            : null);
    Color color =
        type == 'Room'
            ? BuddyTheme.primaryColor
            : type == 'Hostel/PG'
            ? Color(0xFF9C27B0)
            : BuddyTheme.successColor;
    Color bgColor =
        type == 'Room'
            ? BuddyTheme.backgroundSecondaryColor
            : type == 'Hostel/PG'
            ? Color(0xFFF3E5F5)
            : Color(0xFFE8F5E9);
    Color textColor =
        type == 'Room'
            ? BuddyTheme.textPrimaryColor
            : type == 'Hostel/PG'
            ? Color(0xFF6A1B9A)
            : Color(0xFF388E3C);
    IconData icon =
        type == 'Room'
            ? Icons.home_rounded
            : type == 'Hostel/PG'
            ? Icons.apartment_rounded
            : Icons.miscellaneous_services_rounded;
    String badge =
        type == 'Room'
            ? 'Room'
            : type == 'Hostel/PG'
            ? 'Hostel/PG'
            : 'Service';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
          onTap: () {
            // Navigate to details page based on type
            if (type == 'Room') {
              Navigator.pushNamed(
                context,
                '/propertyDetails',
                arguments: {'propertyId': item['id'], 'propertyData': item},
              );
            } else if (type == 'Hostel/PG') {
              Navigator.pushNamed(
                context,
                '/hostelpg_details',
                arguments: {'propertyId': item['id']},
              );
            } else if (type == 'Service') {
              Navigator.pushNamed(
                context,
                '/service_details',
                arguments: {'serviceId': item['id']},
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Colored top bar
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(BuddyTheme.borderRadiusLg),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child:
                            imageUrl != null && imageUrl.isNotEmpty
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: 72,
                                    height: 72,
                                    errorBuilder:
                                        (c, e, s) =>
                                            Icon(icon, color: color, size: 36),
                                  ),
                                )
                                : Icon(icon, color: color, size: 36),
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    badge,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.location_on, color: color, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor.withOpacity(0.7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (type == 'Room' && item['rent'] != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Rent: ₹${item['rent']}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (type == 'Hostel/PG' &&
                                item['startingAt'] != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Starting at: ₹${item['startingAt']}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (type == 'Service' &&
                                item['serviceType'] != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Type: ${item['serviceType']}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Close button
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black38),
                        onPressed:
                            () => setState(() => _selectedProperty = null),
                        tooltip: 'Close',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Properties')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.center,
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: false, // Disable My Location layer to prevent permission errors
            myLocationButtonEnabled: false, // Disable My Location button
            markers: _markers,
            circles: {
              Circle(
                circleId: const CircleId('search_radius'),
                center: widget.center,
                radius: widget.radiusKm * 1000,
                fillColor: Colors.blue.withOpacity(0.1),
                strokeColor: Colors.blue,
                strokeWidth: 2,
              ),
            },
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          Positioned(
            top: 16,
            right: 16,
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_rounded, color: Colors.blue, size: 20),
                    const SizedBox(width: 4),
                    const Text('Room', style: TextStyle(color: Colors.black)),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.apartment_rounded,
                      color: Colors.purple,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Hostel/PG',
                      style: TextStyle(color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.miscellaneous_services_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Service',
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_selectedProperty != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildPropertyCard(_selectedProperty!),
            ),
        ],
      ),
    );
  }
}
