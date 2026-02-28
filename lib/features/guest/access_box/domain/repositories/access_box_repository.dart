import '../entities/access_box_entity.dart';

/// Contrato del repositorio de códigos de acceso
abstract class AccessBoxRepository {
  /// Obtiene los códigos de acceso para una reserva
  /// Incluye el código principal, WiFi y códigos adicionales
  Future<AccessBoxEntity?> getAccessBox(String bookingId);
}
