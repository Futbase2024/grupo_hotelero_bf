import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../auth/domain/bloc/auth_bloc.dart';
import '../../../checkins/presentation/screens/checkin_detail_screen.dart';
import '../../../checkins/presentation/widgets/checkin_danger_actions_sheet.dart';
import '../../../domain/bloc/bloc.dart';
import '../../../domain/entities/admin_booking_entity.dart';
import '../../../domain/repositories/admin_panel_repository.dart';
import '../../../shared/widgets/admin_widgets.dart';
import 'checkins/checkin_status_style.dart';
import 'checkins/checkins_filter_dialog.dart';
import 'checkins/checkins_grouped_list.dart';
import 'checkins/checkins_header.dart';
import 'checkins/checkins_search_bar.dart';

/// Tab de check-ins del dashboard de administración
class CheckinsTab extends StatefulWidget {
  const CheckinsTab({super.key});

  @override
  State<CheckinsTab> createState() => _CheckinsTabState();
}

class _CheckinsTabState extends State<CheckinsTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
      // Solo reconstruir cuando cambian datos/filtros relevantes para check-ins.
      // Evita rebuilds de este tab por cambios ajenos (reservas, notificaciones,
      // resumen), que antes reconstruían los 3 tabs del IndexedStack a la vez.
      buildWhen: (prev, curr) =>
          prev.checkins != curr.checkins ||
          prev.checkinsStatusFilter != curr.checkinsStatusFilter ||
          prev.checkinsSearchQuery != curr.checkinsSearchQuery ||
          prev.checkinsDateFilter != curr.checkinsDateFilter ||
          prev.checkinsCustomDateStart != curr.checkinsCustomDateStart ||
          prev.checkinsCustomDateEnd != curr.checkinsCustomDateEnd ||
          prev.checkinsSortOrder != curr.checkinsSortOrder ||
          prev.isLoadingCheckins != curr.isLoadingCheckins ||
          prev.isRefreshingCheckins != curr.isRefreshingCheckins,
      builder: (context, state) {
        return SizedBox.expand(
          child: Column(
            children: [
              CheckinsHeader(
                count: state.filteredCheckins.length,
                statusFilter: state.checkinsStatusFilter,
                isRefreshing: state.isRefreshingCheckins,
                sortOrder: state.checkinsSortOrder,
                onToggleSort: () => _toggleSort(context, state),
              ),
              CheckinsSearchBar(
                controller: _searchController,
                searchQuery: state.checkinsSearchQuery,
                hasActiveFilters: _hasActiveFilters(state),
                onSearchChanged: (value) =>
                    context.read<AdminDashboardBloc>().add(
                          AdminDashboardCheckinsSearchChanged(
                            value.isEmpty ? null : value,
                          ),
                        ),
                onClearSearch: () {
                  _searchController.clear();
                  context.read<AdminDashboardBloc>().add(
                        const AdminDashboardCheckinsSearchChanged(null),
                      );
                },
                onOpenFilters: () => _showFilterDialog(context, state),
              ),
              CheckinsActiveFilterChips(
                dateFilter: state.checkinsDateFilter,
                statusFilter: state.checkinsStatusFilter,
                customStart: state.checkinsCustomDateStart,
                customEnd: state.checkinsCustomDateEnd,
                onRemoveDateFilter: () =>
                    context.read<AdminDashboardBloc>().add(
                          const AdminDashboardCheckinsDateFilterChanged(
                            dateFilter: DateFilter.all,
                          ),
                        ),
                onRemoveStatusFilter: () =>
                    context.read<AdminDashboardBloc>().add(
                          const AdminDashboardCheckinsFilterChanged('submitted'),
                        ),
              ),
              Expanded(child: _CheckinsListSection(state: state)),
            ],
          ),
        );
      },
    );
  }

  bool _hasActiveFilters(AdminDashboardState state) =>
      state.checkinsDateFilter != DateFilter.all ||
      (state.checkinsStatusFilter != null &&
          state.checkinsStatusFilter != 'submitted');

  void _toggleSort(BuildContext context, AdminDashboardState state) {
    final newOrder = state.checkinsSortOrder == SortOrder.descending
        ? SortOrder.ascending
        : SortOrder.descending;
    context
        .read<AdminDashboardBloc>()
        .add(AdminDashboardCheckinsSortChanged(newOrder));
  }

  Future<void> _showFilterDialog(
    BuildContext context,
    AdminDashboardState state,
  ) async {
    final bloc = context.read<AdminDashboardBloc>();

    final result = await CheckinsFilterDialog.show(
      context,
      dateFilter: state.checkinsDateFilter,
      statusFilter: state.checkinsStatusFilter ?? 'submitted',
      customStart: state.checkinsCustomDateStart,
      customEnd: state.checkinsCustomDateEnd,
    );

    if (result == null) return;

    bloc.add(AdminDashboardCheckinsDateFilterChanged(
      dateFilter: result.dateFilter,
      customDateStart: result.customStart,
      customDateEnd: result.customEnd,
    ));
    bloc.add(AdminDashboardCheckinsFilterChanged(result.statusFilter));
  }
}

