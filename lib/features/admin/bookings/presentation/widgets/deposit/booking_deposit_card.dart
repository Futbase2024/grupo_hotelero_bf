import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../core/enums/enums.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/money_cents.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../domain/entities/booking_deposit_entity.dart';
import '../../../../domain/repositories/admin_panel_repository.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/info_dialog.dart';
import '../../../data/services/deposit_link_sender.dart';
import 'confirm_deposit_paid_dialog.dart';
import 'register_deposit_return_dialog.dart';
import 'request_deposit_dialog.dart';

/// Tarjeta de la fianza opcional de una reserva, con todas sus acciones:
/// pedir / reenviar el enlace, eximir, marcar pagada (y validar) y registrar
/// la devolución.
///
/// No se muestra si la reserva no tiene fianza y ya no se puede pedir
/// (check-in validado o cancelado), para no añadir ruido.
class BookingDepositCard extends StatefulWidget {
  const BookingDepositCard({
    super.key,
    required this.deposit,
    required this.repository,
    required this.onChanged,
    this.onValidated,
  });

  final BookingDepositEntity deposit;
  final AdminPanelRepository repository;

  /// Tras cualquier cambio, para que la pantalla recargue sus datos
  final Future<void> Function() onChanged;

  /// Cuando confirmar el pago ha validado el check-in (p. ej. enviar el email
  /// de confirmación al huésped)
  final Future<void> Function()? onValidated;

  @override
  State<BookingDepositCard> createState() => _BookingDepositCardState();
}

class _BookingDepositCardState extends State<BookingDepositCard> {
  final _sender = const DepositLinkSender();
  bool _isBusy = false;

  BookingDepositEntity get _deposit => widget.deposit;

