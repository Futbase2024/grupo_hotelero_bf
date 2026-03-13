import 'package:flutter/services.dart';

/// TextInputFormatter para formatear códigos de reserva
///
/// Formato: XX-XXXX-XXXX (12 caracteres con guiones)
/// - Grupo 1: 2 caracteres alfanuméricos
/// - Grupo 2: 4 caracteres alfanuméricos
/// - Grupo 3: 4 caracteres alfanuméricos
///
/// Funcionalidades:
/// - Autocompleta guiones mientras escribe
/// - Convierte automáticamente a mayúsculas
/// - Detecta pegado de código completo y lo formatea
/// - Solo permite letras A-Z y números 0-9
/// - NO obliga a escribir prefijo "BF"
class BfCodeFormatter extends TextInputFormatter {
  /// Longitud total del código formateado: XX-XXXX-XXXX
  static const int totalLength = 12;

  /// Longitud del código sin guiones: 10 caracteres
  static const int rawLength = 10;

  /// Valor inicial del campo (vacío)
  static String get initialValue => '';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Si el campo está vacío, dejarlo vacío
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Obtener solo caracteres alfanuméricos del nuevo texto
    final rawChars = newValue.text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');

    // Si no hay caracteres alfanuméricos, dejar vacío
    if (rawChars.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Convertir a mayúsculas y limitar a 10 caracteres
    final upperChars = rawChars.toUpperCase();
    final limitedChars = upperChars.length > rawLength ? upperChars.substring(0, rawLength) : upperChars;

    // Construir el código formateado: XX-XXXX-XXXX
    final formatted = _buildFormattedCode(limitedChars);

    // Calcular la posición del cursor
    final cursorPosition = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }

  /// Construye el código formateado: XX-XXXX-XXXX
  String _buildFormattedCode(String chars) {
    if (chars.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();

    // Grupo 1: primeros 2 caracteres
    for (int i = 0; i < chars.length && i < 2; i++) {
      buffer.write(chars[i]);
    }

    // Si hay más de 2 caracteres, añadir guion y grupo 2
    if (chars.length > 2) {
      buffer.write('-');
      for (int i = 2; i < chars.length && i < 6; i++) {
        buffer.write(chars[i]);
      }
    }

    // Si hay más de 6 caracteres, añadir guion y grupo 3
    if (chars.length > 6) {
      buffer.write('-');
      for (int i = 6; i < chars.length; i++) {
        buffer.write(chars[i]);
      }
    }

    return buffer.toString();
  }

  /// Valida si un código tiene el formato correcto y está completo
  /// Formato esperado: XX-XXXX-XXXX (12 caracteres)
  static bool isValid(String code) {
    return RegExp(r'^[A-Z0-9]{2}-[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(code.toUpperCase());
  }

  /// Valida si un código está completo (12 caracteres)
  static bool isComplete(String code) {
    return code.length == totalLength;
  }

  /// Extrae el código limpio sin formato (solo alfanuméricos)
  static String extractCleanCode(String formattedCode) {
    return formattedCode.replaceAll('-', '').toUpperCase();
  }

  /// Valida el formato parcialmente (mientras escribe)
  /// Retorna: null si válido, mensaje de error si inválido
  static String? validatePartial(String code) {
    if (code.isEmpty) {
      return null; // Vacío es válido (placeholder visible)
    }

    // Verificar que solo tenga caracteres válidos
    final cleanCode = code.replaceAll('-', '');
    if (!RegExp(r'^[A-Z0-9]*$').hasMatch(cleanCode.toUpperCase())) {
      return 'Solo se permiten letras y números';
    }

    return null;
  }
}
