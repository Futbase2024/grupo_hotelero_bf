import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../bloc/invoices_period_bloc.dart';
import '../../bloc/invoices_period_event.dart';
import '../../bloc/invoices_period_state.dart';
import 'period_export_actions.dart';
import 'period_export_listener.dart';
import 'period_filters.dart';

/// Hoja "Facturas por periodo": rango, filtros y acciones.
/// Devuelve `true` si el usuario pulsa "Ver listado".
class PeriodSelectorSheet extends StatelessWidget {
  const PeriodSelectorSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: PeriodExportListener(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                20 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SheetHandle(),
                  SizedBox(height: 12),
                  _SheetTitle(),
                  SizedBox(height: 20),
                  PeriodSectionLabel('Atajos'),
                  PeriodPresetChips(),
                  SizedBox(height: 20),
                  PeriodSectionLabel('Fecha de emisión'),
                  PeriodDateRangeField(),
                  SizedBox(height: 20),
                  PeriodSectionLabel('Estados'),
                  PeriodStatusFilter(),
                  SizedBox(height: 20),
                  PeriodPropertyDropdown(),
                  PeriodPreviewSummary(),
                  SizedBox(height: 12),
                  _SummaryToggle(),
                  SizedBox(height: 16),
                  _SheetActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.gray600,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.date_range_outlined, color: AppColors.gold),
        SizedBox(width: 10),
        Text(
          'Facturas por periodo',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.white),
        ),
      ],
    );
  }
}

class _SummaryToggle extends StatelessWidget {
  const _SummaryToggle();

  @override
  Widget build(BuildContext context) {
    final includeSummary = context.select<InvoicesPeriodBloc, bool>(
      (bloc) => bloc.state.includeSummary,
    );
    return CheckboxListTile(
      value: includeSummary,
      contentPadding: EdgeInsets.zero,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.gold,
      checkColor: AppColors.black,
      side: const BorderSide(color: AppColors.gray500),
      title: const Text(
        'Incluir portada con resumen en el PDF',
        style: TextStyle(fontSize: 14, color: AppColors.gray300),
      ),
      onChanged: (value) => context
          .read<InvoicesPeriodBloc>()
          .add(InvoicesPeriodSummaryToggled(value ?? true)),
    );
  }
}

class _SheetActions extends StatelessWidget {
  const _SheetActions();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoicesPeriodBloc, InvoicesPeriodState>(
      buildWhen: (p, c) =>
          p.count != c.count ||
          p.isLoading != c.isLoading ||
          p.isExporting != c.isExporting ||
          p.includeSummary != c.includeSummary,
      builder: (context, state) {
        final enabled = state.count > 0 && !state.isLoading && !state.isExporting;
        final pages = state.count + (state.includeSummary ? 1 : 0);

        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: enabled ? () => Navigator.pop(context, true) : null,
                icon: const Icon(Icons.list_alt_outlined),
                label: const Text('Ver listado'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  disabledForegroundColor: AppColors.gray600,
                  side: BorderSide(color: enabled ? AppColors.gold : AppColors.darkBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: enabled
                    ? () => showPeriodPdfActionSheet(
                          context,
                          format: PeriodExportFormat.invoicesPdf,
                          title: 'PDF con ${state.count} facturas',
                        )
                    : null,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(enabled ? 'PDF ($pages págs.)' : 'PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.black,
                  disabledBackgroundColor: AppColors.darkBorder,
                  disabledForegroundColor: AppColors.gray600,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
