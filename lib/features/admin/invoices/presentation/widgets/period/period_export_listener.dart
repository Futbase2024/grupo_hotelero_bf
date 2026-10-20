import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/admin_widgets.dart';
import '../../../data/services/invoice_pdf_service.dart';
import '../../bloc/invoices_period_bloc.dart';
import '../../bloc/invoices_period_event.dart';
import '../../bloc/invoices_period_state.dart';

/// Escucha los archivos generados por [InvoicesPeriodBloc] y los imprime o
/// comparte; muestra los errores en un diálogo y una capa de "Generando…".
class PeriodExportListener extends StatelessWidget {
  PeriodExportListener({super.key, required this.child});

  final Widget child;
  final _pdfService = InvoicePdfService();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<InvoicesPeriodBloc, InvoicesPeriodState>(
          listenWhen: (p, c) => c.pendingExport != null && p.pendingExport != c.pendingExport,
          listener: (context, state) => _deliver(context, state.pendingExport!),
        ),
        BlocListener<InvoicesPeriodBloc, InvoicesPeriodState>(
          listenWhen: (p, c) => c.error != null && p.error != c.error,
          listener: (context, state) => InfoDialog.error(
            context,
            title: 'Error',
            message: state.error!,
          ),
        ),
      ],
      child: Stack(
        children: [
          child,
          const _ExportingOverlay(),
        ],
      ),
    );
  }

  Future<void> _deliver(BuildContext context, PeriodExportFile file) async {
    final bloc = context.read<InvoicesPeriodBloc>();
    final box = context.findRenderObject() as RenderBox?;
    final rect = box == null ? null : box.localToGlobal(Offset.zero) & box.size;

    try {
      if (file.action == PeriodExportAction.print && file.isPdf) {
        await _pdfService.printPdfBytes(file.bytes, name: file.fileName);
      } else {
        await _pdfService.shareFileBytes(
          file.bytes,
          fileName: file.fileName,
          mimeType: file.mimeType,
          subject: '${file.fileName} - Grupo Hotelero BF',
          shareRect: rect,
        );
      }
    } catch (e) {
      if (context.mounted) {
        await InfoDialog.error(
          context,
          title: 'No se pudo completar',
          message: 'Error al imprimir o compartir el archivo: $e',
        );
      }
    } finally {
      bloc.add(const InvoicesPeriodExportConsumed());
    }
  }
}

class _ExportingOverlay extends StatelessWidget {
  const _ExportingOverlay();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoicesPeriodBloc, InvoicesPeriodState>(
      buildWhen: (p, c) => p.exportingFormat != c.exportingFormat,
      builder: (context, state) {
        if (!state.isExporting) return const SizedBox.shrink();

        final message = switch (state.exportingFormat!) {
          PeriodExportFormat.invoicesPdf => 'Generando ${state.count} facturas…',
          PeriodExportFormat.listPdf => 'Generando listado…',
          PeriodExportFormat.csv => 'Generando CSV…',
        };

        return Positioned.fill(
          child: ColoredBox(
            color: AppColors.blackWithAlpha80,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.gold),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
