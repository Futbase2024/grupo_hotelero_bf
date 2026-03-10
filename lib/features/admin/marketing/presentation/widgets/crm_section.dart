import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

/// Sección de CRM de huéspedes
class CrmSection extends StatelessWidget {
  const CrmSection({super.key});

  // En producción, los huéspedes vendrían de Supabase
  // Por ahora mostramos estado vacío
  List<_GuestData> get _guests => [];

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
                    Icons.people_outline,
                    size: 20,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CRM Huéspedes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                    ),
                    Text(
                      '${_guests.length} huéspedes registrados',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                // TODO: Ver todos los huéspedes
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
        // Estadísticas rápidas
        _buildQuickStats(context),
        const SizedBox(height: 12),
        // Lista de huéspedes
        ...(_guests.isEmpty
            ? [_buildEmptyState(context)]
            : _guests.map((g) => _GuestCard(guest: g))),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _QuickStatCard(
              icon: Icons.star_outline,
              value: '0',
              label: 'VIP',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickStatCard(
              icon: Icons.repeat,
              value: '0',
              label: 'Recurrentes',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickStatCard(
              icon: Icons.person_add_outlined,
              value: '0',
              label: 'Nuevos',
            ),
          ),
        ],
      ),
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
              Icons.people_outline,
              size: 40,
              color: AppColors.gray500,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay huéspedes en el CRM',
              style: TextStyle(
                color: AppColors.getTextSecondaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Datos de un huésped
class _GuestData {
  final String name;
  final String email;
  final int totalBookings;
  final double totalSpent;
  final List<String> tags;
  final DateTime lastVisit;

  _GuestData({
    required this.name,
    required this.email,
    required this.totalBookings,
    required this.totalSpent,
    required this.tags,
    required this.lastVisit,
  });
}

/// Tarjeta de estadística rápida
class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.getBorderColor(context),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.gold,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimaryColor(context),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de huésped individual
class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.guest});

  final _GuestData guest;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.getBorderColor(context),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.goldWithAlpha20,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                _getInitials(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              ),
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
                    Expanded(
                      child: Text(
                        guest.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.getTextPrimaryColor(context),
                        ),
                      ),
                    ),
                    // Tags
                    ...guest.tags.take(2).map((tag) => _buildTag(tag)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: AppColors.getTextSecondaryColor(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${guest.totalBookings} reservas',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getTextSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.euro_outlined,
                      size: 12,
                      color: AppColors.getTextSecondaryColor(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${guest.totalSpent.toStringAsFixed(0)}€ total',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Último: ${_getTimeAgo()}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          // Acción
          Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.gray500,
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    Color color;
    switch (tag) {
      case 'VIP':
        color = AppColors.gold;
      case 'Recurrente':
        color = AppColors.info;
      case 'Familia':
        color = AppColors.success;
      case 'Nuevo':
        color = AppColors.warning;
      default:
        color = AppColors.gray500;
    }

    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  String _getInitials() {
    final parts = guest.name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return guest.name.isNotEmpty ? guest.name[0] : '?';
  }

  String _getTimeAgo() {
    final diff = DateTime.now().difference(guest.lastVisit);
    if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return 'hace ${months}m';
    } else if (diff.inDays > 0) {
      return 'hace ${diff.inDays}d';
    } else {
      return 'hoy';
    }
  }
}
