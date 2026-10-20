import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import 'period_filters.dart';

/// Cabecera de mes del listado: "MARZO 2026 ··· 3 facturas · 2.310,00 €"
class PeriodMonthHeader extends StatelessWidget {
  const PeriodMonthHeader({
    super.key,
    required this.month,
    required this.count,
    required this.total,
  });

  final DateTime month;
  final int count;
  final double total;

  // Nombres fijos: no depende de que intl tenga cargados los símbolos 'es'
  static const _monthNames = [
    'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
    'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Text(
            '${_monthNames[month.month - 1]} ${month.year}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Divider(color: AppColors.darkBorder)),
          const SizedBox(width: 10),
          Text(
            '$count · ${formatPeriodCurrency(total)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.gray300,
            ),
          ),
        ],
      ),
    );
  }
}
