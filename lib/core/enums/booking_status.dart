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

  /// Etiqueta legible para mostrar en UI
  String get label {
    return switch (this) {
      BookingStatus.created => 'Creada',
      BookingStatus.confirmed => 'Confirmada',
      BookingStatus.active => 'Activa',
      BookingStatus.inHouse => 'En casa',
      BookingStatus.checkedIn => 'Activa', // Legacy - mostrar como Activa
      BookingStatus.checkedOut => 'Finalizada',
      BookingStatus.closed => 'Cerrada',
      BookingStatus.cancelled => 'Cancelada',
    };
  }

  /// Descripción del estado
  String get description {
    return switch (this) {
      BookingStatus.created => 'Reserva creada, pendiente de confirmación',
      BookingStatus.confirmed => 'Reserva confirmada, pendiente de check-in',
      BookingStatus.active => 'Check-in validado, panel completo accesible',
      BookingStatus.inHouse => 'Huésped físicamente en el alojamiento',
      BookingStatus.checkedIn => 'Check-in validado (legacy)', // Legacy
      BookingStatus.checkedOut => 'Check-out realizado, huésped ha salido',
      BookingStatus.closed => 'Reserva finalizada y cerrada',
      BookingStatus.cancelled => 'Reserva cancelada',
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
