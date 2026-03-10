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

  // ✅ OPTIMIZACIÓN: Caché para datos semi-estáticos (30 min)
  List<PropertyEntity>? _cache;
  DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(minutes: 30);

  /// ✅ OPTIMIZACIÓN: Verificar si el caché es válido y no ha expirado
  bool _isCacheValid() {
    if (_cache == null || _cacheTimestamp == null) return false;
    final now = DateTime.now();
    final difference = now.difference(_cacheTimestamp!);
    return difference < _cacheDuration;
  }

  @override
  Future<List<PropertyEntity>> getAll() async {
    try {
      log('📦 PropertiesRepository: Iniciando carga de datos...');

      // ✅ OPTIMIZACIÓN: Usar caché si es válido y no ha expirado
      if (_isCacheValid()) {
        log('📦 PropertiesRepository: Usando caché válido (edad: ${DateTime.now().difference(_cacheTimestamp!).inMinutes} minutos)');
        return _cache!;
      }

      log('📦 PropertiesRepository: Caché expirado o vacío, recargando datos desde Supabase...');

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
        unitsByProperty.putIfAbsent(propertyId, () => <Map<String, dynamic>>[]).add(unit);
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

      // Guardar en caché
      _cache = properties;
      _cacheTimestamp = DateTime.now();

      return _cache!;
    } catch (e, stackTrace) {
      log('❌ PropertiesRepository: Error al cargar alojamientos: $e');
      log('❌ StackTrace: $stackTrace');
      throw Exception('Error al cargar alojamientos: $e');
    }
  }

  @override
  Future<PropertyEntity?> getById(String id) async {
    try {
      // ✅ OPTIMIZACIÓN: Usar caché si es válido
      if (_isCacheValid() && _cache != null) {
        try {
          return _cache!.firstWhere((p) => p.id == id);
        } catch (_) {
          return null;
        }
      }

      // Si no está en caché, fetch desde Supabase
      final response = await _supabase
          .from(SupabaseTables.properties)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      // Obtener las unidades de la propiedad
      final unitsResponse = await _supabase
          .from(SupabaseTables.unitsWithFullAddress)
          .select()
          .eq('property_id', id);

      if (unitsResponse.isEmpty) return null;

      return PropertyEntity.fromJson({
        ...response,
        'units': unitsResponse,
      });
    } catch (e, stackTrace) {
      log('❌ PropertiesRepository: Error al obtener propiedad $id: $e');
      log('❌ StackTrace: $stackTrace');
      rethrow;
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
          .map((json) => UnitEntity.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      log('❌ PropertiesRepository: Error al obtener unidades: $e');
      log('❌ StackTrace: $stackTrace');
      rethrow;
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
    } catch (e, stackTrace) {
      log('❌ PropertiesRepository: Error al obtener unidad $unitId: $e');
      log('❌ StackTrace: $stackTrace');
      rethrow;
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
          .map((json) => UnitPhotoEntity.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      log('❌ PropertiesRepository: Error al obtener fotos de unidad: $e');
      log('❌ StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<Map<String, UnitPhotoEntity>> getCoverPhotos(List<String> unitIds) async {
    try {
      if (unitIds.isEmpty) return {};

      final response = await _supabase
          .from(SupabaseTables.unitPhotos)
          .select()
          .inFilter('unit_id', unitIds)
          .eq('is_cover', true)
          .order('sort_order', ascending: true);

      final Map<String, UnitPhotoEntity> coverPhotos = {};
      for (final json in response) {
        final photo = UnitPhotoEntity.fromJson(json);
        coverPhotos[photo.unitId] = photo;
      }

      return coverPhotos;
    } catch (e, stackTrace) {
      log('❌ PropertiesRepository: Error al obtener fotos de cobertura: $e');
      log('❌ StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<List<PropertyEntity>> search(String query) async {
    try {
      // ✅ OPTIMIZACIÓN: Primero buscar en caché si es válido
      if (_isCacheValid()) {
        final filteredProperties = _cache!.where((p) {
          final name = p.name.toLowerCase();
          final city = (p.city ?? '').toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || city.contains(searchLower);
        }).toList();
        log('📦 PropertiesRepository: Búsqueda en caché: ${filteredProperties.length} resultados');
        return filteredProperties;
      }

      // Si no hay caché, cargar datos primero
      final allProperties = await getAll();
      return allProperties.where((p) {
        final name = p.name.toLowerCase();
        final city = (p.city ?? '').toLowerCase();
        final searchLower = query.toLowerCase();
        return name.contains(searchLower) || city.contains(searchLower);
      }).toList();
    } catch (e, stackTrace) {
      log('❌ PropertiesRepository: Error al buscar propiedades: $e');
      log('❌ StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// ✅ OPTIMIZACIÓN: Eliminar stream Realtime - datos semi-estáticos no necesitan tiempo real
  /// Usar getAll() con caché en su lugar
  @Deprecated('Usar getAll() con caché en lugar de Realtime')
  @override
  Stream<List<PropertyEntity>> watchAll() {
    // ⚠️ DEPRECATED: Este método se mantiene por compatibilidad hacia atrás
    // pero usa Realtime innecesariamente para datos semi-estáticos
    // RECOMENDACIÓN: Usar getAll() con caché para mejor rendimiento
    // TODO: Eliminar en futuras versiones cuando no haya dependencias
    return Stream.fromFuture(getAll());
  }

  @override
  Future<List<String>> getCommonAreasPhotos(String propertyId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.commonAreasPhotos)
          .select()
          .eq('property_id', propertyId)
          .order('display_order', ascending: true);

      return (response as List).cast<String>();
    } catch (e, stackTrace) {
      log('❌ PropertiesRepository: Error al obtener fotos de zonas comunes: $e');
      log('❌ StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// ✅ Método para invalidar manualmente el caché cuando se sabe que datos han cambiado
  void invalidateCache() {
    _cache = null;
    _cacheTimestamp = null;
    log('📦 PropertiesRepository: Caché invalidado manualmente');
  }
}
