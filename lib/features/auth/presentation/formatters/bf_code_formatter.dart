import 'package:flutter/services.dart';

/// TextInputFormatter para formatear códigos de reserva BF-XXXX-XXXX
///
/// Funcionalidades:
/// - Convierte automáticamente a mayúsculas
/// - Añade guiones automáticamente en posiciones 2 y 7
/// - Limita a 12 caracteres visibles (BF-XXXX-XXXX)
/// - Solo permite letras A-Z y números 0-9
///
/// Ejemplo de uso:
/// ```dart
/// TextFormField(
///   inputFormatters: [BfCodeFormatter()],
///   ...
/// )
/// ```
class BfCodeFormatter extends TextInputFormatter {
  /// Patrón del código: BF-XXXX-XXXX
  static const String _prefix = 'BF';

  /// Longitud total del código formateado
  static const int _totalLength = 12;

  /// Posiciones donde insertar guiones (después del carácter en esa posición)
  static const Set<int> _hyphenPositions = {2, 7};

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Obtener el texto sin formato (solo alfanuméricos)
    final rawText = newValue.text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');

    // Convertir a mayúsculas
    final upperText = rawText.toUpperCase();

    // Construir el texto formateado
    final formatted = _formatCode(upperText);

    // Calcular la nueva posición del cursor
    final selectionIndex = _calculateSelectionIndex(
      formatted,
      newValue.selection.baseOffset,
      rawText.length,
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }

  /// Formatea el texto crudo añadiendo guiones en las posiciones correctas
  String _formatCode(String rawText) {
    final buffer = StringBuffer();

    // Añadir prefijo BF si hay al menos 1 carácter
    if (rawText.isNotEmpty) {
      // Asegurar que empieza con BF
      String processedText = rawText;

      // Si el usuario empieza escribiendo sin BF, lo añadimos
      if (!processedText.startsWith(_prefix)) {
        if (processedText.length >= 2) {
          processedText = '$_prefix${processedText.substring(2)}';
        } else {
          // Si solo hay 1 carácter, mantenerlo (el usuario está escribiendo)
          processedText = rawText;
        }
      }

      // Procesar carácter por carácter
      for (int i = 0; i < processedText.length && buffer.length < _totalLength; i++) {
        final char = processedText[i];

        // Añadir guion antes de ciertas posiciones
        if (_hyphenPositions.contains(buffer.length)) {
          buffer.write('-');
        }

        // Solo añadir caracteres alfanuméricos
        if (RegExp(r'[A-Za-z0-9]').hasMatch(char)) {
          buffer.write(char.toUpperCase());
        }

        // Parar si alcanzamos la longitud máxima
        if (buffer.length >= _totalLength) break;
      }
    }

    return buffer.toString();
  }

  /// Calcula la posición del cursor después del formateo
  int _calculateSelectionIndex(String formatted, int originalPosition, int rawLength) {
    // Si el cursor estaba al final, mantenerlo al final
    if (originalPosition >= rawLength) {
      return formatted.length;
    }

    // Calcular la posición considerando los guiones añadidos
    int hyphensBefore = 0;
    for (final pos in _hyphenPositions) {
      if (pos <= originalPosition + hyphensBefore) {
        hyphensBefore++;
      }
    }

    return (originalPosition + hyphensBefore).clamp(0, formatted.length);
  }

  /// Valida si un código tiene el formato correcto
  static bool isValidFormat(String code) {
    return RegExp(r'^BF-[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(code.toUpperCase());
  }

  /// Valida si un código está completo (12 caracteres)
  static bool isComplete(String code) {
    return code.length == _totalLength;
  }
}
