/// Interruptor del formulario de registro de viajeros (RD 933/2021) por reserva.
///
/// El método principal del check-in es la subida de fotos del documento; el
/// formulario solo aparece en las reservas en las que el staff lo activa.
abstract class TravellerFormAdminRepository {
  /// Si la reserva tiene activado el formulario de registro de viajeros
  Future<bool> isEnabled(String bookingId);

  /// Activa o desactiva el formulario. Devuelve el valor que queda guardado.
  ///
  /// Lanza [TravellerFormToggleException] si el servidor lo rechaza (por
  /// ejemplo, porque el check-in ya se ha enviado).
  Future<bool> setEnabled({required String bookingId, required bool enabled});
}

/// Rechazo del servidor al cambiar el interruptor
class TravellerFormToggleException implements Exception {
  const TravellerFormToggleException(this.code);

  /// Código devuelto por `set_booking_traveller_form`
  final String code;

  /// El check-in ya se envió: el método de check-in ya no se puede cambiar
  bool get isCheckinAlreadySubmitted =>
      code.startsWith('checkin_already_submitted');

  @override
  String toString() => 'TravellerFormToggleException($code)';
}
