import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/money_cents.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../domain/entities/booking_deposit_entity.dart';
import '../../../data/services/deposit_link_sender.dart';
import 'deposit_dialog_parts.dart';

/// Datos introducidos en [RequestDepositDialog]
class RequestDepositInput {
  const RequestDepositInput({
    required this.amountCents,
    required this.paymentLink,
    required this.sendViaChat,
    required this.externalChannel,
    required this.saveAsDefault,
  });

  final int amountCents;
  final String paymentLink;
  final bool sendViaChat;
  final DepositExternalChannel externalChannel;
  final bool saveAsDefault;

  /// Canales a guardar en `bookings.deposit_sent_via`
  List<String> get sentVia => [
        if (sendViaChat) 'chat',
        if (externalChannel.dbValue != null) externalChannel.dbValue!,
      ];
}

/// Diálogo para pedir (o reenviar) la fianza de una reserva.
///
/// El importe sale relleno con la fianza ya pedida o con la sugerida del
/// alojamiento, y se puede cambiar. El enlace lo genera el admin en su
/// pasarela de pago y lo pega aquí.
class RequestDepositDialog extends StatefulWidget {
  const RequestDepositDialog({super.key, required this.deposit});

  final BookingDepositEntity deposit;

  /// Muestra el diálogo y devuelve los datos, o `null` si se cancela
  static Future<RequestDepositInput?> show(
    BuildContext context, {
    required BookingDepositEntity deposit,
  }) {
    return showDialog<RequestDepositInput>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.blackWithAlpha80,
      builder: (_) => RequestDepositDialog(deposit: deposit),
    );
  }

  @override
  State<RequestDepositDialog> createState() => _RequestDepositDialogState();
}

