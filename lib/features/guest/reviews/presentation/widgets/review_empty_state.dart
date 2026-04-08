import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

/// Widget que se muestra cuando no hay reseñas
class ReviewEmptyState extends StatelessWidget {
  const ReviewEmptyState({
    super.key,
    this.onWriteReview,
    this.canWriteReview = false,
  });

  final VoidCallback? onWriteReview;
  final bool canWriteReview;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.goldWithAlpha10,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rate_review_outlined,
                size: 40,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 24),

            // Título
            Text(
              S.of(context).guest_reviews_empty_title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.gray900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Descripción
            Text(
              S.of(context).guest_reviews_empty_subtitle,
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? AppColors.silver.withValues(alpha: 0.7)
                    : AppColors.gray600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            // Botón para escribir reseña
            if (canWriteReview && onWriteReview != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onWriteReview,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(S.of(context).guest_reviews_write_first),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

/// Widget cuando no hay reseñas con el filtro aplicado
class ReviewFilterEmptyState extends StatelessWidget {
  const ReviewFilterEmptyState({
    super.key,
    required this.currentFilter,
    this.onClearFilter,
  });

  final int currentFilter;
  final VoidCallback? onClearFilter;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? AppColors.gray800 : AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.filter_list_off,
                size: 32,
                color: isDark ? AppColors.silver : AppColors.gray500,
              ),
            ),
            const SizedBox(height: 16),

            // Título
            Text(
              S
                  .of(context)
                  .guest_reviews_filter_empty_title(currentFilter.toString()),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.gray900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Descripción
            Text(
              S.of(context).guest_reviews_filter_empty_subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.silver.withValues(alpha: 0.7)
                    : AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),

            // Botón para limpiar filtro
            if (onClearFilter != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onClearFilter,
                icon: const Icon(Icons.close, size: 18),
                label: Text(S.of(context).guest_reviews_clear_filter),
                style: TextButton.styleFrom(foregroundColor: AppColors.gold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
