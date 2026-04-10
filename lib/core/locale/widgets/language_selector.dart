import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/locale_cubit.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Variantes del selector de idioma
enum LanguageSelectorVariant { compact, list }

/// Widget reutilizable para seleccionar el idioma de la aplicación.
///
/// [compact] - Bandera + código de idioma (para Public Home)
/// [list] - Lista vertical de idiomas (para Settings)
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    this.variant = LanguageSelectorVariant.compact,
  });

  final LanguageSelectorVariant variant;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case LanguageSelectorVariant.compact:
        return const _CompactSelector();
      case LanguageSelectorVariant.list:
        return const _ListSelector();
    }
  }
}

/// Selector compacto: bandera + código de idioma
/// Diseñado para ser robusto en web release mode con fallback si
/// LocaleCubit no está disponible.
class _CompactSelector extends StatelessWidget {
  const _CompactSelector();

  @override
  Widget build(BuildContext context) {
    String currentLocale = 'es';
    LocaleCubit? localeCubit;

    try {
      localeCubit = context.read<LocaleCubit>();
      currentLocale = localeCubit.state.languageCode;
    } catch (_) {
      // LocaleCubit no disponible - usar valores por defecto
    }

    final isDark = AppColors.isDarkMode(context);

    return GestureDetector(
      onTap: localeCubit != null
          ? () => _showLanguageMenu(context, localeCubit!)
          : null,
      child: Container(
        constraints: const BoxConstraints(minWidth: 52, minHeight: 30),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.blackWithAlpha50
              : AppColors.blackWithAlpha05,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.gold : AppColors.blackWithAlpha20,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bandera como texto sobre fondo gold (sin Image.asset para
            // máxima compatibilidad en web release mode)
            Container(
              width: 22,
              height: 15,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.center,
              child: Text(
                _getCountryCode(currentLocale),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              currentLocale.toUpperCase(),
              style: TextStyle(
                color: isDark ? AppColors.gold : AppColors.black,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Código de país a partir del código de idioma para el indicador visual
  String _getCountryCode(String languageCode) {
    switch (languageCode) {
      case 'es':
        return 'ES';
      case 'en':
        return 'GB';
      case 'de':
        return 'DE';
      case 'fr':
        return 'FR';
      case 'it':
        return 'IT';
      case 'pt':
        return 'PT';
      default:
        return languageCode.toUpperCase();
    }
  }

  void _showLanguageMenu(BuildContext context, LocaleCubit localeCubit) {
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      items: LocaleCubit.supportedLocales.map((locale) {
        final isSelected =
            locale.languageCode == localeCubit.state.languageCode;
        return PopupMenuItem<String>(
          value: locale.languageCode,
          height: 44,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
                child: Text(
                  locale.languageCode.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                LocaleCubit.nativeNames[locale.languageCode] ??
                    locale.languageCode,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.gold : null,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(Icons.check_rounded, color: AppColors.gold, size: 20),
            ],
          ),
        );
      }).toList(),
    ).then((code) {
      if (code != null) {
        localeCubit.setLocale(Locale(code));
      }
    });
  }
}

/// Selector tipo lista: para la pantalla de ajustes
class _ListSelector extends StatelessWidget {
  const _ListSelector();

  @override
  Widget build(BuildContext context) {
    final localeCubit = context.read<LocaleCubit>();
    final currentCode = context.select(
      (LocaleCubit cubit) => cubit.state.languageCode,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: LocaleCubit.supportedLocales.map((locale) {
        final code = locale.languageCode;
        final isSelected = code == currentCode;
        final nativeName =
            LocaleCubit.nativeNames[code] ?? code.toUpperCase();

        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.goldWithAlpha20
                : AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: isSelected
                  ? AppColors.gold
                  : AppColors.getBorderColor(context),
            ),
          ),
          child: InkWell(
            onTap: () => localeCubit.setLocale(locale),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      code.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    nativeName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.gold
                          : AppColors.getTextPrimaryColor(context),
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(Icons.check_rounded, color: AppColors.gold, size: 22),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
