import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/review_entity.dart';
import 'rating_stars.dart';

/// Widget que muestra el resumen de ratings con barras de distribución
class RatingSummaryCard extends StatelessWidget {
  const RatingSummaryCard({
    super.key,
    required this.reviews,
    this.onRatingTap,
  });

  final List<ReviewEntity> reviews;
  final ValueChanged<int>? onRatingTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    if (reviews.isEmpty) {
      return _EmptyRatingSummary(isDark: isDark);
    }

    final averageRating = reviews.averageRating;
    final distribution = reviews.ratingDistribution;
    final totalReviews = reviews.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.gray800 : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.gold.withValues(alpha: 0.3) : AppColors.gray200,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating promedio grande
          _buildAverageRating(averageRating, totalReviews, isDark),
          const SizedBox(width: 24),

          // Distribución de ratings
          Expanded(
            child: _buildRatingDistribution(distribution, totalReviews, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageRating(double averageRating, int totalReviews, bool isDark) {
    return Column(
      children: [
        // Número grande
        Text(
          averageRating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.gray900,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),

        // Estrellas
        RatingStars(
          rating: averageRating.round(),
          starSize: 20,
        ),
        const SizedBox(height: 8),

        // Total de reseñas
        Text(
          '$totalReviews ${totalReviews == 1 ? 'reseña' : 'reseñas'}',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.silver.withValues(alpha: 0.7) : AppColors.gray500,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingDistribution(
    Map<int, int> distribution,
    int totalReviews,
    bool isDark,
  ) {
    return Column(
      children: [5, 4, 3, 2, 1].map((rating) {
        final count = distribution[rating] ?? 0;
        final percentage = totalReviews > 0 ? count / totalReviews : 0.0;

        return _RatingBar(
          rating: rating,
          count: count,
          percentage: percentage,
          onTap: onRatingTap != null ? () => onRatingTap!(rating) : null,
          isDark: isDark,
        );
      }).toList(),
    );
  }
}

/// Barra individual de rating
class _RatingBar extends StatelessWidget {
  const _RatingBar({
    required this.rating,
    required this.count,
    required this.percentage,
    required this.isDark,
    this.onTap,
  });

  final int rating;
  final int count;
  final double percentage;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            // Número de estrellas
            SizedBox(
              width: 16,
              child: Text(
                rating.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.silver.withValues(alpha: 0.7) : AppColors.gray500,
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Estrella pequeña
            const Icon(
              Icons.star_rounded,
              size: 16,
              color: AppColors.gold,
            ),
            const SizedBox(width: 8),

            // Barra de progreso
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: isDark ? AppColors.gray700 : AppColors.gray200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Cantidad
            SizedBox(
              width: 24,
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.silver.withValues(alpha: 0.7) : AppColors.gray500,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget cuando no hay reseñas
class _EmptyRatingSummary extends StatelessWidget {
  const _EmptyRatingSummary({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.gray800 : AppColors.gray50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.gold.withValues(alpha: 0.3) : AppColors.gray200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.star_outline_rounded,
            size: 48,
            color: isDark ? AppColors.silver.withValues(alpha: 0.5) : AppColors.gray400,
          ),
          const SizedBox(height: 12),
          Text(
            'Sin reseñas aún',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.white : AppColors.gray900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sé el primero en dejar una reseña',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.silver.withValues(alpha: 0.7) : AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}
