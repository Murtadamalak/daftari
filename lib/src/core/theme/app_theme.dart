import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens — Daftari Brand Identity with Premium Teal (#098677)
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // ── Primary – Deep Teal (#098677) ──────────────────────────────────────────
  static const primary = Color(0xFF098677); // Premium teal
  static const primaryDark = Color(0xFF065E53); // Darker teal shade
  static const primaryLight = Color(0xFF2EA697); // Lighter teal shade
  static const primarySurface = Color(0xFFE6F3F2); // Faint teal tint

  // ── Accent – Warm Gold ────────────────────────────────────────────────────
  static const accent = Color(0xFFC8962C); // Warm gold
  static const accentSurface = Color(0xFFFDF3DC); // Faint gold

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const success = Color(0xFF16A34A); // Green — debts owed TO you
  static const successSurface = Color(0xFFDCFCE7);
  static const successLight = Color(0xFF4ADE80);

  // ── Neutrals – Light (Elegant modern minty-gray / clean surfaces) ──────────
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF4F7F6); // Soft premium clean mint-gray background
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFE8EEEC); // Light gray-teal variant
  static const border = Color(0xFFD0DCDA); // Premium thin borders
  static const divider = Color(0xFFE4ECEB);

  static const textPrimary = Color(0xFF0A221F); // Dark emerald-grey text
  static const textSecondary = Color(0xFF3F5E5A); // Medium emerald-grey text
  static const textDisabled = Color(0xFF8BA5A1);

  // ── Neutrals – Dark ───────────────────────────────────────────────────────
  static const darkBg = Color(0xFF081210); // Deep, luxurious dark emerald-black
  static const darkSurface = Color(0xFF101D1A); // Dark card surface
  static const darkSurface2 = Color(0xFF162A26); // Elevated dark surface
  static const darkBorder = Color(0xFF1E3C36);
  static const darkDivider = Color(0xFF12221F);

  static const darkTextPrimary = Color(0xFFE6FAF7);
  static const darkTextSecondary = Color(0xFF85AFA7);

  // ── Semantic helpers ──────────────────────────────────────────────────────
  static const danger = Color(0xFFDC2626); // Red — debts you OWE
  static const dangerSurface = Color(0xFFFEE2E2);
  static const dangerLight = Color(0xFFF87171);

  static const warning = Color(0xFFD97706);
  static const warningSurface = Color(0xFFFEF3C7);

  static const info = Color(0xFF1D4ED8);
  static const infoSurface = Color(0xFFDBEAFE);
}

// ─────────────────────────────────────────────────────────────────────────────
// Typography helpers — Using local custom KOMedia-Black font
// ─────────────────────────────────────────────────────────────────────────────

TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
  const family = 'KOMedia';
  return TextTheme(
    displayLarge: TextStyle(fontFamily: family, fontSize: 34, fontWeight: FontWeight.w900, color: primaryColor),
    displayMedium: TextStyle(fontFamily: family, fontSize: 28, fontWeight: FontWeight.w800, color: primaryColor),
    displaySmall: TextStyle(fontFamily: family, fontSize: 24, fontWeight: FontWeight.w700, color: primaryColor),
    headlineLarge: TextStyle(fontFamily: family, fontSize: 22, fontWeight: FontWeight.w800, color: primaryColor),
    headlineMedium: TextStyle(fontFamily: family, fontSize: 20, fontWeight: FontWeight.w700, color: primaryColor),
    headlineSmall: TextStyle(fontFamily: family, fontSize: 18, fontWeight: FontWeight.w700, color: primaryColor),
    titleLarge: TextStyle(fontFamily: family, fontSize: 19, fontWeight: FontWeight.w700, color: primaryColor),
    titleMedium: TextStyle(fontFamily: family, fontSize: 17, fontWeight: FontWeight.w700, color: primaryColor),
    titleSmall: TextStyle(fontFamily: family, fontSize: 15, fontWeight: FontWeight.w600, color: primaryColor),
    bodyLarge: TextStyle(fontFamily: family, fontSize: 17, fontWeight: FontWeight.w500, color: secondaryColor),
    bodyMedium: TextStyle(fontFamily: family, fontSize: 15, fontWeight: FontWeight.w500, color: secondaryColor),
    bodySmall: TextStyle(fontFamily: family, fontSize: 13, fontWeight: FontWeight.w400, color: secondaryColor),
    labelLarge: const TextStyle(fontFamily: family, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.1),
    labelMedium: const TextStyle(fontFamily: family, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
    labelSmall: const TextStyle(fontFamily: family, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.2),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Main AppTheme class
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  // ── Light Theme ───────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    final cs = const ColorScheme.light().copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.primarySurface,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.accent,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.accentSurface,
      error: AppColors.danger,
      onError: AppColors.white,
      errorContainer: AppColors.dangerSurface,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceVariant,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'KOMedia',
      textTheme: _buildTextTheme(AppColors.textPrimary, AppColors.textSecondary),

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.divider,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: 'KOMedia',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
      ),

      // ── Navigation Bar ────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        indicatorColor: AppColors.primarySurface,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
                fontFamily: 'KOMedia',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary);
          }
          return const TextStyle(
              fontFamily: 'KOMedia',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textDisabled);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 22);
          }
          return const IconThemeData(color: AppColors.textDisabled, size: 22);
        }),
      ),

      // ── Cards ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withOpacity(0.04),
      ),

      // ── Input Fields ──────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.7), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        hintStyle: const TextStyle(
            fontFamily: 'KOMedia',
            fontSize: 14,
            color: AppColors.textDisabled,
            fontWeight: FontWeight.w400),
        labelStyle: const TextStyle(
            fontFamily: 'KOMedia',
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500),
        floatingLabelStyle: const TextStyle(
            fontFamily: 'KOMedia',
            fontSize: 12,
            color: AppColors.primary,
            fontWeight: FontWeight.w700),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),

      // ── Filled Button ─────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontFamily: 'KOMedia',
              fontSize: 15,
              fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),

      // ── Elevated Button ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontFamily: 'KOMedia',
              fontSize: 14,
              fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),

      // ── Outlined Button ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontFamily: 'KOMedia',
              fontSize: 14,
              fontWeight: FontWeight.w600),
        ),
      ),

      // ── Text Button ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
              fontFamily: 'KOMedia',
              fontSize: 14,
              fontWeight: FontWeight.w600),
        ),
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: StadiumBorder(),
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primarySurface,
        labelStyle: const TextStyle(
            fontFamily: 'KOMedia',
            fontSize: 13,
            fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),

      // ── ListTile ──────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12))),
        tileColor: AppColors.white,
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ── Snackbar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: const TextStyle(
            fontFamily: 'KOMedia',
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.white
                : AppColors.textDisabled),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.surfaceVariant),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ── Progress indicator ────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          fontFamily: 'KOMedia',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'KOMedia',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
      ),

      // ── Bottom Sheet ─────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      // ── Segmented Button ─────────────────────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.surfaceVariant),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.white
                  : AppColors.textSecondary),
          textStyle: WidgetStateProperty.all(const TextStyle(
              fontFamily: 'KOMedia',
              fontSize: 13,
              fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────────────────

  static ThemeData get darkTheme {
    const darkPrimary = Color(0xFF38B5A6); // High-contrast, premium soft teal/emerald

    final cs = const ColorScheme.dark().copyWith(
      primary: darkPrimary,
      onPrimary: AppColors.darkBg,
      primaryContainer: const Color(0xFF0F322E),
      onPrimaryContainer: const Color(0xFFA5E6DD),
      secondary: AppColors.accent,
      onSecondary: AppColors.darkBg,
      error: AppColors.dangerLight,
      onError: AppColors.white,
      errorContainer: const Color(0xFF450A0A),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurface2,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkDivider,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.darkBg,
      fontFamily: 'KOMedia',
      textTheme: _buildTextTheme(AppColors.darkTextPrimary, AppColors.darkTextSecondary),
      
      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black26,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: 'KOMedia',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.darkTextPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary, size: 22),
      ),
      
      // ── Navigation Bar ────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: const Color(0xFF0F322E),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return const TextStyle(
                fontFamily: 'KOMedia',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: darkPrimary);
          }
          return const TextStyle(
              fontFamily: 'KOMedia',
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.darkTextSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return const IconThemeData(color: darkPrimary, size: 22);
          }
          return const IconThemeData(color: AppColors.darkTextSecondary, size: 22);
        }),
      ),
      
      // ── Cards ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
        margin: EdgeInsets.zero,
      ),
      
      // ── Input Fields ──────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.darkBorder.withOpacity(0.5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.dangerLight, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.dangerLight, width: 2),
        ),
        hintStyle: const TextStyle(
            fontFamily: 'KOMedia',
            fontSize: 14,
            color: AppColors.darkTextSecondary,
            fontWeight: FontWeight.w400),
        labelStyle: const TextStyle(
            fontFamily: 'KOMedia',
            fontSize: 13,
            color: AppColors.darkTextSecondary),
        floatingLabelStyle: const TextStyle(
            fontFamily: 'KOMedia',
            fontSize: 12,
            color: darkPrimary,
            fontWeight: FontWeight.w700),
      ),
      
      // ── Filled Button ─────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: AppColors.darkBg,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontFamily: 'KOMedia',
              fontSize: 15,
              fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      
      // ── Elevated Button ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: AppColors.darkBg,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontFamily: 'KOMedia',
              fontSize: 14,
              fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      
      // ── Outlined Button ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: darkPrimary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontFamily: 'KOMedia',
              fontSize: 14,
              fontWeight: FontWeight.w600),
        ),
      ),
      
      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkPrimary,
        foregroundColor: AppColors.darkBg,
        elevation: 4,
        shape: StadiumBorder(),
      ),
      
      // ── Snackbar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkSurface2,
        contentTextStyle: const TextStyle(
            fontFamily: 'KOMedia',
            color: AppColors.darkTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      
      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          fontFamily: 'KOMedia',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'KOMedia',
          fontSize: 14,
          color: AppColors.darkTextSecondary,
        ),
      ),
      
      // ── Bottom Sheet ─────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      
      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.darkBg
                : AppColors.darkTextSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? darkPrimary
                : AppColors.darkSurface2),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      
      // ── Progress indicator ────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: darkPrimary,
      ),
    );
  }

  // ── Semantic color helpers ─────────────────────────────────────────────────
  static const success = AppColors.success;
  static const successSurface = AppColors.successSurface;
  static const danger = AppColors.danger;
  static const dangerSurface = AppColors.dangerSurface;
  static const warning = AppColors.warning;
  static const warningSurface = AppColors.warningSurface;

  static const customCenterFloat = CustomCenterFloatLocation();
  static const customEndFloat = CustomEndFloatLocation();
}