/// Contenido de la lista según el estado de carga.
class _CheckinsListSection extends StatelessWidget {
  const _CheckinsListSection({required this.state});

  final AdminDashboardState state;

  void _reload(BuildContext context) {
    context
        .read<AdminDashboardBloc>()
        .add(const AdminDashboardCheckinsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingCheckins) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    final checkins = state.filteredCheckins;

    if (checkins.isEmpty) {
      return _CheckinsEmptyView(
        state: state,
        onRefresh: () async => _reload(context),
      );
    }

    return CheckinsGroupedList(
      checkins: checkins,
      onRefresh: () async => _reload(context),
      onTapCheckin: (checkin) => _navigateToDetail(context, checkin),
      onManualCheckin: (checkin) => _showManualCheckinDialog(context, checkin),
      onMoreActions: (checkin) => _showDangerActions(context, checkin),
    );
  }

  Future<void> _navigateToDetail(
    BuildContext context,
    AdminBookingEntity checkin,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CheckinDetailScreen(
          checkinId: checkin.checkinId!,
          bookingCode: checkin.bookingCode,
        ),
      ),
    );

    if (result == true && context.mounted) _reload(context);
  }

  /// Abre la hoja para borrar los datos del check-in o la reserva completa
  Future<void> _showDangerActions(
    BuildContext context,
    AdminBookingEntity checkin,
  ) async {
    final authState = context.read<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;

    final result = await CheckinDangerActionsSheet.show(
      context: context,
      repository: getIt<AdminPanelRepository>(),
      bookingId: checkin.id,
      bookingCode: checkin.bookingCode,
      isAdmin: isAdmin,
    );

    if (result == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == CheckinDangerResult.checkinDeleted
              ? S.of(context).admin_checkin_deleted_success
              : S.of(context).admin_checkin_booking_deleted_success,
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.fixed,
      ),
    );

    _reload(context);
  }

  /// Muestra diálogo de confirmación para check-in manual
  Future<void> _showManualCheckinDialog(
    BuildContext context,
    AdminBookingEntity checkin,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ManualCheckinDialog(checkin: checkin),
    );

    if (confirmed == true && context.mounted) {
      await _executeManualCheckin(context, checkin.id);
    }
  }

  /// Ejecuta la validación manual del check-in
  Future<void> _executeManualCheckin(
    BuildContext context,
    String bookingId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      ),
    );

    try {
      await getIt<AdminPanelRepository>().manualCheckinValidate(bookingId);
      navigator.pop();

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Check-in manual validado correctamente'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.fixed,
        ),
      );

      if (context.mounted) _reload(context);
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.fixed,
        ),
      );
    }
  }
}

class _CheckinsEmptyView extends StatelessWidget {
  const _CheckinsEmptyView({required this.state, required this.onRefresh});

