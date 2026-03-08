import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(
          () => _errorMessage = 'يرجى إدخال البريد الإلكتروني وكلمة المرور');
      return;
    }

    if (!_isLogin &&
        (_fullNameController.text.isEmpty || _phoneController.text.isEmpty)) {
      setState(() => _errorMessage = 'يرجى إكمال جميع الحقول');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', _rememberMe);

      if (_isLogin) {
        await ref.read(authProvider.notifier).login(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
      } else {
        await ref.read(authProvider.notifier).signUp(
              _emailController.text.trim(),
              _passwordController.text.trim(),
              _fullNameController.text.trim(),
              _shopNameController.text.trim(),
              _phoneController.text.trim(),
            );
      }
    } catch (e) {
      String errorText = 'حدث خطأ غير معروف، يرجى المحاولة لاحقاً.';
      final eStr = e.toString().toLowerCase();

      if (eStr.contains('invalid login credentials')) {
        errorText = 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      } else if (eStr.contains('email not confirmed') ||
          eStr.contains('email_not_confirmed')) {
        errorText = 'البريد الإلكتروني غير مؤكد.';
      } else if (eStr.contains('weak_password') ||
          eStr.contains('password should be at least')) {
        errorText = 'كلمة المرور ضعيفة. يجب أن لا تقل عن 6 أحرف.';
      } else if (eStr.contains('user_already_exists') ||
          eStr.contains('already registered')) {
        errorText = 'هذا البريد الإلكتروني مسجل مسبقاً.';
      } else if (eStr.contains('invalid_email') ||
          eStr.contains('invalid email')) {
        errorText = 'صيغة البريد الإلكتروني غير صحيحة.';
      } else {
        errorText = 'خطأ: ${e.toString()}';
      }

      setState(() => _errorMessage = errorText);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (authState.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      body: Row(
        children: [
          // ── Left Panel (desktop only) ─────────────────────────────────────
          if (MediaQuery.of(context).size.width > 800)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primary,
                      AppColors.primaryLight
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          'د',
                          style: GoogleFonts.cairo(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'دفتري',
                      style: GoogleFonts.cairo(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'نظام إدارة المبيعات والديون',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                    const SizedBox(height: 48),
                    _FeatureRow(
                        Icons.receipt_long_outlined, 'إدارة الفواتير بسهولة'),
                    const SizedBox(height: 14),
                    _FeatureRow(Icons.account_balance_wallet_outlined,
                        'تتبع الديون والمدفوعات'),
                    const SizedBox(height: 14),
                    _FeatureRow(
                        Icons.analytics_outlined, 'تقارير شاملة وتصدير PDF'),
                    const SizedBox(height: 14),
                    _FeatureRow(Icons.devices_outlined, 'ويب وهاتف وكمبيوتر'),
                  ],
                ),
              ),
            ),

          // ── Right Panel — Form ────────────────────────────────────────────
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo (mobile only)
                      if (MediaQuery.of(context).size.width <= 800)
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primaryDark,
                                  AppColors.primaryLight
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Text('د',
                                  style: GoogleFonts.cairo(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white)),
                            ),
                          ),
                        ),
                      if (MediaQuery.of(context).size.width <= 800)
                        const SizedBox(height: 20),

                      // Title
                      Text(
                        _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
                        style: GoogleFonts.cairo(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isLogin
                            ? 'أدخل بياناتك للوصول إلى حسابك'
                            : 'أنشئ حسابك مجاناً وابدأ الآن',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Register fields
                      if (!_isLogin) ...[
                        _buildField(
                          label: 'الاسم الكامل',
                          controller: _fullNameController,
                          icon: Icons.person_outline,
                          isDark: isDark,
                        ),
                        _buildField(
                          label: 'اسم المحل',
                          controller: _shopNameController,
                          icon: Icons.store_outlined,
                          isDark: isDark,
                        ),
                        _buildField(
                          label: 'رقم الهاتف',
                          controller: _phoneController,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          isDark: isDark,
                        ),
                      ],

                      // Common fields
                      _buildField(
                        label: 'البريد الإلكتروني',
                        controller: _emailController,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        isDark: isDark,
                      ),
                      _buildField(
                        label: 'كلمة المرور',
                        controller: _passwordController,
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isDark: isDark,
                      ),

                      // Remember me
                      if (_isLogin)
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5)),
                                side: BorderSide(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.border,
                                    width: 1.5),
                                onChanged: (val) =>
                                    setState(() => _rememberMe = val ?? false),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'تذكرني (البقاء متصلاً)',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),

                      // Error message
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.dangerSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.danger.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.danger, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.cairo(
                                    color: AppColors.danger,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Submit button
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : Text(
                                  _isLogin ? 'دخول' : 'إنشاء الحساب',
                                  style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Toggle login / register
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                            children: [
                              TextSpan(
                                text: _isLogin
                                    ? 'ليس لديك حساب؟ '
                                    : 'لديك حساب؟ ',
                              ),
                              TextSpan(
                                text: _isLogin ? 'سجل الآن' : 'سجل دخول',
                                style: GoogleFonts.cairo(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        keyboardType: keyboardType,
        style: GoogleFonts.cairo(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
        ),
      ),
    );
  }
}

// ─── Feature Row ──────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.cairo(
            color: Colors.white.withOpacity(0.85),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
