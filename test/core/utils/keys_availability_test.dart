// Tests de la regla de disponibilidad de códigos (14:00 o early check-in del
// admin el mismo día de llegada).

import 'package:bf_stay/core/utils/keys_availability.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final checkInDate = DateTime(2026, 10, 4);

  group('KeysAvailability.availableAt', () {
    test('sin early check-in: las 14:00 del día de llegada', () {
      expect(
        KeysAvailability.availableAt(checkInDate: checkInDate),
        DateTime(2026, 10, 4, 14),
      );
    });

    test('early check-in del mismo día: la hora marcada por el admin', () {
      final early = DateTime(2026, 10, 4, 10, 30);

      expect(
        KeysAvailability.availableAt(
          checkInDate: checkInDate,
          earlyCheckinAvailableAt: early,
        ),
        early,
      );
    });

    test('early check-in de otro día: se ignora y vale las 14:00', () {
      expect(
        KeysAvailability.availableAt(
          checkInDate: checkInDate,
          earlyCheckinAvailableAt: DateTime(2026, 10, 3, 18),
        ),
        DateTime(2026, 10, 4, 14),
      );
    });
  });

  group('KeysAvailability.isAvailable', () {
    test('días antes de la llegada: no disponible', () {
      expect(
        KeysAvailability.isAvailable(
          checkInDate: checkInDate,
          now: DateTime(2026, 10, 2, 20),
        ),
        isFalse,
      );
    });

    test('día de llegada antes de las 14:00: no disponible', () {
      expect(
        KeysAvailability.isAvailable(
          checkInDate: checkInDate,
          now: DateTime(2026, 10, 4, 13, 59),
        ),
        isFalse,
      );
    });

    test('a las 14:00 en punto: disponible', () {
      expect(
        KeysAvailability.isAvailable(
          checkInDate: checkInDate,
          now: DateTime(2026, 10, 4, 14),
        ),
        isTrue,
      );
    });

    test('early check-in del mismo día ya pasado: disponible antes de las 14:00', () {
      expect(
        KeysAvailability.isAvailable(
          checkInDate: checkInDate,
          earlyCheckinAvailableAt: DateTime(2026, 10, 4, 11),
          now: DateTime(2026, 10, 4, 11, 5),
        ),
        isTrue,
      );
    });

    test('early check-in del mismo día aún no alcanzado: no disponible', () {
      expect(
        KeysAvailability.isAvailable(
          checkInDate: checkInDate,
          earlyCheckinAvailableAt: DateTime(2026, 10, 4, 11),
          now: DateTime(2026, 10, 4, 10, 59),
        ),
        isFalse,
      );
    });

    test('early check-in marcado otro día no adelanta la disponibilidad', () {
      expect(
        KeysAvailability.isAvailable(
          checkInDate: checkInDate,
          earlyCheckinAvailableAt: DateTime(2026, 10, 3, 9),
          now: DateTime(2026, 10, 4, 9),
        ),
        isFalse,
      );
    });
  });
}
