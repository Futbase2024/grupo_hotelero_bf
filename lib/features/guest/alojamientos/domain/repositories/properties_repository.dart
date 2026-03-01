import '../entities/property_entity.dart';
import '../entities/unit_entity.dart';
import '../entities/unit_photo_entity.dart';

/// Contrato del repositorio de propiedades/alojamientos
abstract class PropertiesRepository {
  /// Obtiene todas las propiedades disponibles con sus unidades
  Future<List<PropertyEntity>> getAll();

  /// Obtiene una propiedad por su ID con sus unidades
  Future<PropertyEntity?> getById(String id);

  /// Obtiene las unidades de una propiedad
  Future<List<UnitEntity>> getUnitsByPropertyId(String propertyId);

  /// Obtiene una unidad por su ID
  Future<UnitEntity?> getUnitById(String unitId);

  /// Obtiene las fotos de una unidad
  Future<List<UnitPhotoEntity>> getUnitPhotos(String unitId);

  /// Obtiene las fotos de cobertura de múltiples unidades
  Future<Map<String, UnitPhotoEntity>> getCoverPhotos(List<String> unitIds);

  /// Busca propiedades por nombre o ciudad
  Future<List<PropertyEntity>> search(String query);

  /// Stream de propiedades en tiempo real
  Stream<List<PropertyEntity>> watchAll();

  /// Obtiene las URLs de las fotos de zonas comunes de un hotel desde Supabase Storage
  /// Retorna una lista de URLs firmadas
  Future<List<String>> getCommonAreasPhotos(String propertyId);
}
