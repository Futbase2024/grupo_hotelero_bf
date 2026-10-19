import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

/// Barra de búsqueda + botón de filtros del tab de check-ins.
class CheckinsSearchBar extends StatelessWidget {
  const CheckinsSearchBar({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.hasActiveFilters,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onOpenFilters,
  });

  final TextEditingController controller;
  final String? searchQuery;
  final bool hasActiveFilters;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final hasQuery = searchQuery != null && searchQuery!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: controller,
              onChanged: onSearchChanged,
              style: TextStyle(color: AppColors.getTextPrimaryColor(context)),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, código o unidad...',
                hintStyle:
                    TextStyle(color: AppColors.getTextTertiaryColor(context)),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.getTextTertiaryColor(context),
                ),
                suffixIcon: hasQuery
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: AppColors.getTextTertiaryColor(context),
                          size: 20,
                        ),
                        onPressed: onClearSearch,
                      )
                    : null,
                filled: true,
                fillColor: AppColors.getInputBackgroundColor(context),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.getBorderColor(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gold),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IntrinsicWidth(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onOpenFilters,
                icon: Badge(
                  isLabelVisible: hasActiveFilters,
                  child: const Icon(Icons.tune, size: 20),
                ),
                label: const Text('Filtros'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasActiveFilters
                      ? AppColors.gold
                      : AppColors.getInputBackgroundColor(context),
                  foregroundColor: hasActiveFilters
                      ? AppColors.darkBackground
                      : AppColors.getTextSecondaryColor(context),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: hasActiveFilters
                          ? AppColors.gold
                          : AppColors.getBorderColor(context),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
