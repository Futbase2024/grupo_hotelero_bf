import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/invoice_entity.dart';
import '../../bloc/invoice_period_presets.dart';
import '../../bloc/invoices_bloc.dart';
import '../../bloc/invoices_period_bloc.dart';
import '../../bloc/invoices_period_event.dart';
import '../../bloc/invoices_period_state.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');
final _currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '€');

/// Formatea importes como 1.234,56 €
String formatPeriodCurrency(double amount) => _currencyFormat.format(amount);

/// Chips con los atajos de periodo (mes, trimestres, año)
class PeriodPresetChips extends StatelessWidget {
  const PeriodPresetChips({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoicesPeriodBloc, InvoicesPeriodState>(
      buildWhen: (p, c) => p.start != c.start || p.end != c.end,
      builder: (context, state) {
        final now = DateTime.now();
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: InvoicePeriodPreset.values.map((preset) {
            final (start, end) = preset.range(now);
            final selected = start == state.start && end == state.end;
            return ChoiceChip(
              label: Text(preset.label),
              selected: selected,
              showCheckmark: false,
              selectedColor: AppColors.gold,
              backgroundColor: AppColors.darkBackground,
              side: BorderSide(color: selected ? AppColors.gold : AppColors.darkBorder),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? AppColors.black : AppColors.gray300,
              ),
              onSelected: (_) => context
                  .read<InvoicesPeriodBloc>()
                  .add(InvoicesPeriodRangeChanged(start: start, end: end)),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Campo con el rango "Desde – Hasta" que abre el selector de fechas
class PeriodDateRangeField extends StatelessWidget {
  const PeriodDateRangeField({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoicesPeriodBloc, InvoicesPeriodState>(
      buildWhen: (p, c) => p.start != c.start || p.end != c.end,
      builder: (context, state) {
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _pickRange(context, state),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                Expanded(child: _DateLabel(label: 'Desde', date: state.start)),
                const Icon(Icons.arrow_forward, size: 16, color: AppColors.gray500),
                const SizedBox(width: 12),
                Expanded(child: _DateLabel(label: 'Hasta', date: state.end)),
                const Icon(Icons.calendar_month_outlined, color: AppColors.gold),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickRange(BuildContext context, InvoicesPeriodState state) async {
    final bloc = context.read<InvoicesPeriodBloc>();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      initialDateRange: DateTimeRange(start: state.start, end: state.end),
      helpText: 'Periodo de emisión',
      saveText: 'Aplicar',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            onPrimary: AppColors.black,
            surface: AppColors.darkSurface,
            onSurface: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      bloc.add(InvoicesPeriodRangeChanged(start: picked.start, end: picked.end));
    }
  }
}

class _DateLabel extends StatelessWidget {
  const _DateLabel({required this.label, required this.date});

  final String label;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
        const SizedBox(height: 2),
        Text(
          _dateFormat.format(date),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
}

/// Checks de estados a incluir
class PeriodStatusFilter extends StatelessWidget {
  const PeriodStatusFilter({super.key});

  static const _order = [
    InvoiceStatus.issued,
    InvoiceStatus.paid,
    InvoiceStatus.cancelled,
    InvoiceStatus.draft,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoicesPeriodBloc, InvoicesPeriodState>(
      buildWhen: (p, c) => p.statuses != c.statuses,
      builder: (context, state) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _order.map((status) {
            final selected = state.statuses.contains(status);
            return FilterChip(
              label: Text(status.label),
              selected: selected,
              selectedColor: AppColors.goldWithAlpha20,
              checkmarkColor: AppColors.gold,
              backgroundColor: AppColors.darkBackground,
              side: BorderSide(color: selected ? AppColors.gold : AppColors.darkBorder),
              labelStyle: TextStyle(
                fontSize: 13,
                color: selected ? AppColors.gold : AppColors.gray400,
              ),
              onSelected: (_) => context
                  .read<InvoicesPeriodBloc>()
                  .add(InvoicesPeriodStatusToggled(status)),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Selector de alojamiento (las propiedades las carga InvoicesBloc)
class PeriodPropertyDropdown extends StatelessWidget {
  const PeriodPropertyDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final properties = context.select<InvoicesBloc, List<Map<String, dynamic>>>(
      (bloc) => bloc.state.properties,
    );
    final propertyId = context.select<InvoicesPeriodBloc, String?>(
      (bloc) => bloc.state.propertyId,
    );

    // Con un solo alojamiento el filtro no aporta nada
    if (properties.length < 2) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: propertyId,
          isExpanded: true,
          dropdownColor: AppColors.darkSurface,
          icon: const Icon(Icons.expand_more, color: AppColors.gold),
          style: const TextStyle(fontSize: 14, color: AppColors.white),
          items: [
            const DropdownMenuItem<String?>(
              child: Text('Todos los alojamientos'),
            ),
            ...properties.map(
              (p) => DropdownMenuItem<String?>(
                value: p['id'] as String,
                child: Text(p['name'] as String, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: (id) {
            final name = id == null
                ? null
                : properties.firstWhere((p) => p['id'] == id)['name'] as String;
            context
                .read<InvoicesPeriodBloc>()
                .add(InvoicesPeriodPropertyChanged(propertyId: id, propertyName: name));
          },
        ),
      ),
    );
  }
}

/// Resumen en vivo: "40 facturas · 12.430,50 €"
class PeriodPreviewSummary extends StatelessWidget {
  const PeriodPreviewSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoicesPeriodBloc, InvoicesPeriodState>(
      buildWhen: (p, c) =>
          p.invoices != c.invoices || p.isLoading != c.isLoading || p.error != c.error,
      builder: (context, state) {
        final String text;
        final Color color;
        if (state.isLoading) {
          text = 'Buscando facturas…';
          color = AppColors.gray400;
        } else if (state.error != null && !state.hasLoaded) {
          text = 'No se pudieron cargar las facturas';
          color = AppColors.error;
        } else if (state.isEmpty) {
          text = 'No hay facturas en este periodo';
          color = AppColors.gray400;
        } else {
          final noun = state.count == 1 ? 'factura' : 'facturas';
          text = '${state.count} $noun · ${formatPeriodCurrency(state.totalAmount)}';
          color = AppColors.gold;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.goldWithAlpha10,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.goldWithAlpha30),
          ),
          child: Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Título de sección pequeño dentro de la hoja
class PeriodSectionLabel extends StatelessWidget {
  const PeriodSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: AppColors.gray500,
        ),
      ),
    );
  }
}
