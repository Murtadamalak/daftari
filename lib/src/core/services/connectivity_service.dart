import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// خدمة مراقبة حالة الاتصال بالإنترنت.
///
/// تُوفر:
/// - [isOnline]: هل الجهاز متصل حالياً
/// - [onConnectivityChanged]: Stream يُعلم المستمعين عند تغيّر حالة الاتصال
/// - [checkConnection]: فحص يدوي لحالة الاتصال
class ConnectivityService {
  static ConnectivityService? _instance;
  ConnectivityService._();

  static ConnectivityService get instance {
    _instance ??= ConnectivityService._();
    return _instance!;
  }

  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool _initialized = false;

  /// هل الجهاز متصل بالإنترنت حالياً
  bool get isOnline => _isOnline;

  /// إعادة حالة الاتصال كـ Stream
  Stream<bool> get onConnectivityChanged => _controller.stream;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// تهيئة الخدمة ومراقبة التغييرات
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // فحص الحالة المبدئية
    await checkConnection();

    // مراقبة التغييرات
    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        final wasOnline = _isOnline;
        _isOnline = results.any((r) => r != ConnectivityResult.none);

        if (wasOnline != _isOnline) {
          debugPrint(
              '[Connectivity] Status changed: ${_isOnline ? "ONLINE ✓" : "OFFLINE ✗"}');
          _controller.add(_isOnline);
        }
      },
      onError: (e) {
        debugPrint('[Connectivity] Error: $e');
      },
    );
  }

  /// فحص يدوي لحالة الاتصال
  Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = results.any((r) => r != ConnectivityResult.none);
    } catch (e) {
      debugPrint('[Connectivity] Check failed: $e');
      _isOnline = false;
    }
    return _isOnline;
  }

  /// تنظيف الموارد
  void dispose() {
    _subscription?.cancel();
    _controller.close();
    _initialized = false;
    _instance = null;
  }
}
