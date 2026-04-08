import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
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

  /// ID de la unidad para filtrar parkings (obligatorio para huéspedes)
  final String? unitId;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return BlocProvider(
      create: (context) => ParkingsBloc(
        parkingsRepository: getIt<ParkingsRepository>(),
      )..add(
          unitId != null
              ? ParkingsByUnitRequested(unitId: unitId!)
              : const ParkingsStarted(),
        ),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.black : AppColors.gray50,
        body: SafeArea(
          top: false,
          child: _ParkingsBody(unitId: unitId),
        ),
      ),
    );
  }
}

/// Body de la pantalla con acceso al BLoC
class _ParkingsBody extends StatelessWidget {
  const _ParkingsBody({this.unitId});

  /// ID de la unidad para filtrar (si aplica)
  final String? unitId;

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
            else if (state is UnitParkingsLoaded)
              // Vista para una unidad específica (huésped)
              state.unitParkings.isEmpty
                  ? const SliverFillRemaining(
                      child: _EmptyView(),
                    )
                  : _UnitParkingsList(
                      unitParkings: state.unitParkings,
                      unitName: state.unitParkings.first.unitName ?? 'Tu Alojamiento',
                    )
            else if (state is AllUnitParkingsLoaded)
              // Vista para admin/todos los parkings
              state.unitParkings.isEmpty
                  ? const SliverFillRemaining(
                      child: _EmptyView(),
                    )
                  : _GroupedParkingsList(
                      groupedParkings: state.groupedParkings,
                      hotelParkings: state.hotelParkings,
                      hotelName: state.hotelName,
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
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
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
            S.of(context).guest_parking_title,
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
    required this.hotelParkings,
    this.hotelName,
  });

  final Map<String, List<UnitParkingEntity>> groupedParkings;
  final List<UnitParkingEntity> hotelParkings;
  final String? hotelName;

  @override
  Widget build(BuildContext context) {
    final unitIds = groupedParkings.keys.toList();
    final hasHotel = hotelParkings.isNotEmpty;
    // Siempre mostrar la info del hotel primero, luego hotel parkings, luego unidades
    final totalItems = 1 + (hasHotel ? 1 : 0) + unitIds.length;

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Índice 0: Información de parking del hotel (siempre visible)
            if (index == 0) {
              return const _HotelParkingInfoCard();
            }

            // Índice 1: Parkings del hotel (si existen)
            if (hasHotel && index == 1) {
              return _UnitParkingSection(
                unitName: hotelName ?? 'Hotel',
                parkings: hotelParkings,
                isHotel: true,
              );
            }

            // Resto: Unidades normales
            final adjustedIndex = index - 1 - (hasHotel ? 1 : 0);
            if (adjustedIndex < 0 || adjustedIndex >= unitIds.length) {
              return const SizedBox.shrink();
            }

            final unitId = unitIds[adjustedIndex];
            final parkings = groupedParkings[unitId]!;
            final unitName = parkings.first.unitName ?? 'Alojamiento';

            return _UnitParkingSection(
              unitName: unitName,
              parkings: parkings,
              isHotel: false,
            );
          },
          childCount: totalItems,
        ),
      ),
    );
  }
}

/// Lista simple de parkings para una unidad específica (vista de huésped)
class _UnitParkingsList extends StatelessWidget {
  const _UnitParkingsList({
    required this.unitParkings,
    required this.unitName,
  });

  final List<UnitParkingEntity> unitParkings;
  final String unitName;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Índice 0: Información de parking del hotel
            if (index == 0) {
              return const _HotelParkingInfoCard();
            }

            // Índice 1: Parkings de la unidad
            if (index == 1) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título de la sección
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      S.of(context).guest_parking_for_unit(unitName),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                    ),
                  ),
                  // Lista de parkings
                  ...unitParkings.map((unitParking) {
                    final parking = unitParking.parking;
                    if (parking == null) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ParkingCard(
                        parking: parking,
                        priority: unitParking.priority,
                        notes: unitParking.notes,
                      ),
                    );
                  }),
                ],
              );
            }

            return const SizedBox.shrink();
          },
          childCount: 2,
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
    this.isHotel = false,
  });

  final String unitName;
  final List<UnitParkingEntity> parkings;
  final bool isHotel;

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
                    child: Icon(
                      widget.isHotel
                          ? Icons.hotel_outlined
                          : Icons.home_outlined,
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
                          '${widget.parkings.length} ${widget.parkings.length == 1 ? S.of(context).guest_parking_available_singular : S.of(context).guest_parking_available_plural}',
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
              S.of(context).guest_parking_error_loading,
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
              S.of(context).guest_parking_empty_title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).guest_parking_empty_subtitle,
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

/// Widget con la información de parking del Hotel BF Boutique Jerez
class _HotelParkingInfoCard extends StatefulWidget {
  const _HotelParkingInfoCard();

  @override
  State<_HotelParkingInfoCard> createState() => _HotelParkingInfoCardState();
}

class _HotelParkingInfoCardState extends State<_HotelParkingInfoCard> {
  bool _isExpanded = true;

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
          // Header (clickeable para expandir/contraer)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.goldWithAlpha20,
                    AppColors.goldWithAlpha10,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: _isExpanded ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_parking,
                      size: 22,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.of(context).guest_parking_info_zones_title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'BF BOUTIQUE JEREZ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextPrimaryColor(context),
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

          // Contenido expandible
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PARKING PLAZA ARENAL
                  _ParkingInfoSection(
                    icon: Icons.local_parking,
                    iconColor: AppColors.gold,
                    title: S.of(context).guest_parking_plaza_arenal_title,
                    subtitle: S.of(context).guest_parking_plaza_arenal_subtitle,
                    content: S.of(context).guest_parking_plaza_arenal_content,
                  ),

                  const SizedBox(height: 20),

                  // PARKING ZONA CENTRO
                  _ParkingInfoSection(
                    icon: Icons.directions_car,
                    iconColor: AppColors.info,
                    title: S.of(context).guest_parking_centro_title,
                    subtitle: S.of(context).guest_parking_centro_subtitle,
                    content: S.of(context).guest_parking_centro_content,
                  ),

                  const SizedBox(height: 20),

                  // PARKING ZONA GRATUITA
                  _ParkingInfoSection(
                    icon: Icons.directions_walk,
                    iconColor: AppColors.success,
                    title: S.of(context).guest_parking_free_zone_title,
                    subtitle: S.of(context).guest_parking_free_zone_subtitle,
                    content: S.of(context).guest_parking_free_zone_content,
                    showGpsLink: true,
                    gpsLabel: 'Calzada del Arroyo',
                    gpsUrl: 'https://www.google.com/maps/search/?api=1&query=Calzada+del+Arroyo+Jerez+de+la+Frontera',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Sección individual de información de parking
class _ParkingInfoSection extends StatelessWidget {
  const _ParkingInfoSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.content,
    this.showGpsLink = false,
    this.gpsLabel,
    this.gpsUrl,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String content;
  final bool showGpsLink;
  final String? gpsLabel;
  final String? gpsUrl;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.blackWithAlpha20 : AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.gray800 : AppColors.gray200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
          if (showGpsLink && gpsUrl != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _openMapsUrl(gpsUrl!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.gps_fixed,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      S.of(context).guest_parking_gps_label(gpsLabel!),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: AppColors.success,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openMapsUrl(String url) {
    final uri = Uri.parse(url);
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
