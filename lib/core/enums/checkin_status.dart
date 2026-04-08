import 'package:flutter/widgets.dart';
import 'package:bf_stay/l10n/app_localizations.dart';

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
  rejected,

  /// Cancelado - la reserva ha sido cancelada, no permite corrección
  cancelled;

  /// Convierte desde string de base de datos
  static CheckinStatus fromString(String value) {
    return switch (value.toLowerCase()) {
      'not_started' => CheckinStatus.notStarted,
      'in_progress' => CheckinStatus.inProgress,
      'draft' => CheckinStatus.inProgress, // Compatibilidad con datos existentes
      'submitted' => CheckinStatus.submitted,
      'validated' => CheckinStatus.validated,
      'rejected' => CheckinStatus.rejected,
      'cancelled' => CheckinStatus.cancelled,
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
      CheckinStatus.cancelled => 'cancelled',
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

  /// Si el check-in fue cancelado (no permite corrección)
  bool get isCancelled => this == CheckinStatus.cancelled;

  /// Si el check-in ya comenzó (no está en not_started)
  bool get hasStarted => this != CheckinStatus.notStarted;
}

extension CheckinStatusL10n on CheckinStatus {
  /// Etiqueta legible para mostrar en UI
  String label(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      CheckinStatus.notStarted => s.enum_checkin_status_not_started,
      CheckinStatus.inProgress => s.enum_checkin_status_in_progress,
      CheckinStatus.submitted => s.enum_checkin_status_submitted,
      CheckinStatus.validated => s.enum_checkin_status_validated,
      CheckinStatus.rejected => s.enum_checkin_status_rejected,
      CheckinStatus.cancelled => s.enum_checkin_status_cancelled,
    };
  }

  /// Descripción del estado
  String description(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      CheckinStatus.notStarted => s.enum_checkin_status_not_started_desc,
      CheckinStatus.inProgress => s.enum_checkin_status_in_progress_desc,
      CheckinStatus.submitted => s.enum_checkin_status_submitted_desc,
      CheckinStatus.validated => s.enum_checkin_status_validated_desc,
      CheckinStatus.rejected => s.enum_checkin_status_rejected_desc,
      CheckinStatus.cancelled => s.enum_checkin_status_cancelled_desc,
    };
  }
}
