/// Estados del ciclo de vida de una reserva
enum BookingStatus {
  /// Admin creó la reserva, pendiente de activación
  created,

  /// Check-in validado, estancia habilitada - panel completo accesible
  active,

  /// Reserva confirmada (legacy - mantener compatibilidad)
  confirmed,

  /// Check-in realizado (legacy - mantener compatibilidad)
  checkedIn,

  /// Check-out realizado (legacy - mantener compatibilidad)
  checkedOut,

  /// Admin cerró la reserva tras validar check-out
  closed,

  /// Reserva cancelada
  cancelled;

  /// Convierte desde string de base de datos
  static BookingStatus fromString(String value) {
    return switch (value.toLowerCase()) {
      'created' => BookingStatus.created,
      'active' => BookingStatus.active,
      'confirmed' => BookingStatus.confirmed,
      'checked_in' => BookingStatus.checkedIn,
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
      BookingStatus.active => 'active',
      BookingStatus.confirmed => 'confirmed',
      BookingStatus.checkedIn => 'checked_in',
      BookingStatus.checkedOut => 'checked_out',
      BookingStatus.closed => 'closed',
      BookingStatus.cancelled => 'cancelled',
    };
  }

  /// Etiqueta legible para mostrar en UI
  String get label {
    return switch (this) {
      BookingStatus.created => 'Creada',
      BookingStatus.active => 'Activa',
      BookingStatus.confirmed => 'Confirmada',
      BookingStatus.checkedIn => 'Check-in realizado',
      BookingStatus.checkedOut => 'Check-out realizado',
      BookingStatus.closed => 'Cerrada',
      BookingStatus.cancelled => 'Cancelada',
    };
  }

  /// Descripción del estado
  String get description {
    return switch (this) {
      BookingStatus.created => 'Reserva creada, pendiente de activación',
      BookingStatus.active => 'Estancia en curso, panel completo accesible',
      BookingStatus.confirmed => 'Reserva confirmada',
      BookingStatus.checkedIn => 'El huésped ha realizado el check-in',
      BookingStatus.checkedOut => 'El huésped ha realizado el check-out',
      BookingStatus.closed => 'Reserva finalizada y cerrada',
      BookingStatus.cancelled => 'Reserva cancelada',
    };
  }

  /// Si la reserva está activa (huésped puede usar el panel completo)
  bool get isPanelAccessible => this == BookingStatus.active;

  /// Si la reserva está cerrada (solo lectura)
  bool get isReadOnly => this == BookingStatus.closed;

  /// Si la reserva fue cancelada
  bool get isCancelled => this == BookingStatus.cancelled;

  /// Si la reserva está en estado inicial
  bool get isPending => this == BookingStatus.created;
}
