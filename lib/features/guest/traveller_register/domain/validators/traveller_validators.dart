/// Validadores del registro de viajeros.
///
/// Son ESPEJO de los del servidor (`is_valid_spanish_id`,
/// `traveller_normalize_doc`, `save_traveller_guest`): sirven para avisar al
/// huésped en el momento, pero el servidor vuelve a validar siempre. Si se
/// cambia una regla aquí, hay que cambiarla también en SQL (y al revés).
abstract final class TravellerValidators {
  static const String _dniLetters = 'TRWAGMYFPDXBNJZSQVHLCKE';

  static final RegExp _separators = RegExp(r'[\s.\-]');
  static final RegExp _phoneSeparators = RegExp(r'[\s\-.()]');
  static final RegExp _dniPattern = RegExp(r'^[0-9]{8}[A-Z]$');
  static final RegExp _niePattern = RegExp(r'^[XYZ][0-9]{7}[A-Z]$');
  static final RegExp _supportPattern = RegExp(r'^[A-Z0-9]{9}$');
  static final RegExp _passportPattern = RegExp(r'^[A-Z0-9]{3,20}$');
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9]{6,15}$');
  static final RegExp _countryPattern = RegExp(r'^[A-Z]{3}$');

  /// Quita espacios, puntos y guiones y pasa a mayúsculas
  static String normalizeDocument(String value) =>
      value.replaceAll(_separators, '').toUpperCase();

  static String normalizePhone(String value) =>
      value.replaceAll(_phoneSeparators, '');

  /// DNI: 8 dígitos + letra de control
  static bool isValidDni(String value) {
    final v = normalizeDocument(value);
    if (!_dniPattern.hasMatch(v)) return false;
    return _controlLetter(int.parse(v.substring(0, 8))) == v[8];
  }

  /// NIE (y TIE, que es su soporte): X/Y/Z + 7 dígitos + letra de control
  static bool isValidNie(String value) {
    final v = normalizeDocument(value);
    if (!_niePattern.hasMatch(v)) return false;
    final prefix = 'XYZ'.indexOf(v[0]);
    final digits = int.parse('$prefix${v.substring(1, 8)}');
    return _controlLetter(digits) == v[8];
  }

  static String _controlLetter(int digits) => _dniLetters[digits % 23];

  /// Número de soporte del DNI (IDESP) o del NIE/TIE (IXESP).
  /// Solo se comprueba la forma: 9 caracteres alfanuméricos.
  static bool isValidSupportNumber(String value) =>
      _supportPattern.hasMatch(normalizeDocument(value));

  /// Pasaporte u otro documento: sin formato fijo (cada país tiene el suyo)
  static bool isValidForeignDocument(String value) =>
      _passportPattern.hasMatch(normalizeDocument(value));

  static bool isValidEmail(String value) => _emailPattern.hasMatch(value.trim());

  static bool isValidPhone(String value) =>
      _phonePattern.hasMatch(normalizePhone(value));

  static bool isValidCountryCode(String value) => _countryPattern.hasMatch(value);

  /// Edad cumplida en una fecha. Se usa la fecha de entrada de la reserva,
  /// nunca un campo de edad guardado.
  static int? ageOn(DateTime? birthDate, DateTime on) {
    if (birthDate == null) return null;
    var age = on.year - birthDate.year;
    final hadBirthday = on.month > birthDate.month ||
        (on.month == birthDate.month && on.day >= birthDate.day);
    if (!hadBirthday) age--;
    return age;
  }
}
