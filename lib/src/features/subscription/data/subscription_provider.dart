import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'subscription_service.dart';
import '../domain/subscription_models.dart';

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Provides a way to trigger confetti globally
final showConfettiProvider = StateProvider<bool>((ref) => false);

final subscriptionServiceProvider = Provider((ref) => SubscriptionService());

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionStatus?>((ref) {
  return SubscriptionNotifier(ref.watch(subscriptionServiceProvider), ref);
});

class SubscriptionNotifier extends StateNotifier<SubscriptionStatus?> {
  final SubscriptionService _service;
  final StateNotifierProviderRef<SubscriptionNotifier, SubscriptionStatus?>
      _ref;
  RealtimeChannel? _subscriptionChannel;

  SubscriptionNotifier(this._service, this._ref) : super(null) {
    _init();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings);
  }

  Future<void> _init() async {
    await _initNotifications();
    // Load from cache first
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_subscription_status');
    if (cached != null) {
      try {
        state = SubscriptionStatus.fromJson(json.decode(cached));
      } catch (_) {}
    }

    await refresh();
    _setupRealtime();
  }

  Future<void> refresh() async {
    final oldStatus = state;
    final status = await _service.getCurrentSubscription();
    if (status != null) {
      // Check if it just became active
      if (oldStatus != null &&
          !oldStatus.isActive &&
          status.isActive &&
          (status.plan != 'free')) {
        _ref.read(showConfettiProvider.notifier).state = true;
        _showNotification();
      }

      state = status;
      // Cache it
      final prefs = await SharedPreferences.getInstance();
      prefs.setString(
          'cached_subscription_status',
          json.encode({
            'plan': status.plan,
            'current_status': status.currentStatus,
            'days_remaining': status.daysRemaining,
            'is_active': status.isActive,
          }));
    }
  }

  void _setupRealtime() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _subscriptionChannel = Supabase.instance.client
        .channel('public:subscriptions')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'subscriptions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            refresh();
          },
        )
        .subscribe();
  }

  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('subscription_channel', 'إشعارات الاشتراكات',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false);
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'تم التفعيل! 🎉',
      body: 'تم تفعيل اشتراكك بنجاح، شكراً لثقتك بنا.',
      notificationDetails: platformChannelSpecifics,
    );
  }

  @override
  void dispose() {
    _subscriptionChannel?.unsubscribe();
    super.dispose();
  }
}

final paymentConfigProvider = FutureProvider<PaymentConfig>((ref) {
  return ref.watch(subscriptionServiceProvider).getPaymentConfig();
});
