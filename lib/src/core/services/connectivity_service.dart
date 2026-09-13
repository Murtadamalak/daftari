import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// خدمة مراقبة حالة الاتصال بالإنترنت.
///
/// تُوفر:
/// - [isOnline]: هل الجهاز متصل حالياً بإنترنت حقيقي
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
  bool get isOnline => kIsWeb ? true : _isOnline;

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
      (results) async {
        final wasOnline = _isOnline;
        final hasAdapter = results.any((r) => r != ConnectivityResult.none);

        if (!hasAdapter) {
          _isOnline = false;
        } else {
          // تحقق من الإنترنت الحقيقي وليس فقط الشبكة المحلية
          _isOnline = await _pingInternet();
        }

        if (wasOnline != _isOnline) {
          debugPrint(
              '[Connectivity] Status changed: ${_isOnline ? "ONLINE ✓" : "OFFLINE ✗"}');
          _controller.add(_isOnline);
        }
      },
      onError: (Object? e) {
        debugPrint('[Connectivity] Error: $e');
      },
    );
  }

  /// فحص يدوي لحالة الاتصال
  Future<bool> checkConnection() async {
    if (kIsWeb) return true;
    try {
      final results = await _connectivity.checkConnectivity();
      final hasAdapter = results.any((r) => r != ConnectivityResult.none);
      if (!hasAdapter) {
        _isOnline = false;
        return false;
      }
      // تحقق من الإنترنت الحقيقي
      _isOnline = await _pingInternet();
    } catch (e) {
      debugPrint('[Connectivity] Check failed: $e');
      _isOnline = false;
    }
    return _isOnline;
  }

  /// ping حقيقي للتحقق من الإنترنت
  Future<bool> _pingInternet() async {
    try {
      final result = await InternetAddress.lookup('supabase.co')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// يُستدعى عند حصول SocketException أثناء طلب شبكي
  /// لتحديث حالة الاتصال فوراً
  void reportNetworkFailure() {
    if (_isOnline) {
      debugPrint('[Connectivity] Network failure reported — marking OFFLINE');
      _isOnline = false;
      _controller.add(false);
      // إعادة فحص بعد 5 ثوانٍ
      Future.delayed(const Duration(seconds: 5), checkConnection);
    }
  }

  /// تنظيف الموارد
  void dispose() {
    _subscription?.cancel();
    _controller.close();
    _initialized = false;
    _instance = null;
  }
}
