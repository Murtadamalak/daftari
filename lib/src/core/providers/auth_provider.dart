import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthRole { initial, guest, user, admin }

class AppAuthState {
  final AuthRole role;
  final User? user;
  final String? subStatus; // e.g. 'active', 'pending', 'expired'
  final String? planType; // e.g. 'free', 'monthly', 'yearly'
  final String? endDate; // e.g. '2026-03-06T14:47:10...'
  final String? fullName;
  final String? shopName;
  final String? phone;
  final bool isLoading; // added loading state
  const AppAuthState({
    this.role = AuthRole.initial,
    this.user,
    this.subStatus,
    this.planType,
    this.endDate,
    this.fullName,
    this.shopName,
    this.phone,
    this.isLoading = true,
  });
}

class AuthNotifier extends StateNotifier<AppAuthState> {
  AuthNotifier() : super(const AppAuthState()) {
    _init();
  }

  void _init() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;

      if (user == null) {
        state = const AppAuthState(role: AuthRole.guest, isLoading: false);
      } else {
        try {
          // Fetch is_admin and subscription status in parallel
          final profileFuture = Supabase.instance.client
              .from('profiles')
              .select('is_admin')
              .eq('id', user.id)
              .maybeSingle();

          final subFuture = Supabase.instance.client
              .from('subscriptions')
              .select('status, plan_type, end_date')
              .eq('user_id', user.id)
              .maybeSingle();

          final results = await Future.wait([profileFuture, subFuture]);
          final profileRes = results[0];
          final subRes = results[1];

          final isAdmin = profileRes != null && profileRes['is_admin'] == true;
          final subStatus =
              subRes != null ? subRes['status'] as String? : 'none';
          final planType =
              subRes != null ? subRes['plan_type'] as String? : 'free';
          final endDate = subRes != null ? subRes['end_date'] as String? : null;

          state = AppAuthState(
            role: isAdmin ? AuthRole.admin : AuthRole.user,
            user: user,
            subStatus: subStatus,
            planType: planType,
            endDate: endDate,
            fullName: user.userMetadata?['full_name'] as String?,
            shopName: user.userMetadata?['shop_name'] as String?,
            phone: user.userMetadata?['phone'] as String?,
            isLoading: false,
          );
        } catch (_) {
          state = AppAuthState(
              role: AuthRole.user,
              user: user,
              subStatus: 'error',
              isLoading: false);
        }
      }
    });
  }

  Future<void> login(String email, String password) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp(String email, String password, String fullName,
      String shopName, String phone) async {
    await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'shop_name': shopName,
        'phone': phone,
      },
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rememberMe');
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> updateProfile({
    String? fullName,
    String? shopName,
    String? phone,
  }) async {
    final attributes = UserAttributes(
      data: {
        if (fullName != null) 'full_name': fullName,
        if (shopName != null) 'shop_name': shopName,
        if (phone != null) 'phone': phone,
      },
    );
    await Supabase.instance.client.auth.updateUser(attributes);
    // Refresh state manually or wait for listener
    refreshStatus();
  }

  void refreshStatus() {
    _init(); // Re-run the listener and status check
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  return AuthNotifier();
});
