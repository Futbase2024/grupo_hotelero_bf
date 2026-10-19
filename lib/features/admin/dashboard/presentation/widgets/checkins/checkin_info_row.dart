import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

/// Par etiqueta/valor con icono, usado dentro de la tarjeta de check-in.
class CheckinInfoRow extends StatelessWidget {
  const CheckinInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isMonospace = false,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isMonospace;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.getTextTertiaryColor(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.getTextTertiaryColor(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: isMonospace ? 'JetBrains Mono' : null,
                  color: valueColor ?? AppColors.getTextPrimaryColor(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
