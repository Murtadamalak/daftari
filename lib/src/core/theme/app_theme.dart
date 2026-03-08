import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens — Daftari Brand Identity
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // ── Primary – Deep Teal (trust, financial security, professionalism) ──────
  static const primary = Color(0xFF0D4C3F); // Deep forest green
  static const primaryDark = Color(0xFF083830); // Darker shade
  static const primaryLight = Color(0xFF1A7060); // Lighter teal
  static const primarySurface = Color(0xFFE8F5F2); // Very faint teal tint

  // ── Accent – Warm Gold ────────────────────────────────────────────────────
  static const accent = Color(0xFFC8962C); // Warm gold
  static const accentSurface = Color(0xFFFDF3DC); // Faint gold

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const success = Color(0xFF16A34A); // Green — debts owed TO you
  static const successSurface = Color(0xFFDCFCE7);
  static const successLight = Color(0xFF4ADE80);

  static const danger = Color(0xFFDC2626); // Red — debts you OWE
  static const dangerSurface = Color(0xFFFEE2E2);
  static const dangerLight = Color(0xFFF87171);

  static const warning = Color(0xFFD97706);
  static const warningSurface = Color(0xFFFEF3C7);

  static const info = Color(0xFF1D4ED8);
  static const infoSurface = Color(0xFFDBEAFE);

  // ── Neutrals – Light (Ivory / Notebook paper feel) ───────────────────────
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF7F5F0); // Warm ivory — notebook
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF0EDE6); // Beige variant
  static const border = Color(0xFFDDD9D0);
  static const divider = Color(0xFFEBE8E0);

  static const textPrimary = Color(0xFF0F1B18); // Near black-green
  static const textSecondary = Color(0xFF4A5E58); // Muted teal-grey
  static const textDisabled = Color(0xFFA0ADA9);

  // ── Neutrals – Dark ───────────────────────────────────────────────────────
  static const darkBg = Color(0xFF0A1612); // Deep dark teal-black
  static const darkSurface = Color(0xFF13211D); // Card dark
  static const darkSurface2 = Color(0xFF1D332D); // Elevated dark
  static const darkBorder = Color(0xFF234D40);
  static const darkDivider = Color(0xFF13211D);

  static const darkTextPrimary = Color(0xFFF0F7F5);
  static const darkTextSecondary = Color(0xFF8AADA5);
}

// ─────────────────────────────────────────────────────────────────────────────
// Typography helpers — Cairo font for excellent Arabic readability
// ─────────────────────────────────────────────────────────────────────────────

