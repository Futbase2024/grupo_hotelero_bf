import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/bloc/bloc.dart';
import '../../../shared/widgets/admin_widgets.dart';
import '../../../checkins/presentation/screens/checkin_detail_screen.dart';

/// Tab de check-ins del dashboard de administración
class CheckinsTab extends StatelessWidget {
  const CheckinsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
      builder: (context, state) {
        return Column(
          children: [
            // Header
            _buildHeader(context),

            // Filter chips
            _buildFilterChips(context, state),

            // Check-ins list
            Expanded(
              child: _buildCheckinsList(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            'Check-ins',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, AdminDashboardState state) {
    final filters = [
      ('all', 'Todos', null),
      ('draft', 'Sin empezar', AppColors.gray500),
      ('submitted', 'Por revisar', const Color(0xFFE67E22)),
      ('validated', 'Validados', const Color(0xFF27AE60)),
      ('rejected', 'Rechazados', const Color(0xFFC0392B)),
      ('cancelled', 'Cancelados', const Color(0xFF7F8C8D)),
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final (value, label, accentColor) = filters[index];
          final isSelected = state.checkinsStatusFilter == value ||
              (state.checkinsStatusFilter == 'all' && value == 'all');

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
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
              selected: isSelected,
              onSelected: (selected) {
                context.read<AdminDashboardBloc>().add(
                      AdminDashboardCheckinsFilterChanged(
                        value == 'all' ? 'all' : value,
                      ),
                    );
              },
              backgroundColor: AppColors.darkSurface,
              selectedColor: AppColors.goldWithAlpha20,
              checkmarkColor: AppColors.gold,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.gold : AppColors.gray400,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.gold : AppColors.darkBorder,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCheckinsList(BuildContext context, AdminDashboardState state) {
    if (state.isLoadingCheckins) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    final checkins = state.filteredCheckins;

    if (checkins.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.how_to_reg_outlined,
        title: 'Sin check-ins',
        subtitle: 'Los check-ins aparecerán cuando los huéspedes los envíen',
      );
    }

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.darkSurface,
      onRefresh: () async {
        context.read<AdminDashboardBloc>().add(
              const AdminDashboardCheckinsLoadRequested(),
            );
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: checkins.length,
        itemBuilder: (context, index) {
          final checkin = checkins[index];
          return _CheckinListTile(
            checkin: checkin,
            onTap: checkin.checkinId != null
                ? () => _navigateToDetail(context, checkin.checkinId!, checkin.bookingCode)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _navigateToDetail(BuildContext context, String checkinId, String bookingCode) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CheckinDetailScreen(
          checkinId: checkinId,
          bookingCode: bookingCode,
        ),
      ),
    );

    // Si se realizó una acción (validar/rechazar/cancelar), recargar la lista
    if (result == true && context.mounted) {
      context.read<AdminDashboardBloc>().add(
            const AdminDashboardCheckinsLoadRequested(),
          );
    }
  }
}

/// Tarjeta profesional de check-in con diseño mejorado
class _CheckinListTile extends StatelessWidget {
  const _CheckinListTile({
    required this.checkin,
    this.onTap,
  });

  final dynamic checkin;
  final VoidCallback? onTap;

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'submitted':
        return const Color(0xFFE67E22);
      case 'validated':
        return const Color(0xFF27AE60);
      case 'rejected':
        return const Color(0xFFC0392B);
      case 'cancelled':
        return const Color(0xFF7F8C8D);
      default:
        return AppColors.gray500;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'submitted':
        return 'Por revisar';
      case 'validated':
        return 'Validado';
      case 'rejected':
        return 'Rechazado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Sin empezar';
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'submitted':
        return Icons.pending_actions_outlined;
      case 'validated':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'cancelled':
        return Icons.block;
      default:
        return Icons.edit_document;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(checkin.checkinStatus);
    final statusText = _getStatusText(checkin.checkinStatus);
    final statusIcon = _getStatusIcon(checkin.checkinStatus);
    final guestName = checkin.guestFullName.isNotEmpty ? checkin.guestFullName : 'Huésped';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackWithAlpha20,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header con estilo gold
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icono de estado con fondo de color
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          statusIcon,
                          size: 20,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nombre del huésped
                      Expanded(
                        child: Text(
                          guestName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBackground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Badge de estado con fondo de color
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Cuerpo con información
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Fila 1: Unidad y Código
                      Row(
                        children: [
                          Expanded(
                            child: _InfoRow(
                              icon: Icons.apartment_outlined,
                              label: checkin.hasMultipleUnits ? 'Unidades' : 'Unidad',
                              value: checkin.hasMultipleUnits && checkin.units.isNotEmpty
                                  ? checkin.units.map((u) => u.name).join(' · ')
                                  : checkin.hasMultipleUnits
                                      ? '${checkin.totalUnits} habitaciones'
                                      : checkin.unitName,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _InfoRow(
                              icon: Icons.confirmation_number_outlined,
                              label: 'Reserva',
                              value: checkin.bookingCode,
                              isMonospace: true,
                              valueColor: AppColors.gold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Fila 2: Fechas
                      Row(
                        children: [
                          Expanded(
                            child: _InfoRow(
                              icon: Icons.login,
                              label: 'Check-in',
                              value: _formatDate(checkin.checkInDate),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _InfoRow(
                              icon: Icons.logout,
                              label: 'Check-out',
                              value: _formatDate(checkin.checkOutDate),
                            ),
                          ),
                        ],
                      ),

                      // Alerta de documentos pendientes
                      if (checkin.hasDocsPending) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${checkin.docsPending} documentos pendientes',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Footer con indicador de acción
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Ver detalle',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gold.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: AppColors.gold.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

/// Fila de información con icono, etiqueta y valor
class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
        Icon(
          icon,
          size: 16,
          color: AppColors.gray500,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: AppColors.gray500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: isMonospace ? 'JetBrains Mono' : null,
                  color: valueColor ?? AppColors.white,
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
