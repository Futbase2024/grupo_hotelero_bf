import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/parking_entity.dart';
import '../../domain/entities/unit_parking_entity.dart';
import '../../domain/repositories/parkings_repository.dart';

/// Implementación del repositorio de parkings usando Supabase
class ParkingsRepositoryImpl implements ParkingsRepository {
  ParkingsRepositoryImpl({
    required SupabaseClient supabaseClient,
  }) : _supabaseClient = supabaseClient;

  final SupabaseClient _supabaseClient;

  @override
  Future<List<ParkingEntity>> getAllParkings() async {
    final response = await _supabaseClient
        .from('parkings')
        .select()
        .eq('is_active', true)
        .order('name', ascending: true);

    return (response as List)
        .map((json) => ParkingEntity.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ParkingEntity?> getParkingById(String id) async {
    final response = await _supabaseClient
        .from('parkings')
        .select()
        .eq('id', id)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;

    return ParkingEntity.fromJson(response);
  }

  @override
  Future<List<UnitParkingEntity>> getParkingsByUnitId(String unitId) async {
    final response = await _supabaseClient
        .from('unit_parkings')
        .select('''
          id,
          unit_id,
          parking_id,
          priority,
          notes,
          parkings (
            id,
            name,
            address_text,
            phone,
            provider,
            lat,
            lng,
            google_maps_url,
            apple_maps_url,
            is_active
          )
        ''')
        .eq('unit_id', unitId)
        .eq('parkings.is_active', true)
        .order('priority', ascending: true);

    return (response as List)
        .map((json) => UnitParkingEntity.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<UnitParkingEntity>> getAllUnitParkings() async {
    final response = await _supabaseClient
        .from('unit_parkings')
        .select('''
          id,
          unit_id,
          parking_id,
          priority,
          notes,
          parkings (
            id,
            name,
            address_text,
            phone,
            provider,
            lat,
            lng,
            google_maps_url,
            apple_maps_url,
            is_active
          ),
          units (
            id,
            name,
            unit_type,
            property_id,
            properties (
              id,
              name
            )
          )
        ''')
        .eq('parkings.is_active', true)
        .order('unit_id', ascending: true)
        .order('priority', ascending: true);

    return (response as List)
        .map((json) => UnitParkingEntity.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
