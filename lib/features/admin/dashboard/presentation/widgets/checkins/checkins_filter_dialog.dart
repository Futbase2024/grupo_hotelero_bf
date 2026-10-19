import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../domain/bloc/bloc.dart';
import 'checkin_status_style.dart';

/// Resultado de los filtros elegidos en el diálogo.
class CheckinsFilterResult {
  const CheckinsFilterResult({
    required this.dateFilter,
    required this.statusFilter,
    this.customStart,
    this.customEnd,
  });

  final DateFilter dateFilter;
  final String statusFilter;
  final DateTime? customStart;
  final DateTime? customEnd;
}

/// Diálogo de filtros de la lista de check-ins.
///
/// Extraído del tab: antes vivía en un método de 300 líneas que devolvía
/// widgets, lo que el proyecto prohíbe expresamente.
class CheckinsFilterDialog extends StatefulWidget {
  const CheckinsFilterDialog({
    super.key,
    required this.initialDateFilter,
    required this.initialStatusFilter,
    this.initialCustomStart,
    this.initialCustomEnd,
  });

  final DateFilter initialDateFilter;
  final String initialStatusFilter;
  final DateTime? initialCustomStart;
  final DateTime? initialCustomEnd;

  /// Abre el diálogo y devuelve los filtros elegidos, o `null` si se cancela.
  static Future<CheckinsFilterResult?> show(
    BuildContext context, {
    required DateFilter dateFilter,
    required String statusFilter,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    return showDialog<CheckinsFilterResult>(
      context: context,
      builder: (_) => CheckinsFilterDialog(
        initialDateFilter: dateFilter,
        initialStatusFilter: statusFilter,
        initialCustomStart: customStart,
        initialCustomEnd: customEnd,
      ),
    );
  }

  @override
  State<CheckinsFilterDialog> createState() => _CheckinsFilterDialogState();
}

class _CheckinsFilterDialogState extends State<CheckinsFilterDialog> {
  late DateFilter _dateFilter = widget.initialDateFilter;
  late String _statusFilter = widget.initialStatusFilter;
  late DateTime? _customStart = widget.initialCustomStart;
  late DateTime? _customEnd = widget.initialCustomEnd;

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _dateFilter = DateFilter.customRange;
        _customStart = picked.start;
        _customEnd = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.getCardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.getGoldWithAlpha(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune, color: AppColors.gold, size: 22),
          ),
          const SizedBox(width: 14),
          Text(
            'Filtros',
            style: TextStyle(
              color: AppColors.getTextPrimaryColor(context),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('Período'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final filter in DateFilter.values)
                  _FilterChip(
                    label: filter.label,
                    selected: _dateFilter == filter,
                    onSelected: () async {
                      if (filter == DateFilter.customRange) {
                        await _pickDateRange();
                      } else {
                        setState(() {
                          _dateFilter = filter;
                          _customStart = null;
                          _customEnd = null;
                        });
                      }
                    },
                  ),
              ],
            ),
            if (_dateFilter == DateFilter.customRange &&
                _customStart != null &&
                _customEnd != null) ...[
              const SizedBox(height: 10),
              _CustomRangeSummary(
                start: _customStart!,
                end: _customEnd!,
                onEdit: _pickDateRange,
              ),
            ],
            const SizedBox(height: 20),
            _SectionTitle('Estado'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'Todos',
                  selected: _statusFilter == 'all',
                  onSelected: () => setState(() => _statusFilter = 'all'),
                ),
                for (final style in CheckinStatusStyle.values)
                  if (style.status != null)
                    _FilterChip(
                      label: style == CheckinStatusStyle.submitted
                          ? style.label
                          : '${style.label}s',
                      accentColor: style.color,
                      selected: _statusFilter == style.status,
                      onSelected: () =>
                          setState(() => _statusFilter = style.status!),
                    ),
                _FilterChip(
                  label: 'Sin empezar',
                  accentColor: CheckinStatusStyle.notStarted.color,
                  selected: _statusFilter == 'draft',
                  onSelected: () => setState(() => _statusFilter = 'draft'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() {
            _dateFilter = DateFilter.all;
            _statusFilter = 'submitted';
            _customStart = null;
            _customEnd = null;
          }),
          child: Text(
            'Limpiar todo',
            style: TextStyle(color: AppColors.getTextSecondaryColor(context)),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(color: AppColors.getTextSecondaryColor(context)),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(
            context,
            CheckinsFilterResult(
              dateFilter: _dateFilter,
              statusFilter: _statusFilter,
              customStart: _customStart,
              customEnd: _customEnd,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.darkBackground,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text(
            'Aplicar',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.getTextTertiaryColor(context),
        letterSpacing: 1.2,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.accentColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (accentColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: AppColors.getSurfaceColor(context),
      selectedColor: AppColors.getGoldWithAlpha(context),
      checkmarkColor: AppColors.gold,
      labelStyle: TextStyle(
        color:
            selected ? AppColors.gold : AppColors.getTextSecondaryColor(context),
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        fontSize: 13,
      ),
      side: BorderSide(
        color: selected ? AppColors.gold : AppColors.getBorderColor(context),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _CustomRangeSummary extends StatelessWidget {
  const _CustomRangeSummary({
    required this.start,
    required this.end,
    required this.onEdit,
  });

  final DateTime start;
  final DateTime end;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.getGoldWithAlpha(context)),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, color: AppColors.gold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${format.format(start)}  →  ${format.format(end)}',
              style: TextStyle(
                color: AppColors.getTextPrimaryColor(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: const Icon(Icons.edit_calendar,
                color: AppColors.gold, size: 20),
          ),
        ],
      ),
    );
  }
}
