import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Título pequeño de un grupo de campos
class TravellerSectionLabel extends StatelessWidget {
  const TravellerSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.getTextSecondaryColor(context),
      ),
    );
  }
}

/// Aviso con icono y fondo suave
class TravellerNotice extends StatelessWidget {
  const TravellerNotice({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opciones excluyentes como fichas (tipo de documento, sexo…)
class TravellerChoiceGroup<T> extends StatelessWidget {
  const TravellerChoiceGroup({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.errorText,
  });

  final List<T> values;
  final T? selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              ChoiceChip(
                label: Text(labelOf(value)),
                selected: value == selected,
                showCheckmark: false,
                selectedColor: AppColors.goldWithAlpha30,
                side: BorderSide(
                  color: value == selected
                      ? AppColors.gold
                      : errorText != null
                          ? AppColors.error
                          : AppColors.getBorderColor(context),
                ),
                onSelected: (_) => onSelected(value),
              ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

/// Campos en fila en pantallas anchas y en columna en móvil
class TravellerFieldRow extends StatelessWidget {
  const TravellerFieldRow({super.key, required this.children});

  final List<Widget> children;

  static const double _breakpoint = 560;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _breakpoint || children.length == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                children[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }
}
