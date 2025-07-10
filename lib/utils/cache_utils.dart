import '../services/search_cache_service.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_storage_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CacheUtils {
  static final SearchCacheService _cacheService = SearchCacheService();
  
  /// Invalidate cache when new room is added
  static Future<void> invalidateRoomCache() async {
    await _cacheService.invalidateCacheOnNewData('room');
  }
  
  /// Invalidate cache when new hostel is added
  static Future<void> invalidateHostelCache() async {
    await _cacheService.invalidateCacheOnNewData('hostel');
  }
  
  /// Invalidate cache when new service is added
  static Future<void> invalidateServiceCache() async {
    await _cacheService.invalidateCacheOnNewData('service');
  }
  
  /// Invalidate cache when new flatmate request is added
  static Future<void> invalidateFlatmateCache() async {
    await _cacheService.invalidateCacheOnNewData('flatmate');
  }
  
  /// Clear all caches (useful for logout or app reset)
  static Future<void> clearAllCaches() async {
    await _cacheService.clearAllCaches();
  }
  
  /// Get cache service instance for direct access
  static SearchCacheService get cacheService => _cacheService;
  
  /// Validate and fix image URLs for flatmate photos
  static String? validateImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }
    
    // Check if URL is valid
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      print('Invalid image URL format: $imageUrl');
      return null;
    }
    
    // Check for common Firebase Storage URL patterns
    if (imageUrl.contains('firebasestorage.googleapis.com')) {
      // Ensure proper Firebase Storage URL format
      if (!imageUrl.contains('alt=media')) {
        // Add alt=media parameter for Firebase Storage URLs
        final separator = imageUrl.contains('?') ? '&' : '?';
        imageUrl = '$imageUrl${separator}alt=media';
        print('Fixed Firebase Storage URL: $imageUrl');
      }
    }
    
    return imageUrl;
  }
  
  /// Check if an image URL is accessible and valid
  static Future<bool> isImageUrlAccessible(String imageUrl) async {
    try {
      print('Checking image accessibility: $imageUrl');
      
      // For Firebase Storage URLs, check if the file exists first
      if (imageUrl.contains('firebasestorage.googleapis.com')) {
        try {
          // Try to get metadata to check if file exists
          final ref = FirebaseStorage.instance.refFromURL(imageUrl);
          await ref.getMetadata();
          print('Firebase Storage file exists');
          return true;
        } catch (e) {
          print('Firebase Storage file not found or inaccessible: $e');
          return false;
        }
      }
      
      // For other URLs, use HTTP HEAD request
      final response = await http.head(Uri.parse(imageUrl));
      
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.startsWith('image/')) {
          print('Image URL is accessible and valid');
          return true;
        } else {
          print('URL is accessible but not an image: $contentType');
          return false;
        }
      } else {
        print('Image URL not accessible: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error checking image accessibility: $e');
      return false;
    }
  }
  
  /// Clean up corrupted images from flatmate requests
  static Future<void> cleanupCorruptedFlatmateImages() async {
    try {
      print('Starting cleanup of corrupted flatmate images...');
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('roomRequests')
          .where('visibility', isEqualTo: true)
          .get();
      
      int cleanedCount = 0;
      int totalImages = 0;
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final imageUrl = data['profilePhotoUrl'] as String?;
        
        if (imageUrl != null && imageUrl.isNotEmpty) {
          totalImages++;
          print('Checking image ${totalImages}: $imageUrl');
          
          final isValid = await isImageUrlAccessible(imageUrl);
          if (!isValid) {
            print('Found corrupted/missing image in document ${doc.id}: $imageUrl');
            
            // Remove the corrupted image URL
            await doc.reference.update({
              'profilePhotoUrl': null,
            });
            
            // Try to delete the corrupted file from Firebase Storage
            try {
              await FirebaseStorageService.deleteImage(imageUrl);
              print('Deleted corrupted image from storage: $imageUrl');
            } catch (e) {
              print('Failed to delete corrupted image from storage: $e');
            }
            
            cleanedCount++;
          } else {
            print('Image is valid: $imageUrl');
          }
        }
      }
      
      print('Cleanup completed. Checked $totalImages images, removed $cleanedCount corrupted images.');
      
      // Invalidate cache to ensure fresh data
      await invalidateFlatmateCache();
      
    } catch (e) {
      print('Error during image cleanup: $e');
    }
  }
  
  /// Force cleanup all flatmate images (use with caution)
  static Future<void> forceCleanupAllFlatmateImages() async {
    try {
      print('Starting FORCE cleanup of ALL flatmate images...');
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('roomRequests')
          .where('visibility', isEqualTo: true)
          .get();
      
      int cleanedCount = 0;
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final imageUrl = data['profilePhotoUrl'] as String?;
        
        if (imageUrl != null && imageUrl.isNotEmpty) {
          print('Removing image from document ${doc.id}: $imageUrl');
          
          // Remove the image URL
          await doc.reference.update({
            'profilePhotoUrl': null,
          });
          
          // Try to delete the file from Firebase Storage
          try {
            await FirebaseStorageService.deleteImage(imageUrl);
            print('Deleted image from storage: $imageUrl');
          } catch (e) {
            print('Failed to delete image from storage: $e');
          }
          
          cleanedCount++;
        }
      }
      
      print('Force cleanup completed. Removed $cleanedCount images.');
      
      // Invalidate cache to ensure fresh data
      await invalidateFlatmateCache();
      
    } catch (e) {
      print('Error during force cleanup: $e');
    }
  }
  
  /// Mark an image as inaccessible to avoid repeated checks
  static void markImageAsInaccessible(String imageUrl) {
    print('Marking image as inaccessible: $imageUrl');
    // This could be extended to cache the result in memory or local storage
    // For now, just log it for debugging purposes
  }
} 