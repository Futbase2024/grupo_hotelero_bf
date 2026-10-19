import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../domain/bloc/bloc.dart';
import 'checkin_status_style.dart';

/// Cabecera del tab: título, recuento y orden.
class CheckinsHeader extends StatelessWidget {
  const CheckinsHeader({
    super.key,
    required this.count,
    required this.statusFilter,
    required this.isRefreshing,
    required this.sortOrder,
    required this.onToggleSort,
  });

  final int count;
  final String? statusFilter;
  final bool isRefreshing;
  final SortOrder sortOrder;
  final VoidCallback onToggleSort;

  /// El contador antes era un número suelto ("1026") que no decía de qué. Al
  /// nombrar el estado filtrado se entiende qué se está contando.
  String get _countLabel {
    if (statusFilter == null || statusFilter == 'all') return '$count';
    final style = CheckinStatusStyle.fromStatus(statusFilter);
    return '$count ${style.label.toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final isDescending = sortOrder == SortOrder.descending;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            'Check-ins',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppColors.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.getGoldWithAlpha(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _countLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Indicador discreto de refresco en segundo plano: la lista actual
          // permanece visible mientras llegan los datos nuevos.
          if (isRefreshing) ...[
            const SizedBox(width: 10),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold,
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            onPressed: onToggleSort,
            icon: Icon(
              isDescending ? Icons.arrow_downward : Icons.arrow_upward,
              size: 20,
            ),
            color: AppColors.gold,
            tooltip: isDescending
                ? 'Más recientes primero'
                : 'Más antiguos primero',
          ),
        ],
      ),
    );
  }
}
