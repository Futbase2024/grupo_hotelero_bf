import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../domain/entities/house_rule_entity.dart';

/// Card que muestra una norma de la casa
class HouseRuleCard extends StatelessWidget {
  const HouseRuleCard({
    super.key,
    required this.rule,
  });

  final HouseRuleEntity rule;

  @override
  Widget build(BuildContext context) {
    final iconData = _getIconData(rule.icon);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              iconData,
              size: 24,
              color: AppColors.black,
            ),
          ),
          const SizedBox(width: 14),

          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  rule.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),

                // Descripción
                if (rule.hasDescription) ...[
                  const SizedBox(height: 6),
                  Text(
                    rule.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getTextSecondaryColor(context),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Obtiene el icono según el nombre
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'no_smoking':
        return Icons.smoke_free;
      case 'no_pets':
        return Icons.pets;
      case 'no_parties':
        return Icons.music_off;
      case 'quiet_hours':
        return Icons.bedtime_outlined;
      case 'no_visitors':
        return Icons.person_off_outlined;
      case 'no_shoes':
        return Icons.no_accounts;
      case 'checkout_time':
        return Icons.schedule;
      case 'checkin_time':
        return Icons.login;
      case 'garbage':
        return Icons.delete_outline;
      case 'air_conditioning':
        return Icons.ac_unit;
      case 'heating':
        return Icons.thermostat;
      case 'pool':
        return Icons.pool;
      case 'keys':
        return Icons.key_outlined;
      case 'info':
      default:
        return Icons.info_outline;
    }
  }
}

/// Header para una sección de categoría
class HouseRuleCategoryHeader extends StatelessWidget {
  const HouseRuleCategoryHeader({
    super.key,
    required this.category,
    required this.ruleCount,
  });

  final String category;
  final int ruleCount;

  @override
  Widget build(BuildContext context) {
    final categoryName = HouseRuleEntity.getCategoryDisplayName(category);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            categoryName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$ruleCount',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
