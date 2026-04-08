import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/locale_cubit.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Variantes del selector de idioma
enum LanguageSelectorVariant { compact, list }

/// Función para obtener la ruta de la bandera
String _getFlagAsset(String languageCode) {
  switch (languageCode) {
    case 'es':
      return 'assets/banderas/es.png';
    case 'en':
      return 'assets/banderas/en.png';
    case 'de':
      return 'assets/banderas/de.png';
    case 'fr':
      return 'assets/banderas/fr.png';
    case 'it':
      return 'assets/banderas/it.png';
    case 'pt':
      return 'assets/banderas/pt.png';
    default:
      return 'assets/banderas/es.png';
  }
}

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
class _CompactSelector extends StatelessWidget {
  const _CompactSelector();

  @override
  Widget build(BuildContext context) {
    final localeCubit = context.read<LocaleCubit>();
    final currentLocale = context.select(
      (LocaleCubit cubit) => cubit.state.languageCode,
    );

    return InkWell(
      onTap: () => _showLanguageMenu(context, localeCubit),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.asset(
                _getFlagAsset(currentLocale),
                width: 24,
                height: 16,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 24,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Center(
                      child: Text(
                        '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 4),
            Text(
              currentLocale.toUpperCase(),
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
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
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.asset(
                  _getFlagAsset(locale.languageCode),
                  width: 24,
                  height: 16,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 24,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Center(
                        child: Text(
                          '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
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
        final nativeName = LocaleCubit.nativeNames[code] ?? code.toUpperCase();

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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Image.asset(
                      _getFlagAsset(code),
                      width: 32,
                      height: 22,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 32,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Center(
                            child: Text(
                              '?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    nativeName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
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
