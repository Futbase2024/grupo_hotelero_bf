import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../domain/entities/admin_booking_entity.dart';
import 'checkin_info_row.dart';
import 'checkin_status_style.dart';

/// Tarjeta de un check-in en la lista del panel.
///
/// Cambios respecto a la versión anterior:
///  · Recibe una `AdminBookingEntity` en lugar de `dynamic`: antes cada acceso
///    a `checkin.guestFullName` se resolvía en runtime y no había ninguna
///    comprobación en compilación.
///  · El dorado sólido se reserva a los check-ins que requieren acción. Con
///    más de mil validados, pintarlos todos en dorado hacía que no destacara
///    nada; ahora el color señala trabajo pendiente.
///  · Colores del tema (`getCardColor`, `getTextPrimaryColor`…) en vez de
///    blanco/oscuro fijos, que se volvían ilegibles en tema claro.
class CheckinListTile extends StatelessWidget {
  const CheckinListTile({
    super.key,
    required this.checkin,
    this.onTap,
    this.onManualCheckin,
    this.onMoreActions,
  });

  final AdminBookingEntity checkin;
  final VoidCallback? onTap;
  final VoidCallback? onManualCheckin;
  final VoidCallback? onMoreActions;

  /// Un check-in admite validación manual mientras el huésped no lo haya
  /// enviado.
  ///
  /// Con fianza pendiente no: la validación queda bloqueada hasta el pago.
  static bool canDoManualCheckin(AdminBookingEntity checkin) {
    if (checkin.isAwaitingDeposit) return false;
    if (checkin.checkinId == null) return true;
    return const ['not_started', 'draft', 'in_progress']
        .contains(checkin.checkinStatus);
  }

  @override
  Widget build(BuildContext context) {
    final style = CheckinStatusStyle.forBooking(checkin);
    final guestName =
        checkin.guestFullName.isNotEmpty ? checkin.guestFullName : 'Huésped';

    // Solo lo accionable lleva cabecera dorada.
    final headerColor =
        style.needsAction ? AppColors.gold : AppColors.getCardColor(context);
    final headerTextColor = style.needsAction
        ? AppColors.darkBackground
        : AppColors.getTextPrimaryColor(context);

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: style.needsAction
                      ? AppColors.gold
                      : AppColors.getBorderColor(context),
                ),
              ),
              child: Column(
                children: [
                  _CheckinTileHeader(
                    guestName: guestName,
                    style: style,
                    backgroundColor: headerColor,
                    textColor: headerTextColor,
                    onMoreActions: onMoreActions,
                  ),
                  _CheckinTileBody(checkin: checkin),
                  _CheckinTileFooter(
                    checkin: checkin,
                    onManualCheckin: onManualCheckin,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckinTileHeader extends StatelessWidget {
  const _CheckinTileHeader({
    required this.guestName,
    required this.style,
    required this.backgroundColor,
    required this.textColor,
    this.onMoreActions,
  });

  final String guestName;
  final CheckinStatusStyle style;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onMoreActions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.getBorderColor(context)),
        ),
      ),
      child: Row(
        children: [
          Icon(style.icon, size: 22, color: style.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              guestName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _CheckinStatusBadge(style: style),
          if (onMoreActions != null)
            IconButton(
              icon: Icon(Icons.more_vert, color: textColor),
              tooltip: S.of(context).admin_checkin_more_actions,
              visualDensity: VisualDensity.compact,
              onPressed: onMoreActions,
            ),
        ],
      ),
    );
  }
}

/// Badge de estado sobre fondo neutro.
///
/// Antes era un badge verde sólido sobre la cabecera dorada: verde sobre
/// amarillo es la combinación que peor distinguen las personas con
/// deuteranopia. Con fondo neutro, punto de color y texto del color del estado
/// el contraste deja de depender del color.
class _CheckinStatusBadge extends StatelessWidget {
  const _CheckinStatusBadge({required this.style});

  final CheckinStatusStyle style;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: style.color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: style.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              style.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: style.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckinTileBody extends StatelessWidget {
  const _CheckinTileBody({required this.checkin});

  final AdminBookingEntity checkin;

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  String _formatDate(DateTime? date) =>
      date == null ? '-' : _dateFormat.format(date);

  String get _unitsLabel {
    if (!checkin.hasMultipleUnits) return checkin.unitName;
    if (checkin.units.isNotEmpty) {
      return checkin.units.map((u) => u.name).join(' · ');
    }
    return '${checkin.totalUnits} habitaciones';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CheckinInfoRow(
                  icon: Icons.apartment_outlined,
                  label: checkin.hasMultipleUnits ? 'Unidades' : 'Unidad',
                  value: _unitsLabel,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CheckinInfoRow(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Reserva',
                  value: checkin.bookingCode,
                  isMonospace: true,
                  valueColor: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CheckinInfoRow(
                  icon: Icons.login,
                  label: 'Check-in',
                  value: _formatDate(checkin.checkInDate),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CheckinInfoRow(
                  icon: Icons.logout,
                  label: 'Check-out',
                  value: _formatDate(checkin.checkOutDate),
                ),
              ),
            ],
          ),
          if (checkin.hasDocsPending) ...[
            const SizedBox(height: 12),
            _DocsPendingBanner(count: checkin.docsPending ?? 0),
          ],
        ],
      ),
    );
  }
}

class _DocsPendingBanner extends StatelessWidget {
  const _DocsPendingBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 18, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count documentos pendientes',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckinTileFooter extends StatelessWidget {
  const _CheckinTileFooter({
    required this.checkin,
    this.onManualCheckin,
  });

  final AdminBookingEntity checkin;
  final VoidCallback? onManualCheckin;

  @override
  Widget build(BuildContext context) {
    final canDoManual = CheckinListTile.canDoManualCheckin(checkin);

    if (canDoManual && onManualCheckin != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onManualCheckin,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Check-in Manual'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      );
    }

    if (checkin.checkinId == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Ver detalle',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.gold),
        ],
      ),
    );
  }
}
