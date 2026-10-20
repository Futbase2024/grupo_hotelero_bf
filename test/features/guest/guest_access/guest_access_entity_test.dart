import 'package:bf_stay/features/guest/alojamientos/domain/entities/unit_entity.dart';
import 'package:bf_stay/features/guest/guest_access/domain/entities/guest_access_entity.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _unitJson({
  String id = 'unit-1',
  String name = 'HAB 1',
  bool withSecrets = true,
}) {
  return {
    'unit_id': id,
    'name': name,
    'unit_type': 'hotel_room',
    'wifi_network': 'BF_WIFI',
    'wifi_password': withSecrets ? 'clave-wifi' : null,
    'box_code': withSecrets ? '1234' : null,
    'box_location_text': withSecrets ? 'Junto al portal' : null,
    'locker_number': withSecrets ? '7' : null,
    'access_instructions': withSecrets ? 'Sube a la 2ª planta' : null,
    'welcome_instructions': withSecrets ? 'Bienvenido' : null,
  };
}

Map<String, dynamic> _accessJson({
  bool canView = true,
  String reason = 'ok',
  String? earlyCheckin,
  String? serverTime = '2026-10-20T15:00:00.000+00:00',
  List<Map<String, dynamic>>? units,
}) {
  return {
    'booking_id': 'booking-1',
    'guest_first_name': 'Ana',
    'can_view': canView,
    'reason': reason,
    'checkin_date': '2026-10-20',
    'checkout_date': '2026-10-22',
    'early_checkin_available_at': earlyCheckin,
    'timezone': 'Europe/Madrid',
    'server_time': serverTime,
    'keybox_code': canView ? '9876' : null,
    'main_door_keycode': canView ? '5555' : null,
    'units': units ?? [_unitJson(withSecrets: canView)],
  };
}

void main() {
  group('GuestAccessReason.fromValue', () {
    test('traduce los valores del servidor', () {
      expect(GuestAccessReason.fromValue('ok'), GuestAccessReason.ok);
      expect(
        GuestAccessReason.fromValue('checkin_not_validated'),
        GuestAccessReason.checkinNotValidated,
      );
      expect(
        GuestAccessReason.fromValue('before_checkin'),
        GuestAccessReason.beforeCheckin,
      );
      expect(
        GuestAccessReason.fromValue('outside_window'),
        GuestAccessReason.outsideWindow,
      );
    });

    test('un valor desconocido o nulo no rompe la app', () {
      expect(GuestAccessReason.fromValue('nuevo'), GuestAccessReason.unknown);
      expect(GuestAccessReason.fromValue(null), GuestAccessReason.unknown);
    });
  });

  group('GuestAccessEntity.fromJson', () {
    test('parsea una reserva con los códigos visibles', () {
      final access = GuestAccessEntity.fromJson(_accessJson());

      expect(access.bookingId, 'booking-1');
      expect(access.guestFirstName, 'Ana');
      expect(access.mainUnit?.unitType, UnitType.hotelRoom);
      expect(access.canView, isTrue);
      expect(access.reason, GuestAccessReason.ok);
      expect(access.checkInDate, DateTime(2026, 10, 20));
      expect(access.checkOutDate, DateTime(2026, 10, 22));
      expect(access.serverTime, DateTime.utc(2026, 10, 20, 15));
      expect(access.keyboxCode, '9876');
      expect(access.mainDoorKeycode, '5555');
      expect(access.mainUnit?.boxCode, '1234');
      expect(access.mainUnit?.wifiPassword, 'clave-wifi');
      expect(access.mainUnit?.lockerNumber, '7');
      expect(access.mainUnit?.welcomeInstructions, 'Bienvenido');
      expect(access.hasMultipleUnits, isFalse);
    });

    test('sin validar: secretos a null pero conserva la red WiFi', () {
      final access = GuestAccessEntity.fromJson(
        _accessJson(canView: false, reason: 'checkin_not_validated'),
      );

      expect(access.canView, isFalse);
      expect(access.reason, GuestAccessReason.checkinNotValidated);
      expect(access.keyboxCode, isNull);
      expect(access.mainDoorKeycode, isNull);
      expect(access.mainUnit?.boxCode, isNull);
      expect(access.mainUnit?.wifiPassword, isNull);
      expect(access.mainUnit?.accessInstructions, isNull);
      expect(access.mainUnit?.wifiNetwork, 'BF_WIFI');
    });

    test('reserva multiunidad conserva el orden del servidor', () {
      final access = GuestAccessEntity.fromJson(
        _accessJson(units: [
          _unitJson(id: 'unit-3', name: 'HAB 3'),
          _unitJson(id: 'unit-4', name: 'HAB 4'),
        ]),
      );

      expect(access.hasMultipleUnits, isTrue);
      expect(access.units.map((u) => u.name), ['HAB 3', 'HAB 4']);
      expect(access.mainUnit?.unitId, 'unit-3');
    });

    test('sin unidades ni hora del servidor no falla', () {
      final before = DateTime.now().toUtc();
      final access = GuestAccessEntity.fromJson(
        _accessJson(units: const [], serverTime: null),
      );

      expect(access.units, isEmpty);
      expect(access.mainUnit, isNull);
      expect(access.serverTime.isBefore(before), isFalse);
    });
  });

  group('GuestAccessEntity.areKeysAvailable', () {
    test('a partir de las 14:00 del día de entrada', () {
      final access = GuestAccessEntity.fromJson(_accessJson());

      expect(access.keysAvailableAt, DateTime(2026, 10, 20, 14));
      expect(access.areKeysAvailable(now: DateTime(2026, 10, 20, 13, 59)), isFalse);
      expect(access.areKeysAvailable(now: DateTime(2026, 10, 20, 14)), isTrue);
    });

    test('el early check-in del mismo día adelanta la hora', () {
      final access = GuestAccessEntity.fromJson(
        _accessJson(earlyCheckin: '2026-10-20T10:30:00'),
      );

      expect(access.keysAvailableAt, DateTime(2026, 10, 20, 10, 30));
      expect(access.areKeysAvailable(now: DateTime(2026, 10, 20, 11)), isTrue);
    });

    test('nunca disponibles si el servidor no entrega los códigos', () {
      final access = GuestAccessEntity.fromJson(
        _accessJson(canView: false, reason: 'checkin_not_validated'),
      );

      expect(access.areKeysAvailable(now: DateTime(2026, 10, 21, 12)), isFalse);
    });

    test('por defecto usa la hora del servidor', () {
      final access = GuestAccessEntity.fromJson(
        _accessJson(serverTime: '2026-10-19T20:00:00'),
      );

      expect(access.areKeysAvailable(), isFalse);
    });
  });
}
