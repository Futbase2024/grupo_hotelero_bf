import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/bloc/reviews_bloc.dart';
import '../../domain/entities/review_entity.dart';
import '../widgets/rating_summary_card.dart';
import '../widgets/review_card.dart';
import '../widgets/review_empty_state.dart';

/// Pantalla que muestra la lista de reseñas de una propiedad
class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({
    super.key,
    required this.propertyId,
    this.propertyName,
    this.guestId,
  });

  final String propertyId;
  final String? propertyName;
  final String? guestId;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.gray900 : AppColors.gray50,
      appBar: AppBar(
        title: Text(
          propertyName ?? S.of(context).guest_reviews_title,
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.gray900,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? AppColors.gray900 : AppColors.gray50,
        foregroundColor: isDark ? AppColors.white : AppColors.gray900,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? AppColors.white : AppColors.gray900,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          // Botón para escribir reseña (solo si está autenticado)
          if (guestId != null)
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: isDark ? AppColors.gold : AppColors.goldDark,
              ),
              onPressed: () => _navigateToCreateReview(context),
              tooltip: S.of(context).guest_reviews_write_review,
            ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<ReviewsBloc, ReviewsState>(
          listener: (context, state) {
            if (state is ReviewCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(S.of(context).guest_reviews_published),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              // Recargar reseñas
              context.read<ReviewsBloc>().add(ReviewsStarted(propertyId: propertyId));
            }
          },
          builder: (context, state) {
            return switch (state) {
              ReviewsInitial() || ReviewsLoading() => const _LoadingView(),
              ReviewsLoaded() => _ReviewsLoadedView(
                  state: state,
                  propertyId: propertyId,
                  guestId: guestId,
                  onWriteReview: () => _navigateToCreateReview(context),
                  onRefresh: () => _onRefresh(context),
                ),
              ReviewsError() => _ErrorView(
                  message: state.message,
                  onRetry: () => _onRetry(context),
                ),
              ReviewCreating() => _LoadingOverlay(message: S.of(context).guest_reviews_publishing),
              ReviewUpdating() => _LoadingOverlay(message: S.of(context).guest_reviews_updating),
              ReviewDeleting() => _LoadingOverlay(message: S.of(context).guest_reviews_deleting),
              _ => const _LoadingView(),
            };
          },
        ),
      ),
    );
  }

  void _navigateToCreateReview(BuildContext context) {
    context.push(
      '/guest/reviews/$propertyId/new',
      extra: {'guestId': guestId, 'propertyName': propertyName},
    );
  }

  void _onRefresh(BuildContext context) {
    context.read<ReviewsBloc>().add(const ReviewsRefreshRequested());
  }

  void _onRetry(BuildContext context) {
    context.read<ReviewsBloc>().add(ReviewsStarted(propertyId: propertyId));
  }
}

/// Vista de carga
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.gold),
          const SizedBox(height: 16),
          Text(
            S.of(context).guest_reviews_loading,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.silver : AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Vista con las reseñas cargadas
class _ReviewsLoadedView extends StatelessWidget {
  const _ReviewsLoadedView({
    required this.state,
    required this.propertyId,
    this.guestId,
    this.onWriteReview,
    this.onRefresh,
  });

  final ReviewsLoaded state;
  final String propertyId;
  final String? guestId;
  final VoidCallback? onWriteReview;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final reviews = state.filteredReviews;

    return RefreshIndicator(
      onRefresh: () async => onRefresh?.call(),
      color: AppColors.gold,
      child: CustomScrollView(
        slivers: [
          // Resumen de ratings
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: RatingSummaryCard(
                reviews: state.reviews,
                onRatingTap: (rating) => _onRatingTap(context, rating),
              ),
            ),
          ),

          // Filtros
          if (state.reviews.isNotEmpty)
            SliverToBoxAdapter(
              child: _FilterChips(
                currentFilter: state.filterMinRating,
                onFilterChanged: (rating) => _onFilterChanged(context, rating),
              ),
            ),

          // Espacio entre filtros y tarjetas
          if (state.reviews.isNotEmpty && reviews.isNotEmpty)
            const SliverToBoxAdapter(
              child: SizedBox(height: 12),
            ),

          // Lista de reseñas o empty state
          if (reviews.isEmpty)
            SliverFillRemaining(
              child: state.reviews.isEmpty
                  ? ReviewEmptyState(
                      canWriteReview: guestId != null,
                      onWriteReview: onWriteReview,
                    )
                  : ReviewFilterEmptyState(
                      currentFilter: state.filterMinRating ?? 0,
                      onClearFilter: () => _onFilterChanged(context, null),
                    ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  final canEdit = guestId != null && guestId == review.guestId;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ReviewCard(
                      review: review,
                      canEdit: canEdit,
                      onEdit: canEdit ? () => _onEditReview(context, review) : null,
                      onDelete: canEdit ? () => _onDeleteReview(context, review) : null,
                    ),
                  );
                },
              ),
            ),

          // Espacio extra al final
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  void _onRatingTap(BuildContext context, int rating) {
    _onFilterChanged(context, rating);
  }

  void _onFilterChanged(BuildContext context, int? rating) {
    context.read<ReviewsBloc>().add(ReviewsFilterByRating(minRating: rating));
  }

  void _onEditReview(BuildContext context, ReviewEntity review) {
    context.push(
      '/guest/reviews/${review.id}/edit',
      extra: {'review': review, 'propertyName': null},
    );
  }

  void _onDeleteReview(BuildContext context, ReviewEntity review) {
    final isDark = AppColors.isDarkMode(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.gray800 : AppColors.white,
        title: Text(
          S.of(dialogContext).guest_reviews_delete_review,
          style: TextStyle(color: isDark ? AppColors.white : AppColors.gray900),
        ),
        content: Text(
          S.of(dialogContext).guest_reviews_delete_confirm,
          style: TextStyle(color: isDark ? AppColors.silver : AppColors.gray700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              S.of(dialogContext).common_cancel,
              style: TextStyle(color: isDark ? AppColors.silver : AppColors.gray600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ReviewsBloc>().add(ReviewsDelete(reviewId: review.id));
            },
            child: Text(S.of(dialogContext).common_delete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

/// Chips de filtro por rating
class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  final int? currentFilter;
  final ValueChanged<int?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Chip "Todos"
          _buildFilterChip(
            context: context,
            label: S.of(context).guest_reviews_filter_all,
            value: null,
            isSelected: currentFilter == null,
            isDark: isDark,
          ),
          const SizedBox(width: 8),

          // Chips por rating
          ...[5, 4, 3, 2, 1].map((rating) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(
                  context: context,
                  label: '$rating ★',
                  value: rating,
                  isSelected: currentFilter == rating,
                  isDark: isDark,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required int? value,
    required bool isSelected,
    required bool isDark,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onFilterChanged(isSelected ? null : value),
      selectedColor: AppColors.goldWithAlpha20,
      checkmarkColor: AppColors.gold,
      backgroundColor: isDark ? AppColors.gray800 : AppColors.gray100,
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.gold
            : (isDark ? AppColors.silver : AppColors.gray700),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.gold : (isDark ? AppColors.gray700 : AppColors.gray300),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

/// Vista de error
class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.silver : AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(S.of(context).common_retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlay de carga
class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      color: AppColors.blackWithAlpha50,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.gray800 : AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.gold),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.white : AppColors.gray900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
