import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// **************************************************************************
/// SMART STITCH — APP THEME
/// Light Mode : Teal + White
/// Dark Mode  : Teal + True Black (Premium)
/// Font       : Poppins
/// **************************************************************************

class AppColors {
  AppColors._();

  // ─── PRIMARY TEAL PALETTE ─────────────────────────────
  static const Color primary = Color(0xFF0E8F95);
  static const Color primaryLight = Color(0xFF35BFC4);
  static const Color primaryDark = Color(0xFF065F63);
  static const Color primarySoft = Color(0xFFE6F8F8);
  static const Color accent = Color(0xFF5ED6D9);

  // ─── LIGHT MODE ───────────────────────────────────────
  static const Color lightBackground = Color(0xFFF8FEFE);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF0FBFB);
  static const Color lightBorder = Color(0xFFD8F1F2);
  static const Color lightDivider = Color(0xFFE7F6F7);

  static const Color lightTextPrimary = Color(0xFF083C3F);
  static const Color lightTextSecondary = Color(0xFF4F7E80);
  static const Color lightTextHint = Color(0xFF8DAFB1);

  // ─── DARK MODE (Premium Teal-Black) ────────────────────
  static const Color darkBackground = Color(0xFF040E11);
  static const Color darkSurface = Color(0xFF0A1B1F);
  static const Color darkSurface2 = Color(0xFF102428);
  static const Color darkBorder = Color(0xFF15333A);
  static const Color darkDivider = Color(0xFF0C2024);

  // Fixed: readable contrast on true black
  static const Color darkTextPrimary =
      Color(0xFFF0F0F0); 
  static const Color darkTextSecondary =
      Color(0xFFABABAB); 
  static const Color darkTextHint = Color(0xFF666666); 

  // ─── STATUS COLORS ────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);

  // ─── STATUS SOFT — Light Mode ─────────────────────────
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color warningSoft = Color(0xFFFFF4D6);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color infoSoft = Color(0xFFE0F2FE);

  // ─── STATUS SOFT — Dark Mode ──────────────────────────
  static const Color successSoftDark = Color(0xFF0D3320);
  static const Color warningSoftDark = Color(0xFF3A2900);
  static const Color errorSoftDark = Color(0xFF3A0F0F);
  static const Color infoSoftDark = Color(0xFF0A2540);

  // ─── EXTRA ────────────────────────────────────────────
  static const Color secondary = primaryLight;

  // ─── GRADIENTS ────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E8F95), Color(0xFF35BFC4)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF065F63), Color(0xFF0E8F95)],
  );

  // ══════════════════════════════════════════════════════════════════════
  // PREMIUM DASHBOARD ADDITIONS
  // Purely additive — nothing above this line was changed.
  // ══════════════════════════════════════════════════════════════════════

  // ─── GLASS SURFACES ───────────────────────────────────
  static const Color darkGlass = Color(0xCC0A1B1F); 
  static const Color darkGlassHi = Color(0xE6102428); 
  static const Color lightGlass = Color(0xF2FFFFFF);
  static const Color lightGlassHi = Color(0xFAFFFFFF);

  static Color glassBorder(bool isDark) =>
      isDark ? Colors.white.withValues(alpha: 0.08) : primary.withValues(alpha: 0.10);

  static Color glassHairline(bool isDark) =>
      isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.6);

  // ─── PREMIUM ACCENT GRADIENTS (blue → purple, used sparingly for "wow" cards) ───
  static const LinearGradient blueRelated = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
  );

  static const LinearGradient purpleGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
  );

  static const LinearGradient tealGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E8F95), Color(0xFF5ED6D9)],
  );

  static const LinearGradient successGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16A34A), Color(0xFF4ADE80)],
  );

  static const LinearGradient warningGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD97706), Color(0xFFFBBF24)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
  );
  static const LinearGradient silverGradient = LinearGradient(
    colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
  );
  static const LinearGradient bronzeGradient = LinearGradient(
    colors: [Color(0xFFD97757), Color(0xFFB45309)],
  );

  /// Soft radial-ish background gradient for the dashboard scaffold.
  static LinearGradient scaffoldGradient(bool isDark) => isDark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF071518), Color(0xFF040E11)],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF3FAFA), Color(0xFFF8FEFE)],
        );
}

