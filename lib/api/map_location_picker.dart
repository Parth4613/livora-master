import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/location_permission_helper.dart';

class MapLocationPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final bool showRadiusPicker;
  const MapLocationPicker({Key? key, this.initialLocation, this.showRadiusPicker = false}) : super(key: key);

  @override
  _MapLocationPickerState createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  LatLng? _pickedLocation;
  LatLng? _mapCenter;
  double _radius = 3.0;
  bool _isLoading = false;
  bool _showRadiusSheet = false;
  bool _showConfirmButton = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    // Set a default location immediately for faster loading
    setState(() {
      _mapCenter = widget.initialLocation ?? LatLng(18.5204, 73.8567); // Default: Pune
    });

    // If we have an initial location, no need to get current position
    if (widget.initialLocation != null) {
      return;
    }

    // Try to get current location in background
    _getCurrentLocationInBackground();
  }

  Future<void> _getCurrentLocationInBackground() async {
    try {
      // Use the helper to get current location with proper permission handling
      final position = await LocationPermissionHelper.getCurrentLocation();
      
      if (position != null && mounted) {
        setState(() {
          _mapCenter = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      // Keep the default location if there's an error
      print('Error getting current location: $e');
    }
  }

  void _onPinDropped(LatLng latLng) {
    setState(() {
      _pickedLocation = latLng;
      if (widget.showRadiusPicker) {
        _showRadiusSheet = true;
        _showRadiusBottomSheet();
      } else {
        _showConfirmButton = true;
      }
    });
  }

  void _showRadiusBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24 + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pin_drop, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Set Search Radius', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Radius: ${_radius.round()} km',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.orangeAccent,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.orange,
                      overlayColor: Colors.orange.withOpacity(0.2),
                      valueIndicatorColor: Colors.orange,
                      trackHeight: 4.0,
                    ),
                    child: Slider(
                      value: _radius,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '${_radius.round()} km',
                      onChanged: (v) => setState(() => _radius = v),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Confirm', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(this.context).pop({'location': _pickedLocation, 'radius': _radius});
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_mapCenter == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Pick Location')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Pick Location')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _mapCenter!,
              zoom: 11,
            ),
            onTap: _onPinDropped,
            myLocationEnabled: false, // Disable My Location layer to prevent permission errors
            myLocationButtonEnabled: false, // Disable My Location button
            markers: _pickedLocation == null
                ? {}
                : {
                    Marker(
                      markerId: MarkerId('picked'),
                      position: _pickedLocation!,
                    ),
                  },
          ),
          // Current location button
          Positioned(
            bottom: 32,
            left: 24,
            child: FloatingActionButton(
              heroTag: "location_button",
              backgroundColor: Colors.green,
              child: Icon(Icons.my_location, color: Colors.white),
              onPressed: () async {
                final hasPermission = await LocationPermissionHelper.requestLocationPermission(context);
                if (hasPermission) {
                  _getCurrentLocationInBackground();
                }
              },
            ),
          ),
          // Confirm button
          if (_showConfirmButton && _pickedLocation != null)
            Positioned(
              bottom: 32,
              right: 24,
              child: FloatingActionButton(
                heroTag: "confirm_button",
                backgroundColor: Colors.blue,
                child: Icon(Icons.check, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop(_pickedLocation);
                },
              ),
            ),
        ],
      ),
    );
  }
}