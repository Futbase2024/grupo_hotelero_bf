import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bf_stay/l10n/app_localizations.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../domain/bloc/alojamientos_bloc.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/entities/unit_entity.dart';
import '../../domain/entities/unit_photo_entity.dart';

/// Pantalla que muestra las habitaciones de un hotel
class HotelRoomsScreen extends StatefulWidget {
  const HotelRoomsScreen({
    super.key,
    required this.propertyId,
  });

  final String propertyId;

  @override
  State<HotelRoomsScreen> createState() => _HotelRoomsScreenState();
}

class _HotelRoomsScreenState extends State<HotelRoomsScreen> {
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
              context.go('/guest/alojamientos');
            }
          },
        ),
        title: Text(
          S.of(context).guest_alojamiento_hotel_rooms_title,
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
              final hotelProperty = state.hotelProperty;
              final hotelRooms = state.hotelRooms;

              if (hotelProperty == null || hotelRooms.isEmpty) {
                return const _EmptyView();
              }

              return _LoadedView(
                property: hotelProperty,
                rooms: hotelRooms,
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
                Icons.hotel_outlined,
                size: 40,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              S.of(context).guest_alojamiento_no_rooms,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).guest_alojamiento_no_rooms_subtitle,
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

/// Vista con datos cargados - Grid de habitaciones
class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.property,
    required this.rooms,
    required this.coverPhotos,
  });

  final PropertyEntity property;
  final List<UnitEntity> rooms;
  final Map<String, UnitPhotoEntity> coverPhotos;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header compacto con info del hotel
          _CompactHotelHeader(property: property),

          // Sección Habitaciones
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Row(
              children: [
                Icon(
                  Icons.meeting_room_outlined,
                  size: 18,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 6),
                Text(
                  S.of(context).guest_alojamiento_rooms,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.gray900,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${rooms.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Grid de habitaciones - wrap para flujo automático
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rooms.map((room) {
                final coverPhoto = coverPhotos[room.id];
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 40) / 3,
                  child: _RoomCard(room: room, coverPhoto: coverPhoto),
                );
              }).toList(),
            ),
          ),

          // Sección Zonas Comunes
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
            child: Row(
              children: [
                Icon(
                  Icons.domain_outlined,
                  size: 18,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 6),
                Text(
                  S.of(context).guest_alojamiento_common_areas,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.gray900,
                  ),
                ),
              ],
            ),
          ),

          // Tarjeta de Zonas Comunes
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: _ZonasComunesCard(propertyId: property.id),
          ),
        ],
      ),
    );
  }
}

/// Header compacto con información del hotel
class _CompactHotelHeader extends StatelessWidget {
  const _CompactHotelHeader({required this.property});

  final PropertyEntity property;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.blackLight : AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.gold.withValues(alpha: 0.3) : AppColors.gray200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.hotel_rounded,
              size: 20,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.gray900,
                  ),
                ),
                if (property.fullAddress.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: isDark ? AppColors.silver : AppColors.gray500,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          property.fullAddress,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de habitación compacta
class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    this.coverPhoto,
  });

  final UnitEntity room;
  final UnitPhotoEntity? coverPhoto;

  /// Colores para los gradientes de fondo
  static const List<List<Color>> _gradientColors = [
    [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
    [Color(0xFF2d132c), Color(0xFF801336), Color(0xFFc72c41)],
    [Color(0xFF0d1b2a), Color(0xFF1b263b), Color(0xFF415a77)],
    [Color(0xFF1a1a1a), Color(0xFF2d2d2d), Color(0xFF404040)],
    [Color(0xFF0c1821), Color(0xFF1b2838), Color(0xFF324a5f)],
    [Color(0xFF2c3e50), Color(0xFF34495e), Color(0xFF5d6d7e)],
  ];

  List<Color> get _colors {
    final roomNumber = int.tryParse(room.name.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return _gradientColors[roomNumber % _gradientColors.length];
  }

  String? get _localImagePath {
    final roomNumber = int.tryParse(room.name.replaceAll(RegExp(r'[^0-9]'), ''));
    if (roomNumber == null || roomNumber < 1 || roomNumber > 9) return null;
    return 'assets/alojamientos/habitaciones/hab$roomNumber.jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    final borderColor = isDark ? AppColors.gold.withValues(alpha: 0.4) : AppColors.gray200;

    return GestureDetector(
      onTap: () {
        context.go('/guest/alojamientos/unit/${room.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: isDark ? 1 : 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Imagen
              AspectRatio(
                aspectRatio: 1.2,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_localImagePath != null)
                      Image.asset(
                        _localImagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _colors,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.bed_rounded,
                              size: 24,
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
                        child: Center(
                          child: Icon(
                            Icons.bed_rounded,
                            size: 24,
                            color: AppColors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Nombre de la habitación
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.blackLight : AppColors.white,
                ),
                child: Text(
                  room.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.white : AppColors.gray900,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card compacta para acceder a la galería de zonas comunes
class _ZonasComunesCard extends StatelessWidget {
  const _ZonasComunesCard({required this.propertyId});

  final String propertyId;

  static const List<String> _previewPhotos = [
    'assets/alojamientos/zonas_comunes/zona1.jpg',
    'assets/alojamientos/zonas_comunes/zona2.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    final borderColor = isDark ? AppColors.gold.withValues(alpha: 0.4) : AppColors.gray200;

    return GestureDetector(
      onTap: () {
        context.go('/guest/alojamientos/hotel/$propertyId/common-areas');
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isDark ? 1 : 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                _previewPhotos.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.goldDark.withValues(alpha: 0.6),
                        AppColors.gold.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
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
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.domain_outlined,
                            color: AppColors.black,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                S.of(context).guest_alojamiento_common_areas,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                              Text(
                                S.of(context).guest_alojamiento_photos_count(_previewPhotos.length),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            color: AppColors.black,
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