class _RequestDepositDialogState extends State<RequestDepositDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _linkController;

  late bool _sendViaChat;
  late DepositExternalChannel _externalChannel;
  bool _saveAsDefault = false;
  bool _showChannelError = false;

  BookingDepositEntity get _deposit => widget.deposit;

  @override
  void initState() {
    super.initState();
    final initialCents =
        _deposit.amountCents ?? _deposit.suggestedAmountCents;
    _amountController = TextEditingController(
      text: initialCents != null ? centsToInput(initialCents) : '',
    );
    _linkController = TextEditingController(text: _deposit.paymentLink ?? '');

    // Por defecto, el chat si el huésped ya está en la app; si no, WhatsApp
    _sendViaChat = _deposit.hasGuestAppUser;
    _externalChannel = !_deposit.hasGuestAppUser && _deposit.hasGuestPhone
        ? DepositExternalChannel.whatsapp
        : DepositExternalChannel.none;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  /// Solo se ofrece guardar como sugerido si el importe es distinto
  bool get _canSaveAsDefault {
    final cents = parseCents(_amountController.text);
    return cents != null && cents != _deposit.suggestedAmountCents;
  }

  void _submit() {
    final hasChannel = _sendViaChat ||
        _externalChannel != DepositExternalChannel.none;
    setState(() => _showChannelError = !hasChannel);

    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid || !hasChannel) return;

    Navigator.of(context).pop(
      RequestDepositInput(
        amountCents: parseCents(_amountController.text)!,
        paymentLink: _linkController.text.trim(),
        sendViaChat: _sendViaChat,
        externalChannel: _externalChannel,
        saveAsDefault: _saveAsDefault && _canSaveAsDefault,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isResend = _deposit.status.isPending;

    return Form(
      key: _formKey,
      child: DepositDialogScaffold(
        icon: Icons.payments_outlined,
        color: AppColors.gold,
        backgroundColor: AppColors.goldWithAlpha10,
        title: s.admin_deposit_request_title,
        actionText: s.admin_deposit_send_button,
        onAction: _submit,
        children: [
          DepositTextField(
            controller: _amountController,
            label: s.admin_deposit_amount_label,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            validator: (value) {
              final cents = parseCents(value ?? '');
              return cents == null || cents <= 0
                  ? s.admin_deposit_amount_invalid
                  : null;
            },
          ),
          if (_canSaveAsDefault && _deposit.propertyName.isNotEmpty)
            _SaveDefaultCheckbox(
              value: _saveAsDefault,
              label: s.admin_deposit_save_default(_deposit.propertyName),
              onChanged: (value) => setState(() => _saveAsDefault = value),
            ),
          const SizedBox(height: 12),
          DepositTextField(
            controller: _linkController,
            label: s.admin_deposit_link_label,
            hint: s.admin_deposit_link_hint,
            keyboardType: TextInputType.url,
            autofocus: isResend || _amountController.text.isNotEmpty,
            validator: (value) {
              final uri = Uri.tryParse(value?.trim() ?? '');
              final isValid = uri != null &&
                  (uri.scheme == 'https' || uri.scheme == 'http') &&
                  uri.host.isNotEmpty;
              return isValid ? null : s.admin_deposit_link_invalid;
            },
          ),
          const SizedBox(height: 20),
          _SectionLabel(s.admin_deposit_send_via),
          const SizedBox(height: 4),
          _ChannelCheckbox(
            icon: Icons.chat_bubble_outline,
            label: s.admin_deposit_channel_chat,
            disabledReason:
                _deposit.hasGuestAppUser ? null : s.admin_deposit_no_app_user,
            value: _sendViaChat,
            onChanged: (value) => setState(() => _sendViaChat = value),
          ),
          const SizedBox(height: 12),
          _SectionLabel(s.admin_deposit_also_send_via),
          const SizedBox(height: 8),
          _ExternalChannelSelector(
            deposit: _deposit,
            value: _externalChannel,
            onChanged: (value) => setState(() => _externalChannel = value),
          ),
          if (_showChannelError) ...[
            const SizedBox(height: 8),
            Text(
              s.admin_deposit_no_channel,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          _BlockingHint(text: s.admin_deposit_blocking_hint),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.getTextSecondaryColor(context),
      ),
    );
  }
}

class _SaveDefaultCheckbox extends StatelessWidget {
  const _SaveDefaultCheckbox({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (checked) => onChanged(checked ?? false),
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.gold,
      checkColor: AppColors.black,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: AppColors.getTextSecondaryColor(context),
        ),
      ),
    );
  }
}

class _ChannelCheckbox extends StatelessWidget {
  const _ChannelCheckbox({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.disabledReason,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Si no es `null`, el canal no está disponible y se explica el motivo
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final enabled = disabledReason == null;

    return CheckboxListTile(
      value: enabled && value,
      onChanged: enabled ? (checked) => onChanged(checked ?? false) : null,
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.gold,
      checkColor: AppColors.black,
      secondary: Icon(
        icon,
        color: enabled
            ? AppColors.gold
            : AppColors.getTextTertiaryColor(context),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: enabled
              ? AppColors.getTextPrimaryColor(context)
              : AppColors.getTextTertiaryColor(context),
        ),
      ),
      subtitle: enabled
          ? null
          : Text(
              disabledReason!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.getTextTertiaryColor(context),
              ),
            ),
    );
  }
}

/// Elige un canal externo: ninguno, WhatsApp o email. Solo uno, porque cada
/// uno abre otra app y encadenar dos dejaría el segundo sin abrir.
class _ExternalChannelSelector extends StatelessWidget {
  const _ExternalChannelSelector({
    required this.deposit,
    required this.value,
    required this.onChanged,
  });

  final BookingDepositEntity deposit;
  final DepositExternalChannel value;
  final ValueChanged<DepositExternalChannel> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ChannelChip(
          label: s.admin_deposit_channel_none,
          selected: value == DepositExternalChannel.none,
          onSelected: () => onChanged(DepositExternalChannel.none),
        ),
        _ChannelChip(
          label: deposit.hasGuestPhone
              ? s.admin_deposit_channel_whatsapp
              : '${s.admin_deposit_channel_whatsapp} · ${s.admin_deposit_no_phone}',
          selected: value == DepositExternalChannel.whatsapp,
          onSelected: deposit.hasGuestPhone
              ? () => onChanged(DepositExternalChannel.whatsapp)
              : null,
        ),
        _ChannelChip(
          label: deposit.hasGuestEmail
              ? s.admin_deposit_channel_email
              : '${s.admin_deposit_channel_email} · ${s.admin_deposit_no_email}',
          selected: value == DepositExternalChannel.email,
          onSelected: deposit.hasGuestEmail
              ? () => onChanged(DepositExternalChannel.email)
              : null,
        ),
      ],
    );
  }
}

class _ChannelChip extends StatelessWidget {
  const _ChannelChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;

  /// `null` deshabilita el chip
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected == null ? null : (_) => onSelected!(),
      showCheckmark: false,
      selectedColor: AppColors.gold,
      backgroundColor: AppColors.getChipBackgroundColor(context),
      side: BorderSide(
        color: selected ? AppColors.gold : AppColors.getBorderColor(context),
      ),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        color: selected
            ? AppColors.black
            : onSelected == null
                ? AppColors.getTextTertiaryColor(context)
                : AppColors.getTextPrimaryColor(context),
      ),
    );
  }
}

class _BlockingHint extends StatelessWidget {
  const _BlockingHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getGoldWithAlpha(context, alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.goldWithAlpha30),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, size: 18, color: AppColors.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
