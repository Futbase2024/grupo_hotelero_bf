// Validadores del registro de viajeros. Deben dar el mismo resultado que
// las funciones SQL equivalentes (is_valid_spanish_id, traveller_age_on…).

import 'package:bf_stay/features/guest/traveller_register/domain/validators/traveller_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DNI', () {
    test('acepta la letra de control correcta, con o sin separadores', () {
      expect(TravellerValidators.isValidDni('12345678Z'), isTrue);
      expect(TravellerValidators.isValidDni('12.345.678-z'), isTrue);
      expect(TravellerValidators.isValidDni(' 12345678 z '), isTrue);
    });

    test('rechaza letra incorrecta o formato erróneo', () {
      expect(TravellerValidators.isValidDni('12345678A'), isFalse);
      expect(TravellerValidators.isValidDni('1234567Z'), isFalse);
      expect(TravellerValidators.isValidDni('X1234567L'), isFalse);
      expect(TravellerValidators.isValidDni(''), isFalse);
    });
  });

  group('NIE / TIE', () {
    test('acepta X, Y y Z con su letra de control', () {
      expect(TravellerValidators.isValidNie('X1234567L'), isTrue);
      expect(TravellerValidators.isValidNie('y-1234567-x'), isTrue);
    });

    test('rechaza letra incorrecta o prefijo no válido', () {
      expect(TravellerValidators.isValidNie('X1234567A'), isFalse);
      expect(TravellerValidators.isValidNie('W1234567L'), isFalse);
      expect(TravellerValidators.isValidNie('12345678Z'), isFalse);
    });
  });

  group('soporte y documentos extranjeros', () {
    test('soporte: 9 caracteres alfanuméricos', () {
      expect(TravellerValidators.isValidSupportNumber('abc123456'), isTrue);
      expect(TravellerValidators.isValidSupportNumber('E12345678'), isTrue);
      expect(TravellerValidators.isValidSupportNumber('ABC12345'), isFalse);
      expect(TravellerValidators.isValidSupportNumber('ABC1234567'), isFalse);
    });

    test('pasaporte: sin formato fijo, de 3 a 20 caracteres', () {
      expect(TravellerValidators.isValidForeignDocument('X12'), isTrue);
      expect(TravellerValidators.isValidForeignDocument('pa 123 456'), isTrue);
      expect(TravellerValidators.isValidForeignDocument('AB'), isFalse);
      expect(TravellerValidators.isValidForeignDocument('ÑÑÑ123'), isFalse);
    });
  });

  group('contacto', () {
    test('email', () {
      expect(TravellerValidators.isValidEmail('ana@example.com'), isTrue);
      expect(TravellerValidators.isValidEmail('ana@example'), isFalse);
      expect(TravellerValidators.isValidEmail('ana example.com'), isFalse);
    });

    test('teléfono con prefijo y separadores', () {
      expect(TravellerValidators.isValidPhone('+34 600 000 000'), isTrue);
      expect(TravellerValidators.isValidPhone('(956) 12-34-56'), isTrue);
      expect(TravellerValidators.isValidPhone('12345'), isFalse);
      expect(TravellerValidators.isValidPhone('600abc000'), isFalse);
    });

    test('país ISO alfa-3', () {
      expect(TravellerValidators.isValidCountryCode('ESP'), isTrue);
      expect(TravellerValidators.isValidCountryCode('ES'), isFalse);
      expect(TravellerValidators.isValidCountryCode('esp'), isFalse);
    });
  });

  group('edad el día de entrada', () {
    final checkin = DateTime(2027, 7, 1);

    test('cuenta si ya ha cumplido años ese día', () {
      expect(TravellerValidators.ageOn(DateTime(2013, 7, 1), checkin), 14);
      expect(TravellerValidators.ageOn(DateTime(2013, 7, 2), checkin), 13);
      expect(TravellerValidators.ageOn(DateTime(2012, 3, 1), checkin), 15);
      expect(TravellerValidators.ageOn(DateTime(1985, 5, 10), checkin), 42);
    });

    test('sin fecha de nacimiento no hay edad', () {
      expect(TravellerValidators.ageOn(null, checkin), isNull);
    });
  });
}
