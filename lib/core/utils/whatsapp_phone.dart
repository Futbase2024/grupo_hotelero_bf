/// Normaliza un teléfono al formato que exige WhatsApp: prefijo de país
/// seguido del número, sin '+', espacios ni separadores.
///
/// Respeta el prefijo internacional cuando el huésped ya lo ha indicado
/// (`+33 6 31 73 57 38` o `0033...`) y solo asume España (34) para números
/// nacionales de 9 dígitos escritos sin prefijo.
String normalizePhoneForWhatsApp(String phone) {
  final trimmed = phone.trim();
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');

  // Prefijo internacional explícito: +33 6 31 73 57 38 -> 33631735738
  if (trimmed.startsWith('+')) return digits;

  // Formato con salida internacional: 0034... / 0033... -> se quita el 00
  if (digits.startsWith('00')) return digits.substring(2);

  // Número nacional español sin prefijo: 656618065 -> 34656618065
  if (digits.length == 9) return '34$digits';

  // Cualquier otro caso ya incluye su prefijo de país
  return digits;
}
