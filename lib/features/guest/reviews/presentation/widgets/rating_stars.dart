import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

/// Widget para mostrar rating con estrellas
/// Puede ser de solo lectura o interactivo para seleccionar rating
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.starSize = 20,
    this.spacing = 2,
    this.interactive = false,
    this.onRatingChanged,
    this.activeColor,
    this.inactiveColor,
    this.showLabel = false,
    this.labelStyle,
  });

  /// Rating actual (1-5)
  final int rating;

  /// Máximo rating (por defecto 5)
  final int maxRating;

  /// Tamaño de las estrellas
  final double starSize;

  /// Espacio entre estrellas
  final double spacing;

  /// Si es interactivo (permite seleccionar)
  final bool interactive;

  /// Callback cuando cambia el rating (solo si interactive = true)
  final ValueChanged<int>? onRatingChanged;

  /// Color de estrellas activas
  final Color? activeColor;

  /// Color de estrellas inactivas
  final Color? inactiveColor;

  /// Si muestra el número al lado
  final bool showLabel;

  /// Estilo del label
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final effectiveActiveColor = activeColor ?? AppColors.gold;
    final effectiveInactiveColor = inactiveColor ?? AppColors.gray300;

    final stars = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final isActive = index < rating;
        return GestureDetector(
          onTap: interactive && onRatingChanged != null
              ? () => onRatingChanged!(index + 1)
              : null,
          child: Padding(
            padding: EdgeInsets.only(
              right: index < maxRating - 1 ? spacing : 0,
            ),
            child: Icon(
              isActive ? Icons.star_rounded : Icons.star_outline_rounded,
              size: starSize,
              color: isActive ? effectiveActiveColor : effectiveInactiveColor,
            ),
          ),
        );
      }),
    );

    if (showLabel) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          stars,
          const SizedBox(width: 8),
          Text(
            rating.toString(),
            style: labelStyle ??
                TextStyle(
                  fontSize: starSize * 0.8,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      );
    }

    return stars;
  }
}

/// Widget de estrellas más compacto para mostrar en listas
class RatingStarsCompact extends StatelessWidget {
  const RatingStarsCompact({
    super.key,
    required this.rating,
    this.totalReviews,
  });

  final int rating;
  final int? totalReviews;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: 16,
          color: AppColors.gold,
        ),
        const SizedBox(width: 4),
        Text(
          rating.toString(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (totalReviews != null) ...[
          const SizedBox(width: 4),
          Text(
            '($totalReviews)',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget de estrellas grande para mostrar rating promedio
class RatingStarsLarge extends StatelessWidget {
  const RatingStarsLarge({
    super.key,
    required this.rating,
    this.totalReviews,
    this.starSize = 28,
  });

  final double rating;
  final int? totalReviews;
  final double starSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: starSize * 2,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1,
              ),
            ),
            const SizedBox(width: 8),
            RatingStars(
              rating: rating.round(),
              starSize: starSize,
            ),
          ],
        ),
        if (totalReviews != null) ...[
          const SizedBox(height: 4),
          Text(
            S.of(context).guest_reviews_count_label(totalReviews!),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