TextTheme _buildTextTheme(Color primary, Color secondary) {
  return GoogleFonts.cairoTextTheme().copyWith(
    displayLarge: GoogleFonts.cairo(
        fontSize: 32, fontWeight: FontWeight.w900, color: primary),
    displayMedium: GoogleFonts.cairo(
        fontSize: 26, fontWeight: FontWeight.w800, color: primary),
    displaySmall: GoogleFonts.cairo(
        fontSize: 22, fontWeight: FontWeight.w700, color: primary),
    headlineLarge: GoogleFonts.cairo(
        fontSize: 20, fontWeight: FontWeight.w800, color: primary),
    headlineMedium: GoogleFonts.cairo(
        fontSize: 18, fontWeight: FontWeight.w700, color: primary),
    headlineSmall: GoogleFonts.cairo(
        fontSize: 16, fontWeight: FontWeight.w700, color: primary),
    titleLarge: GoogleFonts.cairo(
        fontSize: 17, fontWeight: FontWeight.w700, color: primary),
    titleMedium: GoogleFonts.cairo(
        fontSize: 15, fontWeight: FontWeight.w700, color: primary),
    titleSmall: GoogleFonts.cairo(
        fontSize: 13, fontWeight: FontWeight.w600, color: primary),
    bodyLarge: GoogleFonts.cairo(
        fontSize: 15, fontWeight: FontWeight.w500, color: secondary),
    bodyMedium: GoogleFonts.cairo(
        fontSize: 13, fontWeight: FontWeight.w500, color: secondary),
    bodySmall: GoogleFonts.cairo(
        fontSize: 11, fontWeight: FontWeight.w400, color: secondary),
    labelLarge: GoogleFonts.cairo(
        fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.1),
    labelMedium: GoogleFonts.cairo(
        fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.1),
    labelSmall: GoogleFonts.cairo(
        fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.2),
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
      textTheme:
          _buildTextTheme(AppColors.textPrimary, AppColors.textSecondary),

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border.withOpacity(0.5),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
      ),

      // ── Navigation Bar ────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        indicatorColor: AppColors.primarySurface,
        indicatorShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary);
          }
          return GoogleFonts.cairo(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withOpacity(0.05),
      ),

      // ── Input Fields ──────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppColors.border.withOpacity(0.7), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        hintStyle: GoogleFonts.cairo(
            fontSize: 14,
            color: AppColors.textDisabled,
            fontWeight: FontWeight.w400),
        labelStyle: GoogleFonts.cairo(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500),
        floatingLabelStyle: GoogleFonts.cairo(
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
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),

      // ── Elevated Button ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(0, 46),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle:
              GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),

      // ── Outlined Button ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 46),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle:
              GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Text Button ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle:
              GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
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
        labelStyle:
            GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),

      // ── ListTile ──────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
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
        contentTextStyle: GoogleFonts.cairo(
            color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.cairo(
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
          textStyle: WidgetStateProperty.all(
              GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────────────────

  static ThemeData get darkTheme {
    const darkPrimary = Color(0xFF4DB896); // Soft teal for dark mode
    const darkAccent = Color(0xFFD8A84A); // Warm gold

    final cs = const ColorScheme.dark().copyWith(
      primary: darkPrimary,
      onPrimary: AppColors.darkBg,
      primaryContainer: Color(0xFF0D3028),
      onPrimaryContainer: Color(0xFFA7D9CC),
      secondary: darkAccent,
      onSecondary: AppColors.darkBg,
      error: AppColors.dangerLight,
      onError: AppColors.white,
      errorContainer: Color(0xFF450A0A),
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
      textTheme: _buildTextTheme(
          AppColors.darkTextPrimary, AppColors.darkTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black26,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.darkTextPrimary,
        ),
        iconTheme:
            const IconThemeData(color: AppColors.darkTextPrimary, size: 22),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: const Color(0xFF0D3028),
        indicatorShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return GoogleFonts.cairo(
                fontSize: 12, fontWeight: FontWeight.w700, color: darkPrimary);
          }
          return GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.darkTextSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return const IconThemeData(color: darkPrimary, size: 22);
          }
          return const IconThemeData(
              color: AppColors.darkTextSecondary, size: 22);
        }),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.darkBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppColors.darkBorder.withOpacity(0.5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.dangerLight, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dangerLight, width: 2),
        ),
        hintStyle: GoogleFonts.cairo(
            fontSize: 14,
            color: AppColors.darkTextSecondary,
            fontWeight: FontWeight.w400),
        labelStyle:
            GoogleFonts.cairo(fontSize: 13, color: AppColors.darkTextSecondary),
        floatingLabelStyle: GoogleFonts.cairo(
            fontSize: 12, color: darkPrimary, fontWeight: FontWeight.w700),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: AppColors.darkBg,
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: AppColors.darkBg,
          minimumSize: const Size(0, 46),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle:
              GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          minimumSize: const Size(0, 46),
          side: const BorderSide(color: darkPrimary, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle:
              GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkPrimary,
        foregroundColor: AppColors.darkBg,
        elevation: 4,
        shape: StadiumBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkSurface2,
        contentTextStyle: GoogleFonts.cairo(
            color: AppColors.darkTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        contentTextStyle: GoogleFonts.cairo(
          fontSize: 14,
          color: AppColors.darkTextSecondary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
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
}
