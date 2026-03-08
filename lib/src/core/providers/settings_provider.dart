import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Keys
// ─────────────────────────────────────────────────────────────────────────────

class _Keys {
  static String get _uid => Supabase.instance.client.auth.currentUser?.id ?? '';
  static String get shopName => '${_uid}_pref_shop_name';
  static String get shopPhone => '${_uid}_pref_shop_phone';
  static String get logoPath => '${_uid}_pref_logo_path';
  static String get themeMode =>
      '${_uid}_pref_theme_mode'; // 0=system,1=light,2=dark
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class AppSettings {
  const AppSettings({
    this.shopName = 'دفتر',
    this.shopPhone = '',
    this.logoPath,
    this.themeMode = ThemeMode.system,
  });

  final String shopName;
  final String shopPhone;
  final String? logoPath;
  final ThemeMode themeMode;

  AppSettings copyWith({
    String? shopName,
    String? shopPhone,
    String? logoPath,
    bool clearLogo = false,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      shopName: shopName ?? this.shopName,
      shopPhone: shopPhone ?? this.shopPhone,
      logoPath: clearLogo ? null : (logoPath ?? this.logoPath),
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  late SharedPreferences _prefs;

  @override
  Future<AppSettings> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _load();
  }

  AppSettings _load() {
    final modeIdx = _prefs.getInt(_Keys.themeMode) ?? 0;
    return AppSettings(
      shopName: _prefs.getString(_Keys.shopName) ?? 'دفتر',
      shopPhone: _prefs.getString(_Keys.shopPhone) ?? '',
      logoPath: _prefs.getString(_Keys.logoPath),
      themeMode: ThemeMode.values[modeIdx.clamp(0, 2)],
    );
  }

  Future<void> setShopName(String v) async {
    await _prefs.setString(_Keys.shopName, v.trim());
    state = AsyncData(state.requireValue.copyWith(shopName: v.trim()));
  }

  Future<void> setShopPhone(String v) async {
    await _prefs.setString(_Keys.shopPhone, v.trim());
    state = AsyncData(state.requireValue.copyWith(shopPhone: v.trim()));
  }

  Future<void> setLogoPath(String? path) async {
    if (path == null) {
      await _prefs.remove(_Keys.logoPath);
      state = AsyncData(state.requireValue.copyWith(clearLogo: true));
    } else {
      await _prefs.setString(_Keys.logoPath, path);
      state = AsyncData(state.requireValue.copyWith(logoPath: path));
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setInt(_Keys.themeMode, mode.index);
    state = AsyncData(state.requireValue.copyWith(themeMode: mode));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// Convenience: just the ThemeMode (watched by MaterialApp).
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).whenOrNull(data: (s) => s.themeMode) ??
      ThemeMode.system;
});
