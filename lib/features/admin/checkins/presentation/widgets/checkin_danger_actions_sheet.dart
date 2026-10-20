import 'package:flutter/material.dart';

import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/core/utils/guest_documents_cleaner.dart';
import 'package:bf_stay/features/admin/domain/repositories/admin_panel_repository.dart';
import 'package:bf_stay/features/admin/shared/widgets/confirmation_dialog.dart';
import 'package:bf_stay/l10n/app_localizations.dart';

/// Resultado de una acción destructiva sobre un check-in.
enum CheckinDangerResult {
  /// Se borraron los datos del check-in; la reserva sigue existiendo.
  checkinDeleted,

  /// Se eliminó la reserva completa.
  bookingDeleted,
}

/// Hoja de acciones destructivas de un check-in.
///
/// Ofrece dos niveles: borrar solo los datos del check-in (la reserva se
/// mantiene y el huésped puede rehacerlo con el mismo código) o borrar el
/// check-in junto con la reserva completa, que es exclusivo de admin.
///
/// Ninguna de las dos avisa al huésped: son acciones de limpieza operativa.
class CheckinDangerActionsSheet extends StatefulWidget {
  const CheckinDangerActionsSheet({
    super.key,
    required this.repository,
    required this.bookingId,
    required this.bookingCode,
    required this.isAdmin,
  });

  /// Repositorio del panel de administración.
  final AdminPanelRepository repository;

  /// Reserva sobre la que se actúa.
  final String bookingId;

  /// Código de la reserva, usado para confirmar el borrado completo.
  final String bookingCode;

  /// Solo los admin pueden eliminar la reserva completa.
  final bool isAdmin;

  /// Muestra la hoja y devuelve la acción ejecutada, o null si no se hizo nada.
  static Future<CheckinDangerResult?> show({
    required BuildContext context,
    required AdminPanelRepository repository,
    required String bookingId,
    required String bookingCode,
    required bool isAdmin,
  }) {
    return showModalBottomSheet<CheckinDangerResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CheckinDangerActionsSheet(
        repository: repository,
        bookingId: bookingId,
        bookingCode: bookingCode,
        isAdmin: isAdmin,
      ),
    );
  }

  @override
  State<CheckinDangerActionsSheet> createState() =>
      _CheckinDangerActionsSheetState();
}

class _CheckinDangerActionsSheetState extends State<CheckinDangerActionsSheet> {
  bool _isWorking = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Indicador de arrastre
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.getBorderColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              S.of(context).admin_checkin_danger_title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.bookingCode,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 20),

            _DangerActionTile(
              icon: Icons.restart_alt,
              color: AppColors.warning,
              title: S.of(context).admin_checkin_delete_title,
              subtitle: S.of(context).admin_checkin_delete_subtitle,
              enabled: !_isWorking,
              onTap: _deleteCheckin,
            ),
            const SizedBox(height: 12),

            if (widget.isAdmin)
              _DangerActionTile(
                icon: Icons.delete_forever,
                color: AppColors.error,
                title: S.of(context).admin_checkin_delete_booking_title,
                subtitle: S.of(context).admin_checkin_delete_booking_subtitle,
                enabled: !_isWorking,
                onTap: _deleteBooking,
              ),

            if (_isWorking) ...[
              const SizedBox(height: 20),
              const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Borra el check-in dejando viva la reserva.
  Future<void> _deleteCheckin() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: S.of(context).admin_checkin_delete_title,
      body: S.of(context).admin_checkin_delete_confirm_body,
      confirmText: S.of(context).admin_checkin_delete_title,
      cancelText: S.of(context).common_cancel,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isWorking = true);
    try {
      final storagePaths = await widget.repository.deleteCheckin(
        bookingId: widget.bookingId,
      );
      await removeGuestDocuments(storagePaths, logTag: 'deleteCheckin');

      if (mounted) {
        Navigator.of(context).pop(CheckinDangerResult.checkinDeleted);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isWorking = false);
        _showError(S.of(context).admin_checkin_error(e.toString()));
      }
    }
  }

  /// Borra la reserva completa junto con su check-in.
  Future<void> _deleteBooking() async {
    final confirmed = await _DeleteBookingConfirmDialog.show(
      context: context,
      bookingCode: widget.bookingCode,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isWorking = true);
    try {
      final storagePaths = await widget.repository.deleteBooking(
        bookingId: widget.bookingId,
      );
      await removeGuestDocuments(storagePaths, logTag: 'deleteBooking');

      if (mounted) {
        Navigator.of(context).pop(CheckinDangerResult.bookingDeleted);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isWorking = false);
        _showError(S.of(context).admin_checkin_error(e.toString()));
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }
}

/// Fila de acción destructiva dentro de la hoja.
class _DangerActionTile extends StatelessWidget {
  const _DangerActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getSurfaceSecondaryColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.getBorderColor(context)),
          ),
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: AppColors.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Confirmación reforzada del borrado de reserva: exige teclear el código.
class _DeleteBookingConfirmDialog extends StatefulWidget {
  const _DeleteBookingConfirmDialog({required this.bookingCode});

  final String bookingCode;

  static Future<bool> show({
    required BuildContext context,
    required String bookingCode,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.blackWithAlpha80,
      builder: (context) =>
          _DeleteBookingConfirmDialog(bookingCode: bookingCode),
    );
    return result ?? false;
  }

  @override
  State<_DeleteBookingConfirmDialog> createState() =>
      _DeleteBookingConfirmDialogState();
}

class _DeleteBookingConfirmDialogState
    extends State<_DeleteBookingConfirmDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final matches = _controller.text.trim().toUpperCase() ==
          widget.bookingCode.toUpperCase();
      if (matches != _matches) {
        setState(() => _matches = matches);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.getCardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever,
                size: 32,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).admin_checkin_delete_booking_title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              S.of(context).admin_checkin_delete_booking_confirm_body,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              S
                  .of(context)
                  .admin_checkin_delete_booking_code_hint(widget.bookingCode),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(color: AppColors.getTextPrimaryColor(context)),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.getInputBackgroundColor(context),
                hintText: widget.bookingCode,
                hintStyle: TextStyle(
                  color: AppColors.getTextTertiaryColor(context),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.getBorderColor(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      S.of(context).common_cancel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.getTextSecondaryColor(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed:
                        _matches ? () => Navigator.of(context).pop(true) : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: _matches
                          ? AppColors.error
                          : AppColors.getSurfaceSecondaryColor(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      S.of(context).common_delete,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _matches
                            ? AppColors.white
                            : AppColors.getTextTertiaryColor(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
