import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/features/admin/domain/entities/admin_entities.dart';
import 'package:bf_stay/features/admin/domain/repositories/admin_panel_repository.dart';
import 'package:bf_stay/l10n/app_localizations.dart';

/// Tarjeta del detalle de check-in que muestra cuándo se borran las imágenes
/// de los documentos de identidad y permite retenerlas o borrarlas ya.
class CheckinDocumentsPrivacyCard extends StatefulWidget {
  const CheckinDocumentsPrivacyCard({
    super.key,
    required this.status,
    required this.documents,
    required this.repository,
    required this.onChanged,
  });

  final BookingDocumentsStatusEntity status;
  final List<CheckinDocumentEntity> documents;
  final AdminPanelRepository repository;

  /// Se llama tras cualquier cambio para recargar el detalle
  final Future<void> Function() onChanged;

  @override
  State<CheckinDocumentsPrivacyCard> createState() => _CheckinDocumentsPrivacyCardState();
}

class _CheckinDocumentsPrivacyCardState extends State<CheckinDocumentsPrivacyCard> {
  static const int _minReasonLength = 5;

  bool _isBusy = false;

  BookingDocumentsStatusEntity get _status => widget.status;

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy HH:mm').format(date);

  @override
  Widget build(BuildContext context) {
    final accent = _status.isRetained ? AppColors.warning : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  S.of(context).admin_docs_privacy_title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_isBusy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ..._buildStatusLines(context),
          const SizedBox(height: 8),
          Text(
            S.of(context).admin_docs_privacy_data_kept,
            style: const TextStyle(color: AppColors.gray500, fontSize: 12),
          ),
          if (_status.hasActiveDocuments) ...[
            const SizedBox(height: 16),
            _buildActions(context),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildStatusLines(BuildContext context) {
    final l10n = S.of(context);

    if (!_status.hasActiveDocuments) {
      final deletedAt = _status.lastDeletedAt;
      return [
        _StatusLine(
          icon: Icons.delete_sweep_outlined,
          color: AppColors.success,
          text: deletedAt != null
              ? l10n.admin_docs_privacy_deleted(_formatDate(deletedAt))
              : l10n.admin_docs_privacy_reason_manual,
        ),
      ];
    }

    if (_status.isRetained) {
      return [
        _StatusLine(
          icon: Icons.lock_clock_outlined,
          color: AppColors.warning,
          text: l10n.admin_docs_privacy_retained,
        ),
        if (_status.retainedReason != null)
          _StatusLine(
            icon: Icons.notes_outlined,
            color: AppColors.gray400,
            text: _status.retainedReason!,
          ),
        if (_status.retainedAt != null)
          _StatusLine(
            icon: Icons.person_outline,
            color: AppColors.gray400,
            text: l10n.admin_docs_privacy_retained_by(
              _status.retainedByName ?? '—',
              _formatDate(_status.retainedAt!),
            ),
          ),
      ];
    }

    final scheduledAt = _status.scheduledAt;
    final isDue = scheduledAt == null || !scheduledAt.isAfter(DateTime.now());

    return [
      _StatusLine(
        icon: Icons.auto_delete_outlined,
        color: AppColors.success,
        text: isDue
            ? l10n.admin_docs_privacy_scheduled_now
            : l10n.admin_docs_privacy_scheduled(_formatDate(scheduledAt)),
      ),
      if (_reasonLabel(context) case final reason?)
        _StatusLine(
          icon: Icons.info_outline,
          color: AppColors.gray400,
          text: reason,
        ),
    ];
  }

  String? _reasonLabel(BuildContext context) {
    final l10n = S.of(context);
    switch (_status.scheduledReason) {
      case DocumentDeletionReason.validated24h:
        return l10n.admin_docs_privacy_reason_validated;
      case DocumentDeletionReason.bookingCancelled:
        return l10n.admin_docs_privacy_reason_cancelled;
      case DocumentDeletionReason.checkoutNotValidated:
        return l10n.admin_docs_privacy_reason_checkout;
      case DocumentDeletionReason.manual:
        return l10n.admin_docs_privacy_reason_manual;
      case null:
        return null;
    }
  }

  Widget _buildActions(BuildContext context) {
    final l10n = S.of(context);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isBusy ? null : (_status.isRetained ? _release : _retain),
            icon: Icon(
              _status.isRetained ? Icons.lock_open_outlined : Icons.lock_outline,
              size: 18,
            ),
            label: Text(
              _status.isRetained
                  ? l10n.admin_docs_privacy_release_button
                  : l10n.admin_docs_privacy_retain_button,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: BorderSide(color: AppColors.warning.withValues(alpha: 0.6)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isBusy || _status.isRetained ? null : _deleteNow,
            icon: const Icon(Icons.delete_forever_outlined, size: 18),
            label: Text(l10n.admin_docs_privacy_delete_button),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              disabledForegroundColor: AppColors.gray600,
              side: BorderSide(
                color: _status.isRetained
                    ? AppColors.darkBorder
                    : AppColors.error.withValues(alpha: 0.6),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== ACCIONES ====================

  Future<void> _retain() async {
    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _RetainReasonDialog(minLength: _minReasonLength),
    );
    if (reason == null || !mounted) return;

    final l10n = S.of(context);
    await _run(
      () => widget.repository.setBookingDocumentsRetention(
        bookingId: _status.bookingId,
        retain: true,
        reason: reason,
      ),
      successMessage: l10n.admin_docs_privacy_retained_success,
    );
  }

  Future<void> _release() async {
    final l10n = S.of(context);
    await _run(
      () => widget.repository.setBookingDocumentsRetention(
        bookingId: _status.bookingId,
        retain: false,
      ),
      successMessage: l10n.admin_docs_privacy_released_success,
    );
  }

  Future<void> _deleteNow() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteDocumentsDialog(count: _status.activeCount),
    );
    if (confirmed != true || !mounted) return;

    final l10n = S.of(context);
    await _run(
      () => widget.repository.deleteBookingDocumentsNow(
        bookingId: _status.bookingId,
        documents: widget.documents,
      ),
      successMessage: l10n.admin_docs_privacy_deleted_success,
    );
  }

  Future<void> _run(
    Future<Object?> Function() action, {
    required String successMessage,
  }) async {
    setState(() => _isBusy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage), backgroundColor: AppColors.success),
      );
      await widget.onChanged();
    } catch (e) {
      debugPrint('❌ [CheckinDocumentsPrivacyCard] Error: $e');
      if (mounted) await _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _showErrorDialog(String message) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ProfessionalDialog(
        color: AppColors.error,
        icon: Icons.error_outline,
        title: S.of(dialogContext).admin_docs_privacy_error_title,
        body: message,
        actions: [
          _DialogButton(
            label: S.of(dialogContext).common_understood,
            color: AppColors.error,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }
}

/// Línea de estado con icono
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.gray300, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pide el motivo de la retención (obligatorio)
class _RetainReasonDialog extends StatefulWidget {
  const _RetainReasonDialog({required this.minLength});

  final int minLength;

  @override
  State<_RetainReasonDialog> createState() => _RetainReasonDialogState();
}

class _RetainReasonDialogState extends State<_RetainReasonDialog> {
  final TextEditingController _controller = TextEditingController();

  bool get _isValid => _controller.text.trim().length >= widget.minLength;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return _ProfessionalDialog(
      color: AppColors.warning,
      icon: Icons.lock_clock_outlined,
      title: l10n.admin_docs_privacy_retain_dialog_title,
      body: l10n.admin_docs_privacy_retain_dialog_body,
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: AppColors.white),
        decoration: InputDecoration(
          hintText: l10n.admin_docs_privacy_retain_reason_hint,
          hintStyle: const TextStyle(color: AppColors.gray500),
          filled: true,
          fillColor: AppColors.darkBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.warning, width: 2),
          ),
        ),
      ),
      actions: [
        _DialogButton(
          label: l10n.admin_docs_privacy_retain_button,
          color: AppColors.warning,
          onPressed: _isValid ? () => Navigator.of(context).pop(_controller.text.trim()) : null,
        ),
        _DialogButton(
          label: l10n.common_cancel,
          color: AppColors.gray400,
          outlined: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// Confirmación del borrado inmediato (irreversible)
class _DeleteDocumentsDialog extends StatelessWidget {
  const _DeleteDocumentsDialog({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return _ProfessionalDialog(
      color: AppColors.error,
      icon: Icons.warning_amber_rounded,
      title: l10n.admin_docs_privacy_delete_dialog_title,
      body: l10n.admin_docs_privacy_delete_dialog_body(count),
      actions: [
        _DialogButton(
          label: l10n.admin_docs_privacy_delete_confirm,
          color: AppColors.error,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        _DialogButton(
          label: l10n.common_cancel,
          color: AppColors.gray400,
          outlined: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

/// Diálogo con icono grande, título, descripción y botones a todo el ancho
class _ProfessionalDialog extends StatelessWidget {
  const _ProfessionalDialog({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
    required this.actions,
    this.content,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String body;
  final Widget? content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: color),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.4, color: AppColors.gray300),
              ),
              if (content != null) ...[
                const SizedBox(height: 20),
                content!,
              ],
              const SizedBox(height: 24),
              for (final action in actions) ...[
                action,
                if (action != actions.last) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    const padding = EdgeInsets.symmetric(vertical: 14);
    const textStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.5)),
                padding: padding,
                shape: shape,
              ),
              child: Text(label, style: textStyle),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.gray700,
                disabledForegroundColor: AppColors.gray400,
                elevation: 0,
                padding: padding,
                shape: shape,
              ),
              child: Text(label, style: textStyle),
            ),
    );
  }
}
