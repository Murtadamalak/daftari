import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/core/services/connectivity_service.dart';
import 'src/core/services/sync_service.dart';
import 'src/data/local/offline_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('ar', null);
    await initializeDateFormatting('en', null);
  } catch (e) {
    debugPrint('DateFormatting error: $e');
  }

  try {
    await Supabase.initialize(
      url: 'https://imzpnabhpaihvisazhay.supabase.co',
      anonKey: 'sb_publishable_XZjwycMZHs1ci-GItcb8gQ_NSbnyiEj',
    );
  } catch (e) {
    debugPrint('Supabase initialize error: $e');
  }

  // ── تهيئة قاعدة البيانات المحلية (للأجهزة المحمولة وسطح المكتب) ──
  if (!kIsWeb) {
    try {
      await OfflineDatabase.instance.database;
    } catch (e) {
      debugPrint('Offline database error: $e');
    }
  }

  // ── تهيئة خدمة مراقبة الاتصال ──
  try {
    await ConnectivityService.instance.initialize();
  } catch (e) {
    debugPrint('Connectivity service error: $e');
  }

  // Check if user opted out of "remember me" — if so, sign them out on cold start.
  try {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('rememberMe') ?? false;
    if (!rememberMe) {
      final existingSession = Supabase.instance.client.auth.currentSession;
      if (existingSession != null) {
        await Supabase.instance.client.auth.signOut();
      }
    }
  } catch (e) {
    debugPrint('Session check error: $e');
  }

  // ── تهيئة محرك المزامنة (بعد التحقق من المستخدم) ──
  if (!kIsWeb) {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        await SyncService.instance.initialize();
      }
    } catch (e) {
      debugPrint('Sync service error: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: DaftarApp(),
    ),
  );
}
