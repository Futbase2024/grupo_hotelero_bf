import '../entities/guest_access_entity.dart';

/// Contrato del repositorio de códigos de acceso del huésped.
abstract class GuestAccessRepository {
  /// Obtiene los códigos de acceso de [bookingId] desde el servidor.
  ///
  /// Los secretos llegan a `null` si el check-in no está validado o la reserva
  /// está fuera de su periodo de acceso ([GuestAccessEntity.reason]).
  Future<GuestAccessEntity> getAccess(String bookingId);
}
