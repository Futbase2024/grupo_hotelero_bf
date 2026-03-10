import 'package:flutter/services.dart';

/// TextInputFormatter para formatear códigos de reserva BF-XXXX-XXXX
///
/// Formato: BF-XXXX-XXXX (12 caracteres)
/// - Prefijo fijo: BF-
/// - Grupo 1: 4 caracteres alfanuméricos
/// - Grupo 2: 4 caracteres alfanuméricos
///
/// Funcionalidades:
/// - Prefijo BF- siempre presente
/// - Convierte automáticamente a mayúsculas
/// - Añade guiones automáticamente mientras escribe
/// - Detecta pegado de código completo y lo formatea
/// - Solo permite letras A-Z y números 0-9
class BfCodeFormatter extends TextInputFormatter {
  /// Prefijo fijo del código
  static const String prefix = 'BF-';

  /// Longitud total del código formateado: BF-XXXX-XXXX
  static const int totalLength = 12;

  /// Valor inicial del campo (solo el prefijo)
  static String get initialValue => prefix;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Si está borrando y queda menos que el prefijo, mantener prefijo
    if (newValue.text.length < oldValue.text.length) {
      if (newValue.text.length < prefix.length) {
        return TextEditingValue(
          text: prefix,
          selection: const TextSelection.collapsed(offset: prefix.length),
        );
      }
    }

    // Obtener solo caracteres alfanuméricos del nuevo texto
    final rawChars = newValue.text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');

    // Si no hay caracteres después de limpiar, mostrar solo prefijo
    if (rawChars.isEmpty) {
      return TextEditingValue(
        text: prefix,
        selection: const TextSelection.collapsed(offset: prefix.length),
      );
    }

    // Extraer solo los caracteres después del prefijo BF
    // (en caso de que hayan pegado "BFABC1234" o "BF-ABC-1234")
    String charsAfterPrefix = rawChars;
    if (charsAfterPrefix.toUpperCase().startsWith('BF')) {
      charsAfterPrefix = charsAfterPrefix.substring(2);
    }

    // Convertir a mayúsculas y limitar a 8 caracteres (4 + 4)
    final upperChars = charsAfterPrefix.toUpperCase();
    final limitedChars = upperChars.length > 8 ? upperChars.substring(0, 8) : upperChars;

    // Construir el código formateado: BF-XXXX-XXXX
    final formatted = _buildFormattedCode(limitedChars);

    // Calcular la posición del cursor
    final cursorPosition = _calculateCursorPosition(formatted, limitedChars.length);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }

  /// Construye el código formateado: BF-XXXX-XXXX
  String _buildFormattedCode(String chars) {
    if (chars.isEmpty) {
      return prefix;
    }

    final buffer = StringBuffer();
    buffer.write(prefix);

    // Añadir primeros 4 caracteres (grupo 1)
    for (int i = 0; i < chars.length && i < 4; i++) {
      buffer.write(chars[i]);
    }

    // Si hay más de 4 caracteres, añadir guion y el resto (grupo 2)
    if (chars.length > 4) {
      buffer.write('-');
      for (int i = 4; i < chars.length; i++) {
        buffer.write(chars[i]);
      }
    }

    return buffer.toString();
  }

  /// Calcula la posición del cursor después del formateo
  int _calculateCursorPosition(String formatted, int charCount) {
    // El cursor siempre al final del texto ingresado
    return formatted.length;
  }

  /// Valida si un código tiene el formato correcto y está completo
  /// Formato esperado: BF-XXXX-XXXX (12 caracteres)
  static bool isValid(String code) {
    return RegExp(r'^BF-[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(code.toUpperCase());
  }

  /// Valida si un código está completo (12 caracteres)
  static bool isComplete(String code) {
    return code.length == totalLength;
  }

  /// Extrae el código limpio sin formato (solo alfanuméricos, incluyendo BF)
  static String extractCleanCode(String formattedCode) {
    return formattedCode.replaceAll('-', '').toUpperCase();
  }
}
