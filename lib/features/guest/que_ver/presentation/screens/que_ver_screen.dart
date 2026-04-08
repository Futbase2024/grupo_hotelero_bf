import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bf_stay/l10n/app_localizations.dart';
import '../../../../../../core/di/injection.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../shared/widgets/responsive_grid_view.dart';
import '../../domain/bloc/que_ver_bloc.dart';
import '../../domain/entities/place_entity.dart';
import '../../domain/repositories/places_repository.dart';
import '../widgets/category_filter_chip.dart';
import '../widgets/level_filter_chip.dart';
import '../widgets/place_card.dart';

/// Pantalla principal de "¿Qué ver?"
class QueVerScreen extends StatelessWidget {
  const QueVerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return BlocProvider(
      create: (context) => QueVerBloc(
        placesRepository: getIt<PlacesRepository>(),
      )..add(const QueVerStarted()),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.black : AppColors.gray50,
        body: const SafeArea(
          top: false,
          child: _QueVerBody(),
        ),
      ),
    );
  }
}

/// Body de la pantalla con acceso al BLoC
class _QueVerBody extends StatelessWidget {
  const _QueVerBody();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QueVerBloc, QueVerState>(
      listener: (context, state) {
        if (state is QueVerError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            // AppBar
            _SliverAppBar(
              hasActiveFilters: state is QueVerLoaded && state.hasActiveFilters,
              onClearFilters: state is QueVerLoaded && state.hasActiveFilters
                  ? () => _onClearFilters(context)
                  : null,
            ),

            // Contenido según estado
            if (state is QueVerInitial || state is QueVerLoading)
              const SliverFillRemaining(
                child: _LoadingView(),
              )
            else if (state is QueVerError)
              SliverFillRemaining(
                child: _ErrorView(message: state.message),
              )
            else if (state is QueVerLoaded) ...[
              // Filtros de nivel
              SliverPersistentHeader(
                pinned: true,
                delegate: _LevelFilterHeader(
                  levelsWithCount: state.levelsWithCount,
                  selectedLevel: state.selectedLevel,
                  onLevelSelected: (level) => _onLevelChanged(context, level),
                ),
              ),

              // Filtros de categoría
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoryFilterHeader(
                  categoriesWithCount: state.categoriesWithCount,
                  selectedCategory: state.selectedCategory,
                  onCategorySelected: (category) =>
                      _onCategoryChanged(context, category),
                ),
              ),

              // Contador de resultados
              SliverToBoxAdapter(
                child: _ResultsCount(count: state.resultCount),
              ),

              // Grid de lugares
              state.filteredPlaces.isEmpty
                  ? SliverFillRemaining(
                      child: _EmptyView(hasFilters: state.hasActiveFilters),
                    )
                  : _PlacesGrid(
                      places: state.filteredPlaces,
                      isRefreshing: state.isRefreshing,
                      onRefresh: () => _onRefresh(context),
                      onPlaceTap: (place) => _onPlaceTap(context, place),
                    ),
            ],
          ],
        );
      },
    );
  }

  void _onRefresh(BuildContext context) {
    context.read<QueVerBloc>().add(const QueVerRefreshRequested());
  }

  void _onLevelChanged(BuildContext context, PlaceLevel? level) {
    context.read<QueVerBloc>().add(QueVerLevelFilterChanged(level: level));
  }

  void _onCategoryChanged(BuildContext context, String? category) {
    context.read<QueVerBloc>().add(QueVerCategoryFilterChanged(category: category));
  }

  void _onPlaceTap(BuildContext context, PlaceEntity place) {
    context.pushNamed(
      'place-detail',
      pathParameters: {'id': place.id},
      extra: {'place': place},
    );
  }

  void _onClearFilters(BuildContext context) {
    context.read<QueVerBloc>().add(const QueVerClearFilters());
  }
}

/// AppBar con título y botón de búsqueda
class _SliverAppBar extends StatelessWidget {
  const _SliverAppBar({
    required this.hasActiveFilters,
    this.onClearFilters,
  });

  final bool hasActiveFilters;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: isDark ? AppColors.black : AppColors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.gold,
        ),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
      title: Text(
        S.of(context).guest_que_ver_title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: isDark ? AppColors.gold : AppColors.textPrimary,
        ),
      ),
      actions: [
        if (hasActiveFilters && onClearFilters != null)
          TextButton(
            onPressed: onClearFilters,
            child: Text(
              S.of(context).guest_que_ver_clear_filters,
              style: TextStyle(
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

/// Header de filtros de nivel
class _LevelFilterHeader extends SliverPersistentHeaderDelegate {
  _LevelFilterHeader({
    required this.levelsWithCount,
    required this.selectedLevel,
    required this.onLevelSelected,
  });

  final Map<PlaceLevel, int> levelsWithCount;
  final PlaceLevel? selectedLevel;
  final void Function(PlaceLevel? level) onLevelSelected;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      color: isDark ? AppColors.black : AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LevelFilterRow(
        levelsWithCount: levelsWithCount,
        selectedLevel: selectedLevel,
        onLevelSelected: onLevelSelected,
      ),
    );
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant _LevelFilterHeader oldDelegate) {
    return levelsWithCount != oldDelegate.levelsWithCount ||
        selectedLevel != oldDelegate.selectedLevel;
  }
}

/// Header de filtros de categoría
class _CategoryFilterHeader extends SliverPersistentHeaderDelegate {
  _CategoryFilterHeader({
    required this.categoriesWithCount,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final Map<String, int> categoriesWithCount;
  final String? selectedCategory;
  final void Function(String? category) onCategorySelected;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      color: isDark ? AppColors.black : AppColors.white,
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: CategoryFilterRow(
        categoriesWithCount: categoriesWithCount,
        selectedCategory: selectedCategory,
        onCategorySelected: onCategorySelected,
      ),
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant _CategoryFilterHeader oldDelegate) {
    return categoriesWithCount != oldDelegate.categoriesWithCount ||
        selectedCategory != oldDelegate.selectedCategory;
  }
}

/// Contador de resultados
class _ResultsCount extends StatelessWidget {
  const _ResultsCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        S.of(context).guest_que_ver_places_count(count),
        style: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.black : AppColors.gray600,
        ),
      ),
    );
  }
}

/// Grid de lugares responsivo
class _PlacesGrid extends StatelessWidget {
  const _PlacesGrid({
    required this.places,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onPlaceTap,
  });

  final List<PlaceEntity> places;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final void Function(PlaceEntity place) onPlaceTap;

  @override
  Widget build(BuildContext context) {
    return SliverResponsiveGridView<PlaceEntity>(
      items: places,
      itemBuilder: (context, place) => PlaceCard(
        place: place,
        onTap: () => onPlaceTap(place),
      ),
      minItemWidth: 160,
      maxItemWidth: 220,
      minItemsPerRow: 2,
      maxItemsPerRow: 3,
      itemSpacing: 12,
      rowSpacing: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

/// Vista de carga
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.gold,
      ),
    );
  }
}

/// Vista de error
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              S.of(context).guest_alojamientos_error_title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista vacía
class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.hasFilters});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.goldWithAlpha20,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 40,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilters ? S.of(context).guest_que_ver_no_results : S.of(context).guest_que_ver_no_places,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? S.of(context).guest_que_ver_try_filters
                  : S.of(context).guest_que_ver_coming_soon,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
