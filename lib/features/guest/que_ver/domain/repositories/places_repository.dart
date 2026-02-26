import '../entities/collection_entity.dart';
import '../entities/place_entity.dart';

/// Contrato del repositorio de lugares y colecciones
abstract class PlacesRepository {
  /// Obtiene todos los lugares activos
  Future<List<PlaceEntity>> getAllPlaces();

  /// Obtiene un lugar por ID
  Future<PlaceEntity?> getPlaceById(String id);

  /// Obtiene un lugar por external ID
  Future<PlaceEntity?> getPlaceByExternalId(String externalId);

  /// Obtiene lugares filtrados por nivel geográfico
  Future<List<PlaceEntity>> getPlacesByLevel(PlaceLevel level);

  /// Obtiene lugares filtrados por categoría
  Future<List<PlaceEntity>> getPlacesByCategory(String category);

  /// Obtiene lugares filtrados por nivel y categoría
  Future<List<PlaceEntity>> getPlacesByLevelAndCategory(
    PlaceLevel level,
    String category,
  );

  /// Busca lugares por texto (título, descripción, tags)
  Future<List<PlaceEntity>> searchPlaces(String query);

  /// Obtiene lugares por lista de IDs
  Future<List<PlaceEntity>> getPlacesByIds(List<String> ids);

  /// Stream de cambios en lugares
  Stream<List<PlaceEntity>> watchPlaces();

  /// Obtiene todas las colecciones activas
  Future<List<CollectionEntity>> getAllCollections();

  /// Obtiene una colección por ID
  Future<CollectionEntity?> getCollectionById(String id);

  /// Obtiene una colección por external ID
  Future<CollectionEntity?> getCollectionByExternalId(String externalId);

  /// Obtiene una colección con sus lugares incluidos
  Future<({CollectionEntity collection, List<PlaceEntity> places})?>
      getCollectionWithPlaces(String id);

  /// Obtiene las categorías disponibles con conteo de lugares
  Future<Map<String, int>> getCategoriesWithCount();

  /// Obtiene los niveles disponibles con conteo de lugares
  Future<Map<PlaceLevel, int>> getLevelsWitCount();
}