  String _errorText(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  /// Ejecuta una acción mostrando el estado de carga y los errores
  Future<void> _run(Future<void> Function() action) async {
    setState(() => _isBusy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        await InfoDialog.error(
          context,
          title: S.of(context).admin_deposit_error_title,
          message: _errorText(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _requestDeposit() async {
    final input = await RequestDepositDialog.show(context, deposit: _deposit);
    if (input == null || !mounted) return;

    await _run(() async {
      final s = S.of(context);
      await widget.repository.requestBookingDeposit(
        bookingId: _deposit.bookingId,
        amountCents: input.amountCents,
        paymentLink: input.paymentLink,
        sentVia: input.sentVia,
      );

      if (input.saveAsDefault) {
        try {
          await widget.repository.updatePropertyDefaultDeposit(
            propertyId: _deposit.propertyId,
            amountCents: input.amountCents,
          );
        } catch (e) {
          // No bloquea: la fianza ya está pedida
          debugPrint('⚠️ [BookingDepositCard] Importe sugerido no guardado: $e');
        }
      }

      final message = s.admin_deposit_guest_message(
        _deposit.guestName,
        formatCents(input.amountCents),
        input.paymentLink,
      );
      final failedChannels = await _sendLink(input, message);
      if (!mounted) return;

      if (failedChannels.isEmpty) {
        await InfoDialog.success(
          context,
          title: s.admin_deposit_done_title,
          message: s.admin_deposit_requested_success,
        );
      } else {
        await InfoDialog.warning(
          context,
          title: s.admin_deposit_error_title,
          message: s.admin_deposit_send_failed(failedChannels.join(', ')),
        );
      }
    });
    // La recarga puede desmontar la tarjeta: siempre después de los diálogos
    await widget.onChanged();
  }

  /// Envía el enlace por los canales elegidos. Devuelve los que fallaron.
  ///
  /// Si falla el email o no se puede abrir WhatsApp, el mensaje se copia al
  /// portapapeles para enviarlo a mano.
  Future<List<String>> _sendLink(
    RequestDepositInput input,
    String message,
  ) async {
    final s = S.of(context);
    final failed = <String>[];

    if (input.sendViaChat) {
      try {
        await _sender.sendViaChat(deposit: _deposit, message: message);
      } catch (e) {
        debugPrint('⚠️ [BookingDepositCard] Error enviando por chat: $e');
        failed.add(s.admin_deposit_channel_chat);
      }
    }

    switch (input.externalChannel) {
      case DepositExternalChannel.whatsapp:
        final opened = await _sender.openWhatsApp(
          phone: _deposit.guestPhone ?? '',
          message: message,
        );
        if (!opened) failed.add(s.admin_deposit_channel_whatsapp);
      case DepositExternalChannel.email:
        final sent = await _sender.sendEmail(bookingId: _deposit.bookingId);
        if (!sent) failed.add(s.admin_deposit_channel_email);
      case DepositExternalChannel.none:
        break;
    }

    if (failed.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: message));
    }
    return failed;
  }

  Future<void> _confirmPaid() async {
    final input =
        await ConfirmDepositPaidDialog.show(context, deposit: _deposit);
    if (input == null || !mounted) return;

    await _run(() async {
      final s = S.of(context);
      final validatedNow = await widget.repository.confirmDepositAndValidate(
        bookingId: _deposit.bookingId,
        reference: input.reference,
      );

      if (validatedNow) await widget.onValidated?.call();
      if (!mounted) return;

      await InfoDialog.success(
        context,
        title: s.admin_deposit_done_title,
        message: validatedNow
            ? s.admin_deposit_confirmed_validated
            : s.admin_deposit_confirmed_only,
      );
    });
    await widget.onChanged();
  }

  Future<void> _waive() async {
    final s = S.of(context);
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: s.admin_deposit_waive_title,
      body: s.admin_deposit_waive_message,
      confirmText: s.admin_deposit_waive_button,
      cancelText: s.common_cancel,
    );
    if (!confirmed || !mounted) return;

    await _run(() async {
      await widget.repository.waiveBookingDeposit(_deposit.bookingId);
      if (!mounted) return;
      await InfoDialog.success(
        context,
        title: s.admin_deposit_done_title,
        message: s.admin_deposit_waived_success,
      );
    });
    await widget.onChanged();
  }

  Future<void> _registerReturn() async {
    final input =
        await RegisterDepositReturnDialog.show(context, deposit: _deposit);
    if (input == null || !mounted) return;

    await _run(() async {
      final s = S.of(context);
      await widget.repository.registerDepositReturn(
        bookingId: _deposit.bookingId,
        returnedCents: input.returnedCents,
        retainedReason: input.retainedReason,
      );
      if (!mounted) return;
      await InfoDialog.success(
        context,
        title: s.admin_deposit_done_title,
        message: s.admin_deposit_returned_success,
      );
    });
    await widget.onChanged();
  }

  Future<void> _openLink() async {
    final uri = Uri.tryParse(_deposit.paymentLink ?? '');
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_deposit.status == DepositStatus.none && !_deposit.canRequest) {
      return const SizedBox.shrink();
    }

    final s = S.of(context);
    final statusColor = _DepositStatusBadge.colorFor(_deposit.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _deposit.status.isPending
              ? statusColor
              : AppColors.getBorderColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DepositCardHeader(
            title: s.admin_deposit_section,
            status: _deposit.status,
          ),
          const SizedBox(height: 16),
          if (_deposit.status == DepositStatus.none)
            _DepositNoneBody(
              isBusy: _isBusy,
              onRequest: _requestDeposit,
            )
          else ...[
            Text(
              formatCents(_deposit.amountCents ?? 0),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            _DepositDetails(deposit: _deposit, onOpenLink: _openLink),
            const SizedBox(height: 16),
            if (_isBusy)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              )
            else
              _DepositActions(
                deposit: _deposit,
                onConfirmPaid: _confirmPaid,
                onResend: _requestDeposit,
                onWaive: _waive,
                onRegisterReturn: _registerReturn,
              ),
          ],
        ],
      ),
    );
  }
}

/// Fechas, canales, referencia y devolución de la fianza
class _DepositDetails extends StatelessWidget {
  const _DepositDetails({required this.deposit, required this.onOpenLink});

  final BookingDepositEntity deposit;
  final VoidCallback onOpenLink;

  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  String _formatDate(DateTime? date) =>
      date == null ? '-' : _dateFormat.format(date.toLocal());

  String _channelsLabel(S s) {
    return deposit.sentVia
        .map((channel) => switch (channel) {
              'chat' => s.admin_deposit_channel_chat,
              'whatsapp' => s.admin_deposit_channel_whatsapp,
              'email' => s.admin_deposit_channel_email,
              _ => channel,
            })
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lines = <String>[
      if (deposit.requestedAt != null)
        deposit.sentVia.isEmpty
            ? s.admin_deposit_requested_info_no_channel(
                _formatDate(deposit.requestedAt))
            : s.admin_deposit_requested_info(
                _formatDate(deposit.requestedAt), _channelsLabel(s)),
      if (deposit.paidAt != null)
        s.admin_deposit_paid_info(_formatDate(deposit.paidAt)),
      if ((deposit.reference ?? '').isNotEmpty)
        s.admin_deposit_reference_info(deposit.reference!),
      if (deposit.returnedAt != null)
        s.admin_deposit_returned_info(
          _formatDate(deposit.returnedAt),
          formatCents(deposit.returnedCents ?? 0),
          formatCents(deposit.retainedCents ?? 0),
        ),
      if ((deposit.retainedReason ?? '').isNotEmpty)
        s.admin_deposit_retained_reason_info(deposit.retainedReason!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines) _DepositInfoLine(text: line),
        if (deposit.status.isPending && deposit.paymentLink != null)
          _DepositLinkRow(
            link: deposit.paymentLink!,
            tooltip: s.admin_deposit_open_link,
            onOpen: onOpenLink,
          ),
      ],
    );
  }
}

