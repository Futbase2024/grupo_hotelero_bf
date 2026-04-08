import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bf_stay/l10n/app_localizations.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../domain/bloc/alojamientos_bloc.dart';
import '../../domain/entities/property_entity.dart';
import '../widgets/unit_card.dart';

/// Pantalla de detalle de un alojamiento
class AlojamientoDetailScreen extends StatelessWidget {
  const AlojamientoDetailScreen({
    super.key,
    required this.propertyId,
  });

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    // Cargar detalle al entrar a la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlojamientosBloc>().add(
            AlojamientoDetailRequested(propertyId: propertyId),
          );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).guest_alojamiento_detail_title),
        centerTitle: true,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
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
                        AlojamientoDetailRequested(propertyId: propertyId),
                      );
                },
              );
            }

            if (state is AlojamientoDetailLoaded) {
              return _DetailView(property: state.property);
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
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
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
                foregroundColor: AppColors.textOnGold,
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

/// Vista de detalle
class _DetailView extends StatelessWidget {
  const _DetailView({required this.property});

  final PropertyEntity property;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con imagen placeholder
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.gold.withValues(alpha: 0.3),
                  AppColors.goldDark.withValues(alpha: 0.3),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.home_work_outlined,
                size: 64,
                color: AppColors.gold,
              ),
            ),
          ),

          // Información principal
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre
                Text(
                  property.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                // Ubicación
                if (property.fullAddress.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          property.fullAddress,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // Botón de normas de la casa
                _HouseRulesButton(propertyId: property.id),

                const SizedBox(height: 24),

                // Sección de unidades
                Row(
                  children: [
                    const Icon(
                      Icons.apartment_outlined,
                      size: 20,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      S.of(context).guest_alojamiento_units_available,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldWithAlpha20,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${property.units.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldDark,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Lista de unidades
                if (property.units.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            S.of(context).guest_alojamiento_no_units,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...property.units.map((unit) => UnitCard(unit: unit)),

                const SizedBox(height: 24),

                // Información adicional
                if (property.hasLocation) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildInfoSection(
                    icon: Icons.map_outlined,
                    title: S.of(context).guest_alojamiento_location,
                    child: _LocationPreview(
                      lat: property.lat!,
                      lng: property.lng!,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppColors.gold,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Preview de ubicación (placeholder)
class _LocationPreview extends StatelessWidget {
  const _LocationPreview({
    required this.lat,
    required this.lng,
  });

  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 32,
              color: AppColors.gold,
            ),
            const SizedBox(height: 8),
            Text(
              'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón para ver las normas de la casa
class _HouseRulesButton extends StatelessWidget {
  const _HouseRulesButton({required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/guest/house-rules/$propertyId'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.goldWithAlpha20,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rule_outlined,
                size: 24,
                color: AppColors.goldDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).guest_house_rules_title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    S.of(context).guest_house_rules_subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.gold,
            ),
          ],
        ),
      ),
    );
  }
}
