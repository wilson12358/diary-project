import 'dart:async';
import 'package:flutter/material.dart';

/// Helper mixin for managing widget lifecycle and preventing setState after dispose
mixin WidgetLifecycleHelper<T extends StatefulWidget> on State<T> {
  /// List to store all stream subscriptions for automatic disposal
  final List<StreamSubscription> _subscriptions = [];
  
  /// Add a stream subscription to be automatically disposed
  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }
  
  /// Safe setState that checks if widget is mounted
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }
  
  /// Listen to a stream with automatic subscription management
  StreamSubscription<T> listenToStream<T>(
    Stream<T> stream, 
    void Function(T) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final subscription = stream.listen(
      (data) {
        if (mounted) {
          onData(data);
        }
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    
    addSubscription(subscription);
    return subscription;
  }
  
  /// Execute async operation with mounted check
  Future<void> safeAsyncOperation(Future<void> Function() operation) async {
    if (!mounted) return;
    
    try {
      await operation();
    } catch (e) {
      if (mounted) {
        debugPrint('Async operation error: $e');
      }
    }
  }
  
  /// Show snackbar only if widget is mounted
  void safeShowSnackBar(String message, {Color? backgroundColor}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
    }
  }
  
  /// Override dispose to automatically cancel all subscriptions
  @override
  void dispose() {
    // Cancel all stream subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    super.dispose();
  }
}

/// Timer helper that automatically cancels on dispose
class SafeTimer {
  Timer? _timer;
  final VoidCallback _onDispose;
  
  SafeTimer(this._onDispose);
  
  /// Start a periodic timer
  void startPeriodic(Duration duration, void Function(Timer) callback) {
    _timer?.cancel();
    _timer = Timer.periodic(duration, callback);
  }
  
  /// Start a one-time timer
  void startOnce(Duration duration, VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(duration, callback);
  }
  
  /// Cancel the timer
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
  
  /// Check if timer is active
  bool get isActive => _timer?.isActive ?? false;
  
  /// Dispose the timer
  void dispose() {
    cancel();
    _onDispose();
  }
}

/// Animation controller helper with automatic disposal
class SafeAnimationController {
  AnimationController? _controller;
  final TickerProvider _vsync;
  final VoidCallback _onDispose;
  
  SafeAnimationController(this._vsync, this._onDispose);
  
  /// Create and return animation controller
  AnimationController create({
    required Duration duration,
    Duration? reverseDuration,
    String? debugLabel,
    double lowerBound = 0.0,
    double upperBound = 1.0,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
  }) {
    _controller?.dispose();
    _controller = AnimationController(
      vsync: _vsync,
      duration: duration,
      reverseDuration: reverseDuration,
      debugLabel: debugLabel,
      lowerBound: lowerBound,
      upperBound: upperBound,
      animationBehavior: animationBehavior,
    );
    return _controller!;
  }
  
  /// Get the current controller
  AnimationController? get controller => _controller;
  
  /// Dispose the controller
  void dispose() {
    _controller?.dispose();
    _controller = null;
    _onDispose();
  }
}

/// Extension on State to provide lifecycle utilities
extension StateLifecycleExtension<T extends StatefulWidget> on State<T> {
  /// Safe setState with mounted check
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }
  
  /// Safe navigation with mounted check
  void safeNavigate(Widget destination) {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => destination),
      );
    }
  }
  
  /// Safe pop with mounted check
  void safePop() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

/// Widget lifecycle debugger
class LifecycleDebugger {
  static bool _enabled = false;
  
  static void enable() {
    _enabled = true;
  }
  
  static void disable() {
    _enabled = false;
  }
  
  static void log(String widgetName, String lifecycle, [String? details]) {
    if (_enabled) {
      print('LIFECYCLE: $widgetName - $lifecycle ${details ?? ''}');
    }
  }
}
