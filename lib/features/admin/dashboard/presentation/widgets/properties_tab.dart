import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/bloc/bloc.dart';
import '../../../shared/widgets/admin_widgets.dart';

/// Tab de propiedades del dashboard de administración (solo para admin)
class PropertiesTab extends StatelessWidget {
  const PropertiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
      builder: (context, state) {
        return Column(
          children: [
            // Header
            _buildHeader(context),

            // Properties list
            Expanded(
              child: _buildPropertiesList(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Text(
            'Alojamientos',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppColors.white,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              // TODO: Open CreatePropertyBottomSheet
            },
            icon: const Icon(Icons.add, color: AppColors.gold, size: 20),
            label: const Text(
              'Añadir',
              style: TextStyle(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesList(BuildContext context, AdminDashboardState state) {
    if (state.isLoadingProperties) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    final properties = state.properties;

    if (properties.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.apartment_outlined,
        title: 'Sin propiedades',
        subtitle: 'Añade la primera propiedad para empezar',
        actionLabel: 'Añadir propiedad',
        onAction: () {
          // TODO: Open CreatePropertyBottomSheet
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.darkSurface,
      onRefresh: () async {
        context.read<AdminDashboardBloc>().add(
              const AdminDashboardPropertiesLoadRequested(),
            );
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
          return _PropertyCard(
            property: property,
            onTap: () {
              // TODO: Navigate to property detail
            },
          );
        },
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.property,
    this.onTap,
  });

  final Map<String, dynamic> property;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            // Icono de propiedad
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.goldWithAlpha10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.apartment_outlined,
                color: AppColors.gold,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Info de propiedad
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property['name'] ?? 'Sin nombre',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${property['units_count'] ?? 0} unidades',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),

            // Flecha
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.getTextSecondaryColor(context),
            ),
          ],
        ),
      ),
    );
  }
}
