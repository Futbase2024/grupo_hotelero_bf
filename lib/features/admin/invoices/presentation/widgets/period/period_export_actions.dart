import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/admin_widgets.dart';
import '../../bloc/invoices_period_bloc.dart';
import '../../bloc/invoices_period_event.dart';
import '../../bloc/invoices_period_state.dart';

/// Lanza una exportación; con lotes grandes de facturas pide confirmación antes
Future<void> requestPeriodExport(
  BuildContext context, {
  required PeriodExportFormat format,
  required PeriodExportAction action,
}) async {
  final bloc = context.read<InvoicesPeriodBloc>();
  final state = bloc.state;

  if (format == PeriodExportFormat.invoicesPdf && state.isLargeBatch) {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: '${state.count} facturas',
      body: 'Generar un PDF con ${state.count} páginas puede tardar un poco. '
          '¿Quieres continuar?',
      confirmText: 'Generar',
    );
    if (!confirmed) return;
  }

  bloc.add(InvoicesPeriodExportRequested(format: format, action: action));
}

/// Hoja para elegir qué hacer con un PDF: imprimir o compartir/guardar
Future<void> showPeriodPdfActionSheet(
  BuildContext context, {
  required PeriodExportFormat format,
  required String title,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            _SheetOption(
              icon: Icons.print_outlined,
              label: 'Imprimir',
              subtitle: 'Abre el diálogo de impresión (también permite guardar como PDF)',
              onTap: () {
                Navigator.pop(sheetContext);
                requestPeriodExport(context, format: format, action: PeriodExportAction.print);
              },
            ),
            const SizedBox(height: 8),
            _SheetOption(
              icon: Icons.ios_share_outlined,
              label: 'Compartir o guardar',
              subtitle: 'Email, WhatsApp, Archivos, Drive…',
              onTap: () {
                Navigator.pop(sheetContext);
                requestPeriodExport(context, format: format, action: PeriodExportAction.share);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkBackground,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        leading: Icon(icon, color: AppColors.gold),
        title: Text(label, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.gray500, fontSize: 12)),
        onTap: onTap,
      ),
    );
  }
}

/// Menú del AppBar del listado con todas las exportaciones
class PeriodExportMenu extends StatelessWidget {
  const PeriodExportMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final enabled = context.select<InvoicesPeriodBloc, bool>(
      (bloc) => bloc.state.count > 0 && !bloc.state.isExporting,
    );

    return PopupMenuButton<_MenuAction>(
      enabled: enabled,
      tooltip: 'Imprimir y exportar',
      icon: Icon(Icons.print_outlined, color: enabled ? AppColors.gold : AppColors.gray600),
      color: AppColors.darkSurface,
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 340),
      onSelected: (action) => requestPeriodExport(
        context,
        format: action.format,
        action: action.action,
      ),
      itemBuilder: (_) => _MenuAction.values
          .map((a) => PopupMenuItem(
                value: a,
                child: Row(
                  children: [
                    Icon(a.icon, size: 20, color: AppColors.gold),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(a.label, style: const TextStyle(color: AppColors.white)),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

enum _MenuAction {
  printInvoices(
    'Imprimir facturas',
    Icons.print_outlined,
    PeriodExportFormat.invoicesPdf,
    PeriodExportAction.print,
  ),
  shareInvoices(
    'PDF de facturas (compartir/guardar)',
    Icons.picture_as_pdf_outlined,
    PeriodExportFormat.invoicesPdf,
    PeriodExportAction.share,
  ),
  printList(
    'Imprimir listado',
    Icons.list_alt_outlined,
    PeriodExportFormat.listPdf,
    PeriodExportAction.print,
  ),
  shareList(
    'PDF del listado (compartir/guardar)',
    Icons.description_outlined,
    PeriodExportFormat.listPdf,
    PeriodExportAction.share,
  ),
  csv(
    'Exportar a Excel (CSV)',
    Icons.table_chart_outlined,
    PeriodExportFormat.csv,
    PeriodExportAction.share,
  );

  const _MenuAction(this.label, this.icon, this.format, this.action);

  final String label;
  final IconData icon;
  final PeriodExportFormat format;
  final PeriodExportAction action;
}
