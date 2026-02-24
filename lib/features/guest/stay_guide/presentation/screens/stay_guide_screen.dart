import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/core/theme/app_theme.dart';

/// Pantalla de Guía de Estadía
class StayGuideScreen extends StatelessWidget {
  const StayGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/guest'),
        ),
        title: const Text('Guía de Estadía'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Todo lo que necesitas saber',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Encuentra información útil sobre tu estadía',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing24),

              // Guide sections
              _GuideSection(
                icon: Icons.info_outline,
                title: 'Información General',
                items: [
                  _GuideItem(
                    title: 'Horarios',
                    subtitle: 'Check-in: 15:00 | Check-out: 11:00',
                  ),
                  _GuideItem(
                    title: 'Contacto',
                    subtitle: '+34 900 123 456',
                  ),
                  _GuideItem(
                    title: 'WiFi',
                    subtitle: 'Red: BF_Stay_Guest | Contraseña: guest2024',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),

              _GuideSection(
                icon: Icons.restaurant_outlined,
                title: 'Restaurantes Cercanos',
                items: [
                  _GuideItem(
                    title: 'Restaurante El Mirador',
                    subtitle: 'Cocina mediterránea - 200m',
                  ),
                  _GuideItem(
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
                    title: 'Centro Histórico',
                    subtitle: 'A 10 minutos caminando',
                  ),
                  _GuideItem(
                    title: 'Playa',
                    subtitle: 'A 5 minutos caminando',
                  ),
                  _GuideItem(
                    title: 'Museo Municipal',
                    subtitle: 'A 15 minutos caminando',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),

              _GuideSection(
                icon: Icons.local_taxi_outlined,
                title: 'Transporte',
                items: [
                  _GuideItem(
                    title: 'Parada de Taxi',
                    subtitle: 'En la puerta del edificio',
                  ),
                  _GuideItem(
                    title: 'Metro',
                    subtitle: 'Estación Central - 500m',
                  ),
                  _GuideItem(
                    title: 'Parking Público',
                    subtitle: 'Parking Central - 200m',
                  ),
                ],
              ),
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
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing8),
                  decoration: BoxDecoration(
                    color: AppColors.goldWithAlpha10,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(icon, color: AppColors.gold, size: 20),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
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
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
