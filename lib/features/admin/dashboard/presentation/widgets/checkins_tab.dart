import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
            onTap: checkin.checkinId != null
                ? () => _navigateToDetail(context, checkin.checkinId!, checkin.bookingCode)
                : null,
            onValidate: checkin.checkinStatus == 'submitted' && checkin.checkinId != null
                ? () => _validateCheckin(context, checkin.checkinId!)
                : null,
            onReject: checkin.checkinStatus == 'submitted' && checkin.checkinId != null
                ? () => _showRejectDialog(context, checkin.checkinId!)
                : null,
          );
        },
      ),
    );
  }

  void _navigateToDetail(BuildContext context, String checkinId, String bookingCode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CheckinDetailScreen(
          checkinId: checkinId,
          bookingCode: bookingCode,
        ),
      ),
    );
  }

  Future<void> _validateCheckin(BuildContext context, String checkinId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Validar Check-in', style: TextStyle(color: AppColors.white)),
        content: const Text(
          '¿Confirmar que el check-in es correcto? La reserva pasará a estado "Checked In".',
          style: TextStyle(color: AppColors.gray300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.gray400)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Validar', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await Supabase.instance.client.rpc(
          'validate_checkin',
          params: {'p_checkin_id': checkinId},
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check-in validado correctamente'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.fixed,
            ),
          );
          context.read<AdminDashboardBloc>().add(
            const AdminDashboardCheckinsLoadRequested(),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.fixed,
            ),
          );
        }
      }
    }
  }

  Future<void> _showRejectDialog(BuildContext context, String checkinId) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Rechazar Check-in', style: TextStyle(color: AppColors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Indica el motivo del rechazo:',
              style: TextStyle(color: AppColors.gray300),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Ej: Documento ilegible',
                hintStyle: const TextStyle(color: AppColors.gray500),
                filled: true,
                fillColor: AppColors.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.gray400)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Rechazar', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await Supabase.instance.client.rpc(
          'reject_checkin',
          params: {
            'p_checkin_id': checkinId,
            'p_reason': reasonController.text.trim().isEmpty
                ? 'Sin motivo especificado'
                : reasonController.text.trim(),
          },
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check-in rechazado'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.fixed,
            ),
          );
          context.read<AdminDashboardBloc>().add(
            const AdminDashboardCheckinsLoadRequested(),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.fixed,
            ),
          );
        }
      }
    }
  }
}

class _CheckinListTile extends StatelessWidget {
  const _CheckinListTile({
    required this.checkin,
    this.onTap,
    this.onValidate,
    this.onReject,
  });

  final dynamic checkin;
  final VoidCallback? onTap;
  final VoidCallback? onValidate;
  final VoidCallback? onReject;

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
    final isSubmitted = checkin.checkinStatus == 'submitted';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
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

                        // Línea 2: Unit name + booking code
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                checkin.unitName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w300,
                                  color: AppColors.getTextSecondaryColor(context),
                                ),
                              ),
                            ),
                            Text(
                              checkin.bookingCode,
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
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

                        // Botones de acción para check-ins pendientes
                        if (isSubmitted && (onValidate != null || onReject != null)) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (onValidate != null)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: onValidate,
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Validar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: AppColors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                              if (onValidate != null && onReject != null)
                                const SizedBox(width: 8),
                              if (onReject != null)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: onReject,
                                    icon: const Icon(Icons.close, size: 16),
                                    label: const Text('Rechazar'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(color: AppColors.error),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
