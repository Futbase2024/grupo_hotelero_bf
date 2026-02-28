/// Estados del proceso de check-in
enum CheckinStatus {
  /// Sin iniciar - el huésped aún no ha accedido
  notStarted,

  /// En progreso - el huésped está rellenando datos/documentos
  inProgress,

  /// Enviado - pendiente de validación por admin
  submitted,

  /// Validado por admin - check-in aprobado
  validated,

  /// Rechazado - necesita corrección/subsanación
  rejected;

  /// Convierte desde string de base de datos
  static CheckinStatus fromString(String value) {
    return switch (value.toLowerCase()) {
      'not_started' => CheckinStatus.notStarted,
      'in_progress' => CheckinStatus.inProgress,
      'draft' => CheckinStatus.inProgress, // Compatibilidad con datos existentes
      'submitted' => CheckinStatus.submitted,
      'validated' => CheckinStatus.validated,
      'rejected' => CheckinStatus.rejected,
      _ => CheckinStatus.notStarted,
    };
  }

  /// Convierte a string para base de datos
  String toDbString() {
    return switch (this) {
      CheckinStatus.notStarted => 'not_started',
      CheckinStatus.inProgress => 'in_progress',
      CheckinStatus.submitted => 'submitted',
      CheckinStatus.validated => 'validated',
      CheckinStatus.rejected => 'rejected',
    };
  }

  /// Etiqueta legible para mostrar en UI
  String get label {
    return switch (this) {
      CheckinStatus.notStarted => 'Pendiente',
      CheckinStatus.inProgress => 'En progreso',
      CheckinStatus.submitted => 'Enviado',
      CheckinStatus.validated => 'Validado',
      CheckinStatus.rejected => 'Rechazado',
    };
  }

  /// Descripción del estado
  String get description {
    return switch (this) {
      CheckinStatus.notStarted => 'El huésped aún no ha iniciado el check-in',
      CheckinStatus.inProgress => 'El huésped está completando sus datos',
      CheckinStatus.submitted => 'Pendiente de revisión por el administrador',
      CheckinStatus.validated => 'Check-in validado, estancia autorizada',
      CheckinStatus.rejected => 'Requiere corrección por el huésped',
    };
  }

  /// Si el huésped puede editar el check-in
  bool get isEditable {
    return this == CheckinStatus.notStarted ||
        this == CheckinStatus.inProgress ||
        this == CheckinStatus.rejected;
  }

  /// Si el check-in está pendiente de acción del admin
  bool get needsAdminAction => this == CheckinStatus.submitted;

  /// Si el check-in ya fue validado
  bool get isValidated => this == CheckinStatus.validated;

  /// Si el check-in fue rechazado y necesita corrección
  bool get needsCorrection => this == CheckinStatus.rejected;

  /// Si el check-in ya comenzó (no está en not_started)
  bool get hasStarted => this != CheckinStatus.notStarted;
}
