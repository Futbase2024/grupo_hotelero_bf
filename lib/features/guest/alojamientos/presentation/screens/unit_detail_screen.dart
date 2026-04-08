import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bf_stay/l10n/app_localizations.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../domain/bloc/alojamientos_bloc.dart';
import '../../domain/entities/unit_entity.dart';
import '../../domain/entities/unit_photo_entity.dart';

/// Pantalla de detalle de una unidad individual
class UnitDetailScreen extends StatefulWidget {
  const UnitDetailScreen({
    super.key,
    required this.unitId,
  });

  final String unitId;

  @override
  State<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends State<UnitDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.gray900 : AppColors.gray50,
      body: SafeArea(
        top: false,
        child: BlocBuilder<AlojamientosBloc, AlojamientosState>(
          builder: (context, state) {
            if (state is AlojamientosLoading) {
              return const _LoadingView();
            }

            if (state is AlojamientosError) {
              return _ErrorView(
                message: state.message,
                onRetry: () {
                  context.read<AlojamientosBloc>().add(
                        UnitDetailRequested(unitId: widget.unitId),
                      );
                },
              );
            }

            if (state is UnitDetailLoaded) {
              return _UnitDetailView(unit: state.unit, photos: state.photos);
            }

            return const _LoadingView();
          },
        ),
      ),
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
              S.of(context).guest_alojamientos_error_title,
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
              label: Text(S.of(context).common_retry),
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

/// Vista principal del detalle de unidad
class _UnitDetailView extends StatelessWidget {
  const _UnitDetailView({
    required this.unit,
    this.photos = const [],
  });

  final UnitEntity unit;
  final List<UnitPhotoEntity> photos;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return CustomScrollView(
      slivers: [
        // AppBar con imagen de fondo
        _SliverAppBar(unit: unit, photos: photos),

        // Contenido
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.gray900 : AppColors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y tipo
                  _TitleSection(unit: unit),

                  const SizedBox(height: AppTheme.spacing24),

                  // Dirección
                  if (unit.fullAddress != null && unit.fullAddress!.isNotEmpty)
                    _AddressSection(unit: unit),

                  const SizedBox(height: AppTheme.spacing24),

                  // Características
                  _FeaturesSection(unit: unit),

                  const SizedBox(height: AppTheme.spacing32),

                  // Descripción placeholder
                  _DescriptionSection(unit: unit),

                  const SizedBox(height: AppTheme.spacing32),

                  // Servicios
                  _ServicesSection(unit: unit),

                  const SizedBox(height: AppTheme.spacing32),

                  // Información de acceso
                  if (unit.boxLocationText != null ||
                      unit.accessInstructions != null)
                    _AccessSection(unit: unit),

                  const SizedBox(height: AppTheme.spacing40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// AppBar con galería de imágenes y botón de volver
class _SliverAppBar extends StatefulWidget {
  const _SliverAppBar({
    required this.unit,
    this.photos = const [],
  });

  final UnitEntity unit;
  final List<UnitPhotoEntity> photos;

  @override
  State<_SliverAppBar> createState() => _SliverAppBarState();
}

class _SliverAppBarState extends State<_SliverAppBar> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Obtiene la URL pública de una imagen de Supabase Storage
  String _getImageUrl(String path) {
    return Supabase.instance.client.storage
        .from('unit-photos')
        .getPublicUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    final hasPhotos = widget.photos.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 320,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? AppColors.gray900 : AppColors.white,
      foregroundColor: isDark ? AppColors.white : AppColors.gray900,
      leading: GestureDetector(
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.alojamientos);
          }
        },
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.black.withValues(alpha: 0.5)
                : AppColors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: isDark ? AppColors.white : AppColors.gray900,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: hasPhotos
            ? _PhotoGallery(
                photos: widget.photos,
                pageController: _pageController,
                getImageUrl: _getImageUrl,
              )
            : _PlaceholderContent(unit: widget.unit),
      ),
    );
  }
}

/// Galería de fotos con PageView
class _PhotoGallery extends StatelessWidget {
  const _PhotoGallery({
    required this.photos,
    required this.pageController,
    required this.getImageUrl,
  });

  final List<UnitPhotoEntity> photos;
  final PageController pageController;
  final String Function(String) getImageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // PageView con imágenes
        PageView.builder(
          controller: pageController,
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            final imageUrl = getImageUrl(photo.path);

            return CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.gray200,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.gold,
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.gray200,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  size: 48,
                  color: AppColors.gray400,
                ),
              ),
            );
          },
        ),
        // Gradiente inferior para mejor legibilidad
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),
        // Indicadores de página
        if (photos.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: _PageIndicator(
              count: photos.length,
              controller: pageController,
            ),
          ),
      ],
    );
  }
}

