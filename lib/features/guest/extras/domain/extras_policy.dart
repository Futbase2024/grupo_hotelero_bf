/// Política de solicitudes de extras del huésped.
///
/// Mantener aquí las reglas evita que la pantalla, el repositorio y la BD se
/// desincronicen. La validación definitiva vive en Supabase (índice único +
/// trigger de ventana temporal); esto es la copia de cliente para poder avisar
/// al huésped antes de que intente solicitarlo.
class ExtrasPolicy {
  const ExtrasPolicy._();

  /// Tipo de extra del Pack Romántico (columna `extra_requests.extra_type`).
  static const String romanticPackType = 'romantic_pack';

  /// Hora de entrada de referencia: la misma que usa la app para las llaves y
  /// los códigos de acceso (14:00 del día de check-in).
  static const int checkInHour = 14;

  /// Antelación mínima con la que debe solicitarse el Pack Romántico.
  static const Duration romanticPackMinAdvance = Duration(hours: 24);

  /// Fecha/hora límite para solicitar el Pack Romántico de una reserva.
  ///
  /// Equivale a las 14:00 del día de entrada menos 24 h, es decir, el día
  /// anterior al check-in a las 14:00.
  static DateTime romanticPackDeadline(DateTime checkInDate) {
    final checkIn = DateTime(
      checkInDate.year,
      checkInDate.month,
      checkInDate.day,
      checkInHour,
    );
    return checkIn.subtract(romanticPackMinAdvance);
  }

  /// `true` si todavía se está dentro del plazo para solicitar el pack.
  static bool isWithinRomanticPackWindow(
    DateTime checkInDate, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    return !reference.isAfter(romanticPackDeadline(checkInDate));
  }
}
