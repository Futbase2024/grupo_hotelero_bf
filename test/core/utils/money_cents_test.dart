import 'package:bf_stay/core/utils/money_cents.dart';
import 'package:bf_stay/core/utils/whatsapp_phone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseCents', () {
    test('acepta enteros y decimales con coma o punto', () {
      expect(parseCents('150'), 15000);
      expect(parseCents('150,5'), 15050);
      expect(parseCents('150,50'), 15050);
      expect(parseCents('150.50'), 15050);
      expect(parseCents(' 150 € '), 15000);
    });

    test('acepta separador de miles cuando hay decimales', () {
      expect(parseCents('1.250,00'), 125000);
      expect(parseCents('1,250.00'), 125000);
    });

    test('no pierde céntimos por redondeo binario', () {
      expect(parseCents('0,29'), 29);
      expect(parseCents('19,99'), 1999);
    });

    test('rechaza importes no válidos', () {
      expect(parseCents(''), isNull);
      expect(parseCents('abc'), isNull);
      expect(parseCents('10,999'), isNull);
      expect(parseCents('-5'), isNull);
    });
  });

  group('formato', () {
    test('formatCents usa euros con coma decimal', () {
      expect(formatCents(15000).replaceAll('\u00A0', ' '), '150,00 €');
    });

    test('centsToInput se puede volver a leer con parseCents', () {
      for (final cents in [1, 99, 15000, 125050]) {
        expect(parseCents(centsToInput(cents)), cents);
      }
    });
  });

  group('normalizePhoneForWhatsApp', () {
    test('respeta el prefijo internacional', () {
      expect(normalizePhoneForWhatsApp('+33 6 31 73 57 38'), '33631735738');
      expect(normalizePhoneForWhatsApp('0044 7700 900123'), '447700900123');
    });

    test('añade 34 a los números españoles de 9 dígitos', () {
      expect(normalizePhoneForWhatsApp('656 61 80 65'), '34656618065');
    });
  });
}
