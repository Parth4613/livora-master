import '../services/search_cache_service.dart';

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
} 