import 'dart:convert';
import 'package:http/http.dart' as http;

class MapTilerAutocompleteService {
  static const String _baseUrl = 'https://api.maptiler.com';
  static const String _apiKey = 'Mq1K53RfqESaSH8vOTy1'; // Replace with your actual API key
  
  String? _sessionToken;
  DateTime? _sessionExpiry;
  
  // Session management
  void _ensureValidSession() {
    if (_sessionToken == null || _sessionExpiry == null || DateTime.now().isAfter(_sessionExpiry!)) {
      _sessionToken = _generateSessionToken();
      _sessionExpiry = DateTime.now().add(const Duration(hours: 1)); // Sessions typically last 1 hour
    }
  }
  
  String _generateSessionToken() {
    // Generate a simple session token (you might want to use a more sophisticated approach)
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  Future<List<AutocompleteResult>> searchPlaces(String query, {String? country, String? language}) async {
    if (query.trim().isEmpty) {
      return [];
    }
    
    _ensureValidSession();
    
    try {
      final queryParams = {
        'key': _apiKey,
        'q': query.trim(),
        'session_token': _sessionToken!,
        'limit': '10',
        'autocomplete': 'true',
        'language': language ?? 'en',
      };
      
      if (country != null) {
        queryParams['country'] = country;
      }
      
      final uri = Uri.parse('$_baseUrl/geocoding/${Uri.encodeComponent(query.trim())}.json').replace(queryParameters: queryParams);
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>? ?? [];
        
        return features.map((feature) {
          final properties = feature['properties'] as Map<String, dynamic>? ?? {};
          final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
          final coordinates = geometry['coordinates'] as List<dynamic>? ?? [];
          
          return AutocompleteResult(
            id: feature['id']?.toString() ?? '',
            name: feature['text']?.toString() ?? '',
            address: properties['address']?.toString() ?? '',
            city: properties['city']?.toString() ?? '',
            state: properties['state']?.toString() ?? '',
            country: properties['country']?.toString() ?? '',
            postcode: properties['postcode']?.toString() ?? '',
            formattedAddress: feature['place_name']?.toString() ?? '',
            latitude: coordinates.isNotEmpty ? (coordinates[1] as num?)?.toDouble() : null,
            longitude: coordinates.isNotEmpty ? (coordinates[0] as num?)?.toDouble() : null,
            type: properties['type']?.toString() ?? '',
            relevance: (feature['relevance'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();
      } else {
        throw Exception('Failed to load places: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching places: $e');
    }
  }
  
  // Clear session when needed
  void clearSession() {
    _sessionToken = null;
    _sessionExpiry = null;
  }
  
  // Public method to start a new session (for autocomplete session grouping)
  void startNewSession() {
    _sessionToken = _generateSessionToken();
    _sessionExpiry = DateTime.now().add(const Duration(hours: 1));
  }
}

class AutocompleteResult {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String country;
  final String postcode;
  final String formattedAddress;
  final double? latitude;
  final double? longitude;
  final String type;
  final double relevance;
  
  AutocompleteResult({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.postcode,
    required this.formattedAddress,
    this.latitude,
    this.longitude,
    required this.type,
    required this.relevance,
  });
  
  // Get a display name for the UI
  String get displayName {
    if (formattedAddress.isNotEmpty) {
      return formattedAddress;
    }
    
    final parts = <String>[];
    if (name.isNotEmpty) parts.add(name);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (country.isNotEmpty) parts.add(country);
    
    return parts.join(', ');
  }
  
  // Get a short display name
  String get shortDisplayName {
    if (name.isNotEmpty && city.isNotEmpty) {
      return '$name, $city';
    }
    return displayName;
  }
  
  @override
  String toString() {
    return 'AutocompleteResult(id: $id, name: $name, formattedAddress: $formattedAddress)';
  }
} 