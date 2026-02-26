import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/bloc/bloc.dart';
import '../../../shared/widgets/admin_widgets.dart';

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
              (state.checkinsStatusFilter == null && value == 'all');

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
                        value == 'all' ? null : value,
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
            onTap: () {
              // TODO: Navigate to booking detail
            },
          );
        },
      ),
    );
  }
}

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
      default:
        return 'Sin empezar';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(checkin.checkinStatus);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Indicador de color según status (3px de ancho)
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),

              // Contenido
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Línea 1: Guest name + status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              checkin.guestFullName.isNotEmpty
                                  ? checkin.guestFullName
                                  : 'Huésped',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getStatusText(checkin.checkinStatus),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Línea 2: Unit name
                      Text(
                        checkin.unitName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: AppColors.getTextSecondaryColor(context),
                        ),
                      ),

                      // Línea 3: Docs pendientes si aplica
                      if (checkin.hasDocsPending) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${checkin.docsPending} documentos pendientes',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Código BF + flecha
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      checkin.bookingCode,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.getTextSecondaryColor(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
