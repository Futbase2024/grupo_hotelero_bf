import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/info_dialog.dart';
import '../../domain/repositories/traveller_form_admin_repository.dart';

/// Interruptor "Formulario de registro de viajeros" del detalle de reserva.
///
/// Por defecto está apagado: el huésped hace el check-in subiendo las fotos
/// del documento. Al activarlo, ese huésped rellena el formulario RD 933.
/// Solo se puede cambiar mientras el check-in no se haya enviado ([isLocked]).
class TravellerFormToggleCard extends StatefulWidget {
  const TravellerFormToggleCard({
    super.key,
    required this.bookingId,
    required this.repository,
    required this.isLocked,
  });

  final String bookingId;
  final TravellerFormAdminRepository repository;

  /// El check-in ya se ha enviado: se muestra el estado pero no se puede cambiar
  final bool isLocked;

  @override
  State<TravellerFormToggleCard> createState() => _TravellerFormToggleCardState();
}

class _TravellerFormToggleCardState extends State<TravellerFormToggleCard> {
  bool _enabled = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final enabled = await widget.repository.isEnabled(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _enabled = enabled;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ [TravellerFormToggleCard] Error cargando estado: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _onChanged(bool value) async {
    final s = S.of(context);
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: value
          ? s.admin_traveller_form_enable_title
          : s.admin_traveller_form_disable_title,
      body: value
          ? s.admin_traveller_form_enable_body
          : s.admin_traveller_form_disable_body,
      confirmText: value
          ? s.admin_traveller_form_enable_button
          : s.admin_traveller_form_disable_button,
      cancelText: s.common_cancel,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);
    String? errorMessage;
    bool? saved;
    try {
      saved = await widget.repository.setEnabled(
        bookingId: widget.bookingId,
        enabled: value,
      );
    } on TravellerFormToggleException catch (e) {
      errorMessage = e.isCheckinAlreadySubmitted
          ? s.admin_traveller_form_locked_note
          : s.admin_traveller_form_error(e.code);
    } catch (e) {
      errorMessage = s.admin_traveller_form_error(e.toString());
    }
    if (!mounted) return;

    // Primero se quita el indicador de carga y después se informa
    setState(() {
      _isSaving = false;
      if (saved != null) _enabled = saved;
    });

    if (errorMessage != null) {
      await InfoDialog.error(
        context,
        title: s.admin_traveller_form_error_title,
        message: errorMessage,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _enabled ? s.admin_traveller_form_enabled : s.admin_traveller_form_disabled,
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final canChange = !widget.isLocked && !_loadFailed && !_isLoading;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _enabled ? AppColors.gold : AppColors.darkBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_ind_outlined,
                size: 18,
                color: _enabled ? AppColors.gold : AppColors.gray500,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.admin_traveller_form_title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.admin_traveller_form_subtitle,
                      style: const TextStyle(
                        color: AppColors.gray400,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_isLoading || _isSaving)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                )
              else
                Switch(
                  value: _enabled,
                  activeThumbColor: AppColors.black,
                  activeTrackColor: AppColors.gold,
                  inactiveThumbColor: AppColors.gray400,
                  inactiveTrackColor: AppColors.darkSurface,
                  onChanged: canChange ? _onChanged : null,
                ),
            ],
          ),
          if (widget.isLocked || _loadFailed) ...[
            const SizedBox(height: 8),
            _TravellerFormNote(
              icon: _loadFailed ? Icons.error_outline : Icons.lock_outline,
              color: _loadFailed ? AppColors.error : AppColors.gray500,
              text: _loadFailed
                  ? s.admin_traveller_form_load_error
                  : s.admin_traveller_form_locked_note,
            ),
          ],
        ],
      ),
    );
  }
}

class _TravellerFormNote extends StatelessWidget {
  const _TravellerFormNote({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 11, height: 1.3),
          ),
        ),
      ],
    );
  }
}
