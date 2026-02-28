import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/core/theme/app_theme.dart';

/// Pantalla de Guía de Estancia
class StayGuideScreen extends StatelessWidget {
  const StayGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurfaceColor(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.getTextPrimaryColor(context)),
          onPressed: () => context.go('/guest'),
        ),
        title: Text(
          'Guía de Estancia',
          style: TextStyle(
            color: AppColors.getTextPrimaryColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icono
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.menu_book_outlined,
                        color: AppColors.black,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    Text(
                      'Todo lo que necesitas saber',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      'Encuentra información útil sobre tu estancia',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getTextSecondaryColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),

              // Guide sections
              _GuideSection(
                icon: Icons.info_outline,
                title: 'Información General',
                items: [
                  _GuideItem(
                    icon: Icons.access_time_outlined,
                    title: 'Horarios',
                    subtitle: 'Check-in: 15:00 | Check-out: 11:00',
                  ),
                  _GuideItem(
                    icon: Icons.phone_outlined,
                    title: 'Contacto',
                    subtitle: '+34 900 123 456',
                  ),
                  _GuideItem(
                    icon: Icons.wifi_outlined,
                    title: 'WiFi',
                    subtitle: 'Red: BF_Stay_Guest | Contraseña: guest2026',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),

              _GuideSection(
                icon: Icons.restaurant_outlined,
                title: 'Restaurantes Cercanos',
                items: [
                  _GuideItem(
                    icon: Icons.dining_outlined,
                    title: 'Restaurante El Mirador',
                    subtitle: 'Cocina mediterránea - 200m',
                  ),
                  _GuideItem(
                    icon: Icons.tapas_outlined,
                    title: 'La Tasca',
                    subtitle: 'Tapas españolas - 350m',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),

              _GuideSection(
                icon: Icons.place_outlined,
                title: 'Lugares de Interés',
                items: [
                  _GuideItem(
                    icon: Icons.account_balance_outlined,
                    title: 'Centro Histórico',
                    subtitle: 'A 10 minutos caminando',
                  ),
                  _GuideItem(
                    icon: Icons.beach_access_outlined,
                    title: 'Playa',
                    subtitle: 'A 5 minutos caminando',
                  ),
                  _GuideItem(
                    icon: Icons.museum_outlined,
                    title: 'Museo Municipal',
                    subtitle: 'A 15 minutos caminando',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),

              _GuideSection(
                icon: Icons.directions_car_outlined,
                title: 'Transporte',
                items: [
                  _GuideItem(
                    icon: Icons.local_taxi_outlined,
                    title: 'Parada de Taxi',
                    subtitle: 'En la puerta del edificio',
                  ),
                  _GuideItem(
                    icon: Icons.subway_outlined,
                    title: 'Metro',
                    subtitle: 'Estación Central - 500m',
                  ),
                  _GuideItem(
                    icon: Icons.local_parking_outlined,
                    title: 'Parking Público',
                    subtitle: 'Parking Central - 200m',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing24),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<_GuideItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: AppColors.goldWithAlpha10,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLarge),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.black, size: 20),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextPrimaryColor(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Items
          ...items,
        ],
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  const _GuideItem({
    required this.title,
    required this.subtitle,
    this.icon,
  });

  final String title;
  final String subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(AppTheme.radiusLarge),
        bottomRight: Radius.circular(AppTheme.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing12,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.goldWithAlpha10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon ?? Icons.info_outline,
                color: AppColors.gold,
                size: 18,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.getTextPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
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
            Icon(
              Icons.chevron_right,
              color: AppColors.getTextSecondaryColor(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
