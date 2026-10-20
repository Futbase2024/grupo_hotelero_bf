import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/invoice_entity.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../bloc/invoices_bloc.dart';
import '../bloc/invoices_period_bloc.dart';
import '../bloc/invoices_period_event.dart';
import '../bloc/invoices_period_state.dart';
import '../widgets/period/period_export_actions.dart';
import '../widgets/period/period_export_listener.dart';
import '../widgets/period/period_invoice_row.dart';
import '../widgets/period/period_kpi_row.dart';
import '../widgets/period/period_month_header.dart';
import 'invoice_detail_screen.dart';

/// Listado en pantalla de las facturas de un periodo, con totales y
/// agrupado por mes. Desde el AppBar se imprime o exporta.
class InvoicesPeriodScreen extends StatelessWidget {
  const InvoicesPeriodScreen({super.key});

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
        title: const _PeriodTitle(),
        actions: const [PeriodExportMenu(), SizedBox(width: 4)],
      ),
      body: SafeArea(
        child: PeriodExportListener(
          child: BlocBuilder<InvoicesPeriodBloc, InvoicesPeriodState>(
            buildWhen: (p, c) =>
                p.invoices != c.invoices || p.isLoading != c.isLoading || p.hasLoaded != c.hasLoaded,
            builder: (context, state) {
              if (state.isLoading && !state.hasLoaded) {
                return const Center(child: CircularProgressIndicator(color: AppColors.gold));
              }
              if (state.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.receipt_long_outlined,
                  title: 'Sin facturas',
                  subtitle: 'No hay facturas en este periodo con los filtros elegidos',
                );
              }
              return _PeriodList(state: state);
            },
          ),
        ),
      ),
    );
  }
}

class _PeriodTitle extends StatelessWidget {
  const _PeriodTitle();

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy');
    return BlocBuilder<InvoicesPeriodBloc, InvoicesPeriodState>(
      buildWhen: (p, c) => p.start != c.start || p.end != c.end || p.propertyName != c.propertyName,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Facturas del periodo',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.white),
            ),
            Text(
              '${format.format(state.start)} – ${format.format(state.end)}'
              '${state.propertyName != null ? ' · ${state.propertyName}' : ''}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.gray400),
            ),
          ],
        );
      },
    );
  }
}

class _PeriodList extends StatelessWidget {
  const _PeriodList({required this.state});

  final InvoicesPeriodState state;

  @override
  Widget build(BuildContext context) {
    final months = state.invoicesByMonth.entries.toList();

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.darkSurface,
      onRefresh: () async =>
          context.read<InvoicesPeriodBloc>().add(const InvoicesPeriodLoadRequested()),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(child: PeriodKpiRow(state: state)),
          ),
          for (final month in months) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: PeriodMonthHeader(
                  month: month.key,
                  count: month.value.length,
                  total: month.value.fold(0.0, (sum, i) => sum + i.totalIncludingTax),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: month.value.length,
                itemBuilder: (context, index) {
                  final invoice = month.value[index];
                  return PeriodInvoiceRow(
                    invoice: invoice,
                    onTap: () => _openDetail(context, invoice),
                  );
                },
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, InvoiceEntity invoice) async {
    final periodBloc = context.read<InvoicesPeriodBloc>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<InvoicesBloc>(),
          child: InvoiceDetailScreen(invoice: invoice),
        ),
      ),
    );
    // En el detalle se puede emitir/cobrar/anular: refrescar el periodo
    if (!periodBloc.isClosed) {
      periodBloc.add(const InvoicesPeriodLoadRequested());
    }
  }
}
