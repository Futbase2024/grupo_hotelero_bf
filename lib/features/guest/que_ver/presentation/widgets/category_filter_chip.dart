import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

/// Chip de filtro por categoría
class CategoryFilterChip extends StatelessWidget {
  const CategoryFilterChip({
    super.key,
    required this.category,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String category;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  /// Obtiene el nombre de visualización de la categoría
  String get _displayName {
    switch (category) {
      case 'cultura':
        return 'Cultura';
      case 'monumentos':
        return 'Monumentos';
      case 'gastronomia':
        return 'Gastronomía';
      case 'enoturismo':
        return 'Enoturismo';
      case 'flamenco':
        return 'Flamenco';
      case 'naturaleza':
        return 'Naturaleza';
      case 'familias':
        return 'Familias';
      case 'compras':
        return 'Compras';
      case 'experiencias':
        return 'Experiencias';
      case 'playa':
        return 'Playa';
      case 'pueblos_blancos':
        return 'Pueblos Blancos';
      default:
        return category;
    }
  }

  /// Obtiene el icono de la categoría
  IconData get _icon {
    switch (category) {
      case 'cultura':
        return Icons.museum_outlined;
      case 'monumentos':
        return Icons.account_balance_outlined;
      case 'gastronomia':
        return Icons.restaurant_outlined;
      case 'enoturismo':
        return Icons.wine_bar_outlined;
      case 'flamenco':
        return Icons.music_note_outlined;
      case 'naturaleza':
        return Icons.park_outlined;
      case 'familias':
        return Icons.family_restroom_outlined;
      case 'compras':
        return Icons.shopping_bag_outlined;
      case 'experiencias':
        return Icons.star_outlined;
      case 'playa':
        return Icons.beach_access_outlined;
      case 'pueblos_blancos':
        return Icons.home_outlined;
      default:
        return Icons.place_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold
              : (isDark ? AppColors.gray800 : AppColors.gray100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.gold
                : (isDark ? AppColors.gray700 : AppColors.gray200),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon,
              size: 16,
              color: isSelected
                  ? AppColors.black
                  : (isDark ? AppColors.gray300 : AppColors.gray700),
            ),
            const SizedBox(width: 6),
            Text(
              _displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.black
                    : (isDark ? AppColors.gray300 : AppColors.gray700),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.black
                      : (isDark ? AppColors.gray700 : AppColors.gray200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
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

/// Widget que muestra todas las categorías como chips horizontales scrollables
class CategoryFilterRow extends StatelessWidget {
  const CategoryFilterRow({
    super.key,
    required this.categoriesWithCount,
    required this.selectedCategory,
    required void Function(String? category) onCategorySelected,
  }) : _onCategorySelected = onCategorySelected;

  final Map<String, int> categoriesWithCount;
  final String? selectedCategory;
  final void Function(String? category) _onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final sortedCategories = categoriesWithCount.keys.toList()..sort();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sortedCategories.length + 1, // +1 para "Todos"
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            // Chip "Todos"
            return CategoryFilterChip(
              category: 'todos',
              count: categoriesWithCount.values.fold(0, (a, b) => a + b),
              isSelected: selectedCategory == null,
              onTap: () => _onCategorySelected(null),
            );
          }

          final category = sortedCategories[index - 1];
          final count = categoriesWithCount[category] ?? 0;

          return CategoryFilterChip(
            category: category,
            count: count,
            isSelected: selectedCategory == category,
            onTap: () => _onCategorySelected(
              selectedCategory == category ? null : category,
            ),
          );
        },
      ),
    );
  }
}
