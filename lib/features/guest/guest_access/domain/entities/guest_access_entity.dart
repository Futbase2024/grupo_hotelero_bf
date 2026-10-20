import 'package:equatable/equatable.dart';

import '../../../../../core/utils/keys_availability.dart';
import '../../../alojamientos/domain/entities/unit_entity.dart';

/// Motivo por el que el servidor entrega (o no) los códigos de acceso.
enum GuestAccessReason {
  /// Check-in validado y dentro de la estancia: los códigos vienen rellenos.
  ok,

  /// El check-in aún no está validado por el staff.
  checkinNotValidated,

  /// Check-in validado, pero todavía no ha llegado el día de entrada.
  beforeCheckin,

  /// Reserva cerrada, cancelada o fuera del periodo de acceso.
  outsideWindow,

  /// Valor desconocido (versión de servidor más nueva que la app).
  unknown;

  static GuestAccessReason fromValue(String? value) {
    return switch (value) {
      'ok' => GuestAccessReason.ok,
      'checkin_not_validated' => GuestAccessReason.checkinNotValidated,
      'before_checkin' => GuestAccessReason.beforeCheckin,
      'outside_window' => GuestAccessReason.outsideWindow,
      _ => GuestAccessReason.unknown,
    };
  }
}

/// Datos de acceso de una unidad de la reserva.
///
/// Los campos secretos llegan a `null` si el servidor no permite verlos.
class GuestAccessUnit extends Equatable {
  const GuestAccessUnit({
    required this.unitId,
    required this.name,
    this.unitType = UnitType.apartment,
    this.wifiNetwork,
    this.wifiPassword,
    this.boxCode,
    this.boxLocationText,
    this.lockerNumber,
    this.accessInstructions,
    this.welcomeInstructions,
  });

  factory GuestAccessUnit.fromJson(Map<String, dynamic> json) {
    return GuestAccessUnit(
      unitId: json['unit_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      unitType: UnitTypeExtension.fromString(
        json['unit_type'] as String? ?? 'apartment',
      ),
      wifiNetwork: json['wifi_network'] as String?,
      wifiPassword: json['wifi_password'] as String?,
      boxCode: json['box_code'] as String?,
      boxLocationText: json['box_location_text'] as String?,
      lockerNumber: json['locker_number'] as String?,
      accessInstructions: json['access_instructions'] as String?,
      welcomeInstructions: json['welcome_instructions'] as String?,
    );
  }

  final String unitId;
  final String name;
  final UnitType unitType;

  /// Nombre de la red WiFi (no se considera secreto).
  final String? wifiNetwork;
  final String? wifiPassword;
  final String? boxCode;
  final String? boxLocationText;
  final String? lockerNumber;
  final String? accessInstructions;
  final String? welcomeInstructions;

  @override
  List<Object?> get props => [
        unitId,
        name,
        unitType,
        wifiNetwork,
        wifiPassword,
        boxCode,
        boxLocationText,
        lockerNumber,
        accessInstructions,
        welcomeInstructions,
      ];
}

/// Códigos de acceso de una reserva, tal como los entrega la RPC
/// `get_guest_access`.
///
/// El servidor solo rellena los secretos con el check-in validado y dentro de
/// la estancia ([canView]); la hora a la que se muestran (14:00 o early
/// check-in) la sigue decidiendo la app con [areKeysAvailable].
class GuestAccessEntity extends Equatable {
  const GuestAccessEntity({
    required this.bookingId,
    this.guestFirstName,
    required this.canView,
    required this.reason,
    required this.checkInDate,
    required this.checkOutDate,
    required this.serverTime,
    this.earlyCheckinAvailableAt,
    this.timezone = 'Europe/Madrid',
    this.keyboxCode,
    this.mainDoorKeycode,
    this.units = const [],
  });

  factory GuestAccessEntity.fromJson(Map<String, dynamic> json) {
    final earlyCheckinStr = json['early_checkin_available_at'] as String?;
    final serverTimeStr = json['server_time'] as String?;
    final unitsJson = json['units'] as List<dynamic>? ?? const [];

    return GuestAccessEntity(
      bookingId: json['booking_id'] as String? ?? '',
      guestFirstName: json['guest_first_name'] as String?,
      canView: json['can_view'] as bool? ?? false,
      reason: GuestAccessReason.fromValue(json['reason'] as String?),
      checkInDate: DateTime.parse(json['checkin_date'] as String),
      checkOutDate: DateTime.parse(json['checkout_date'] as String),
      earlyCheckinAvailableAt:
          earlyCheckinStr != null ? DateTime.parse(earlyCheckinStr) : null,
      timezone: json['timezone'] as String? ?? 'Europe/Madrid',
      serverTime: serverTimeStr != null
          ? DateTime.parse(serverTimeStr)
          : DateTime.now().toUtc(),
      keyboxCode: json['keybox_code'] as String?,
      mainDoorKeycode: json['main_door_keycode'] as String?,
      units: unitsJson
          .whereType<Map<String, dynamic>>()
          .map(GuestAccessUnit.fromJson)
          .toList(),
    );
  }

  final String bookingId;

  /// Nombre de pila del huésped principal (no es secreto).
  final String? guestFirstName;

  /// Si el servidor ha entregado los secretos.
  final bool canView;
  final GuestAccessReason reason;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final DateTime? earlyCheckinAvailableAt;
  final String timezone;

  /// Hora del servidor en el momento de la consulta.
  final DateTime serverTime;

  /// Código de acceso de la reserva (único por reserva).
  final String? keyboxCode;

  /// Código del portal del edificio.
  final String? mainDoorKeycode;

  /// Unidades de la reserva; la principal va primero.
  final List<GuestAccessUnit> units;

  /// Unidad principal de la reserva, si la hay.
  GuestAccessUnit? get mainUnit => units.isEmpty ? null : units.first;

  bool get hasMultipleUnits => units.length > 1;

  /// Momento a partir del cual la app muestra los códigos.
  DateTime get keysAvailableAt => KeysAvailability.availableAt(
        checkInDate: checkInDate,
        earlyCheckinAvailableAt: earlyCheckinAvailableAt,
      );

  /// Si en [now] (por defecto, la hora del servidor) ya se pueden mostrar los
  /// códigos: hace falta que el servidor los entregue y que haya llegado la
  /// hora.
  bool areKeysAvailable({DateTime? now}) {
    return canView &&
        KeysAvailability.isAvailable(
          checkInDate: checkInDate,
          earlyCheckinAvailableAt: earlyCheckinAvailableAt,
          now: now ?? serverTime,
        );
  }

  @override
  List<Object?> get props => [
        bookingId,
        guestFirstName,
        canView,
        reason,
        checkInDate,
        checkOutDate,
        earlyCheckinAvailableAt,
        timezone,
        serverTime,
        keyboxCode,
        mainDoorKeycode,
        units,
      ];
}
