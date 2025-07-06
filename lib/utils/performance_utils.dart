// utils/performance_utils.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerformanceUtils {
  // تحسين الأداء - تخزين مؤقت للبيانات
  static final Map<String, dynamic> _memoryCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _defaultCacheDuration = Duration(minutes: 5);

  // تحسين الأداء - حفظ البيانات في التخزين المؤقت
  static void setCachedData(String key, dynamic data, {Duration? duration}) {
    _memoryCache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    
    // حفظ في التخزين المحلي للبيانات المهمة
    if (key.startsWith('important_')) {
      _saveToLocalStorage(key, data);
    }
  }

  // تحسين الأداء - استرجاع البيانات من التخزين المؤقت
  static dynamic getCachedData(String key, {Duration? duration}) {
    final cacheDuration = duration ?? _defaultCacheDuration;
    final timestamp = _cacheTimestamps[key];
    
    if (timestamp != null && DateTime.now().difference(timestamp) < cacheDuration) {
      return _memoryCache[key];
    }
    
    return null;
  }

  // تحسين الأداء - استرجاع البيانات من التخزين المحلي (async)
  static Future<dynamic> getCachedDataAsync(String key, {Duration? duration}) async {
    final cacheDuration = duration ?? _defaultCacheDuration;
    final timestamp = _cacheTimestamps[key];
    
    if (timestamp != null && DateTime.now().difference(timestamp) < cacheDuration) {
      return _memoryCache[key];
    }
    
    // محاولة استرجاع من التخزين المحلي
    if (key.startsWith('important_')) {
      return await _getFromLocalStorage(key);
    }
    
    return null;
  }

  // تحسين الأداء - مسح التخزين المؤقت
  static void clearCache() {
    _memoryCache.clear();
    _cacheTimestamps.clear();
  }

  // تحسين الأداء - مسح البيانات القديمة
  static void cleanOldCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _defaultCacheDuration) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  // تحسين الأداء - حفظ في التخزين المحلي
  static Future<void> _saveToLocalStorage(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (data is String) {
        await prefs.setString(key, data);
      } else if (data is int) {
        await prefs.setInt(key, data);
      } else if (data is bool) {
        await prefs.setBool(key, data);
      } else if (data is double) {
        await prefs.setDouble(key, data);
      } else if (data is List<String>) {
        await prefs.setStringList(key, data);
      }
    } catch (e) {
      debugPrint('Error saving to local storage: $e');
    }
  }

  // تحسين الأداء - استرجاع من التخزين المحلي
  static Future<dynamic> _getFromLocalStorage(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.get(key);
    } catch (e) {
      debugPrint('Error getting from local storage: $e');
      return null;
    }
  }

  // تحسين الأداء - تحسين الصور
  static String optimizeImageUrl(String url, {int width = 400, int height = 400, int quality = 80}) {
    if (url.isEmpty) return url;
    
    if (url.contains('unsplash.com')) {
      final separator = url.contains('?') ? '&' : '?';
      return '$url${separator}w=$width&h=$height&fit=crop&q=$quality';
    }
    return url;
  }

  // تحسين الأداء - تقليل استهلاك الذاكرة
  static void disposeResources() {
    clearCache();
    cleanOldCache();
  }

  // تحسين الأداء - فحص الاتصال بالإنترنت
  static bool isNetworkAvailable() {
    // يمكن إضافة منطق فحص الاتصال هنا
    return true;
  }

  // تحسين الأداء - إعدادات التطبيق
  static Map<String, dynamic> getAppSettings() {
    return {
      'imageCacheSize': 50 * 1024 * 1024, // 50MB
      'maxImageWidth': 800,
      'maxImageHeight': 800,
      'imageQuality': 70,
      'cacheDuration': _defaultCacheDuration.inMinutes,
      'enableOfflineMode': true,
    };
  }

  // تحسين الأداء - الحصول على حجم الكاش
  static int get cacheSize => _memoryCache.length;

  // تحسين الأداء - التحقق من وجود مفتاح في الكاش
  static bool hasKey(String key) {
    final timestamp = _cacheTimestamps[key];
    return timestamp != null && DateTime.now().difference(timestamp) < _defaultCacheDuration;
  }
}

// تحسين الأداء - مزيج للتحكم في الأداء
mixin PerformanceMixin {
  bool _isDisposed = false;
  
  bool get isDisposed => _isDisposed;
  
  void dispose() {
    _isDisposed = true;
  }
  
  // تحسين الأداء - التحقق من حالة الـ widget
  bool get isMounted => !_isDisposed;
  
  // تحسين الأداء - setState آمن
  void safeSetState(VoidCallback fn) {
    if (isMounted) {
      fn();
    }
  }
}

// تحسين الأداء - مدير التخزين المؤقت للصور
class ImageCacheManager {
  static final Map<String, String> _imageCache = {};
  static final Map<String, DateTime> _imageTimestamps = {};
  static const Duration _imageCacheDuration = Duration(hours: 1);
  
  static void cacheImage(String key, String url) {
    if (key.isNotEmpty && url.isNotEmpty) {
      _imageCache[key] = url;
      _imageTimestamps[key] = DateTime.now();
    }
  }
  
  static String? getCachedImage(String key) {
    if (key.isEmpty) return null;
    
    final timestamp = _imageTimestamps[key];
    if (timestamp != null && DateTime.now().difference(timestamp) < _imageCacheDuration) {
      return _imageCache[key];
    }
    return null;
  }
  
  static void clearImageCache() {
    _imageCache.clear();
    _imageTimestamps.clear();
  }
  
  static void removeExpiredImages() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    for (final entry in _imageTimestamps.entries) {
      if (now.difference(entry.value) > _imageCacheDuration) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _imageCache.remove(key);
      _imageTimestamps.remove(key);
    }
  }
  
  static int get cacheSize => _imageCache.length;
  
  static bool hasImage(String key) {
    if (key.isEmpty) return false;
    
    final timestamp = _imageTimestamps[key];
    return timestamp != null && DateTime.now().difference(timestamp) < _imageCacheDuration;
  }

  static void removeImage(String key) {
    if (key.isNotEmpty) {
      _imageCache.remove(key);
      _imageTimestamps.remove(key);
    }
  }
} 