/// Estados del proceso de check-out
enum CheckoutStatus {
  /// Sin iniciar - la estancia aún está en curso
  notStarted,

  /// Solicitado - el huésped ha solicitado el check-out
  requested,

  /// Validado por admin - check-out aprobado, reserva lista para cerrar
  validated,

  /// Rechazado - hay incidencias o datos faltantes
  rejected;

  /// Convierte desde string de base de datos
  static CheckoutStatus fromString(String value) {
    return switch (value.toLowerCase()) {
      'not_started' => CheckoutStatus.notStarted,
      'requested' => CheckoutStatus.requested,
      'validated' => CheckoutStatus.validated,
      'rejected' => CheckoutStatus.rejected,
      _ => CheckoutStatus.notStarted,
    };
  }

  /// Convierte a string para base de datos
  String toDbString() {
    return switch (this) {
      CheckoutStatus.notStarted => 'not_started',
      CheckoutStatus.requested => 'requested',
      CheckoutStatus.validated => 'validated',
      CheckoutStatus.rejected => 'rejected',
    };
  }

  /// Etiqueta legible para mostrar en UI
  String get label {
    return switch (this) {
      CheckoutStatus.notStarted => 'Sin iniciar',
      CheckoutStatus.requested => 'Solicitado',
      CheckoutStatus.validated => 'Validado',
      CheckoutStatus.rejected => 'Rechazado',
    };
  }

  /// Descripción del estado
  String get description {
    return switch (this) {
      CheckoutStatus.notStarted => 'La estancia aún está en curso',
      CheckoutStatus.requested => 'El huésped ha solicitado el check-out',
      CheckoutStatus.validated => 'Check-out validado, reserva lista para cerrar',
      CheckoutStatus.rejected => 'Hay incidencias que resolver',
    };
  }

  /// Si el huésped puede solicitar check-out
  bool get canRequest => this == CheckoutStatus.notStarted;

  /// Si el check-out está pendiente de acción del admin
  bool get needsAdminAction => this == CheckoutStatus.requested;

  /// Si el check-out ya fue validado
  bool get isValidated => this == CheckoutStatus.validated;

  /// Si el check-out fue rechazado y necesita resolución
  bool get needsResolution => this == CheckoutStatus.rejected;

  /// Si el check-out ya comenzó
  bool get hasStarted => this != CheckoutStatus.notStarted;
}
