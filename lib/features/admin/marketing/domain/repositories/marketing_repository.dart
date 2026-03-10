import '../entities/campaign_entity.dart';

/// Contrato del repositorio de marketing
abstract class MarketingRepository {
  /// Obtiene todas las campañas de una propiedad
  Future<List<CampaignEntity>> getCampaigns(String propertyId);

  /// Obtiene una campaña por ID
  Future<CampaignEntity?> getCampaign(String id);

  /// Crea una nueva campaña
  Future<CampaignEntity> createCampaign(CampaignEntity campaign);

  /// Actualiza una campaña existente
  Future<CampaignEntity> updateCampaign(CampaignEntity campaign);

  /// Elimina una campaña
  Future<void> deleteCampaign(String id);

  /// Observa cambios en las campañas en tiempo real
  Stream<List<CampaignEntity>> watchCampaigns(String propertyId);

  /// Actualiza el estado de una campaña
  Future<CampaignEntity> updateCampaignStatus(String id, CampaignStatus status);

  /// Programa una campaña para envío futuro
  Future<CampaignEntity> scheduleCampaign(String id, DateTime scheduledAt);

  /// Libera recursos
  void dispose();
}