class CustomCenterFloatLocation extends FloatingActionButtonLocation {
  const CustomCenterFloatLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = (scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width) / 2;
    
    double fabY = scaffoldGeometry.scaffoldSize.height - 
        scaffoldGeometry.floatingActionButtonSize.height - 
        scaffoldGeometry.minInsets.bottom - 16;
        
    final isMobile = scaffoldGeometry.scaffoldSize.width < 600;
    if (isMobile) {
      fabY -= 92; // 72 (bar height) + 12 (bottom margin) + 8 (extra spacing)
    }
    
    return Offset(fabX, fabY);
  }
}

class CustomEndFloatLocation extends FloatingActionButtonLocation {
  const CustomEndFloatLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX;
    if (scaffoldGeometry.textDirection == TextDirection.rtl) {
      fabX = 16 + scaffoldGeometry.minInsets.left;
    } else {
      fabX = scaffoldGeometry.scaffoldSize.width - 
          scaffoldGeometry.floatingActionButtonSize.width - 
          scaffoldGeometry.minInsets.right - 16;
    }

    double fabY = scaffoldGeometry.scaffoldSize.height - 
        scaffoldGeometry.floatingActionButtonSize.height - 
        scaffoldGeometry.minInsets.bottom - 16;

    final isMobile = scaffoldGeometry.scaffoldSize.width < 600;
    if (isMobile) {
      fabY -= 92;
    }

    return Offset(fabX, fabY);
  }
}

