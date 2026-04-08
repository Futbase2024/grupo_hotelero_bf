import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/review_entity.dart';
import 'rating_stars.dart';

/// Tarjeta que muestra una reseña individual
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.review,
    this.onEdit,
    this.onDelete,
    this.canEdit = false,
    this.showProperty = false,
  });

  final ReviewEntity review;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool canEdit;
  final bool showProperty;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.gray800 : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.gold.withValues(alpha: 0.3) : AppColors.gray200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, nombre, fecha, verificado
          _buildHeader(context, isDark),
          const SizedBox(height: 12),

          // Rating
          RatingStars(rating: review.rating, starSize: 18),
          const SizedBox(height: 12),

          // Título (si existe)
          if (review.hasTitle) ...[
            Text(
              review.title!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Comentario
          _CommentText(comment: review.comment, isDark: isDark),

          // Acciones (editar/eliminar)
          if (canEdit && (onEdit != null || onDelete != null))
            _buildActions(context, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        // Avatar con iniciales
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.goldWithAlpha20,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              review.guestInitials,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.gold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Nombre y fecha
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      review.displayGuestName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.white : AppColors.gray900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (review.isVerified) ...[
                    const SizedBox(width: 8),
                    _VerifiedBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                review.timeAgo,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.silver.withValues(alpha: 0.7) : AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (onEdit != null)
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(S.of(context).common_edit),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? AppColors.silver : AppColors.gray600,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(S.of(context).common_delete),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Badge de verificado
class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 12,
            color: AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            S.of(context).guest_reviews_verified,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

/// Texto del comentario con "Ver más" si es muy largo
class _CommentText extends StatefulWidget {
  const _CommentText({required this.comment, required this.isDark});

  final String comment;
  final bool isDark;

  @override
  State<_CommentText> createState() => _CommentTextState();
}

class _CommentTextState extends State<_CommentText> {
  bool _isExpanded = false;
  static const int _maxLines = 4;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.comment.length > 200;

    if (!isLong) {
      return Text(
        widget.comment,
        style: TextStyle(
          fontSize: 14,
          color: widget.isDark ? AppColors.silver : AppColors.gray700,
          height: 1.5,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.comment,
          style: TextStyle(
            fontSize: 14,
            color: widget.isDark ? AppColors.silver : AppColors.gray700,
            height: 1.5,
          ),
          maxLines: _isExpanded ? null : _maxLines,
          overflow: _isExpanded ? null : TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Text(
            _isExpanded ? S.of(context).guest_reviews_show_less : S.of(context).guest_reviews_show_more,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.gold,
            ),
          ),
        ),
      ],
    );
  }
}
