import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

/// Sección de campañas de marketing
class CampaignsSection extends StatelessWidget {
  const CampaignsSection({super.key});

  // En producción, las campañas vendrían de Supabase
  // Por ahora mostramos estado vacío
  List<_CampaignData> get _campaigns => [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.goldWithAlpha20,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    size: 20,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Campañas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                // TODO: Ver todas las campañas
              },
              child: const Text(
                'Ver todo',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.gold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...(_campaigns.isEmpty
            ? [_buildEmptyState(context)]
            : _campaigns.map((c) => _CampaignCard(campaign: c))),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorderColor(context),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 40,
              color: AppColors.gray500,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay campañas',
              style: TextStyle(
                color: AppColors.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Crear campaña
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Crear primera campaña'),
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

/// Datos de una campaña
class _CampaignData {
  final String name;
  final CampaignType type;
  final CampaignStatus status;
  final int? sent;
  final double? openRate;
  final DateTime? scheduledDate;

  _CampaignData({
    required this.name,
    required this.type,
    required this.status,
    this.sent,
    this.openRate,
    this.scheduledDate,
  });
}

enum CampaignType { email, push, sms, whatsapp }

enum CampaignStatus { draft, scheduled, active, paused, completed }

/// Tarjeta de campaña individual
class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.campaign});

  final _CampaignData campaign;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.getBorderColor(context),
        ),
      ),
      child: Row(
        children: [
          // Icono del tipo
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.goldWithAlpha20,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTypeIcon(),
              size: 20,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 12),
          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatusBadge(),
                    if (campaign.sent != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${campaign.sent} enviados',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                    if (campaign.openRate != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${campaign.openRate!.toInt()}% apertura',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                    if (campaign.scheduledDate != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _getScheduledText(),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Acción
          Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.gray500,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    switch (campaign.status) {
      case CampaignStatus.active:
        color = AppColors.success;
        text = 'Activa';
      case CampaignStatus.scheduled:
        color = AppColors.info;
        text = 'Programada';
      case CampaignStatus.paused:
        color = AppColors.warning;
        text = 'Pausada';
      case CampaignStatus.completed:
        color = AppColors.gray500;
        text = 'Completada';
      case CampaignStatus.draft:
        color = AppColors.gray500;
        text = 'Borrador';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (campaign.type) {
      case CampaignType.email:
        return Icons.email_outlined;
      case CampaignType.push:
        return Icons.notifications_active_outlined;
      case CampaignType.sms:
        return Icons.sms_outlined;
      case CampaignType.whatsapp:
        return Icons.chat_outlined;
    }
  }

  String _getScheduledText() {
    final now = DateTime.now();
    final diff = campaign.scheduledDate!.difference(now);

    if (diff.inDays > 0) {
      return 'En ${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return 'En ${diff.inHours}h';
    } else {
      return 'Próximamente';
    }
  }
}
