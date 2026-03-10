import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import 'campaigns_section.dart';
import 'automations_section.dart';
import 'crm_section.dart';

/// Tab de Marketing del panel de administración.
/// Incluye:
/// - Métricas de comunicaciones
/// - Gestión de campañas
/// - Automatizaciones
/// - CRM de huéspedes
class MarketingTab extends StatelessWidget {
  const MarketingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),
          const SizedBox(height: 24),

          // KPIs de comunicaciones
          _buildMetricsGrid(context),
          const SizedBox(height: 24),

          // Sección de Campañas
          const CampaignsSection(),
          const SizedBox(height: 24),

          // Sección de Automatizaciones
          const AutomationsSection(),
          const SizedBox(height: 24),

          // Sección de CRM
          const CrmSection(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Marketing',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Gestiona campañas y comunicaciones',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.getTextSecondaryColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comunicaciones este mes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.email_outlined,
                  value: '0',
                  label: 'Emails enviados',
                  subtitle: 'Sin datos',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.notifications_active_outlined,
                  value: '0',
                  label: 'Push enviados',
                  subtitle: 'Sin datos',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tarjeta de métrica individual
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.subtitle,
  });

  final IconData icon;
  final String value;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorderColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.goldWithAlpha20,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.getTextSecondaryColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
