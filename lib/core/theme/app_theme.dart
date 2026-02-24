import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Configuración de tema de BF Stay
/// Incluye tema claro y oscuro con la paleta de marca
class AppTheme {
  AppTheme._();

  // ============== ESPACIADO ==============

  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // ============== BORDES REDONDEADOS ==============

  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusXXLarge = 24.0;
  static const double radiusFull = 999.0;

  // ============== ELEVACIONES ==============

  static const double elevationNone = 0.0;
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  static const double elevationXHigh = 16.0;

  // ============== ICONOS ==============

  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // ============== BOTONES ==============

  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 44.0;
  static const double buttonHeightLarge = 52.0;

  // ============== INPUTS ==============

  static const double inputHeight = 52.0;
  static const double inputBorderWidth = 1.5;

  // ============== TEXT STYLES ==============

  static TextStyle get _baseTextStyle => GoogleFonts.poppins();

  static TextTheme get _textTheme => TextTheme(
    // Display
    displayLarge: _baseTextStyle.copyWith(
      fontSize: 57,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
      color: AppColors.textPrimary,
    ),
    displayMedium: _baseTextStyle.copyWith(
      fontSize: 45,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      color: AppColors.textPrimary,
    ),
    displaySmall: _baseTextStyle.copyWith(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      color: AppColors.textPrimary,
    ),

    // Headline
    headlineLarge: _baseTextStyle.copyWith(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: AppColors.textPrimary,
    ),
    headlineMedium: _baseTextStyle.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: AppColors.textPrimary,
    ),
    headlineSmall: _baseTextStyle.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: AppColors.textPrimary,
    ),

    // Title
    titleLarge: _baseTextStyle.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: AppColors.textPrimary,
    ),
    titleMedium: _baseTextStyle.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      color: AppColors.textPrimary,
    ),
    titleSmall: _baseTextStyle.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: AppColors.textPrimary,
    ),

    // Body
    bodyLarge: _baseTextStyle.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      color: AppColors.textPrimary,
    ),
    bodyMedium: _baseTextStyle.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: AppColors.textPrimary,
    ),
    bodySmall: _baseTextStyle.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: AppColors.textSecondary,
    ),

    // Label
    labelLarge: _baseTextStyle.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: AppColors.textPrimary,
    ),
    labelMedium: _baseTextStyle.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: AppColors.textPrimary,
    ),
    labelSmall: _baseTextStyle.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: AppColors.textSecondary,
    ),
  );

  // ============== TEMA CLARO ==============

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: AppColors.gold,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.goldWithAlpha20,
      onPrimaryContainer: AppColors.goldDark,

      secondary: AppColors.silver,
      onSecondary: AppColors.black,
      secondaryContainer: AppColors.silverWithAlpha20,
      onSecondaryContainer: AppColors.silverDark,

      tertiary: AppColors.black,
      onTertiary: AppColors.white,

      error: AppColors.error,
      onError: AppColors.white,
      errorContainer: AppColors.errorLight,
      onErrorContainer: AppColors.error,

      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.backgroundSecondary,

      outline: AppColors.border,
      outlineVariant: AppColors.borderLight,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: _textTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      centerTitle: true,
      titleTextStyle: _baseTextStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(double.infinity, buttonHeightMedium),
        padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: _baseTextStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gold,
        backgroundColor: Colors.transparent,
        minimumSize: const Size(double.infinity, buttonHeightMedium),
        padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        side: const BorderSide(color: AppColors.gold, width: 1.5),
        textStyle: _baseTextStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.gold,
        padding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing8),
        textStyle: _baseTextStyle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundInput,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacing16,
        vertical: spacing16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.gold, width: inputBorderWidth),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.error, width: inputBorderWidth),
      ),
      hintStyle: _baseTextStyle.copyWith(
        color: AppColors.placeholder,
        fontSize: 14,
      ),
      labelStyle: _baseTextStyle.copyWith(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
      errorStyle: _baseTextStyle.copyWith(
        color: AppColors.error,
        fontSize: 12,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: spacing24,
    ),
    iconTheme: const IconThemeData(
      color: AppColors.iconDefault,
      size: iconMedium,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.gray100,
      selectedColor: AppColors.goldWithAlpha20,
      disabledColor: AppColors.gray200,
      labelStyle: _baseTextStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusFull),
      ),
      side: BorderSide.none,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.gold,
      unselectedItemColor: AppColors.gray400,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.background,
      indicatorColor: AppColors.goldWithAlpha20,
      elevation: 0,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return _baseTextStyle.copyWith(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
          color: states.contains(WidgetState.selected)
              ? AppColors.gold
              : AppColors.gray400,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.gold
              : AppColors.gray400,
          size: 24,
        );
      }),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.gold,
      foregroundColor: AppColors.white,
      elevation: elevationMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.gray900,
      contentTextStyle: _baseTextStyle.copyWith(
        color: AppColors.white,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.background,
      elevation: elevationHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXLarge),
      ),
      titleTextStyle: _baseTextStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      contentTextStyle: _baseTextStyle.copyWith(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.background,
      elevation: elevationHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(radiusXLarge),
        ),
      ),
    ),
  );

  // ============== TEMA OSCURO ==============

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.gold,
      onPrimary: AppColors.black,
      primaryContainer: AppColors.goldDark,
      onPrimaryContainer: AppColors.goldLight,

      secondary: AppColors.silver,
      onSecondary: AppColors.black,
      secondaryContainer: AppColors.silverDark,
      onSecondaryContainer: AppColors.silverLight,

      tertiary: AppColors.white,
      onTertiary: AppColors.black,

      error: AppColors.error,
      onError: AppColors.white,
      errorContainer: AppColors.errorLight,
      onErrorContainer: AppColors.error,

      surface: AppColors.black,
      onSurface: AppColors.white,
      surfaceContainerHighest: AppColors.blackLight,

      outline: AppColors.gray700,
      outlineVariant: AppColors.gray800,
    ),
    scaffoldBackgroundColor: AppColors.black,
    textTheme: _textTheme.copyWith(
      displayLarge: _textTheme.displayLarge?.copyWith(color: AppColors.white),
      displayMedium: _textTheme.displayMedium?.copyWith(color: AppColors.white),
      displaySmall: _textTheme.displaySmall?.copyWith(color: AppColors.white),
      headlineLarge: _textTheme.headlineLarge?.copyWith(color: AppColors.white),
      headlineMedium: _textTheme.headlineMedium?.copyWith(color: AppColors.white),
      headlineSmall: _textTheme.headlineSmall?.copyWith(color: AppColors.white),
      titleLarge: _textTheme.titleLarge?.copyWith(color: AppColors.white),
      titleMedium: _textTheme.titleMedium?.copyWith(color: AppColors.white),
      titleSmall: _textTheme.titleSmall?.copyWith(color: AppColors.white),
      bodyLarge: _textTheme.bodyLarge?.copyWith(color: AppColors.gray100),
      bodyMedium: _textTheme.bodyMedium?.copyWith(color: AppColors.gray200),
      bodySmall: _textTheme.bodySmall?.copyWith(color: AppColors.gray400),
      labelLarge: _textTheme.labelLarge?.copyWith(color: AppColors.white),
      labelMedium: _textTheme.labelMedium?.copyWith(color: AppColors.white),
      labelSmall: _textTheme.labelSmall?.copyWith(color: AppColors.gray300),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.white,
      centerTitle: true,
      titleTextStyle: _baseTextStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.white,
        size: 24,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.blackLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        side: const BorderSide(color: AppColors.gray700),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.black,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(double.infinity, buttonHeightMedium),
        padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: _baseTextStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gold,
        backgroundColor: Colors.transparent,
        minimumSize: const Size(double.infinity, buttonHeightMedium),
        padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        side: const BorderSide(color: AppColors.gold, width: 1.5),
        textStyle: _baseTextStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.blackLight,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacing16,
        vertical: spacing16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.gray700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.gray700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.gold, width: inputBorderWidth),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: _baseTextStyle.copyWith(
        color: AppColors.gray500,
        fontSize: 14,
      ),
      labelStyle: _baseTextStyle.copyWith(
        color: AppColors.gray400,
        fontSize: 14,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.gray700,
      thickness: 1,
      space: spacing24,
    ),
    iconTheme: const IconThemeData(
      color: AppColors.gray300,
      size: iconMedium,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.black,
      selectedItemColor: AppColors.gold,
      unselectedItemColor: AppColors.gray500,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.gray100,
      contentTextStyle: _baseTextStyle.copyWith(
        color: AppColors.black,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.blackLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXLarge),
      ),
    ),
  );
}