class _DepositCardHeader extends StatelessWidget {
  const _DepositCardHeader({required this.title, required this.status});

  final String title;
  final DepositStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.payments_outlined,
            color: AppColors.black,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        _DepositStatusBadge(status: status),
      ],
    );
  }
}

/// Badge ajustado al texto con el estado de la fianza
class _DepositStatusBadge extends StatelessWidget {
  const _DepositStatusBadge({required this.status});

  final DepositStatus status;

  static Color colorFor(DepositStatus status) => switch (status) {
        DepositStatus.none => AppColors.gray500,
        DepositStatus.pending => AppColors.warning,
        DepositStatus.paid => AppColors.success,
        DepositStatus.returned => AppColors.info,
      };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);

    return Align(
      alignment: Alignment.centerRight,
      child: IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color),
          ),
          child: Text(
            status.label(context).toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _DepositNoneBody extends StatelessWidget {
  const _DepositNoneBody({required this.isBusy, required this.onRequest});

  final bool isBusy;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.admin_deposit_none_hint,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.getTextSecondaryColor(context),
          ),
        ),
        const SizedBox(height: 16),
        _DepositButton(
          label: s.admin_deposit_request_button,
          icon: Icons.payments_outlined,
          color: AppColors.gold,
          isFilled: false,
          onPressed: isBusy ? null : onRequest,
        ),
      ],
    );
  }
}

class _DepositInfoLine extends StatelessWidget {
  const _DepositInfoLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: AppColors.getTextSecondaryColor(context),
        ),
      ),
    );
  }
}

class _DepositLinkRow extends StatelessWidget {
  const _DepositLinkRow({
    required this.link,
    required this.tooltip,
    required this.onOpen,
  });

  final String link;
  final String tooltip;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.link, size: 16, color: AppColors.gold),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            link,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.gold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.open_in_new, size: 18, color: AppColors.gold),
          tooltip: tooltip,
          visualDensity: VisualDensity.compact,
          onPressed: onOpen,
        ),
      ],
    );
  }
}

/// Acciones disponibles según el estado de la fianza
class _DepositActions extends StatelessWidget {
  const _DepositActions({
    required this.deposit,
    required this.onConfirmPaid,
    required this.onResend,
    required this.onWaive,
    required this.onRegisterReturn,
  });

  final BookingDepositEntity deposit;
  final VoidCallback onConfirmPaid;
  final VoidCallback onResend;
  final VoidCallback onWaive;
  final VoidCallback onRegisterReturn;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    switch (deposit.status) {
      case DepositStatus.pending:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DepositButton(
              label: deposit.willValidateOnConfirm
                  ? s.admin_deposit_confirm_button
                  : s.admin_deposit_mark_paid_button,
              icon: Icons.verified_outlined,
              color: AppColors.success,
              onPressed: onConfirmPaid,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DepositButton(
                    label: s.admin_deposit_resend_button,
                    icon: Icons.send_outlined,
                    color: AppColors.gold,
                    isFilled: false,
                    onPressed: onResend,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DepositButton(
                    label: s.admin_deposit_waive_button,
                    icon: Icons.money_off_outlined,
                    color: AppColors.gray500,
                    isFilled: false,
                    onPressed: onWaive,
                  ),
                ),
              ],
            ),
          ],
        );
      case DepositStatus.paid:
        return _DepositButton(
          label: s.admin_deposit_return_button,
          icon: Icons.currency_exchange,
          color: AppColors.info,
          isFilled: false,
          onPressed: onRegisterReturn,
        );
      case DepositStatus.none:
      case DepositStatus.returned:
        return const SizedBox.shrink();
    }
  }
}

class _DepositButton extends StatelessWidget {
  const _DepositButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isFilled = true,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    const padding = EdgeInsets.symmetric(vertical: 12, horizontal: 8);
    final text = Text(label, textAlign: TextAlign.center);

    if (isFilled) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: text,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.getTextColorForBackground(color),
          elevation: 0,
          padding: padding,
          shape: shape,
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: text,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: padding,
        shape: shape,
      ),
    );
  }
}
