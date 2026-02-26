import 'dart:async';
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/config/supabase_config.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/entities/unit_entity.dart';
import '../../domain/entities/unit_photo_entity.dart';
import '../../domain/repositories/properties_repository.dart';

/// Implementación del repositorio de propiedades con Supabase
class PropertiesRepositoryImpl implements PropertiesRepository {
  PropertiesRepositoryImpl({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  @override
  Future<List<PropertyEntity>> getAll() async {
    try {
      log('📦 PropertiesRepository: Iniciando carga de datos...');

      // Obtener propiedades
      final propertiesResponse = await _supabase
          .from(SupabaseTables.properties)
          .select()
          .order('name', ascending: true);

      log('📦 PropertiesRepository: Propiedades obtenidas: ${propertiesResponse.length}');

      // Obtener todas las unidades con dirección completa
      final unitsResponse = await _supabase
          .from(SupabaseTables.unitsWithFullAddress)
          .select()
          .order('name', ascending: true);

      log('📦 PropertiesRepository: Unidades obtenidas: ${unitsResponse.length}');

      // Mapear unidades por property_id
      final unitsByProperty = <String, List<Map<String, dynamic>>>{};
      for (final unit in unitsResponse) {
        final propertyId = unit['property_id'] as String;
        unitsByProperty.putIfAbsent(propertyId, () => []).add(unit);
      }

      log('📦 PropertiesRepository: Unidades mapeadas por propiedad: ${unitsByProperty.length}');

      // Construir propiedades con sus unidades
      final properties = propertiesResponse.map((property) {
        final propertyId = property['id'] as String;
        final units = unitsByProperty[propertyId] ?? [];

        log('📦 PropertiesRepository: Propiedad ${property['name']} tiene ${units.length} unidades');

        return PropertyEntity.fromJson({
          ...property,
          'units': units,
        });
      }).toList();

      log('📦 PropertiesRepository: Total propiedades construidas: ${properties.length}');
      log('📦 PropertiesRepository: Total unidades: ${properties.fold<int>(0, (sum, p) => sum + p.units.length)}');

      return properties;
    } catch (e, stackTrace) {
      log('❌ PropertiesRepository: Error al cargar alojamientos: $e');
      log('❌ StackTrace: $stackTrace');
      throw Exception('Error al cargar alojamientos: $e');
    }
  }

  @override
  Future<PropertyEntity?> getById(String id) async {
    try {
      // Obtener la propiedad
      final propertyResponse = await _supabase
          .from(SupabaseTables.properties)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (propertyResponse == null) return null;

      // Obtener las unidades de la propiedad con dirección completa
      final unitsResponse = await _supabase
          .from(SupabaseTables.unitsWithFullAddress)
          .select()
          .eq('property_id', id)
          .order('name', ascending: true);

      return PropertyEntity.fromJson({
        ...propertyResponse,
        'units': unitsResponse,
      });
    } catch (e) {
      throw Exception('Error al cargar el alojamiento: $e');
    }
  }

  @override
  Future<List<UnitEntity>> getUnitsByPropertyId(String propertyId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.unitsWithFullAddress)
          .select()
          .eq('property_id', propertyId)
          .order('name', ascending: true);

      return response
          .map<UnitEntity>(
              (json) => UnitEntity.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar las unidades: $e');
    }
  }

  @override
  Future<UnitEntity?> getUnitById(String unitId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.unitsWithFullAddress)
          .select()
          .eq('id', unitId)
          .maybeSingle();

      if (response == null) return null;

      return UnitEntity.fromJson(response);
    } catch (e) {
      throw Exception('Error al cargar la unidad: $e');
    }
  }

  @override
  Future<List<UnitPhotoEntity>> getUnitPhotos(String unitId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.unitPhotos)
          .select()
          .eq('unit_id', unitId)
          .order('sort_order', ascending: true);

      return response
          .map<UnitPhotoEntity>((json) => UnitPhotoEntity.fromJson(json))
          .toList();
    } catch (e) {
      log('❌ PropertiesRepository: Error al cargar fotos: $e');
      throw Exception('Error al cargar las fotos: $e');
    }
  }

  @override
  Future<Map<String, UnitPhotoEntity>> getCoverPhotos(List<String> unitIds) async {
    if (unitIds.isEmpty) return {};

    try {
      final response = await _supabase
          .from(SupabaseTables.unitPhotos)
          .select()
          .inFilter('unit_id', unitIds)
          .eq('is_cover', true);

      final Map<String, UnitPhotoEntity> coverPhotos = {};
      for (final json in response) {
        final photo = UnitPhotoEntity.fromJson(json);
        coverPhotos[photo.unitId] = photo;
      }

      return coverPhotos;
    } catch (e) {
      log('❌ PropertiesRepository: Error al cargar fotos de cobertura: $e');
      return {};
    }
  }

  @override
  Future<List<PropertyEntity>> search(String query) async {
    try {
      final searchTerm = '%${query.toLowerCase()}%';

      // Buscar propiedades por nombre o ciudad
      final propertiesResponse = await _supabase
          .from(SupabaseTables.properties)
          .select()
          .or('name.ilike.$searchTerm,city.ilike.$searchTerm')
          .order('name', ascending: true);

      if (propertiesResponse.isEmpty) return [];

      // Obtener los IDs de las propiedades encontradas
      final propertyIds =
          propertiesResponse.map((p) => p['id'] as String).toList();

      // Obtener las unidades de esas propiedades con dirección completa
      final unitsResponse = await _supabase
          .from(SupabaseTables.unitsWithFullAddress)
          .select()
          .inFilter('property_id', propertyIds)
          .order('name', ascending: true);

      // Mapear unidades por property_id
      final unitsByProperty = <String, List<Map<String, dynamic>>>{};
      for (final unit in unitsResponse) {
        final propertyId = unit['property_id'] as String;
        unitsByProperty.putIfAbsent(propertyId, () => []).add(unit);
      }

      // Construir propiedades con sus unidades
      return propertiesResponse.map((property) {
        final propertyId = property['id'] as String;
        final units = unitsByProperty[propertyId] ?? [];

        return PropertyEntity.fromJson({
          ...property,
          'units': units,
        });
      }).toList();
    } catch (e) {
      throw Exception('Error en la búsqueda: $e');
    }
  }

  @override
  Stream<List<PropertyEntity>> watchAll() {
    return _supabase
        .from(SupabaseTables.properties)
        .stream(primaryKey: ['id'])
        .order('name', ascending: true)
        .asyncMap((properties) async {
      // Obtener todas las unidades
      final propertyIds = properties.map((p) => p['id'] as String).toList();

      if (propertyIds.isEmpty) return [];

      final unitsResponse = await _supabase
          .from(SupabaseTables.unitsWithFullAddress)
          .select()
          .inFilter('property_id', propertyIds);

      // Mapear unidades por property_id
      final unitsByProperty = <String, List<Map<String, dynamic>>>{};
      for (final unit in unitsResponse) {
        final propertyId = unit['property_id'] as String;
        unitsByProperty.putIfAbsent(propertyId, () => []).add(unit);
      }

      // Construir propiedades con sus unidades
      return properties.map((property) {
        final propertyId = property['id'] as String;
        final units = unitsByProperty[propertyId] ?? [];

        return PropertyEntity.fromJson({
          ...property,
          'units': units,
        });
      }).toList();
    });
  }
}