/// ─── TEXT STYLES ─────────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static const String _font = 'Poppins';

  static const TextStyle display = TextStyle(
      fontFamily: _font,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.5);
  static const TextStyle h1 = TextStyle(
      fontFamily: _font,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.3,
      letterSpacing: -0.3);
  static const TextStyle h2 = TextStyle(
      fontFamily: _font,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.3);
  static const TextStyle h3 = TextStyle(
      fontFamily: _font,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.4);
  static const TextStyle h4 = TextStyle(
      fontFamily: _font,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.4);
  static const TextStyle h5 = TextStyle(
      fontFamily: _font,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4);

  static const TextStyle bodyLarge = TextStyle(
      fontFamily: _font,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.6);
  static const TextStyle bodyMedium = TextStyle(
      fontFamily: _font,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.6);
  static const TextStyle bodySmall = TextStyle(
      fontFamily: _font,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.5);

  static const TextStyle labelLarge = TextStyle(
      fontFamily: _font,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1);
  static const TextStyle labelMedium = TextStyle(
      fontFamily: _font,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2);
  static const TextStyle labelSmall = TextStyle(
      fontFamily: _font,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3);
  static const TextStyle button = TextStyle(
      fontFamily: _font,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3);
  static const TextStyle caption = TextStyle(
      fontFamily: _font,
      fontSize: 11,
      fontWeight: FontWeight.w400,
      height: 1.4);

  // ─── PREMIUM ADDITIONS ─────────────────────────────────
  static const TextStyle metricValue = TextStyle(
      fontFamily: _font,
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.1);
  static const TextStyle sectionTitle = TextStyle(
      fontFamily: _font,
      fontSize: 17,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2);
  static const TextStyle sectionSubtitle = TextStyle(
      fontFamily: _font,
      fontSize: 12.5,
      fontWeight: FontWeight.w400,
      height: 1.4);
}

/// ─── BORDER RADIUS ───────────────────────────────────────────────────────────
class AppRadius {
  AppRadius._();

  static const BorderRadius xs = BorderRadius.all(Radius.circular(6));
  static const BorderRadius small = BorderRadius.all(Radius.circular(10));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(14));
  static const BorderRadius large = BorderRadius.all(Radius.circular(20));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(28));
  static const BorderRadius full = BorderRadius.all(Radius.circular(100));
}

