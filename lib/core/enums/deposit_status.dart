import 'package:flutter/widgets.dart';
import 'package:bf_stay/l10n/app_localizations.dart';

/// Estado de la fianza opcional de una reserva (columna `bookings.deposit_status`)
///
/// La fianza solo existe en las reservas en las que el admin la pide. Mientras
/// está [pending] el check-in no se puede validar por ninguna vía, de modo que
/// el huésped no ve códigos ni instrucciones de acceso.
enum DepositStatus {
  /// Sin fianza: validación normal
  none,

  /// Pedida al huésped: bloquea la validación del check-in
  pending,

  /// El admin comprobó el cobro en su pasarela
  paid,

  /// Devuelta tras el check-out (total o parcialmente)
  returned;

  /// Convierte desde string de base de datos
  static DepositStatus fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'pending' => DepositStatus.pending,
      'paid' => DepositStatus.paid,
      'returned' => DepositStatus.returned,
      _ => DepositStatus.none,
    };
  }

  /// Convierte a string para base de datos
  String toDbString() => name;

  /// Si bloquea la validación del check-in
  bool get isPending => this == DepositStatus.pending;

  /// Texto localizado del estado
  String label(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      DepositStatus.none => s.admin_deposit_status_none,
      DepositStatus.pending => s.admin_deposit_status_pending,
      DepositStatus.paid => s.admin_deposit_status_paid,
      DepositStatus.returned => s.admin_deposit_status_returned,
    };
  }
}
