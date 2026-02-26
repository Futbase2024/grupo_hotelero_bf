import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../domain/bloc/parkings_bloc.dart';
import '../../domain/entities/unit_parking_entity.dart';
import '../../domain/repositories/parkings_repository.dart';
import '../widgets/parking_card.dart';

/// Pantalla principal de Parkings
class ParkingsScreen extends StatelessWidget {
  const ParkingsScreen({
    super.key,
    this.unitId,
  });

  /// ID de la unidad para filtrar parkings (opcional)
  final String? unitId;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return BlocProvider(
      create: (context) => ParkingsBloc(
        parkingsRepository: getIt<ParkingsRepository>(),
      )..add(const ParkingsStarted()),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.black : AppColors.gray50,
        body: const SafeArea(
          top: false,
          child: _ParkingsBody(),
        ),
      ),
    );
  }
}

/// Body de la pantalla con acceso al BLoC
class _ParkingsBody extends StatelessWidget {
  const _ParkingsBody();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ParkingsBloc, ParkingsState>(
      listener: (context, state) {
        if (state is ParkingsError) {
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
              onRefresh: () => _onRefresh(context),
            ),

            // Contenido según estado
            if (state is ParkingsInitial || state is ParkingsLoading)
              const SliverFillRemaining(
                child: _LoadingView(),
              )
            else if (state is ParkingsError)
              SliverFillRemaining(
                child: _ErrorView(
                  message: state.message,
                  onRetry: () => _onRetry(context),
                ),
              )
            else if (state is AllUnitParkingsLoaded)
              state.groupedParkings.isEmpty
                  ? const SliverFillRemaining(
                      child: _EmptyView(),
                    )
                  : _GroupedParkingsList(
                      groupedParkings: state.groupedParkings,
                    ),
          ],
        );
      },
    );
  }

  void _onRefresh(BuildContext context) {
    context.read<ParkingsBloc>().add(const ParkingsRefreshRequested());
  }

  void _onRetry(BuildContext context) {
    context.read<ParkingsBloc>().add(const ParkingsLoadRequested());
  }
}

/// AppBar con título
class _SliverAppBar extends StatelessWidget {
  const _SliverAppBar({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: isDark ? AppColors.black : AppColors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.gold,
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'P',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Parkings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(
            Icons.refresh,
            color: AppColors.gold,
          ),
        ),
      ],
    );
  }
}

/// Lista de parkings agrupados por unidad
class _GroupedParkingsList extends StatelessWidget {
  const _GroupedParkingsList({
    required this.groupedParkings,
  });

  final Map<String, List<UnitParkingEntity>> groupedParkings;

  @override
  Widget build(BuildContext context) {
    final unitIds = groupedParkings.keys.toList();

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final unitId = unitIds[index];
            final parkings = groupedParkings[unitId]!;
            final unitName = parkings.first.unitName ?? 'Alojamiento';

            return _UnitParkingSection(
              unitName: unitName,
              parkings: parkings,
            );
          },
          childCount: unitIds.length,
        ),
      ),
    );
  }
}

/// Sección de parkings para una unidad específica (colapsable)
class _UnitParkingSection extends StatefulWidget {
  const _UnitParkingSection({
    required this.unitName,
    required this.parkings,
  });

  final String unitName;
  final List<UnitParkingEntity> parkings;

  @override
  State<_UnitParkingSection> createState() => _UnitParkingSectionState();
}

class _UnitParkingSectionState extends State<_UnitParkingSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.gray900 : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.gray800 : AppColors.gray200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la unidad (clickeable para expandir/contraer)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.goldWithAlpha10,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: _isExpanded ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.goldWithAlpha20,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.home_outlined,
                      size: 20,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.unitName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextPrimaryColor(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.parkings.length} ${widget.parkings.length == 1 ? 'parking disponible' : 'parkings disponibles'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.getTextSecondaryColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.gold,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),

          // Lista de parkings (solo si está expandido)
          if (_isExpanded)
            ...widget.parkings.map((unitParking) {
              final parking = unitParking.parking;
              if (parking == null) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: ParkingCard(
                  parking: parking,
                  priority: unitParking.priority,
                  notes: unitParking.notes,
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Vista de carga
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: AppColors.gold,
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
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error al cargar',
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
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

/// Vista vacía
class _EmptyView extends StatelessWidget {
  const _EmptyView();

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
              child: Icon(
                Icons.local_parking,
                size: 40,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay parkings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pronto añadiremos información de parkings cercanos',
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
