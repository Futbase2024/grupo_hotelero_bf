import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../domain/entities/place_entity.dart';

/// Chip de filtro por nivel geográfico
class LevelFilterChip extends StatelessWidget {
  const LevelFilterChip({
    super.key,
    required this.level,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final PlaceLevel level;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  Color get _backgroundColor {
    if (isSelected) {
      switch (level) {
        case PlaceLevel.jerez:
          return AppColors.gold; // Dorado principal
        case PlaceLevel.alrededores:
          return AppColors.goldDark; // Dorado más oscuro
        case PlaceLevel.provincia:
          return AppColors.goldLight; // Dorado más claro
      }
    }
    return Colors.transparent;
  }

  Color get _borderColor {
    if (isSelected) {
      switch (level) {
        case PlaceLevel.jerez:
          return AppColors.gold;
        case PlaceLevel.alrededores:
          return AppColors.goldDark;
        case PlaceLevel.provincia:
          return AppColors.goldLight;
      }
    }
    return AppColors.gray300;
  }

  Color get _textColor {
    if (isSelected) return AppColors.black;
    switch (level) {
      case PlaceLevel.jerez:
        return AppColors.gold;
      case PlaceLevel.alrededores:
        return AppColors.goldDark;
      case PlaceLevel.provincia:
        return AppColors.goldLight;
    }
  }

  IconData get _icon {
    switch (level) {
      case PlaceLevel.jerez:
        return Icons.location_city;
      case PlaceLevel.alrededores:
        return Icons.drive_eta;
      case PlaceLevel.provincia:
        return Icons.map_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _backgroundColor.withValues(
            alpha: isSelected ? 1.0 : (isDark ? 0.1 : 0.05),
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _borderColor : AppColors.gray300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon,
              size: 18,
              color: _textColor,
            ),
            const SizedBox(width: 8),
            Text(
              level.shortName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: _textColor,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.black
                      : (isDark ? AppColors.gray700 : AppColors.gray200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.white
                        : (isDark ? AppColors.gray400 : AppColors.gray600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget que muestra los niveles geográficos como chips
class LevelFilterRow extends StatelessWidget {
  const LevelFilterRow({
    super.key,
    required this.levelsWithCount,
    required this.selectedLevel,
    required void Function(PlaceLevel? level) onLevelSelected,
  }) : _onLevelSelected = onLevelSelected;

  final Map<PlaceLevel, int> levelsWithCount;
  final PlaceLevel? selectedLevel;
  final void Function(PlaceLevel? level) _onLevelSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Chip "Todos"
          _AllLevelsChip(
            totalCount: levelsWithCount.values.fold(0, (a, b) => a + b),
            isSelected: selectedLevel == null,
            onTap: () => _onLevelSelected(null),
          ),
          ...PlaceLevel.values.map((level) {
            final count = levelsWithCount[level] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: LevelFilterChip(
                level: level,
                count: count,
                isSelected: selectedLevel == level,
                onTap: () => _onLevelSelected(
                  selectedLevel == level ? null : level,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Chip para "Todos los niveles"
class _AllLevelsChip extends StatelessWidget {
  const _AllLevelsChip({
    required this.totalCount,
    required this.isSelected,
    required this.onTap,
  });

  final int totalCount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold
              : (isDark ? AppColors.gray800 : AppColors.gray100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.gray300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.public,
              size: 18,
              color: isSelected
                  ? AppColors.black
                  : (isDark ? AppColors.gray300 : AppColors.gray700),
            ),
            const SizedBox(width: 8),
            Text(
              'Todos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.black
                    : (isDark ? AppColors.gray300 : AppColors.gray700),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.black
                    : (isDark ? AppColors.gray700 : AppColors.gray200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                totalCount.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.white
                      : (isDark ? AppColors.gray400 : AppColors.gray600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
