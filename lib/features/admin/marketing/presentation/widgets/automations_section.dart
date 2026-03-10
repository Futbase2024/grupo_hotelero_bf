import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

/// Sección de automatizaciones de marketing
class AutomationsSection extends StatelessWidget {
  const AutomationsSection({super.key});

  // En producción, las automatizaciones vendrían de Supabase
  // Por ahora mostramos estado vacío
  List<_AutomationData> get _automations => [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.goldWithAlpha20,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_outlined,
                    size: 20,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Automatizaciones',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                // TODO: Ver todas las automatizaciones
              },
              child: const Text(
                'Ver todo',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.gold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...(_automations.isEmpty
            ? [_buildEmptyState(context)]
            : _automations.map((a) => _AutomationCard(automation: a))),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorderColor(context),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 40,
              color: AppColors.gray500,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay automatizaciones',
              style: TextStyle(
                color: AppColors.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Crear automatización
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Crear primera automatización'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Datos de una automatización
class _AutomationData {
  final String name;
  final String description;
  final String trigger;
  final AutomationType type;
  final Duration delay;
  final bool isActive;

  _AutomationData({
    required this.name,
    required this.description,
    required this.trigger,
    required this.type,
    required this.delay,
    required this.isActive,
  });
}

enum AutomationType { email, push, sms, whatsapp }

/// Tarjeta de automatización individual
class _AutomationCard extends StatelessWidget {
  const _AutomationCard({required this.automation});

  final _AutomationData automation;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: automation.isActive
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.getBorderColor(context),
        ),
      ),
      child: Row(
        children: [
          // Indicador de estado
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: automation.isActive
                  ? AppColors.success
                  : AppColors.gray500,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      automation.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _getTypeIcon(),
                      size: 16,
                      color: AppColors.gold,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  automation.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondaryColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getDelayText(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          // Toggle
          Switch(
            value: automation.isActive,
            onChanged: (value) {
              // TODO: Toggle automatización
            },
            activeTrackColor: AppColors.success.withValues(alpha: 0.3),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.success;
              }
              return AppColors.gray500;
            }),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (automation.type) {
      case AutomationType.email:
        return Icons.email_outlined;
      case AutomationType.push:
        return Icons.notifications_active_outlined;
      case AutomationType.sms:
        return Icons.sms_outlined;
      case AutomationType.whatsapp:
        return Icons.chat_outlined;
    }
  }

  String _getDelayText() {
    if (automation.delay == Duration.zero) {
      return 'Sin delay';
    } else if (automation.delay.inHours >= 24) {
      final days = automation.delay.inDays;
      return '${days}d delay';
    } else {
      final hours = automation.delay.inHours;
      return '${hours}h delay';
    }
  }
}
