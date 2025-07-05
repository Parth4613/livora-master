import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchCacheService {
  static const String _cachePrefix = 'search_cache_';
  static const String _cacheTimestampPrefix = 'cache_timestamp_';
  static const Duration _cacheDuration = Duration(minutes: 15); // 15 minutes cache
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache keys for different data types
  static const String _roomsCacheKey = 'rooms';
  static const String _hostelsCacheKey = 'hostels';
  static const String _servicesCacheKey = 'services';
  static const String _flatmatesCacheKey = 'flatmates';
  
  /// Get cached data if available and not expired
  Future<List<Map<String, dynamic>>?> getCachedData(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampKey = _cacheTimestampPrefix + cacheKey;
      final dataKey = _cachePrefix + cacheKey;
      
      // Check if cache exists and is not expired
      final timestamp = prefs.getInt(timestampKey);
      if (timestamp == null) return null;
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > _cacheDuration) {
        // Cache expired, remove it
        await prefs.remove(timestampKey);
        await prefs.remove(dataKey);
        return null;
      }
      
      // Return cached data
      final cachedData = prefs.getString(dataKey);
      if (cachedData != null) {
        final List<dynamic> decoded = jsonDecode(cachedData);
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error reading cache: $e');
    }
    return null;
  }
  
  /// Save data to cache with timestamp
  Future<void> saveToCache(String cacheKey, List<Map<String, dynamic>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampKey = _cacheTimestampPrefix + cacheKey;
      final dataKey = _cachePrefix + cacheKey;
      
      // Save timestamp
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
      
      // Save data
      final encodedData = jsonEncode(data);
      await prefs.setString(dataKey, encodedData);
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }
  
  /// Clear specific cache
  Future<void> clearCache(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampKey = _cacheTimestampPrefix + cacheKey;
      final dataKey = _cachePrefix + cacheKey;
      
      await prefs.remove(timestampKey);
      await prefs.remove(dataKey);
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
  
  /// Clear all caches
  Future<void> clearAllCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_cacheTimestampPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Error clearing all caches: $e');
    }
  }
  
  /// Get rooms with caching
  Future<List<Map<String, dynamic>>> getRoomsWithCache() async {
    // Try cache first
    final cachedData = await getCachedData(_roomsCacheKey);
    if (cachedData != null) {
      print('Using cached rooms data');
      return cachedData;
    }
    
    // Fetch from Firestore if not cached
    print('Fetching rooms from Firestore');
    final data = await _fetchRoomsFromFirestore();
    
    // Cache the result
    await saveToCache(_roomsCacheKey, data);
    
    return data;
  }
  
  /// Get hostels with caching
  Future<List<Map<String, dynamic>>> getHostelsWithCache() async {
    final cachedData = await getCachedData(_hostelsCacheKey);
    if (cachedData != null) {
      print('Using cached hostels data');
      return cachedData;
    }
    
    print('Fetching hostels from Firestore');
    final data = await _fetchHostelsFromFirestore();
    await saveToCache(_hostelsCacheKey, data);
    
    return data;
  }
  
  /// Get services with caching
  Future<List<Map<String, dynamic>>> getServicesWithCache() async {
    final cachedData = await getCachedData(_servicesCacheKey);
    if (cachedData != null) {
      print('Using cached services data');
      return cachedData;
    }
    
    print('Fetching services from Firestore');
    final data = await _fetchServicesFromFirestore();
    await saveToCache(_servicesCacheKey, data);
    
    return data;
  }
  
  /// Get flatmates with caching
  Future<List<Map<String, dynamic>>> getFlatmatesWithCache() async {
    final cachedData = await getCachedData(_flatmatesCacheKey);
    if (cachedData != null) {
      print('Using cached flatmates data');
      return cachedData;
    }
    
    print('Fetching flatmates from Firestore');
    final data = await _fetchFlatmatesFromFirestore();
    await saveToCache(_flatmatesCacheKey, data);
    
    return data;
  }
  
  /// Invalidate cache when new data is added
  Future<void> invalidateCacheOnNewData(String dataType) async {
    switch (dataType.toLowerCase()) {
      case 'room':
        await clearCache(_roomsCacheKey);
        break;
      case 'hostel':
        await clearCache(_hostelsCacheKey);
        break;
      case 'service':
        await clearCache(_servicesCacheKey);
        break;
      case 'flatmate':
        await clearCache(_flatmatesCacheKey);
        break;
    }
  }
  
  // Private methods to fetch from Firestore
  Future<List<Map<String, dynamic>>> _fetchRoomsFromFirestore() async {
    final now = DateTime.now();
    final query = _firestore
        .collection('room_listings')
        .where('visibility', isEqualTo: true);
    final querySnapshot = await query.get();
    
    final List<Map<String, dynamic>> loadedRooms = [];
    final batch = _firestore.batch();
    
    for (var doc in querySnapshot.docs) {
      final room = doc.data();
      DateTime? expiryDate;
      
      if (room['expiryDate'] != null) {
        if (room['expiryDate'] is Timestamp) {
          expiryDate = (room['expiryDate'] as Timestamp).toDate();
        } else if (room['expiryDate'] is String) {
          expiryDate = DateTime.tryParse(room['expiryDate']);
        }
      }
      
      if (expiryDate != null && expiryDate.isBefore(now)) {
        batch.update(doc.reference, {'visibility': false});
        continue;
      }
      
      if (expiryDate != null && expiryDate.isAfter(now)) {
        room['id'] = doc.id;
        room['key'] = doc.id;
        loadedRooms.add(room);
      }
    }
    
    await batch.commit();
    
    // Sort by creation date
    loadedRooms.sort((a, b) {
      var aTime = a['createdAt'];
      var bTime = b['createdAt'];
      
      if (aTime is Timestamp) aTime = aTime.toDate();
      if (bTime is Timestamp) bTime = bTime.toDate();
      if (aTime is String) aTime = DateTime.tryParse(aTime);
      if (bTime is String) bTime = DateTime.tryParse(bTime);
      
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      
      return bTime.compareTo(aTime);
    });
    
    return loadedRooms;
  }
  
  Future<List<Map<String, dynamic>>> _fetchHostelsFromFirestore() async {
    final now = DateTime.now();
    final query = _firestore
        .collection('hostel_listings')
        .where('visibility', isEqualTo: true);
    final querySnapshot = await query.get();
    
    final List<Map<String, dynamic>> loadedHostels = [];
    final batch = _firestore.batch();
    
    for (var doc in querySnapshot.docs) {
      final v = doc.data();
      DateTime? expiryDate;
      
      if (v['expiryDate'] != null) {
        if (v['expiryDate'] is Timestamp) {
          expiryDate = (v['expiryDate'] as Timestamp).toDate();
        } else if (v['expiryDate'] is String) {
          expiryDate = DateTime.tryParse(v['expiryDate']);
        }
      }
      
      if (expiryDate != null && expiryDate.isBefore(now)) {
        batch.update(doc.reference, {'visibility': false});
        continue;
      }
      
      if (v['visibility'] == true) {
        loadedHostels.add({
          ...v,
          'key': doc.id,
          'location': v['address'] ?? '',
          'type': v['hostelType'] ?? '',
          'amenities': v['facilities'] ?? [],
          'imageUrl': _extractHostelImageUrl(v['uploadedPhotos']),
          'createdAt': v['createdAt'] ?? '',
        });
      }
    }
    
    await batch.commit();
    
    // Sort by creation date
    loadedHostels.sort((a, b) {
      var aTime = a['createdAt'];
      var bTime = b['createdAt'];
      
      if (aTime is Timestamp) aTime = aTime.toDate();
      if (bTime is Timestamp) bTime = bTime.toDate();
      if (aTime is String) aTime = DateTime.tryParse(aTime);
      if (bTime is String) bTime = DateTime.tryParse(bTime);
      
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      
      return bTime.compareTo(aTime);
    });
    
    return loadedHostels;
  }
  
  Future<List<Map<String, dynamic>>> _fetchServicesFromFirestore() async {
    final now = DateTime.now();
    final query = _firestore
        .collection('service_listings')
        .where('visibility', isEqualTo: true);
    final querySnapshot = await query.get();
    
    final List<Map<String, dynamic>> loaded = [];
    final batch = _firestore.batch();
    
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      DateTime? expiryDate;
      
      if (data['expiryDate'] != null) {
        if (data['expiryDate'] is Timestamp) {
          expiryDate = (data['expiryDate'] as Timestamp).toDate();
        } else if (data['expiryDate'] is String) {
          expiryDate = DateTime.tryParse(data['expiryDate']);
        }
      }
      
      if (expiryDate != null && expiryDate.isBefore(now)) {
        batch.update(doc.reference, {'visibility': false});
        continue;
      }
      
      if (expiryDate != null && expiryDate.isAfter(now)) {
        data['key'] = doc.id;
        data['imageUrl'] = data['coverPhoto'] ??
            (data['additionalPhotos'] is List &&
                    (data['additionalPhotos'] as List).isNotEmpty
                ? data['additionalPhotos'][0]
                : (data['imageUrl'] ?? ''));
        loaded.add(data);
      }
    }
    
    await batch.commit();
    
    // Sort by creation date
    loaded.sort((a, b) {
      var aTime = a['createdAt'];
      var bTime = b['createdAt'];
      
      if (aTime is Timestamp) aTime = aTime.toDate();
      if (bTime is Timestamp) bTime = bTime.toDate();
      if (aTime is String) aTime = DateTime.tryParse(aTime);
      if (bTime is String) bTime = DateTime.tryParse(bTime);
      
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    
    return loaded;
  }
  
  Future<List<Map<String, dynamic>>> _fetchFlatmatesFromFirestore() async {
    final now = DateTime.now();
    final query = _firestore
        .collection('roomRequests')
        .where('visibility', isEqualTo: true);
    final querySnapshot = await query.get();
    
    final List<Map<String, dynamic>> loaded = [];
    final batch = _firestore.batch();
    
    for (var doc in querySnapshot.docs) {
      final flatmate = doc.data();
      DateTime? expiryDate;
      
      if (flatmate['expiryDate'] != null) {
        if (flatmate['expiryDate'] is Timestamp) {
          expiryDate = (flatmate['expiryDate'] as Timestamp).toDate();
        } else if (flatmate['expiryDate'] is String) {
          expiryDate = DateTime.tryParse(flatmate['expiryDate']);
        }
      }
      
      if (expiryDate != null && expiryDate.isBefore(now)) {
        batch.update(doc.reference, {'visibility': false});
        continue;
      }
      
      if (flatmate['visibility'] == true) {
        flatmate['key'] = doc.id;
        loaded.add(flatmate);
      }
    }
    
    await batch.commit();
    
    // Sort by creation date
    loaded.sort((a, b) {
      var aTime = a['createdAt'];
      var bTime = b['createdAt'];
      
      if (aTime is Timestamp) aTime = aTime.toDate();
      if (bTime is Timestamp) bTime = bTime.toDate();
      if (aTime is String) aTime = DateTime.tryParse(aTime);
      if (bTime is String) bTime = DateTime.tryParse(bTime);
      
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      
      return bTime.compareTo(aTime);
    });
    
    return loaded;
  }
  
  String _extractHostelImageUrl(dynamic uploadedPhotos) {
    if (uploadedPhotos is Map) {
      if (uploadedPhotos.containsKey('Building Front')) {
        return uploadedPhotos['Building Front'].toString();
      }
      if (uploadedPhotos.isNotEmpty) {
        return uploadedPhotos.values.first.toString();
      }
    }
    if (uploadedPhotos is List && uploadedPhotos.isNotEmpty) {
      return uploadedPhotos[0].toString();
    }
    return '';
  }
} 