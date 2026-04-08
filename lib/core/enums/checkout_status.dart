import 'package:flutter/widgets.dart';
import 'package:bf_stay/l10n/app_localizations.dart';

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

extension CheckoutStatusL10n on CheckoutStatus {
  /// Etiqueta legible para mostrar en UI
  String label(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      CheckoutStatus.notStarted => s.enum_checkout_status_not_started,
      CheckoutStatus.requested => s.enum_checkout_status_requested,
      CheckoutStatus.validated => s.enum_checkout_status_validated,
      CheckoutStatus.rejected => s.enum_checkout_status_rejected,
    };
  }

  /// Descripción del estado
  String description(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      CheckoutStatus.notStarted => s.enum_checkout_status_not_started_desc,
      CheckoutStatus.requested => s.enum_checkout_status_requested_desc,
      CheckoutStatus.validated => s.enum_checkout_status_validated_desc,
      CheckoutStatus.rejected => s.enum_checkout_status_rejected_desc,
    };
  }
}
