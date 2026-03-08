import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  await initializeDateFormatting('en', null);

  await Supabase.initialize(
    url: 'https://imzpnabhpaihvisazhay.supabase.co',
    anonKey: 'sb_publishable_XZjwycMZHs1ci-GItcb8gQ_NSbnyiEj',
  );

  // Check if user opted out of "remember me" — if so, sign them out on cold start.
  // This runs once before the app UI is built.
  final prefs = await SharedPreferences.getInstance();
  final rememberMe = prefs.getBool('rememberMe') ?? false;
  if (!rememberMe) {
    // Sign out silently if there's a persisted session but user didn't want it
    final existingSession = Supabase.instance.client.auth.currentSession;
    if (existingSession != null) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  runApp(
    const ProviderScope(
      child: DaftarApp(),
    ),
  );
}
