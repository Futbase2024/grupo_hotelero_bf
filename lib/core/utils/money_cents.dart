import 'package:intl/intl.dart';

/// Importes guardados en céntimos (enteros) para no arrastrar decimales en BD.

final _currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '€');
final _inputFormat = NumberFormat('0.00', 'es_ES');

/// 15000 -> "150,00 €"
String formatCents(int cents) => _currencyFormat.format(cents / 100);

/// 15000 -> "150,00" (para rellenar un campo de texto)
String centsToInput(int cents) => _inputFormat.format(cents / 100);

/// Convierte lo que escribe el admin a céntimos: "150", "150,5", "150.50",
/// "1.250,00". Retorna `null` si no es un importe válido.
int? parseCents(String input) {
  var text = input.trim().replaceAll('€', '').replaceAll(' ', '');
  if (text.isEmpty) return null;

  // Con coma y punto, el último separador es el decimal ("1.250,00")
  final lastComma = text.lastIndexOf(',');
  final lastDot = text.lastIndexOf('.');
  if (lastComma >= 0 && lastDot >= 0) {
    final decimalSep = lastComma > lastDot ? ',' : '.';
    final thousandsSep = decimalSep == ',' ? '.' : ',';
    text = text.replaceAll(thousandsSep, '').replaceAll(decimalSep, '.');
  } else {
    text = text.replaceAll(',', '.');
  }

  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) return null;
  return (double.parse(text) * 100).round();
}
