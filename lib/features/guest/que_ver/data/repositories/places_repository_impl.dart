import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/constants/supabase_tables.dart';
import '../../domain/entities/collection_entity.dart';
import '../../domain/entities/place_entity.dart';
import '../../domain/entities/place_photo_entity.dart';
import '../../domain/repositories/places_repository.dart';

/// Implementación del repositorio de lugares usando Supabase
class PlacesRepositoryImpl implements PlacesRepository {
  PlacesRepositoryImpl({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Nombre del bucket de imágenes de lugares
  static const String _imagesBucket = 'poi-images';

  /// Construye la URL pública de una imagen
  String? _buildImageUrl(String? imagePath) {
    debugPrint('📷 [PlacesRepo] _buildImageUrl llamado con imagePath: "$imagePath"');

    if (imagePath == null || imagePath.isEmpty) {
      debugPrint('📷 [PlacesRepo] imagePath es null o vacío, retornando null');
      return null;
    }

    // Si ya es una URL completa, devolverla tal cual
    if (imagePath.startsWith('http')) {
      debugPrint('📷 [PlacesRepo] Ya es URL completa: $imagePath');
      return imagePath;
    }

    // Construir URL del bucket directamente con el path completo
    final url = _supabase.storage.from(_imagesBucket).getPublicUrl(imagePath);
    debugPrint('📷 [PlacesRepo] URL construida para bucket "$_imagesBucket": $url');
    return url;
  }

  /// Procesa un lugar para añadir URLs de imágenes correctas
  PlaceEntity _processPlace(
    Map<String, dynamic> json, {
    List<PlacePhotoEntity>? photos,
  }) {
    debugPrint('📷 [PlacesRepo] _processPlace llamado');
    debugPrint('📷 [PlacesRepo]   - json[image_url] original: ${json['image_url']}');
    debugPrint('📷 [PlacesRepo]   - photos proporcionadas: ${photos?.length ?? 0}');

    final processedJson = Map<String, dynamic>.from(json);
    processedJson['image_url'] = _buildImageUrl(json['image_url'] as String?);
    if (photos != null) {
      processedJson['photos'] = photos.map((p) => p.toJson()).toList();
    }

    debugPrint('📷 [PlacesRepo]   - processedJson[image_url]: ${processedJson['image_url']}');
    debugPrint('📷 [PlacesRepo]   - processedJson[photos]: ${processedJson['photos']}');

    return PlaceEntity.fromJson(processedJson);
  }

  /// Carga las fotos de un lugar desde la tabla place_photos
  Future<List<PlacePhotoEntity>> _loadPlacePhotos(String placeId) async {
    debugPrint('📷 [PlacesRepo] _loadPlacePhotos llamado para placeId: $placeId');
    try {
      final response = await _supabase
          .from(SupabaseTables.placePhotos)
          .select()
          .eq('place_id', placeId)
          .order('sort_order', ascending: true);

      debugPrint('📷 [PlacesRepo] Respuesta de place_photos: ${response.length} fotos encontradas');

      if (response.isNotEmpty) {
        debugPrint('📷 [PlacesRepo] Datos crudos de place_photos:');
        for (int i = 0; i < response.length; i++) {
          debugPrint('📷 [PlacesRepo]   Foto $i: ${response[i]}');
        }
      }

      final photos = response.map<PlacePhotoEntity>((json) {
        final originalUrl = json['image_url'] as String?;
        final processedJson = Map<String, dynamic>.from(json);
        processedJson['image_url'] = _buildImageUrl(originalUrl);
        final photo = PlacePhotoEntity.fromJson(processedJson);
        debugPrint('📷 [PlacesRepo] Foto procesada - id: ${photo.id}, imageUrl: ${photo.imageUrl}');
        return photo;
      }).toList();

      debugPrint('📷 [PlacesRepo] Total fotos procesadas: ${photos.length}');
      return photos;
    } catch (e) {
      debugPrint('📷 [PlacesRepo] ERROR en _loadPlacePhotos: $e');
      return [];
    }
  }

  @override
  Future<List<PlaceEntity>> getAllPlaces() async {
    try {
      final response = await _supabase
          .from(SupabaseTables.places)
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return response
          .map<PlaceEntity>((json) => _processPlace(json))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar los lugares: $e');
    }
  }

  @override
  Future<PlaceEntity?> getPlaceById(String id) async {
    debugPrint('📷 [PlacesRepo] getPlaceById llamado con id: $id');
    try {
      final response = await _supabase
          .from(SupabaseTables.places)
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        debugPrint('📷 [PlacesRepo] No se encontró lugar con id: $id');
        return null;
      }

      debugPrint('📷 [PlacesRepo] Lugar encontrado: ${response['title']}');
      debugPrint('📷 [PlacesRepo] image_url del lugar: ${response['image_url']}');

      // Cargar las fotos del lugar
      final photos = await _loadPlacePhotos(id);

      final place = _processPlace(response, photos: photos);

      debugPrint('📷 [PlacesRepo] PlaceEntity creado:');
      debugPrint('📷 [PlacesRepo]   - imageUrl: ${place.imageUrl}');
      debugPrint('📷 [PlacesRepo]   - hasImage: ${place.hasImage}');
      debugPrint('📷 [PlacesRepo]   - photos.length: ${place.photos.length}');
      debugPrint('📷 [PlacesRepo]   - hasPhotos: ${place.hasPhotos}');
      debugPrint('📷 [PlacesRepo]   - allImages: ${place.allImages}');

      return place;
    } catch (e) {
      debugPrint('📷 [PlacesRepo] ERROR en getPlaceById: $e');
      throw Exception('Error al cargar el lugar: $e');
    }
  }

  @override
  Future<PlaceEntity?> getPlaceByExternalId(String externalId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.places)
          .select()
          .eq('external_id', externalId)
          .eq('is_active', true)
          .maybeSingle();

      return response != null ? _processPlace(response) : null;
    } catch (e) {
      throw Exception('Error al cargar el lugar: $e');
    }
  }

  @override
  Future<List<PlaceEntity>> getPlacesByLevel(PlaceLevel level) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.places)
          .select()
          .eq('level', level.name)
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return response
          .map<PlaceEntity>((json) => _processPlace(json))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar los lugares: $e');
    }
  }

  @override
  Future<List<PlaceEntity>> getPlacesByCategory(String category) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.places)
          .select()
          .contains('categories', [category])
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return response
          .map<PlaceEntity>((json) => _processPlace(json))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar los lugares: $e');
    }
  }

  @override
  Future<List<PlaceEntity>> getPlacesByLevelAndCategory(
    PlaceLevel level,
    String category,
  ) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.places)
          .select()
          .eq('level', level.name)
          .contains('categories', [category])
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return response
          .map<PlaceEntity>((json) => _processPlace(json))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar los lugares: $e');
    }
  }

  @override
  Future<List<PlaceEntity>> searchPlaces(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      final response = await _supabase
          .from(SupabaseTables.places)
          .select()
          .eq('is_active', true)
          .or('title.ilike.%$lowerQuery%,short_description.ilike.%$lowerQuery%,tags.cs.{"$lowerQuery"}')
          .order('sort_order', ascending: true);

      return response
          .map<PlaceEntity>((json) => _processPlace(json))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar lugares: $e');
    }
  }

  @override
  Future<List<PlaceEntity>> getPlacesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    try {
      final response = await _supabase
          .from(SupabaseTables.places)
          .select()
          .inFilter('id', ids)
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return response
          .map<PlaceEntity>((json) => _processPlace(json))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar los lugares: $e');
    }
  }

  @override
  Stream<List<PlaceEntity>> watchPlaces() {
    return _supabase
        .from(SupabaseTables.places)
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('sort_order')
        .map((data) =>
            data.map<PlaceEntity>((json) => _processPlace(json)).toList());
  }

  /// Obtiene los place_ids para una colección desde la tabla intermedia
  Future<List<String>> _getPlaceIdsForCollection(String collectionId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.placeCollections)
          .select('place_id')
          .eq('collection_id', collectionId)
          .order('sort_order', ascending: true);

      return response
          .map<String>((json) => json['place_id'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<CollectionEntity>> getAllCollections() async {
    try {
      // Obtener colecciones desde la tabla collections
      final collectionsResponse = await _supabase
          .from(SupabaseTables.collections)
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      // Para cada colección, obtener sus place_ids desde place_collections
      final collections = <CollectionEntity>[];
      for (final collectionJson in collectionsResponse) {
        final placeIds = await _getPlaceIdsForCollection(collectionJson['id'] as String);

        final processedJson = Map<String, dynamic>.from(collectionJson);
        processedJson['place_ids'] = placeIds;
        processedJson['image_url'] = _buildImageUrl(collectionJson['image_url'] as String?);

        collections.add(CollectionEntity.fromJson(processedJson));
      }

      return collections;
    } catch (e) {
      throw Exception('Error al cargar las colecciones: $e');
    }
  }

  @override
  Future<CollectionEntity?> getCollectionById(String id) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.collections)
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      final placeIds = await _getPlaceIdsForCollection(id);
      final processedJson = Map<String, dynamic>.from(response);
      processedJson['place_ids'] = placeIds;
      processedJson['image_url'] = _buildImageUrl(response['image_url'] as String?);

      return CollectionEntity.fromJson(processedJson);
    } catch (e) {
      throw Exception('Error al cargar la colección: $e');
    }
  }

  @override
  Future<CollectionEntity?> getCollectionByExternalId(String externalId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.collections)
          .select()
          .eq('external_id', externalId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      final placeIds = await _getPlaceIdsForCollection(response['id'] as String);
      final processedJson = Map<String, dynamic>.from(response);
      processedJson['place_ids'] = placeIds;
      processedJson['image_url'] = _buildImageUrl(response['image_url'] as String?);

      return CollectionEntity.fromJson(processedJson);
    } catch (e) {
      throw Exception('Error al cargar la colección: $e');
    }
  }

  @override
  Future<({CollectionEntity collection, List<PlaceEntity> places})?>
      getCollectionWithPlaces(String id) async {
    try {
      final collection = await getCollectionById(id);
      if (collection == null) return null;

      final places = await getPlacesByIds(collection.placeIds);

      return (collection: collection, places: places);
    } catch (e) {
      throw Exception('Error al cargar la colección: $e');
    }
  }

  @override
  Future<Map<String, int>> getCategoriesWithCount() async {
    try {
      final places = await getAllPlaces();
      final countMap = <String, int>{};

      for (final place in places) {
        for (final category in place.categories) {
          countMap[category] = (countMap[category] ?? 0) + 1;
        }
      }

      return countMap;
    } catch (e) {
      throw Exception('Error al obtener categorías: $e');
    }
  }

  @override
  Future<Map<PlaceLevel, int>> getLevelsWitCount() async {
    try {
      final places = await getAllPlaces();
      final countMap = <PlaceLevel, int>{};

      for (final place in places) {
        countMap[place.level] = (countMap[place.level] ?? 0) + 1;
      }

      return countMap;
    } catch (e) {
      throw Exception('Error al obtener niveles: $e');
    }
  }
}
