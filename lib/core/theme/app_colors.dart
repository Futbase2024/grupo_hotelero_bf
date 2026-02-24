import 'package:flutter/material.dart';

/// Paleta de colores oficial de BF Stay
/// Colores principales: Gold, Silver, Black, White
class AppColors {
  AppColors._();

  // ============== COLORES PRINCIPALES ==============

  /// Gold - Color primario de marca
  static const Color gold = Color(0xFFC6A75E);

  /// Silver - Color secundario de marca
  static const Color silver = Color(0xFFC0C0C0);

  /// Black - Color de fondo principal
  static const Color black = Color(0xFF111111);

  /// White - Color de superficie principal
  static const Color white = Color(0xFFFFFFFF);

  // ============== VARIANTES DE GOLD ==============

  static const Color goldLight = Color(0xFFD4BC7A);
  static const Color goldDark = Color(0xFFA88D45);
  static const Color goldWithAlpha20 = Color(0x33C6A75E);
  static const Color goldWithAlpha10 = Color(0x1AC6A75E);

  // ============== VARIANTES DE SILVER ==============

  static const Color silverLight = Color(0xFFD4D4D4);
  static const Color silverDark = Color(0xFF909090);
  static const Color silverWithAlpha20 = Color(0x33C0C0C0);

  // ============== VARIANTES DE BLACK ==============

  static const Color blackLight = Color(0xFF2A2A2A);
  static const Color blackWithAlpha80 = Color(0xCC111111);
  static const Color blackWithAlpha50 = Color(0x80111111);
  static const Color blackWithAlpha20 = Color(0x33111111);

  // ============== ESCALAS DE GRISES ==============

  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFE5E5E5);
  static const Color gray300 = Color(0xFFD4D4D4);
  static const Color gray400 = Color(0xFFA3A3A3);
  static const Color gray500 = Color(0xFF737373);
  static const Color gray600 = Color(0xFF525252);
  static const Color gray700 = Color(0xFF404040);
  static const Color gray800 = Color(0xFF262626);
  static const Color gray900 = Color(0xFF171717);

  // ============== COLORES DE ESTADO ==============

  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0x3322C55E);
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
    return Theme.of(context).brightness == Brightness.dark ? black : white;
  }

  /// Retorna el color de fondo secundario según el tema
  static Color getSurfaceSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? blackLight : gray50;
  }

  /// Retorna el color de fondo para cards según el tema
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? blackLight : white;
  }

  /// Retorna el color de texto primario según el tema
  static Color getTextPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? white : gray900;
  }

  /// Retorna el color de texto secundario según el tema
  static Color getTextSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? gray300 : gray600;
  }

  /// Retorna el color de borde según el tema
  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? gray700 : gray200;
  }

  /// Retorna el color del hero overlay según el tema
  static Color getHeroOverlayColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? black.withValues(alpha: 0.5)
        : white.withValues(alpha: 0.7);
  }

  /// Retorna el color del gradiente hero según el tema
  static Color getHeroGradientStart(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.transparent
        : white.withValues(alpha: 0.3);
  }

  /// Retorna el color del gradiente hero final según el tema
  static Color getHeroGradientEnd(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? gray900.withValues(alpha: 0.9)
        : white.withValues(alpha: 0.95);
  }

  /// Retorna el color de fondo del contenedor de servicios según el tema
  static Color getServicesContainerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? gray800.withValues(alpha: 0.4)
        : gray100.withValues(alpha: 0.8);
  }

  /// Retorna el color de fondo del card de servicio según el tema
  static Color getServiceCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? gray800.withValues(alpha: 0.3)
        : white.withValues(alpha: 0.9);
  }

  /// Retorna true si el tema actual es oscuro
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
