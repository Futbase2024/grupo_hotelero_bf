import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
              return _LoadedView(state: state);
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
    required this.state,
  });

  final AlojamientosLoaded state;

  @override
  Widget build(BuildContext context) {
    final apartments = state.apartments;
    final hotelRooms = state.hotelRooms;
    final hotelProperty = state.hotelProperty;

    if (apartments.isEmpty && hotelRooms.isEmpty) {
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
                // Los apartamentos primero
                if (index < apartments.length) {
                  final unit = apartments[index];
                  final coverPhoto = state.coverPhotos[unit.id];
                  return _UnitCard(unit: unit, index: index, coverPhoto: coverPhoto);
                }
                // Luego la tarjeta del Hotel (si hay habitaciones)
                if (hotelRooms.isNotEmpty && hotelProperty != null) {
                  return _HotelCard(
                    property: hotelProperty,
                    roomCount: hotelRooms.length,
                  );
                }
                return null;
              },
              childCount: apartments.length + (hotelRooms.isNotEmpty ? 1 : 0),
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

  /// Mapeo de nombres de unidades a imágenes locales
  static const Map<String, String> _unitImageMap = {
    'Apartamento Bandera': 'assets/alojamientos/ApartamentoBanferra.jpeg',
    'Apartamento BF Jerez': 'assets/alojamientos/ApartamentoBFJerez.jpeg',
    'Ático Jerez': 'assets/alojamientos/ApartamentoAticoJerez.jpeg',
    'BF Jacuzzi Jerez': 'assets/alojamientos/ApartamentoBFJacuzzi.jpeg',
    'Jacuzzi Jerez': 'assets/alojamientos/EstudioBFJacuzzi.jpeg',
  };

  /// Obtiene la ruta de la imagen local para una unidad
  String? get _localImagePath => _unitImageMap[unit.name];

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    // Borde dorado más visible en modo oscuro
    final borderColor = isDark ? AppColors.gold : AppColors.black.withValues(alpha: 0.15);
    // Fondo de la sección de texto adaptado al tema
    final cardBgColor = isDark ? AppColors.blackLight : AppColors.white;

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
                    // Imagen local o gradiente de fondo
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
                    if (_localImagePath == null)
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

/// Card especial para el Hotel que agrupa las habitaciones
class _HotelCard extends StatelessWidget {
  const _HotelCard({
    required this.property,
    required this.roomCount,
  });

  final PropertyEntity property;
  final int roomCount;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    final borderColor = isDark ? AppColors.gold : AppColors.black.withValues(alpha: 0.15);
    final cardBgColor = isDark ? AppColors.blackLight : AppColors.white;

    return GestureDetector(
      onTap: () {
        context.go('/guest/alojamientos/hotel/${property.id}');
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
              // Imagen del hotel
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Imagen local del hotel
                    Image.asset(
                      'assets/alojamientos/HotelBoutique.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.goldDark.withValues(alpha: 0.8),
                              AppColors.gold.withValues(alpha: 0.9),
                              AppColors.goldLight.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.hotel_rounded,
                            size: 56,
                            color: AppColors.white.withValues(alpha: 0.4),
                          ),
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
                    // Badge de Hotel
                    Positioned(
                      top: AppTheme.spacing12,
                      right: AppTheme.spacing12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing8,
                          vertical: AppTheme.spacing4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.black,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: const Text(
                          'HOTEL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Texto debajo
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
                        property.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.white : AppColors.gray900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (property.fullAddress.isNotEmpty) ...[
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
                      const SizedBox(height: AppTheme.spacing8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.meeting_room_outlined,
                                size: 14,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$roomCount habitaciones',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: AppColors.gold,
                          ),
                        ],
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
