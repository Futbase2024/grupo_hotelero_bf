import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_colors.dart';
import '../cubit/theme_cubit.dart';

/// Widget para cambiar el tema de la aplicación
/// Disponible en 3 variantes: icon, switch y segmented
enum ThemeToggleVariant { icon, toggle, segmented }

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({
    super.key,
    this.variant = ThemeToggleVariant.icon,
    this.showLabel = false,
  });

  final ThemeToggleVariant variant;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case ThemeToggleVariant.icon:
        return _IconButtonToggle(showLabel: showLabel);
      case ThemeToggleVariant.toggle:
        return _SwitchToggle(showLabel: showLabel);
      case ThemeToggleVariant.segmented:
        return _SegmentedToggle();
    }
  }
}

/// Botón de icono simple para alternar tema
class _IconButtonToggle extends StatelessWidget {
  const _IconButtonToggle({required this.showLabel});

  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();
    final isDark = context.select((ThemeCubit cubit) => cubit.isDarkMode);

    return InkWell(
      onTap: () => themeCubit.toggleTheme(),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return RotationTransition(
                  turns: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(isDark),
                color: AppColors.gold,
                size: 24,
              ),
            ),
            if (showLabel) ...[
              const SizedBox(width: 8),
              Text(
                isDark ? 'Claro' : 'Oscuro',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.gold,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Switch estilo toggle para cambiar tema
class _SwitchToggle extends StatelessWidget {
  const _SwitchToggle({required this.showLabel});

  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();
    final isDark = context.select((ThemeCubit cubit) => cubit.isDarkMode);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.light_mode_rounded,
          color: isDark ? AppColors.gray400 : AppColors.gold,
          size: 20,
        ),
        const SizedBox(width: 8),
        Switch(
          value: isDark,
          onChanged: (_) => themeCubit.toggleTheme(),
          activeTrackColor: AppColors.goldWithAlpha20,
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.gold;
            }
            return null;
          }),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.dark_mode_rounded,
          color: isDark ? AppColors.gold : AppColors.gray400,
          size: 20,
        ),
        if (showLabel) ...[
          const SizedBox(width: 12),
          Text(
            isDark ? 'Modo Oscuro' : 'Modo Claro',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ],
    );
  }
}

/// Control segmentado con 3 opciones: Claro, Sistema, Oscuro
class _SegmentedToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();
    final themeMode = context.select((ThemeCubit cubit) => cubit.state);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tema de la aplicación',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Claro'),
              icon: Icon(Icons.light_mode_rounded, size: 18),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              label: Text('Sistema'),
              icon: Icon(Icons.settings_suggest_rounded, size: 18),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Oscuro'),
              icon: Icon(Icons.dark_mode_rounded, size: 18),
            ),
          ],
          selected: {themeMode},
          onSelectionChanged: (Set<ThemeMode> selection) {
            themeCubit.setThemeMode(selection.first);
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.gold;
              }
              return null;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.white;
              }
              return AppColors.textPrimary;
            }),
          ),
        ),
      ],
    );
  }
}
