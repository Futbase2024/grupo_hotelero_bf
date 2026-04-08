import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bf_stay/l10n/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/invoice_entity.dart';
import '../bloc/invoices_bloc.dart';
import '../bloc/invoices_event.dart';
import '../bloc/invoices_state.dart';
import '../widgets/invoices_tab.dart';
import '../../data/services/invoice_pdf_service.dart';

/// Pantalla de detalle de factura con previsualización
class InvoiceDetailScreen extends StatelessWidget {
  InvoiceDetailScreen({
    super.key,
    required this.invoice,
  });

  final InvoiceEntity invoice;
  final _pdfService = InvoicePdfService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          invoice.invoiceNumber,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Status badge - se actualiza desde el estado
          BlocBuilder<InvoicesBloc, InvoicesState>(
            buildWhen: (previous, current) => previous.invoices != current.invoices,
            builder: (context, state) {
              final currentInvoice = _getCurrentInvoice(state);
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: InvoiceStatusBadge(status: currentInvoice?.status ?? invoice.status),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<InvoicesBloc, InvoicesState>(
        listenWhen: (previous, current) => previous.error != current.error,
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          // Obtener la factura actualizada del estado
          final currentInvoice = _getCurrentInvoice(state);

          // Si la factura ya no existe (fue eliminada), volver atrás
          if (currentInvoice == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pop(context);
            });
            return const SizedBox.shrink();
          }

          return Column(
            children: [
              // Invoice preview - siempre usa la factura actualizada
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _InvoicePreviewCard(invoice: currentInvoice),
                ),
              ),

              // Action buttons
              _buildActionButtons(context, currentInvoice),
            ],
          );
        },
      ),
    );
  }

  /// Obtiene la factura actualizada del estado del BLoC
  InvoiceEntity? _getCurrentInvoice(InvoicesState state) {
    try {
      return state.invoices.firstWhere(
        (inv) => inv.id == invoice.id,
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildActionButtons(BuildContext context, InvoiceEntity currentInvoice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
          top: BorderSide(color: AppColors.darkBorder),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primary actions based on status
            _buildPrimaryActions(context, currentInvoice),

            const SizedBox(height: 12),

            // Secondary actions
            Row(
              children: [
                Expanded(
                  child: _SecondaryActionButton(
                    icon: Icons.picture_as_pdf_outlined,
                    label: S.of(context).admin_invoice_generate_pdf,
                    onPressed: () => _generatePdf(context, currentInvoice),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SecondaryActionButton(
                    icon: Icons.share_outlined,
                    label: S.of(context).admin_invoice_share,
                    onPressed: () => _showShareOptions(context, currentInvoice),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SecondaryActionButton(
                    icon: Icons.download_outlined,
                    label: S.of(context).admin_invoice_download,
                    onPressed: () => _downloadPdf(context, currentInvoice),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryActions(BuildContext context, InvoiceEntity currentInvoice) {
    final actions = <Widget>[];

    // Emitir (solo borradores)
    if (currentInvoice.canBeIssued) {
      actions.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _confirmIssue(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.send_outlined),
            label: Text(
              S.of(context).admin_invoice_issue,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    // Marcar pagada (solo emitidas)
    if (currentInvoice.canBePaid) {
      actions.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _confirmMarkPaid(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(
              S.of(context).admin_invoice_mark_paid,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    // Cancelar (borradores o emitidas)
    if (currentInvoice.canBeCancelled) {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(width: 12));
      }
      actions.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _confirmCancel(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.cancel_outlined),
            label: Text(
              S.of(context).common_cancel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    // Si está pagada o cancelada, mostrar info
    if (currentInvoice.isPaid || currentInvoice.isCancelled) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (currentInvoice.isPaid ? AppColors.success : AppColors.error)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: (currentInvoice.isPaid ? AppColors.success : AppColors.error)
                .withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              currentInvoice.isPaid ? Icons.check_circle : Icons.cancel,
              color: currentInvoice.isPaid ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                currentInvoice.isPaid
                    ? S.of(context).admin_invoice_paid_on(_formatDate(currentInvoice.paidAt))
                    : S.of(context).admin_invoice_cancelled(currentInvoice.cancellationReason ?? ''),
                style: TextStyle(
                  color: currentInvoice.isPaid ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return actions.isEmpty ? const SizedBox.shrink() : Row(children: actions);
  }

  void _confirmIssue(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        title: Text(
          S.of(context).admin_invoice_issue_confirm_title,
          style: const TextStyle(color: AppColors.white),
        ),
        content: Text(
          S.of(context).admin_invoice_issue_confirm_message(invoice.invoiceNumber),
          style: const TextStyle(color: AppColors.gray400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              S.of(context).common_cancel,
              style: const TextStyle(color: AppColors.gray400),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.black,
            ),
            child: Text(S.of(context).admin_invoice_issue),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<InvoicesBloc>().add(InvoiceIssueRequested(invoice.id));
      Navigator.pop(context);
    }
  }

  void _confirmMarkPaid(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        title: Text(
          S.of(context).admin_invoice_mark_paid_confirm_title,
          style: const TextStyle(color: AppColors.white),
        ),
        content: Text(
          S.of(context).admin_invoice_mark_paid_confirm_message(invoice.formattedTotal),
          style: const TextStyle(color: AppColors.gray400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              S.of(context).common_cancel,
              style: const TextStyle(color: AppColors.gray400),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
            ),
            child: Text(S.of(context).admin_invoice_confirm_payment),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<InvoicesBloc>().add(InvoiceMarkPaidRequested(invoice.id));
      Navigator.pop(context);
    }
  }

  void _confirmCancel(BuildContext context) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        title: Text(
          S.of(context).admin_invoice_cancel_confirm_title,
          style: const TextStyle(color: AppColors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).admin_invoice_cancel_reason_label,
              style: const TextStyle(color: AppColors.gray400),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: S.of(context).admin_invoice_cancel_reason_hint,
                hintStyle: const TextStyle(color: AppColors.gray500),
                filled: true,
                fillColor: AppColors.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              S.of(context).admin_invoice_dont_cancel,
              style: const TextStyle(color: AppColors.gray400),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: Text(S.of(context).admin_invoice_cancel_invoice),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<InvoicesBloc>().add(
        InvoiceCancelRequested(invoice.id, reasonController.text.trim()),
      );
      Navigator.pop(context);
    }
  }

  void _generatePdf(BuildContext context, InvoiceEntity currentInvoice) async {
    try {
      await _pdfService.printInvoice(currentInvoice);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).admin_invoice_error_generate_pdf(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showShareOptions(BuildContext context, InvoiceEntity currentInvoice) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  S.of(context).admin_invoice_share_title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ShareOption(
                      icon: Icons.email_outlined,
                      label: S.of(context).common_email_type,
                      color: AppColors.gold,
                      onPressed: () {
                        Navigator.pop(context);
                        _shareViaEmail(context, currentInvoice);
                      },
                    ),
                    _ShareOption(
                      icon: Icons.message_outlined,
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      onPressed: () {
                        Navigator.pop(context);
                        _shareViaWhatsApp(context, currentInvoice);
                      },
                    ),
                    _ShareOption(
                      icon: Icons.copy_outlined,
                      label: S.of(context).admin_invoice_copy_link,
                      color: AppColors.info,
                      onPressed: () {
                        Navigator.pop(context);
                        _copyLink(context, currentInvoice);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shareViaEmail(BuildContext context, InvoiceEntity currentInvoice) async {
    try {
      // Obtener posición del botón para iPad
      final box = context.findRenderObject() as RenderBox?;
      final rect = _getShareRect(box);

      await _pdfService.shareInvoice(currentInvoice, rect);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).admin_invoice_error_share(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _shareViaWhatsApp(BuildContext context, InvoiceEntity currentInvoice) async {
    try {
      // Obtener posición del botón para iPad
      final box = context.findRenderObject() as RenderBox?;
      final rect = _getShareRect(box);

      await _pdfService.shareInvoice(currentInvoice, rect);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).admin_invoice_error_share(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _copyLink(BuildContext context, InvoiceEntity currentInvoice) async {
    try {
      // Obtener posición del botón para iPad
      final box = context.findRenderObject() as RenderBox?;
      final rect = _getShareRect(box);

      await _pdfService.shareInvoice(currentInvoice, rect);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).admin_invoice_error_share(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Obtiene el Rect para compartir en iPad
  Rect _getShareRect(RenderBox? box) {
    if (box == null) return Rect.zero;

    final position = box.localToGlobal(Offset.zero);
    return position & const Size(100, 100);
  }

  void _downloadPdf(BuildContext context, InvoiceEntity currentInvoice) async {
    try {
      final file = await _pdfService.saveInvoiceToFile(currentInvoice);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).admin_invoice_pdf_saved(file.path)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).admin_invoice_error_download(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

/// Previsualización visual de la factura
class _InvoicePreviewCard extends StatelessWidget {
  const _InvoicePreviewCard({required this.invoice});

  final InvoiceEntity invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con logo y datos emisor
          _buildHeader(context),

          const Divider(color: AppColors.darkBorder, height: 1),

          // Datos cliente
          _buildClientSection(context),

          const Divider(color: AppColors.darkBorder, height: 1),

          // Detalles factura
          _buildInvoiceDetails(context),

          const Divider(color: AppColors.darkBorder, height: 1),

          // Líneas de factura
          _buildLineItems(context),

          const Divider(color: AppColors.darkBorder, height: 1),

          // Totales
          _buildTotals(context),

          // Notas
          if (invoice.notes != null && invoice.notes!.isNotEmpty)
            _buildNotes(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo / Nombre emisor
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.issuerName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${S.of(context).admin_invoice_nif_label}: ${invoice.issuerNif}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray400,
                  ),
                ),
                if (invoice.issuerAddress != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    invoice.issuerAddress!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
                if (invoice.issuerCity != null || invoice.issuerPostalCode != null)
                  Text(
                    '${invoice.issuerPostalCode ?? ''} ${invoice.issuerCity ?? ''}'.trim(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gray500,
                    ),
                  ),
              ],
            ),
          ),

          // Número de factura
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                S.of(context).admin_invoice_label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray500,
                ),
              ),
              Text(
                invoice.invoiceNumber,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cliente
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).admin_invoice_bill_to,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  invoice.clientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                if (invoice.clientNif != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${S.of(context).admin_invoice_nif_label}: ${invoice.clientNif}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
                if (invoice.clientEmail != null || invoice.clientPhone != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      invoice.clientEmail,
                      invoice.clientPhone,
                    ].where((e) => e != null).join(' · '),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
                if (invoice.clientAddress != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    invoice.clientAddress!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Fechas
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildDateRow(S.of(context).admin_invoice_issue_date_label, invoice.formattedIssueDate),
              if (invoice.dueDate != null)
                _buildDateRow(
                  S.of(context).admin_invoice_due_date_label,
                  DateFormat('dd/MM/yyyy').format(invoice.dueDate!),
                ),
              if (invoice.periodStart != null && invoice.periodEnd != null)
                _buildDateRow(
                  S.of(context).admin_invoice_period_label,
                  '${DateFormat('dd/MM').format(invoice.periodStart!)} - ${DateFormat('dd/MM/yyyy').format(invoice.periodEnd!)}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.gray500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDetails(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            invoice.concept,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.white,
            ),
          ),
          if (invoice.bookingCode != null && invoice.bookingCode!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.hotel_outlined,
                  size: 14,
                  color: AppColors.gray500,
                ),
                const SizedBox(width: 4),
                Text(
                  '${S.of(context).admin_invoice_booking_label}: ${invoice.bookingCode}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
                if (invoice.unitName != null && invoice.unitName!.isNotEmpty)
                  Text(
                    ' · ${invoice.unitName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLineItems(BuildContext context) {
    if (invoice.lineItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          S.of(context).admin_invoice_no_line_items,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.gray500,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.darkBorder),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    S.of(context).admin_invoice_col_description,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    S.of(context).admin_invoice_col_qty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    S.of(context).admin_invoice_col_price,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    S.of(context).admin_invoice_col_total,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items
          ...invoice.lineItems.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.white,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.gray300,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '${item.unitPrice.toStringAsFixed(2)} €',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.gray300,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '${item.subtotal.toStringAsFixed(2)} €',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTotals(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkBackground.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildTotalRow(S.of(context).admin_invoice_tax_base, invoice.taxBase),
          const SizedBox(height: 8),
          _buildTotalRow(
            '${S.of(context).admin_invoice_tax_label} (${invoice.taxRate.toStringAsFixed(0)}%)',
            invoice.taxAmount,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.of(context).admin_invoice_total_label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
                Text(
                  invoice.formattedTotal,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.gray400,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} €',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildNotes(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).admin_invoice_notes_label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            invoice.notes!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.gray400,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón de acción secundario
class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkBackground,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.gold, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opción de compartir
class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
