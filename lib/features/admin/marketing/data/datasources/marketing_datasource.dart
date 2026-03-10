import 'package:flutter/foundation.dart';

import '../../../../../core/config/supabase_config.dart';
import '../../../../../core/constants/supabase_tables.dart' as tables;
import '../../domain/entities/campaign_entity.dart';

/// Datasource para operaciones de marketing con Supabase
class MarketingDatasource {
  MarketingDatasource();

  final _client = SupabaseConfig.client;

  void _log(String message) {
    debugPrint('[MarketingDatasource] $message');
  }

  // ============================================
  // CAMPAIGNS
  // ============================================

  /// Obtiene todas las campañas de una propiedad
  Future<List<CampaignEntity>> getCampaigns(String propertyId) async {
    _log('Obteniendo campañas para propiedad: $propertyId');

    final response = await _client
        .from(tables.SupabaseTables.marketingCampaigns)
        .select()
        .eq('property_id', propertyId)
        .order('created_at', ascending: false);

    _log('Campañas obtenidas: ${(response as List).length}');

    return (response as List)
        .map((json) => CampaignEntity.fromJson(json))
        .toList();
  }

  /// Obtiene una campaña por ID
  Future<CampaignEntity?> getCampaign(String id) async {
    _log('Obteniendo campaña: $id');

    final response = await _client
        .from(tables.SupabaseTables.marketingCampaigns)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) {
      _log('Campaña no encontrada: $id');
      return null;
    }

    return CampaignEntity.fromJson(response);
  }

  /// Crea una nueva campaña
  Future<CampaignEntity> createCampaign(CampaignEntity campaign) async {
    _log('Creando campaña: ${campaign.name}');

    final response = await _client
        .from(tables.SupabaseTables.marketingCampaigns)
        .insert(campaign.toJsonForCreate())
        .select()
        .single();

    _log('Campaña creada: ${response['id']}');

    return CampaignEntity.fromJson(response);
  }

  /// Actualiza una campaña existente
  Future<CampaignEntity> updateCampaign(CampaignEntity campaign) async {
    _log('Actualizando campaña: ${campaign.id}');

    final data = campaign.toJson();
    data.remove('id');
    data.remove('created_at');

    final response = await _client
        .from(tables.SupabaseTables.marketingCampaigns)
        .update(data)
        .eq('id', campaign.id)
        .select()
        .single();

    _log('Campaña actualizada: ${campaign.id}');

    return CampaignEntity.fromJson(response);
  }

  /// Elimina una campaña
  Future<void> deleteCampaign(String id) async {
    _log('Eliminando campaña: $id');

    await _client
        .from(tables.SupabaseTables.marketingCampaigns)
        .delete()
        .eq('id', id);

    _log('Campaña eliminada: $id');
  }

  /// Observa cambios en las campañas de una propiedad en tiempo real
  Stream<List<CampaignEntity>> watchCampaigns(String propertyId) {
    _log('Observando campañas para propiedad: $propertyId');

    return _client
        .from(tables.SupabaseTables.marketingCampaigns)
        .stream(primaryKey: ['id'])
        .eq('property_id', propertyId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => CampaignEntity.fromJson(json)).toList());
  }

  // ============================================
  // CAMPAIGN STATUS
  // ============================================

  /// Actualiza el estado de una campaña
  Future<CampaignEntity> updateCampaignStatus(
    String id,
    CampaignStatus status,
  ) async {
    _log('Actualizando estado de campaña $id a: ${status.name}');

    final response = await _client
        .from(tables.SupabaseTables.marketingCampaigns)
        .update({'status': status.name})
        .eq('id', id)
        .select()
        .single();

    return CampaignEntity.fromJson(response);
  }

  /// Programa una campaña para envío futuro
  Future<CampaignEntity> scheduleCampaign(
    String id,
    DateTime scheduledAt,
  ) async {
    _log('Programando campaña $id para: $scheduledAt');

    final response = await _client
        .from(tables.SupabaseTables.marketingCampaigns)
        .update({
          'status': 'scheduled',
          'scheduled_at': scheduledAt.toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();

    return CampaignEntity.fromJson(response);
  }
}
