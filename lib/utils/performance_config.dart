import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Performance configuration for the diary app
class PerformanceConfig {
  // Animation durations (in milliseconds)
  static const int fastAnimationDuration = 200;
  static const int normalAnimationDuration = 400;
  static const int slowAnimationDuration = 600;
  
  // Cache settings
  static const int entriesCacheExpiryMinutes = 5;
  static const int userDataCacheExpiryMinutes = 10;
  static const int mediaCacheExpiryMinutes = 30;
  
  // Pagination settings
  static const int defaultPageSize = 20;
  static const int searchPageSize = 50;
  static const int maxSearchResults = 100;
  
  // Debounce settings (in milliseconds)
  static const int searchDebounceMs = 300;
  static const int scrollDebounceMs = 100;
  static const int inputDebounceMs = 500;
  
  // Image optimization
  static const int maxImageWidth = 1024;
  static const int maxImageHeight = 1024;
  static const double imageCompressionQuality = 0.8;
  
  // List optimization
  static const int maxVisibleItems = 10;
  static const int preloadDistance = 5;
  
  // Network optimization
  static const int requestTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  static const int retryDelayMs = 1000;
  
  // Memory optimization
  static const int maxCachedImages = 50;
  static const int maxCachedEntries = 100;
  
  // Performance flags
  static const bool enableImageCaching = true;
  static const bool enableEntryCaching = true;
  static const bool enableLazyLoading = true;
  static const bool enableSmoothScrolling = true;
  static const bool enableAnimationOptimization = true;
  
  // Debug performance settings
  static const bool enablePerformanceLogging = false;
  static const bool enableFrameRateMonitoring = false;
  static const bool enableMemoryMonitoring = false;
}

// Performance monitoring utilities
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<Duration>> _measurements = {};
  
  static void startTimer(String operation) {
    _startTimes[operation] = DateTime.now();
  }
  
  static Duration stopTimer(String operation) {
    final startTime = _startTimes[operation];
    if (startTime == null) return Duration.zero;
    
    final duration = DateTime.now().difference(startTime);
    _startTimes.remove(operation);
    
    if (PerformanceConfig.enablePerformanceLogging) {
      print('Performance: $operation took ${duration.inMilliseconds}ms');
    }
    
    // Store measurement for analysis
    _measurements.putIfAbsent(operation, () => []).add(duration);
    
    return duration;
  }
  
  static double getAverageTime(String operation) {
    final measurements = _measurements[operation];
    if (measurements == null || measurements.isEmpty) return 0.0;
    
    final totalMs = measurements.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
    return totalMs / measurements.length;
  }
  
  static void clearMeasurements() {
    _measurements.clear();
  }
  
  static Map<String, double> getAllAverages() {
    final averages = <String, double>{};
    for (final operation in _measurements.keys) {
      averages[operation] = getAverageTime(operation);
    }
    return averages;
  }
}

// Memory optimization utilities
class MemoryOptimizer {
  static final List<Function> _cleanupTasks = [];
  
  static void addCleanupTask(Function task) {
    _cleanupTasks.add(task);
  }
  
  static void performCleanup() {
    for (final task in _cleanupTasks) {
      try {
        task();
      } catch (e) {
        print('Error during cleanup: $e');
      }
    }
    _cleanupTasks.clear();
  }
  
  static void clearImageCache() {
    // Clear Flutter's image cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
  
  static void clearTextCache() {
    // Clear text layout cache
    // Note: skiaUnrefQueue is not available in newer Flutter versions
    // This method is kept for future implementation
  }
}

// Animation optimization utilities
class AnimationOptimizer {
  static bool _isLowEndDevice = false;
  
  static void detectDeviceCapability() {
    // Simple heuristic for low-end devices
    // In a real app, you might use device info plugin
    _isLowEndDevice = false; // Placeholder
  }
  
  static Duration getOptimizedDuration(int baseDuration) {
    if (_isLowEndDevice) {
      return Duration(milliseconds: (baseDuration * 0.7).round());
    }
    return Duration(milliseconds: baseDuration);
  }
  
  static Curve getOptimizedCurve(Curve baseCurve) {
    if (_isLowEndDevice) {
      return Curves.easeOut; // Simpler curve for low-end devices
    }
    return baseCurve;
  }
  
  static bool shouldEnableAnimations() {
    return !_isLowEndDevice;
  }
}
