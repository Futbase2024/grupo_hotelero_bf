/// Politica de check-in comun a todos los canales de comunicacion con el huesped
/// (WhatsApp, PDF de la reserva y, en el futuro, la plantilla de correo).
///
/// Mantener aqui la hora limite evita que los distintos textos se desincronicen.
class CheckinPolicy {
  const CheckinPolicy._();

  /// Hora maxima a la que el huesped puede realizar el check-in.
  static const String maxCheckinTime = '23:00';

  /// Aviso destacado sobre la hora limite de check-in.
  static const String maxCheckinNotice =
      'IMPORTANTE: la hora máxima para realizar el check-in son las '
      '$maxCheckinTime h.';

  /// Hora (local de la propiedad) del dia de entrada a partir de la cual el
  /// check-in se autovalida solo, sin revision del admin y sin importar el
  /// interruptor de auto-validacion de la reserva.
  ///
  /// No hay hora de cierre: una vez pasada esta hora, cualquier check-in de la
  /// reserva se autovalida.
  ///
  /// La regla vive en la base de datos: `public.checkin_auto_validate_cutoff()`.
  /// Si se cambia aqui, hay que cambiarla tambien alli.
  static const String autoValidateAfterHour = maxCheckinTime;
}
