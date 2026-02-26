import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../domain/bloc/alojamientos_bloc.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/entities/unit_entity.dart';
import '../../domain/entities/unit_photo_entity.dart';

/// Pantalla de listado de alojamientos para huéspedes
class AlojamientosScreen extends StatefulWidget {
  const AlojamientosScreen({super.key});

  @override
  State<AlojamientosScreen> createState() => _AlojamientosScreenState();
}

class _AlojamientosScreenState extends State<AlojamientosScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.gray900 : AppColors.gray50,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.gray900 : AppColors.gray50,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? AppColors.gold : AppColors.gray900,
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
          'Nuestros Alojamientos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.white : AppColors.gray900,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: BlocConsumer<AlojamientosBloc, AlojamientosState>(
          listener: (context, state) {
            if (state is AlojamientosError) {
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
            if (state is AlojamientosInitial || state is AlojamientosLoading) {
              return const _LoadingView();
            }

            if (state is AlojamientosError) {
              return _ErrorView(
                message: state.message,
                onRetry: _onRetry,
              );
            }

            if (state is AlojamientosLoaded) {
              return _LoadedView(
                properties: state.properties,
                coverPhotos: state.coverPhotos,
              );
            }

            return const _LoadingView();
          },
        ),
      ),
    );
  }

  void _onRetry() {
    context.read<AlojamientosBloc>().add(
          const AlojamientosLoadRequested(),
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
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
                color: isDark ? AppColors.white : AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.silver : AppColors.gray600,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista con datos cargados - Grid de alojamientos
class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.properties,
    this.coverPhotos = const {},
  });

  final List<PropertyEntity> properties;
  final Map<String, UnitPhotoEntity> coverPhotos;

  /// Obtiene todas las unidades de todas las propiedades
  List<UnitEntity> get _allUnits {
    return properties.expand((p) => p.units).toList();
  }

  @override
  Widget build(BuildContext context) {
    final units = _allUnits;

    if (units.isEmpty) {
      return const _EmptyView();
    }

    return CustomScrollView(
      slivers: [
        // Grid de alojamientos
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppTheme.spacing16,
              crossAxisSpacing: AppTheme.spacing16,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final unit = units[index];
                final coverPhoto = coverPhotos[unit.id];
                return _UnitCard(unit: unit, index: index, coverPhoto: coverPhoto);
              },
              childCount: units.length,
            ),
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: AppTheme.spacing24),
        ),
      ],
    );
  }
}

/// Card de unidad con imagen de fondo y texto debajo
class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.index,
    this.coverPhoto,
  });

  final UnitEntity unit;
  final int index;
  final UnitPhotoEntity? coverPhoto;

  /// Colores para los gradientes de fondo
  static const List<List<Color>> _gradientColors = [
    [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)], // Azul oscuro
    [Color(0xFF2d132c), Color(0xFF801336), Color(0xFFc72c41)], // Burdeos
    [Color(0xFF0d1b2a), Color(0xFF1b263b), Color(0xFF415a77)], // Azul grisáceo
    [Color(0xFF1a1a1a), Color(0xFF2d2d2d), Color(0xFF404040)], // Negro/Gris
    [Color(0xFF0c1821), Color(0xFF1b2838), Color(0xFF324a5f)], // Azul profundo
    [Color(0xFF2c3e50), Color(0xFF34495e), Color(0xFF5d6d7e)], // Gris azulado
  ];

  List<Color> get _colors => _gradientColors[index % _gradientColors.length];

  /// Obtiene la URL pública de una imagen de Supabase Storage
  String _getImageUrl(String path) {
    return Supabase.instance.client.storage
        .from('unit-photos')
        .getPublicUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    // Borde dorado más visible en modo oscuro
    final borderColor = isDark ? AppColors.gold : AppColors.black.withValues(alpha: 0.15);
    // Fondo de la sección de texto adaptado al tema
    final cardBgColor = isDark ? AppColors.blackLight : AppColors.white;
    final hasCoverPhoto = coverPhoto != null;

    return GestureDetector(
      onTap: () {
        context.go('/guest/alojamientos/unit/${unit.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: borderColor, width: isDark ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
              color: isDark ? AppColors.gold.withValues(alpha: 0.1) : AppColors.black.withValues(alpha: 0.1),
              blurRadius: isDark ? 16 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge - 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen de fondo con gradiente o foto real
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Imagen o gradiente de fondo
                    if (hasCoverPhoto)
                      CachedNetworkImage(
                        imageUrl: _getImageUrl(coverPhoto!.path),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _colors,
                            ),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.gold,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _colors,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              unit.unitType == UnitType.apartment
                                  ? Icons.apartment_rounded
                                  : Icons.bed_rounded,
                              size: 48,
                              color: AppColors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _colors,
                          ),
                        ),
                      ),
                    // Overlay con gradiente
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                    // Icono decorativo (solo si no hay foto)
                    if (!hasCoverPhoto)
                      Center(
                        child: Icon(
                          unit.unitType == UnitType.apartment
                              ? Icons.apartment_rounded
                              : Icons.bed_rounded,
                          size: 48,
                          color: AppColors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    // Badge de tipo
                    Positioned(
                      top: AppTheme.spacing12,
                      right: AppTheme.spacing12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing8,
                          vertical: AppTheme.spacing4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Text(
                          unit.unitType.displayName,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Texto debajo - fondo adaptado al tema
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppTheme.radiusLarge - 1),
                      bottomRight: Radius.circular(AppTheme.radiusLarge - 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        unit.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.white : AppColors.gray900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (unit.fullAddress != null && unit.fullAddress!.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spacing4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: isDark ? AppColors.silver : AppColors.gray500,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                unit.fullAddress!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.silver : AppColors.gray500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppTheme.spacing8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
    final isDark = AppColors.isDarkMode(context);

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
                color: AppColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.home_work_outlined,
                size: 40,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay alojamientos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay alojamientos disponibles en este momento',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.silver : AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
