import '../entities/traveller_entity.dart';
import '../entities/traveller_register_status.dart';

/// Registro de viajeros (RD 933/2021) de una reserva.
///
/// Toda la lógica legal y de permisos vive en el servidor (RPCs
/// `save_traveller_guest`, `traveller_register_issues`,
/// `sign_traveller_entry_form`, `submit_traveller_checkin`).
abstract class TravellerRegisterRepository {
  /// Huéspedes de la reserva con sus datos del registro
  Future<List<TravellerEntity>> getTravellers(String bookingId);

  /// Crea (si `traveller.id` es null) o actualiza un huésped. Devuelve su id.
  ///
  /// Si cambian datos ya firmados, el servidor invalida los partes afectados
  /// y hay que volver a firmar.
  Future<String> saveTraveller({
    required String bookingId,
    required TravellerEntity traveller,
  });

  /// Qué falta, quién debe firmar y si se puede enviar
  Future<TravellerRegisterStatus> getStatus(String bookingId);

  /// Genera el parte de entrada del huésped (14+) con los menores de 14 a su
  /// cargo, y lo firma. Devuelve el id del parte.
  Future<String> signEntryForm({
    required String bookingId,
    required String guestId,
    required String signatureSvg,
  });

  /// Envía el check-in. Falla si el registro no está completo.
  Future<void> submit(String bookingId);
}

/// Error devuelto por el servidor con un código conocido
/// (`invalid_document_number`, `checkin_locked`, `register_incomplete`…)
class TravellerRegisterException implements Exception {
  const TravellerRegisterException(this.code, [this.detail]);

  final String code;
  final String? detail;

  /// Extrae el código de un mensaje de Postgres del tipo
  /// `checkin_locked: el check-in ya se ha enviado`
  factory TravellerRegisterException.fromServerMessage(String message) {
    final separator = message.indexOf(':');
    if (separator <= 0) return TravellerRegisterException(message.trim());
    return TravellerRegisterException(
      message.substring(0, separator).trim(),
      message.substring(separator + 1).trim(),
    );
  }

  @override
  String toString() => 'TravellerRegisterException($code)';
}
