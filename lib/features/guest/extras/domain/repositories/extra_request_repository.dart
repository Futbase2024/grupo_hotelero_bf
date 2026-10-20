import '../entities/extra_request_entity.dart';

/// Error de dominio: el extra ya fue solicitado para esa reserva.
class ExtraAlreadyRequestedException implements Exception {
  const ExtraAlreadyRequestedException();
}

/// Error de dominio: se solicitó el extra fuera de plazo (menos de 24 h antes
/// de la entrada, en el caso del Pack Romántico).
class ExtraRequestWindowClosedException implements Exception {
  const ExtraRequestWindowClosedException();
}

/// Contrato del repositorio de solicitudes de extras (Pack Romántico, etc.).
///
/// La implementación está en
/// `data/repositories/extra_request_repository_impl.dart`.
abstract class ExtraRequestRepository {
  /// Crea una nueva solicitud de extra (la hace el huésped).
  ///
  /// Lanza [ExtraAlreadyRequestedException] si ya existe una solicitud activa
  /// del mismo extra para esa reserva, y [ExtraRequestWindowClosedException]
  /// si se ha superado el plazo permitido.
  Future<ExtraRequestEntity> create(ExtraRequestEntity request);

  /// Devuelve la solicitud activa (no cancelada) de un extra para una reserva,
  /// o `null` si el huésped todavía no lo ha solicitado.
  Future<ExtraRequestEntity?> getActiveByBookingAndType({
    required String bookingId,
    required String extraType,
  });

  /// Obtiene todas las solicitudes (para el admin), opcionalmente filtradas.
  Future<List<ExtraRequestEntity>> getAll({
    String? propertyId,
    ExtraRequestStatus? status,
  });

  /// Stream en tiempo real de las solicitudes (para el listado admin).
  Stream<List<ExtraRequestEntity>> watchAll({String? propertyId});

  /// Elimina definitivamente una solicitud (acción del admin).
  ///
  /// Al borrarla, el huésped vuelve a poder solicitar ese extra si sigue en
  /// plazo, porque el bloqueo anti-duplicados solo cuenta solicitudes vivas.
  Future<void> delete(String id);

  /// Marca una solicitud como gestionada por el admin.
  Future<void> markAsManaged(String id, {String? managedBy, String? notes});

  /// Actualiza el estado de una solicitud.
  Future<void> updateStatus(
    String id,
    ExtraRequestStatus status, {
    String? managedBy,
    String? notes,
  });
}
