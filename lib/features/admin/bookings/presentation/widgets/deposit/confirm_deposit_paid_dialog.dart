import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/money_cents.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../domain/entities/booking_deposit_entity.dart';
import 'deposit_dialog_parts.dart';

/// Resultado de [ConfirmDepositPaidDialog]
class ConfirmDepositPaidInput {
  const ConfirmDepositPaidInput({this.reference});

  /// Nº de operación de la pasarela, si el admin lo indica
  final String? reference;
}

/// Pide al admin que confirme que ha comprobado el cobro en su pasarela antes
/// de marcar la fianza como pagada (y validar el check-in si ya está enviado).
class ConfirmDepositPaidDialog extends StatefulWidget {
  const ConfirmDepositPaidDialog({super.key, required this.deposit});

  final BookingDepositEntity deposit;

  /// Devuelve los datos introducidos, o `null` si se cancela
  static Future<ConfirmDepositPaidInput?> show(
    BuildContext context, {
    required BookingDepositEntity deposit,
  }) {
    return showDialog<ConfirmDepositPaidInput>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.blackWithAlpha80,
      builder: (_) => ConfirmDepositPaidDialog(deposit: deposit),
    );
  }

  @override
  State<ConfirmDepositPaidDialog> createState() =>
      _ConfirmDepositPaidDialogState();
}

class _ConfirmDepositPaidDialogState extends State<ConfirmDepositPaidDialog> {
  final _referenceController = TextEditingController();

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final amount = formatCents(widget.deposit.amountCents ?? 0);

    return DepositDialogScaffold(
      icon: Icons.verified_outlined,
      color: AppColors.success,
      backgroundColor: AppColors.successLight,
      title: s.admin_deposit_confirm_title,
      actionText: s.admin_deposit_confirm_action,
      onAction: () {
        final reference = _referenceController.text.trim();
        Navigator.of(context).pop(
          ConfirmDepositPaidInput(
            reference: reference.isEmpty ? null : reference,
          ),
        );
      },
      children: [
        DepositDialogMessage(
          widget.deposit.willValidateOnConfirm
              ? s.admin_deposit_confirm_message_validate(amount)
              : s.admin_deposit_confirm_message_paid_only(amount),
        ),
        const SizedBox(height: 20),
        DepositTextField(
          controller: _referenceController,
          label: s.admin_deposit_reference_label,
        ),
      ],
    );
  }
}
