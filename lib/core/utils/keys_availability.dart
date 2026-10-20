/// Regla de disponibilidad de llaves y códigos de acceso (caja, WiFi...).
///
/// El huésped puede entrar en la app antes de llegar (check-in online), pero
/// los códigos solo se muestran:
///  · por defecto, desde las 14:00 del día de check-in;
///  · antes, si el admin activa el early check-in ese MISMO día (si lo marca
///    otro día se ignora).
///
/// Para que cambiar el reloj del móvil no adelante la disponibilidad, `now`
/// debe ser la hora del servidor siempre que se tenga.
abstract final class KeysAvailability {
  /// Hora por defecto a partir de la cual están disponibles los códigos.
  static const int defaultHour = 14;

  /// Momento a partir del cual el huésped puede ver los códigos.
  static DateTime availableAt({
    required DateTime checkInDate,
    DateTime? earlyCheckinAvailableAt,
  }) {
    final earlyTime = earlyCheckinAvailableAt;
    if (earlyTime != null &&
        earlyTime.year == checkInDate.year &&
        earlyTime.month == checkInDate.month &&
        earlyTime.day == checkInDate.day) {
      return earlyTime;
    }

    return DateTime(
      checkInDate.year,
      checkInDate.month,
      checkInDate.day,
      defaultHour,
    );
  }

  /// Si en el instante [now] el huésped ya puede ver los códigos.
  static bool isAvailable({
    required DateTime checkInDate,
    DateTime? earlyCheckinAvailableAt,
    required DateTime now,
  }) {
    final availableFrom = availableAt(
      checkInDate: checkInDate,
      earlyCheckinAvailableAt: earlyCheckinAvailableAt,
    );
    return !now.isBefore(availableFrom);
  }
}