  final AdminDashboardState state;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final hasFilters = state.checkinsDateFilter != DateFilter.all ||
        (state.checkinsSearchQuery?.isNotEmpty ?? false);

    // El estado vacío también admite "tirar para refrescar": con el filtro
    // por defecto ("Por revisar") es lo habitual y el admin necesita poder
    // forzar la recarga sin salir del tab.
    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.getCardColor(context),
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: EmptyStateWidget(
              icon: Icons.how_to_reg_outlined,
              title: 'Sin check-ins',
              subtitle: hasFilters
                  ? 'No hay resultados para los filtros aplicados'
                  : 'Los check-ins aparecerán cuando los huéspedes los envíen',
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualCheckinDialog extends StatelessWidget {
  const _ManualCheckinDialog({required this.checkin});

  final AdminBookingEntity checkin;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.getCardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success),
          const SizedBox(width: 12),
          Text(
            'Check-in Manual',
            style: TextStyle(color: AppColors.getTextPrimaryColor(context)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Validar check-in manualmente?',
            style: TextStyle(
              color: AppColors.getTextSecondaryColor(context),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceColor(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.getBorderColor(context)),
            ),
            child: Column(
              children: [
                _DialogInfoLine(
                  icon: Icons.person,
                  text: checkin.guestFullName.isNotEmpty
                      ? checkin.guestFullName
                      : 'Huésped',
                ),
                const SizedBox(height: 8),
                _DialogInfoLine(
                  icon: Icons.apartment,
                  text: checkin.unitName,
                ),
                const SizedBox(height: 8),
                _DialogInfoLine(
                  icon: Icons.confirmation_number,
                  text: checkin.bookingCode,
                  color: AppColors.gold,
                  isMonospace: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.info),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El huésped podrá acceder a todas las funciones de la app '
                    'sin completar el check-in online.',
                    style: TextStyle(color: AppColors.info, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancelar',
            style: TextStyle(color: AppColors.getTextSecondaryColor(context)),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Validar Check-in'),
        ),
      ],
    );
  }
}

class _DialogInfoLine extends StatelessWidget {
  const _DialogInfoLine({
    required this.icon,
    required this.text,
    this.color,
    this.isMonospace = false,
  });

  final IconData icon;
  final String text;
  final Color? color;
  final bool isMonospace;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.getTextTertiaryColor(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color ?? AppColors.getTextPrimaryColor(context),
              fontSize: 14,
              fontFamily: isMonospace ? 'JetBrains Mono' : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Chips de filtros activos, con opción de quitarlos.
class CheckinsActiveFilterChips extends StatelessWidget {
  const CheckinsActiveFilterChips({
    super.key,
    required this.dateFilter,
    required this.statusFilter,
    required this.onRemoveDateFilter,
    required this.onRemoveStatusFilter,
    this.customStart,
    this.customEnd,
  });

  final DateFilter dateFilter;
  final String? statusFilter;
  final DateTime? customStart;
  final DateTime? customEnd;
  final VoidCallback onRemoveDateFilter;
  final VoidCallback onRemoveStatusFilter;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (dateFilter != DateFilter.all) {
      chips.add(_RemovableChip(
        icon: Icons.calendar_today,
        label: dateFilter.label,
        onRemove: onRemoveDateFilter,
      ));
    }

    if (statusFilter != null &&
        statusFilter != 'all' &&
        statusFilter != 'submitted') {
      chips.add(_RemovableChip(
        icon: Icons.filter_list,
        label: CheckinStatusStyle.fromStatus(statusFilter).label,
        onRemove: onRemoveStatusFilter,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }
}

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({
    required this.icon,
    required this.label,
    required this.onRemove,
  });

  final IconData icon;
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.getGoldWithAlpha(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getGoldWithAlpha(context, alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16, color: AppColors.gold),
          ),
        ],
      ),
    );
  }
}