/// ─── SHADOWS ─────────────────────────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft(Color color) => [
        BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4)),
      ];

  static List<BoxShadow> medium(Color color) => [
        BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8)),
      ];

  static const List<BoxShadow> primary = [
    BoxShadow(color: Color(0x4D0E8F95), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> primaryStrong = [
    BoxShadow(color: Color(0x730E8F95), blurRadius: 24, offset: Offset(0, 10)),
  ];

  /// Colored glow used behind premium cards — subtle, not overdone.
  static List<BoxShadow> glow(Color color, {double alpha = 0.28, double blur = 28}) => [
        BoxShadow(color: color.withValues(alpha: alpha), blurRadius: blur, offset: const Offset(0, 10)),
      ];

  static List<BoxShadow> card(bool isDark) => [
        BoxShadow(
          color: isDark ? Colors.black.withValues(alpha: 0.45) : const Color(0xFF0E8F95).withValues(alpha: 0.06),
          blurRadius: isDark ? 24 : 18,
          offset: const Offset(0, 8),
        ),
      ];
}

/// ─── LIGHT THEME ─────────────────────────────────────────────────────────────
ThemeData lightTheme() {
  const Color primary = AppColors.primary;
  const Color bg = AppColors.lightBackground;
  const Color surface = AppColors.lightSurface;
  const Color textPrimary = AppColors.lightTextPrimary;
  const Color textSecondary = AppColors.lightTextSecondary;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.primaryLight,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.lightBorder,
    ),
    scaffoldBackgroundColor: bg,

    // ─── APP BAR ───────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary),
      iconTheme: IconThemeData(color: textPrimary),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),

    // ─── CARD ──────────────────────────────────────────
    cardTheme: const CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
        side: BorderSide(color: AppColors.lightBorder, width: 1),
      ),
      margin: EdgeInsets.all(0),
    ),

    // ─── BUTTONS ───────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        textStyle: AppTextStyles.button,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        textStyle: AppTextStyles.button,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: const BorderSide(color: primary, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
          foregroundColor: primary, textStyle: AppTextStyles.button),
    ),

    // ─── INPUT ─────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      hintStyle:
          AppTextStyles.bodyMedium.copyWith(color: AppColors.lightTextHint),
      labelStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: const OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: AppColors.lightBorder)),
      enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: AppColors.lightBorder)),
      focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: primary, width: 1.5)),
      errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: AppColors.error)),
      focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: AppColors.error, width: 1.5)),
      prefixIconColor: AppColors.lightTextSecondary,
      suffixIconColor: AppColors.lightTextSecondary,
    ),

    // ─── BOTTOM NAV ────────────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: AppColors.lightTextHint,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(
          fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(
          fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w400),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: AppColors.primarySoft,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primary, size: 24);
        }
        return const IconThemeData(color: AppColors.lightTextHint, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: primary);
        }
        return const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.lightTextHint);
      }),
    ),

    // ─── CHIP ──────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primarySoft,
      selectedColor: primary,
      labelStyle:
          AppTextStyles.labelMedium.copyWith(color: AppColors.primaryDark),
      secondaryLabelStyle:
          AppTextStyles.labelMedium.copyWith(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.full),
      side: BorderSide.none,
    ),

    // ─── MISC ──────────────────────────────────────────
    dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider, thickness: 1, space: 1),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.lightTextHint),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? primary : AppColors.lightBorder),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? primary : Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.white),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.xs),
      side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? primary : AppColors.lightTextHint),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      elevation: 8,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
      titleTextStyle: AppTextStyles.h4.copyWith(color: textPrimary),
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.lightTextPrimary,
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: AppColors.primarySoft,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primary,
      unselectedLabelColor: AppColors.lightTextHint,
      indicatorColor: primary,
      labelStyle: AppTextStyles.labelLarge,
      unselectedLabelStyle: AppTextStyles.labelLarge,
      dividerColor: AppColors.lightDivider,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: AppTextStyles.bodyMedium
          .copyWith(color: textPrimary, fontWeight: FontWeight.w500),
      subtitleTextStyle: AppTextStyles.bodySmall.copyWith(color: textSecondary),
      iconColor: AppColors.lightTextSecondary,
    ),
    textTheme: _buildTextTheme(textPrimary, textSecondary),
  );
}

