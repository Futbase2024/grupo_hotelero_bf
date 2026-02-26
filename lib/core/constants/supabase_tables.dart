/// Constantes de nombres de tablas en Supabase
///
/// Este archivo centraliza todos los nombres de tablas para:
/// - Evitar errores de tipeo
/// - Facilitar refactorizaciones
/// - Mantener consistencia en toda la aplicación
class SupabaseTables {
  SupabaseTables._();

  // ============================================
  // PROPIEDADES Y ALOJAMIENTOS
  // ============================================

  /// Tabla de propiedades (alojamientos)
  static const String properties = 'properties';

  /// Tabla de unidades (apartamentos/habitaciones)
  static const String units = 'units';

  /// Tabla de fotos de unidades
  static const String unitPhotos = 'unit_photos';

  // ============================================
  // RESERVAS Y HUÉSPEDES
  // ============================================

  /// Tabla de reservas
  static const String bookings = 'bookings';

  /// Tabla de huéspedes
  static const String guests = 'guests';

  /// Tabla de check-ins
  static const String checkins = 'checkins';

  // ============================================
  // NORMAS DE LA CASA
  // ============================================

  /// Tabla de normas de la casa
  static const String houseRules = 'house_rules';

  // ============================================
  // ¿QUÉ VER? - LUGARES Y EXPERIENCIAS
  // ============================================

  /// Tabla de lugares/experiencias turísticas
  static const String places = 'places';

  /// Tabla de colecciones de lugares
  static const String collections = 'collections';

  /// Tabla de relación lugares-colecciones
  static const String placeCollections = 'place_collections';

  /// Tabla de fotos de lugares
  static const String placePhotos = 'place_photos';

  // ============================================
  // PARKINGS
  // ============================================

  /// Tabla de parkings cercanos a alojamientos
  static const String parkings = 'parkings';

  /// Tabla de relación unidades-parkings
  static const String unitParkings = 'unit_parkings';

  // ============================================
  // RESEÑAS Y COMENTARIOS
  // ============================================

  /// Tabla de reseñas
  static const String reviews = 'reviews';

  /// Vista de reseñas con datos de guest
  static const String reviewsWithGuest = 'reviews_with_guest';

  // ============================================
  // USUARIOS Y AUTENTICACIÓN
  // ============================================

  /// Tabla de perfiles de usuario
  static const String profiles = 'profiles';

  /// Tabla de sesiones
  static const String sessions = 'sessions';
}

/// Constantes de nombres de columnas comunes
class SupabaseColumns {
  SupabaseColumns._();

  // Columnas comunes en todas las tablas
  static const String id = 'id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String isActive = 'is_active';
  static const String sortOrder = 'sort_order';

  // Columnas de propiedades
  static const String propertyName = 'name';
  static const String propertyDescription = 'description';
  static const String propertyAddress = 'address';

  // Columnas de unidades
  static const String unitName = 'name';
  static const String unitPropertyId = 'property_id';

  // Columnas de lugares
  static const String placeExternalId = 'external_id';
  static const String placeLevel = 'level';
  static const String placeTitle = 'title';
  static const String placeShortDescription = 'short_description';
  static const String placeLongDescription = 'long_description';
  static const String placeCategories = 'categories';
  static const String placeDuration = 'recommended_duration_minutes';
  static const String placeBestTime = 'best_time_to_visit';
  static const String placePriceLevel = 'price_level';
  static const String placeAddress = 'address';
  static const String placeGeoLat = 'geo_lat';
  static const String placeGeoLng = 'geo_lng';
  static const String placeBookingUrl = 'booking_url';
  static const String placeWebsiteUrl = 'website_url';
  static const String placeTips = 'tips';
  static const String placeTags = 'tags';
  static const String placeImageUrl = 'image_url';
  static const String placeImageAlt = 'image_alt';
}
