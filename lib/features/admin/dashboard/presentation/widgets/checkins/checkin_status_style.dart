import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/admin_booking_entity.dart';

/// Estilo visual de cada estado de check-in.
///
/// Antes cada color se repetía hardcodeado (`Color(0xFFE67E22)`…) en tres
/// métodos distintos de la lista. Aquí hay una sola fuente de verdad y usa
/// `AppColors`, como exige el proyecto.
enum CheckinStatusStyle {
  /// Enviado por el huésped: requiere que alguien lo revise.
  submitted(
    status: 'submitted',
    label: 'Por revisar',
    color: AppColors.warning,
    icon: Icons.pending_actions_outlined,
    needsAction: true,
  ),
  validated(
    status: 'validated',
    label: 'Validado',
    color: AppColors.success,
    icon: Icons.check_circle_outline,
  ),
  rejected(
    status: 'rejected',
    label: 'Rechazado',
    color: AppColors.error,
    icon: Icons.cancel_outlined,
    needsAction: true,
  ),
  cancelled(
    status: 'cancelled',
    label: 'Cancelado',
    color: AppColors.gray500,
    icon: Icons.block,
  ),
  notStarted(
    status: null,
    label: 'Sin empezar',
    color: AppColors.gray500,
    icon: Icons.edit_document,
  ),

  /// Fianza pedida y aún sin pagar: el check-in no se puede validar.
  ///
  /// No es un valor de `checkins.status` (sale de `bookings.deposit_status`),
  /// por eso `status` es `null`: así no aparece como filtro y [fromStatus]
  /// nunca lo devuelve (antes encuentra [notStarted]). Se obtiene con
  /// [forBooking].
  awaitingDeposit(
    status: null,
    label: 'Pendiente de pago',
    color: AppColors.warning,
    icon: Icons.payments_outlined,
    needsAction: true,
  );

  const CheckinStatusStyle({
    required this.status,
    required this.label,
    required this.color,
    required this.icon,
    this.needsAction = false,
  });

  /// Valor tal cual se guarda en la columna `checkins.status`.
  final String? status;
  final String label;
  final Color color;
  final IconData icon;

  /// Si el check-in espera una acción del equipo. Solo estos se destacan en
  /// dorado dentro de la lista; el resto va en tarjeta neutra para que lo que
  /// requiere atención resalte de verdad.
  final bool needsAction;

  /// Estilo para una reserva: si espera el pago de la fianza prevalece sobre
  /// el estado del check-in.
  static CheckinStatusStyle forBooking(AdminBookingEntity booking) {
    if (booking.isAwaitingDeposit) return CheckinStatusStyle.awaitingDeposit;
    return fromStatus(booking.checkinStatus);
  }

  static CheckinStatusStyle fromStatus(String? status) {
    return CheckinStatusStyle.values.firstWhere(
      (style) => style.status == status,
      orElse: () => CheckinStatusStyle.notStarted,
    );
  }
}
