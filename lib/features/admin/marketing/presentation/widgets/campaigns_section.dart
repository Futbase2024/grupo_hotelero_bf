import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../domain/bloc/campaigns_bloc.dart';
import '../../domain/entities/campaign_entity.dart';
import '../../data/repositories/marketing_repository_impl.dart';
import '../sheets/create_campaign_bottom_sheet.dart';

/// Sección de campañas de marketing
class CampaignsSection extends StatefulWidget {
  const CampaignsSection({
    super.key,
    required this.propertyId,
    required this.userId,
  });

  final String propertyId;
  final String userId;

  @override
  State<CampaignsSection> createState() => _CampaignsSectionState();
}

class _CampaignsSectionState extends State<CampaignsSection> {
  late final CampaignsBloc _campaignsBloc;

  @override
  void initState() {
    super.initState();
    _campaignsBloc = CampaignsBloc(
      repository: MarketingRepositoryImpl(),
    );
    // Solo cargar campañas si hay un propertyId válido
    if (widget.propertyId.isNotEmpty) {
      _campaignsBloc.add(CampaignsStarted(propertyId: widget.propertyId));
    }
  }

  @override
  void dispose() {
    _campaignsBloc.add(const CampaignsDisposed());
    _campaignsBloc.close();
    super.dispose();
  }

  Future<void> _handleCreateCampaign(CampaignEntity campaign) async {
    _campaignsBloc.add(CampaignCreateRequested(campaign: campaign));
  }

  void _showCreateCampaignSheet() {
    CreateCampaignBottomSheet.show(
      context,
      propertyId: widget.propertyId,
      userId: widget.userId,
      onSave: _handleCreateCampaign,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay propertyId, mostrar estado para seleccionar propiedad
    if (widget.propertyId.isEmpty) {
      return _buildNoPropertySelectedState(context);
    }

    return BlocProvider.value(
      value: _campaignsBloc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          BlocBuilder<CampaignsBloc, CampaignsState>(
            builder: (context, state) {
              if (state is CampaignsInitial) {
                return const SizedBox.shrink();
              }
              if (state is CampaignsLoading) {
                return const _LoadingIndicator();
              }
              if (state is CampaignsLoaded) {
                if (state.campaigns.isEmpty) {
                  return _buildEmptyState(context);
                }
                return _buildCampaignsList(state.campaigns);
              }
              if (state is CampaignsError) {
                return _buildErrorState(
                  context,
                  state.message,
                  state.previousCampaigns,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoPropertySelectedState(BuildContext context) {
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
              Icons.apartment_outlined,
              size: 40,
              color: AppColors.gray500,
            ),
            const SizedBox(height: 12),
            Text(
              'Selecciona un alojamiento',
              style: TextStyle(
                color: AppColors.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ve a la pestaña Alojamientos y selecciona una propiedad',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.getTextTertiaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
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
        BlocBuilder<CampaignsBloc, CampaignsState>(
          builder: (context, state) {
            final hasCampaigns = state is CampaignsLoaded && state.campaigns.isNotEmpty;

            if (!hasCampaigns) return const SizedBox.shrink();

            return TextButton(
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
            );
          },
        ),
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
              onPressed: _showCreateCampaignSheet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Crear campaña'),
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

  Widget _buildCampaignsList(List<CampaignEntity> campaigns) {
    return Column(
      children: [
        ...campaigns.take(3).map((campaign) => _CampaignCard(
          campaign: campaign,
          onTap: () {
            // TODO: Ver detalle de campaña
          },
        )),
        if (campaigns.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () {
                // TODO: Ver todas las campañas
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text('Ver ${campaigns.length - 3} más'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String message,
    List<CampaignEntity>? previousCampaigns,
  ) {
    if (previousCampaigns != null && previousCampaigns.isNotEmpty) {
      return _buildCampaignsList(previousCampaigns);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 40,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(
            'Error al cargar campañas',
            style: TextStyle(
              color: AppColors.getTextPrimaryColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.getTextSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _campaignsBloc.add(const CampaignsLoadRequested());
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicador de carga
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorderColor(context),
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
        ),
      ),
    );
  }
}

/// Tarjeta de campaña individual
class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.campaign,
    required this.onTap,
  });

  final CampaignEntity campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
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
                          if (campaign.sentCount != null && campaign.sentCount! > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${campaign.sentCount} enviados',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.getTextSecondaryColor(context),
                              ),
                            ),
                          ],
                          if (campaign.openRate != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              campaign.openRateFormatted,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                          if (campaign.scheduledAt != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              campaign.scheduledIn,
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
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final color = _getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        campaign.status.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (campaign.status) {
      case CampaignStatus.active:
        return AppColors.success;
      case CampaignStatus.scheduled:
        return AppColors.info;
      case CampaignStatus.paused:
        return AppColors.warning;
      case CampaignStatus.completed:
        return AppColors.gray500;
      case CampaignStatus.draft:
        return AppColors.gray500;
    }
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
}
