import 'package:flutter/material.dart';

/// Paleta de colores oficial de BF Stay
/// Colores principales: Gold, Silver, Black, White
class AppColors {
  AppColors._();

  // ============== COLORES PRINCIPALES ==============

  /// Gold - Color primario de marca
  static const Color gold = Color.fromARGB(255, 255, 201, 22);

  /// Silver - Color secundario de marca
  static const Color silver = Color(0xFFC0C0C0);

  /// Black - Color de fondo principal (dark theme background)
  // static const Color black = Color(0xFF1A1A1A);
  static const Color black = Color(0xFF0D0D0D);

  /// White - Color de superficie principal
  static const Color white = Color(0xFFFFFFFF);

  // ============== VARIANTES DE WHITE ==============

  static const Color whiteWithAlpha90 = Color(0xE6FFFFFF);
  static const Color whiteWithAlpha80 = Color(0xCCFFFFFF);
  static const Color whiteWithAlpha70 = Color(0xB3FFFFFF);
  static const Color whiteWithAlpha50 = Color(0x80FFFFFF);
  static const Color whiteWithAlpha40 = Color(0x66FFFFFF);
  static const Color whiteWithAlpha30 = Color(0x4DFFFFFF);
  static const Color whiteWithAlpha20 = Color(0x33FFFFFF);
  static const Color whiteWithAlpha10 = Color(0x1AFFFFFF);
  static const Color whiteWithAlpha05 = Color(0x0DFFFFFF);

  // ============== VARIANTES DE GOLD ==============

  static const Color goldLight = Color(0xFFE5C962);
  static const Color goldDark = Color(0xFFB8942D);
  static const Color goldWithAlpha20 = Color(0x33D4AF37);
  static const Color goldWithAlpha10 = Color(0x1AD4AF37);
  static const Color goldWithAlpha30 = Color(0x4DD4AF37);
  static const Color goldWithAlpha40 = Color(0x66D4AF37);
  static const Color goldWithAlpha50 = Color(0x80D4AF37);

  // ============== VARIANTES DE SILVER ==============

  static const Color silverLight = Color(0xFFD4D4D4);
  static const Color silverDark = Color(0xFF909090);
  static const Color silverWithAlpha20 = Color(0x33C0C0C0);

  // ============== VARIANTES DE BLACK (DARK THEME) ==============

  /// Surface/Card en dark theme
  static const Color blackLight = Color(0xFF1A1A1A);

  /// Border en dark theme
  static const Color blackBorder = Color(0xFF2A2A2A);

  static const Color blackWithAlpha80 = Color(0xCC0D0D0D);
  static const Color blackWithAlpha50 = Color(0x800D0D0D);
  static const Color blackWithAlpha20 = Color(0x330D0D0D);
  static const Color blackWithAlpha40 = Color(0x660D0D0D);
  static const Color blackWithAlpha30 = Color(0x4D0D0D0D);
  static const Color blackWithAlpha90 = Color(0xE60D0D0D);
  static const Color blackWithAlpha05 = Color(0x0D0D0D0D);

