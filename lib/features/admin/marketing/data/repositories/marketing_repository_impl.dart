import '../datasources/marketing_datasource.dart';
import '../../domain/entities/campaign_entity.dart';
import '../../domain/repositories/marketing_repository.dart';

/// Implementación del repositorio de marketing
class MarketingRepositoryImpl implements MarketingRepository {
  MarketingRepositoryImpl({MarketingDatasource? datasource})
      : _datasource = datasource ?? MarketingDatasource();

  final MarketingDatasource _datasource;

  @override
  Future<List<CampaignEntity>> getCampaigns(String propertyId) async {
    return await _datasource.getCampaigns(propertyId);
  }

  @override
  Future<CampaignEntity?> getCampaign(String id) async {
    return await _datasource.getCampaign(id);
  }

  @override
  Future<CampaignEntity> createCampaign(CampaignEntity campaign) async {
    return await _datasource.createCampaign(campaign);
  }

  @override
  Future<CampaignEntity> updateCampaign(CampaignEntity campaign) async {
    return await _datasource.updateCampaign(campaign);
  }

  @override
  Future<void> deleteCampaign(String id) async {
    return await _datasource.deleteCampaign(id);
  }

  @override
  Stream<List<CampaignEntity>> watchCampaigns(String propertyId) {
    return _datasource.watchCampaigns(propertyId);
  }

  @override
  Future<CampaignEntity> updateCampaignStatus(
    String id,
    CampaignStatus status,
  ) async {
    return await _datasource.updateCampaignStatus(id, status);
  }

  @override
  Future<CampaignEntity> scheduleCampaign(String id, DateTime scheduledAt) async {
    return await _datasource.scheduleCampaign(id, scheduledAt);
  }

  @override
  void dispose() {
    // No hay recursos que liberar por ahora
  }
}