/// ─── DARK THEME ──────────────────────────────────────────────────────────────
ThemeData darkTheme() {
  const Color primary = AppColors.primaryLight; 
  const Color bg = AppColors.darkBackground;
  const Color surface = AppColors.darkSurface;
  const Color textPrimary = AppColors.darkTextPrimary;
  const Color textSecondary = AppColors.darkTextSecondary;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: AppColors.primarySoft,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.darkBorder,
    ),
    scaffoldBackgroundColor: bg,

    // ─── APP BAR ───────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary),
      iconTheme: IconThemeData(color: textPrimary),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),

    // ─── CARD ──────────────────────────────────────────
    cardTheme: const CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
        side: BorderSide(color: AppColors.darkBorder, width: 1),
      ),
      margin: EdgeInsets.all(0),
    ),

    // ─── BUTTONS ───────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        textStyle: AppTextStyles.button,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        textStyle: AppTextStyles.button,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: const BorderSide(color: primary, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
          foregroundColor: primary, textStyle: AppTextStyles.button),
    ),

    // ─── INPUT ─────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface2,
      hintStyle:
          AppTextStyles.bodyMedium.copyWith(color: AppColors.darkTextHint),
      labelStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: const OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: AppColors.darkBorder)),
      enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: AppColors.darkBorder)),
      focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: primary, width: 1.5)),
      errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: AppColors.error)),
      focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: AppColors.error, width: 1.5)),
      prefixIconColor: AppColors.darkTextSecondary,
      suffixIconColor: AppColors.darkTextSecondary,
    ),

    // ─── BOTTOM NAV ────────────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: primary,
      unselectedItemColor: AppColors.darkTextHint,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(
          fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(
          fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w400),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      indicatorColor: AppColors.primaryDark,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primary, size: 24);
        }
        return const IconThemeData(color: AppColors.darkTextHint, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: primary);
        }
        return const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.darkTextHint);
      }),
    ),

    // ─── CHIP ──────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkSurface2,
      selectedColor: primary,
      labelStyle: AppTextStyles.labelMedium.copyWith(color: textSecondary),
      secondaryLabelStyle:
          AppTextStyles.labelMedium.copyWith(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.full),
      side: const BorderSide(color: AppColors.darkBorder),
    ),

    // ─── MISC ──────────────────────────────────────────
    dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider, thickness: 1, space: 1),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.darkTextHint),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? primary : AppColors.darkBorder),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? primary : Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.white),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.xs),
      side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? primary : AppColors.darkTextHint),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      elevation: 8,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
      titleTextStyle: AppTextStyles.h4.copyWith(color: textPrimary),
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
    ),
    // Fixed: was using darkSurface2 bg with darkTextPrimary — now clearly readable
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurface2,
      contentTextStyle:
          AppTextStyles.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
      actionTextColor: AppColors.primaryLight,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: AppColors.darkSurface2,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primary,
      unselectedLabelColor: AppColors.darkTextHint,
      indicatorColor: primary,
      labelStyle: AppTextStyles.labelLarge,
      unselectedLabelStyle: AppTextStyles.labelLarge,
      dividerColor: AppColors.darkDivider,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: AppTextStyles.bodyMedium
          .copyWith(color: textPrimary, fontWeight: FontWeight.w500),
      subtitleTextStyle: AppTextStyles.bodySmall.copyWith(color: textSecondary),
      iconColor: AppColors.darkTextSecondary,
    ),
    textTheme: _buildTextTheme(textPrimary, textSecondary),
  );
}

/// ─── SHARED TEXT THEME ───────────────────────────────────────────────────────
TextTheme _buildTextTheme(Color primary, Color secondary) {
  return TextTheme(
    displayLarge: AppTextStyles.display.copyWith(color: primary),
    displayMedium: AppTextStyles.h1.copyWith(color: primary),
    displaySmall: AppTextStyles.h2.copyWith(color: primary),
    headlineLarge: AppTextStyles.h2.copyWith(color: primary),
    headlineMedium: AppTextStyles.h3.copyWith(color: primary),
    headlineSmall: AppTextStyles.h4.copyWith(color: primary),
    titleLarge: AppTextStyles.h4.copyWith(color: primary),
    titleMedium: AppTextStyles.h5.copyWith(color: primary),
    titleSmall: AppTextStyles.labelLarge.copyWith(color: primary),
    bodyLarge: AppTextStyles.bodyLarge.copyWith(color: primary),
    bodyMedium: AppTextStyles.bodyMedium.copyWith(color: primary),
    bodySmall: AppTextStyles.bodySmall.copyWith(color: secondary),
    labelLarge: AppTextStyles.labelLarge.copyWith(color: primary),
    labelMedium: AppTextStyles.labelMedium.copyWith(color: secondary),
    labelSmall: AppTextStyles.labelSmall.copyWith(color: secondary),
  );
}