  // ============== ESCALAS DE GRISES ==============

  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFE5E5E5);
  static const Color gray300 = Color(0xFFD4D4D4);
  static const Color gray400 = Color(0xFFA0A0A0);
  static const Color gray500 = Color(0xFF737373);
  static const Color gray600 = Color(0xFF525252);
  static const Color gray700 = Color(0xFF404040);
  static const Color gray800 = Color(0xFF262626);
  static const Color gray900 = Color(0xFF171717);

  // ============== DARK THEME ESPECÍFICOS ==============

  /// Fondo principal en dark theme
  static const Color darkBackground = Color(0xFF0D0D0D);

  /// Superficie/Card en dark theme
  static const Color darkSurface = Color(0xFF1A1A1A);

  /// Borde en dark theme
  static const Color darkBorder = Color(0xFF2A2A2A);

  /// Texto primario en dark theme
  static const Color darkTextPrimary = Color(0xFFFFFFFF);

  /// Texto secundario en dark theme
  static const Color darkTextSecondary = Color(0xFFA0A0A0);

  // ============== VARIANTES DARK SURFACE ==============

  static const Color darkSurfaceWithAlpha30 = Color(0x4D1A1A1A);
  static const Color darkSurfaceWithAlpha40 = Color(0x661A1A1A);
  static const Color darkSurfaceWithAlpha50 = Color(0x801A1A1A);
  static const Color darkSurfaceWithAlpha60 = Color(0x991A1A1A);
  static const Color darkSurfaceWithAlpha70 = Color(0xB31A1A1A);
  static const Color darkSurfaceWithAlpha80 = Color(0xCC1A1A1A);

  // ============== VARIANTES DARK BACKGROUND ==============

  static const Color darkBackgroundWithAlpha40 = Color(0x660D0D0D);
  static const Color darkBackgroundWithAlpha50 = Color(0x800D0D0D);
  static const Color darkBackgroundWithAlpha70 = Color(0xB30D0D0D);
  static const Color darkBackgroundWithAlpha80 = Color(0xCC0D0D0D);
  static const Color darkBackgroundWithAlpha90 = Color(0xE60D0D0D);

  // ============== COLORES ROMÁNTICOS ==============

  /// Rosa romántico - Color principal del pack romántico
  static const Color romanticPink = Color(0xFFE91E63);

  /// Rojo romántico - Para acentos y degradados
  static const Color romanticRed = Color(0xFFC2185B);

  /// Púrpura romántico - Para degradados elegantes
  static const Color romanticPurple = Color(0xFF9C27B0);

  // ============== COLORES DE ESTADO ==============

  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0x3322C55E);

  /// Verde de éxito con 10% de alpha (fondos de icono, chips)
  static const Color successWithAlpha10 = Color(0x1A22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0x33F59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0x33EF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0x333B82F6);

  // ============== COLORES DE TEXTO ==============

  static const Color textPrimary = gray900;
  static const Color textSecondary = gray600;
  static const Color textTertiary = gray400;
  static const Color textDisabled = gray300;
  static const Color textOnDark = white;
  static const Color textOnGold = black;
  static const Color textLink = gold;

  // ============== COLORES DE FONDO ==============

  static const Color background = white;
  static const Color backgroundSecondary = gray50;
  static const Color backgroundDark = black;
  static const Color backgroundCard = white;
  static const Color backgroundInput = gray100;

  // ============== COLORES DE BORDE ==============

  static const Color border = gray200;
  static const Color borderLight = gray100;
  static const Color borderDark = gray300;
  static const Color borderFocus = gold;

  // ============== COLORES DE SOMBRAS ==============

  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);
  static const Color shadowDark = Color(0x33000000);

  // ============== COLORES ESPECÍFICOS DE UI ==============

  static const Color divider = gray200;
  static const Color iconDefault = gray500;
  static const Color iconActive = gold;
  static const Color iconDisabled = gray300;
  static const Color placeholder = gray400;
  static const Color overlay = Color(0x80000000);
  static const Color modalBackground = Color(0xF5FFFFFF);

  // ============== GRADIENTES ==============

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold, goldDark],
  );

  static const LinearGradient silverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [silverLight, silver, silverDark],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [blackLight, black],
  );

  // ============== MÉTODOS HELPER ==============

  /// Retorna el color apropiado según el estado del widget
  static Color getStateColor({
    required bool isFocused,
    required bool hasError,
    required bool isDisabled,
    Color? normalColor,
    Color? focusColor,
    Color? errorColor,
    Color? disabledColor,
  }) {
    if (isDisabled) return disabledColor ?? gray300;
    if (hasError) return errorColor ?? error;
    if (isFocused) return focusColor ?? gold;
    return normalColor ?? border;
  }

  /// Retorna el color de texto apropiado según el fondo
  static Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textPrimary : textOnDark;
  }

  // ============== COLORES DINÁMICOS SEGÚN TEMA ==============

  /// Retorna el color de fondo principal según el tema
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkBackground : white;
  }

  /// Retorna el color de fondo secundario según el tema
  static Color getSurfaceSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkSurface : gray50;
  }

  /// Retorna el color de fondo para cards según el tema
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkSurface : white;
  }

  /// Retorna el color de texto primario según el tema
  static Color getTextPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : gray900;
  }

  /// Retorna el color de texto secundario según el tema
  static Color getTextSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? white : gray600;
  }

  /// Retorna el color de borde según el tema
  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkBorder : gray200;
  }

  /// Retorna el color del hero overlay según el tema
  static Color getHeroOverlayColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackgroundWithAlpha50
        : whiteWithAlpha70;
  }

  /// Retorna el color del gradiente hero según el tema
  static Color getHeroGradientStart(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.transparent
        : whiteWithAlpha30;
  }

  /// Retorna el color del gradiente hero final según el tema
  static Color getHeroGradientEnd(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackgroundWithAlpha90
        : whiteWithAlpha70;
  }

  /// Retorna el color de fondo del contenedor de servicios según el tema
  static Color getServicesContainerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurfaceWithAlpha40
        : gray100;
  }

  /// Retorna el color de fondo del card de servicio según el tema
  static Color getServiceCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurfaceWithAlpha30
        : whiteWithAlpha90;
  }

  /// Retorna el color de fondo para inputs según el tema
  static Color getInputBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkSurface : gray100;
  }

  /// Retorna el color de fondo para chips/tags según el tema
  static Color getChipBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurfaceWithAlpha60
        : gray100;
  }

  /// Retorna el color gold con alpha adaptado al tema
  static Color getGoldWithAlpha(BuildContext context, {double alpha = 0.2}) {
    if (Theme.of(context).brightness == Brightness.dark) {
      // Retornar el color predefinido más cercano
      if (alpha <= 0.1) return goldWithAlpha10;
      if (alpha <= 0.2) return goldWithAlpha20;
      if (alpha <= 0.3) return goldWithAlpha30;
      if (alpha <= 0.4) return goldWithAlpha40;
      return goldWithAlpha50;
    }
    return goldWithAlpha20;
  }

  /// Retorna el color de texto terciario según el tema
  static Color getTextTertiaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? gray400 : gray400;
  }

  /// Retorna true si el tema actual es oscuro
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // ============== COLORES HOUSE RULES (DARK ADAPTATIVOS) ==============

  /// Color de fondo del icono en las normas de la casa
  static Color getHouseRuleIconBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? goldWithAlpha10
        : goldWithAlpha20;
  }

  /// Color del borde de la tarjeta de norma de la casa
  static Color getHouseRuleCardBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? goldWithAlpha20
        : goldWithAlpha30;
  }

  /// Color de fondo del badge de contador en house rules
  static Color getHouseRuleBadgeBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? goldWithAlpha10
        : goldWithAlpha20;
  }

  /// Color del divider vertical en house rules
  static Color getHouseRuleDividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? goldWithAlpha50
        : gold;
  }
}
