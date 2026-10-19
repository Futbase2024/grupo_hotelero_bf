import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/money_cents.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../domain/entities/booking_deposit_entity.dart';
import 'deposit_dialog_parts.dart';

/// Datos introducidos en [RegisterDepositReturnDialog]
class DepositReturnInput {
  const DepositReturnInput({required this.returnedCents, this.retainedReason});

  final int returnedCents;

  /// Obligatorio si se retiene parte de la fianza
  final String? retainedReason;
}

/// Registra la devolución de la fianza tras el check-out, para llevar el
/// control. Por defecto se devuelve todo; si se devuelve menos, se pide el
/// motivo de lo retenido (p. ej. desperfectos).
class RegisterDepositReturnDialog extends StatefulWidget {
  const RegisterDepositReturnDialog({super.key, required this.deposit});

  final BookingDepositEntity deposit;

  /// Devuelve los datos introducidos, o `null` si se cancela
  static Future<DepositReturnInput?> show(
    BuildContext context, {
    required BookingDepositEntity deposit,
  }) {
    return showDialog<DepositReturnInput>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.blackWithAlpha80,
      builder: (_) => RegisterDepositReturnDialog(deposit: deposit),
    );
  }

  @override
  State<RegisterDepositReturnDialog> createState() =>
      _RegisterDepositReturnDialogState();
}

class _RegisterDepositReturnDialogState
    extends State<RegisterDepositReturnDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _returnedController;
  final _reasonController = TextEditingController();

  int get _totalCents => widget.deposit.amountCents ?? 0;

  /// Céntimos retenidos según lo escrito, o `null` si el importe no es válido
  int? get _retainedCents {
    final returned = parseCents(_returnedController.text);
    if (returned == null || returned > _totalCents) return null;
    return _totalCents - returned;
  }

  @override
  void initState() {
    super.initState();
    _returnedController = TextEditingController(
      text: centsToInput(_totalCents),
    );
  }

  @override
  void dispose() {
    _returnedController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final retained = _retainedCents ?? 0;
    final reason = _reasonController.text.trim();
    Navigator.of(context).pop(
      DepositReturnInput(
        returnedCents: parseCents(_returnedController.text)!,
        retainedReason: retained > 0 ? reason : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final retained = _retainedCents ?? 0;

    return Form(
      key: _formKey,
      child: DepositDialogScaffold(
        icon: Icons.currency_exchange,
        color: AppColors.info,
        backgroundColor: AppColors.infoLight,
        title: s.admin_deposit_return_title,
        actionText: s.admin_deposit_save,
        onAction: _submit,
        children: [
          DepositDialogMessage(
            s.admin_deposit_return_total(formatCents(_totalCents)),
          ),
          const SizedBox(height: 20),
          DepositTextField(
            controller: _returnedController,
            label: s.admin_deposit_returned_label,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            validator: (value) {
              final cents = parseCents(value ?? '');
              if (cents == null) return s.admin_deposit_amount_invalid;
              if (cents > _totalCents) return s.admin_deposit_returned_exceeds;
              return null;
            },
          ),
          if (retained > 0) ...[
            const SizedBox(height: 12),
            Text(
              s.admin_deposit_retained_preview(formatCents(retained)),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 12),
            DepositTextField(
              controller: _reasonController,
              label: s.admin_deposit_reason_label,
              maxLines: 2,
              validator: (value) => (value ?? '').trim().isEmpty
                  ? s.admin_deposit_reason_required
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
