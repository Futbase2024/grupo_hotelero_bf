import 'package:flutter/widgets.dart';
import 'package:bf_stay/l10n/app_localizations.dart';

/// Estados del ciclo de vida de una reserva
enum BookingStatus {
  /// Admin creó la reserva, pendiente de confirmación
  created,

  /// Reserva confirmada, pendiente de check-in
  confirmed,

  /// Check-in validado, panel completo accesible
  active,

  /// Huésped físicamente en el alojamiento (fecha de check-in alcanzada)
  inHouse,

  /// Check-out realizado, huésped ha abandonado el alojamiento
  checkedOut,

  /// Admin cerró la reserva tras validar todo
  closed,

  /// Reserva cancelada
  cancelled,

  /// Check-in realizado (legacy - mantener compatibilidad, usar active)
  @Deprecated('Use active instead')
  checkedIn;

  /// Convierte desde string de base de datos
  static BookingStatus fromString(String value) {
    return switch (value.toLowerCase()) {
      'created' => BookingStatus.created,
      'confirmed' => BookingStatus.confirmed,
      'active' => BookingStatus.active,
      'in_house' => BookingStatus.inHouse,
      'checked_in' => BookingStatus.active, // Mapear legacy a active
      'checked_out' => BookingStatus.checkedOut,
      'closed' => BookingStatus.closed,
      'cancelled' => BookingStatus.cancelled,
      _ => BookingStatus.created,
    };
  }

  /// Convierte a string para base de datos
  String toDbString() {
    return switch (this) {
      BookingStatus.created => 'created',
      BookingStatus.confirmed => 'confirmed',
      BookingStatus.active => 'active',
      BookingStatus.inHouse => 'in_house',
      BookingStatus.checkedIn => 'checked_in', // Legacy
      BookingStatus.checkedOut => 'checked_out',
      BookingStatus.closed => 'closed',
      BookingStatus.cancelled => 'cancelled',
    };
  }

  /// Si el huésped puede acceder al panel completo (check-in validado o en casa)
  bool get isPanelAccessible =>
      this == BookingStatus.active ||
      this == BookingStatus.inHouse ||
      this == BookingStatus.checkedIn; // Legacy

  /// Si el huésped está físicamente en el alojamiento
  bool get isInHouse => this == BookingStatus.inHouse;

  /// Si la reserva está cerrada (solo lectura)
  bool get isReadOnly => this == BookingStatus.closed;

  /// Si la reserva fue cancelada
  bool get isCancelled => this == BookingStatus.cancelled;

  /// Si la reserva está en estado inicial (pendiente de confirmación)
  bool get isPending => this == BookingStatus.created;

  /// Si la reserva está confirmada pero sin check-in
  bool get isConfirmed => this == BookingStatus.confirmed;
}

extension BookingStatusL10n on BookingStatus {
  /// Etiqueta legible para mostrar en UI
  String label(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      BookingStatus.created => s.enum_booking_status_created,
      BookingStatus.confirmed => s.enum_booking_status_confirmed,
      BookingStatus.active => s.enum_booking_status_active,
      BookingStatus.inHouse => s.enum_booking_status_in_house,
      BookingStatus.checkedIn => s.enum_booking_status_active,
      BookingStatus.checkedOut => s.enum_booking_status_checked_out,
      BookingStatus.closed => s.enum_booking_status_closed,
      BookingStatus.cancelled => s.enum_booking_status_cancelled,
    };
  }

  /// Descripción del estado
  String description(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      BookingStatus.created => s.enum_booking_status_created_desc,
      BookingStatus.confirmed => s.enum_booking_status_confirmed_desc,
      BookingStatus.active => s.enum_booking_status_active_desc,
      BookingStatus.inHouse => s.enum_booking_status_in_house_desc,
      BookingStatus.checkedIn => s.enum_booking_status_checked_in_legacy_desc,
      BookingStatus.checkedOut => s.enum_booking_status_checked_out_desc,
      BookingStatus.closed => s.enum_booking_status_closed_desc,
      BookingStatus.cancelled => s.enum_booking_status_cancelled_desc,
    };
  }
}
