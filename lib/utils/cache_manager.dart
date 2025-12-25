/// Simple in-memory cache manager for API responses
/// Reduces redundant network calls and improves responsiveness
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final Map<String, _CacheEntry> _cache = {};
  
  /// Get cached data if available and not expired
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    
    return entry.data as T?;
  }
  
  /// Set cache with optional duration (default: 5 minutes)
  void set(String key, dynamic data, {Duration duration = const Duration(minutes: 5)}) {
    _cache[key] = _CacheEntry(
      data: data,
      expiry: DateTime.now().add(duration),
    );
  }
  
  /// Clear specific cache entry
  void clear(String key) {
    _cache.remove(key);
  }
  
  /// Clear all cache
  void clearAll() {
    _cache.clear();
  }
  
  /// Clear expired entries
  void clearExpired() {
    _cache.removeWhere((key, value) => value.isExpired);
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiry;
  
  _CacheEntry({required this.data, required this.expiry});
  
  bool get isExpired => DateTime.now().isAfter(expiry);
}
