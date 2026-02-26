import '../entities/review_entity.dart';

/// Contrato del repositorio de reseñas
abstract class ReviewsRepository {
  /// Obtiene todas las reseñas de una propiedad
  Future<List<ReviewEntity>> getByPropertyId(String propertyId);

  /// Obtiene todas las reseñas de una unidad específica
  Future<List<ReviewEntity>> getByUnitId(String unitId);

  /// Obtiene una reseña por su ID
  Future<ReviewEntity?> getById(String id);

  /// Obtiene las reseñas de un huésped
  Future<List<ReviewEntity>> getByGuestId(String guestId);

  /// Crea una nueva reseña
  Future<ReviewEntity> create(ReviewEntity review);

  /// Actualiza una reseña existente
  Future<ReviewEntity> update(ReviewEntity review);

  /// Elimina una reseña (soft delete)
  Future<void> delete(String id);

  /// Obtiene el rating promedio de una propiedad
  Future<double> getAverageRating(String propertyId);

  /// Obtiene la distribución de ratings de una propiedad
  Future<Map<int, int>> getRatingDistribution(String propertyId);

  /// Verifica si un huésped puede dejar reseña (tiene reserva completada)
  Future<bool> canGuestReview(String guestId, String propertyId);

  /// Stream de reseñas en tiempo real para una propiedad
  Stream<List<ReviewEntity>> watchByPropertyId(String propertyId);
}
