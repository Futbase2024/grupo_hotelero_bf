import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/invoice_entity.dart';
import '../../bloc/invoices_period_state.dart';
import 'period_filters.dart';

/// KPIs del periodo: nº facturas, base imponible y total, más el desglose
class PeriodKpiRow extends StatelessWidget {
  const PeriodKpiRow({super.key, required this.state});

  final InvoicesPeriodState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _KpiCard(
                  icon: Icons.receipt_long_outlined,
                  label: 'Facturas',
                  value: '${state.count}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(
                  icon: Icons.account_balance_outlined,
                  label: 'Base imponible',
                  value: formatPeriodCurrency(state.totalBase),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(
                  icon: Icons.euro_outlined,
                  label: 'Total',
                  value: formatPeriodCurrency(state.totalAmount),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            _KpiDetail(label: 'IVA', value: formatPeriodCurrency(state.totalTax)),
            _KpiDetail(
              label: 'Pagadas',
              value: '${state.countByStatus(InvoiceStatus.paid)}',
              color: AppColors.success,
            ),
            _KpiDetail(
              label: 'Pendientes de cobro',
              value: '${state.countByStatus(InvoiceStatus.issued)} · '
                  '${formatPeriodCurrency(state.totalPending)}',
              color: AppColors.info,
            ),
            if (state.countByStatus(InvoiceStatus.cancelled) > 0)
              _KpiDetail(
                label: 'Anuladas',
                value: '${state.countByStatus(InvoiceStatus.cancelled)}',
                color: AppColors.error,
              ),
            if (state.countByStatus(InvoiceStatus.draft) > 0)
              _KpiDetail(
                label: 'Borradores',
                value: '${state.countByStatus(InvoiceStatus.draft)}',
              ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldWithAlpha20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.gold),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
        ],
      ),
    );
  }
}

class _KpiDetail extends StatelessWidget {
  const _KpiDetail({required this.label, required this.value, this.color = AppColors.gray300});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$label: ',
        style: const TextStyle(fontSize: 12, color: AppColors.gray500),
        children: [
          TextSpan(
            text: value,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