/// Indicadores de página
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.controller,
  });

  final int count;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        int currentPage = 0;
        if (controller.hasClients) {
          currentPage = controller.page?.round() ?? 0;
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (index) {
            final isActive = index == currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? AppColors.white : AppColors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Contenido placeholder cuando no hay fotos
class _PlaceholderContent extends StatelessWidget {
  const _PlaceholderContent({required this.unit});

  final UnitEntity unit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradiente de fondo elegante
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gold.withValues(alpha: 0.15),
                AppColors.goldDark.withValues(alpha: 0.25),
                AppColors.black.withValues(alpha: 0.4),
              ],
            ),
          ),
        ),
        // Patrón decorativo
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppColors.black.withValues(alpha: 0.2),
              ],
            ),
          ),
        ),
        // Icono central
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  unit.unitType == UnitType.apartment
                      ? Icons.apartment_rounded
                      : Icons.bed_rounded,
                  size: 40,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  unit.unitType.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sección de título
class _TitleSection extends StatelessWidget {
  const _TitleSection({required this.unit});

  final UnitEntity unit;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          unit.name,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.gray900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.goldWithAlpha20,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    unit.unitType == UnitType.apartment
                        ? Icons.apartment_outlined
                        : Icons.bed_outlined,
                    size: 16,
                    color: AppColors.goldDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    unit.unitType.displayName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Sección de dirección
class _AddressSection extends StatelessWidget {
  const _AddressSection({required this.unit});

  final UnitEntity unit;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.blackLight
            : AppColors.gray100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.gray800
              : AppColors.gray200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.goldWithAlpha20,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              size: 22,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).guest_alojamiento_location,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.silver : AppColors.gray500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unit.fullAddress!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.white : AppColors.gray900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección de características
class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection({required this.unit});

  final UnitEntity unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: S.of(context).guest_alojamiento_features),
        const SizedBox(height: AppTheme.spacing16),
        Row(
          children: [
            _FeatureCard(
              icon: Icons.check_circle_outline,
              label: S.of(context).guest_alojamiento_feature_flexible_checkin,
            ),
            const SizedBox(width: AppTheme.spacing12),
            _FeatureCard(
              icon: Icons.wifi_outlined,
              label: S.of(context).guest_alojamiento_feature_wifi,
            ),
            const SizedBox(width: AppTheme.spacing12),
            _FeatureCard(
              icon: Icons.ac_unit_outlined,
              label: S.of(context).guest_alojamiento_feature_ac,
            ),
          ],
        ),
      ],
    );
  }
}

/// Tarjeta de característica
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.blackLight
              : AppColors.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? AppColors.gray800
                : AppColors.gray200,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: AppColors.gold,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.silver : AppColors.gray600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sección de descripción
class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.unit});

  final UnitEntity unit;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: S.of(context).guest_alojamiento_description),
        const SizedBox(height: AppTheme.spacing12),
        Text(
          S.of(context).guest_alojamiento_description_text(unit.unitType.displayName.toLowerCase()),
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: isDark ? AppColors.silver : AppColors.gray600,
          ),
        ),
      ],
    );
  }
}

/// Sección de servicios
class _ServicesSection extends StatelessWidget {
  const _ServicesSection({required this.unit});

  final UnitEntity unit;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    final s = S.of(context);
    final services = [
      {'icon': Icons.kitchen_outlined, 'label': s.guest_alojamiento_service_kitchen},
      {'icon': Icons.local_laundry_service_outlined, 'label': s.guest_alojamiento_service_washer},
      {'icon': Icons.tv_outlined, 'label': s.guest_alojamiento_service_tv},
      {'icon': Icons.bed_outlined, 'label': s.guest_alojamiento_service_bedding},
      {'icon': Icons.bathtub_outlined, 'label': s.guest_alojamiento_service_towels},
      {'icon': Icons.coffee_outlined, 'label': s.guest_alojamiento_service_coffee},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: S.of(context).guest_alojamiento_services),
        const SizedBox(height: AppTheme.spacing16),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.blackLight
                : AppColors.gray50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.gray800
                  : AppColors.gray200,
            ),
          ),
          child: Wrap(
            spacing: AppTheme.spacing12,
            runSpacing: AppTheme.spacing12,
            children: services.map((service) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.gray800
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      service['icon'] as IconData,
                      size: 16,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      service['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.white : AppColors.gray700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Sección de información de acceso
class _AccessSection extends StatelessWidget {
  const _AccessSection({required this.unit});

  final UnitEntity unit;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: S.of(context).guest_alojamiento_access_info),
        const SizedBox(height: AppTheme.spacing16),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: AppColors.goldWithAlpha10,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (unit.boxLocationText != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.vpn_key_outlined,
                      size: 20,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.of(context).guest_alojamiento_box_location,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.silver : AppColors.gray500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            unit.boxLocationText!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.white : AppColors.gray900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              if (unit.boxLocationText != null && unit.accessInstructions != null)
                const SizedBox(height: AppTheme.spacing16),
              if (unit.accessInstructions != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.of(context).guest_alojamiento_access_instructions,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.silver : AppColors.gray500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            unit.accessInstructions!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.white : AppColors.gray900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Título de sección reutilizable
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.white : AppColors.gray900,
      ),
    );
  }
}
