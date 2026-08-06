import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../auth/domain/bloc/auth_bloc.dart';
import '../../../domain/bloc/bloc.dart';
import '../../../domain/repositories/admin_panel_repository.dart';
import '../../../shared/widgets/admin_widgets.dart';
import '../../../checkins/presentation/screens/checkin_detail_screen.dart';
import '../../../checkins/presentation/widgets/checkin_danger_actions_sheet.dart';

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
              _buildHeader(context, state),
              _buildSearchAndFilterBar(context, state),
              _buildActiveFilterChips(context, state),
              Expanded(
                child: _buildCheckinsList(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, AdminDashboardState state) {
    final count = state.filteredCheckins.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Text(
            'Check-ins',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.goldWithAlpha20,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.gold,
              ),
            ),
          ),
          // Indicador discreto de refresco en segundo plano: la lista actual
          // permanece visible mientras llegan los datos nuevos.
          if (state.isRefreshingCheckins) ...[
            const SizedBox(width: 10),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold,
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            onPressed: () {
              final newOrder = state.checkinsSortOrder == SortOrder.descending
                  ? SortOrder.ascending
                  : SortOrder.descending;
              context.read<AdminDashboardBloc>().add(
                    AdminDashboardCheckinsSortChanged(newOrder),
                  );
            },
            icon: Icon(
              state.checkinsSortOrder == SortOrder.descending
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              size: 20,
            ),
            color: AppColors.gold,
            tooltip: state.checkinsSortOrder == SortOrder.descending
                ? 'Más recientes primero'
                : 'Más antiguos primero',
          ),
        ],
      ),
    );
  }

  // ─── Search + Filter button row ────────────────────────────────────────

  Widget _buildSearchAndFilterBar(
    BuildContext context,
    AdminDashboardState state,
  ) {
    final hasActiveFilters = state.checkinsDateFilter != DateFilter.all ||
        (state.checkinsStatusFilter != null && state.checkinsStatusFilter != 'submitted');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          // Search bar (flex: 2)
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                context.read<AdminDashboardBloc>().add(
                      AdminDashboardCheckinsSearchChanged(
                        value.isEmpty ? null : value,
                      ),
                    );
              },
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, código o unidad...',
                hintStyle: const TextStyle(color: AppColors.gray500),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.gray500),
                suffixIcon: state.checkinsSearchQuery != null &&
                        state.checkinsSearchQuery!.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.gray500, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          context.read<AdminDashboardBloc>().add(
                                const AdminDashboardCheckinsSearchChanged(
                                    null),
                              );
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.darkSurface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gold),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Filter button
          IntrinsicWidth(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
              onPressed: () => _showFilterDialog(context, state),
              icon: Badge(
                isLabelVisible: hasActiveFilters,
                child: const Icon(Icons.tune, size: 20),
              ),
              label: const Text('Filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    hasActiveFilters ? AppColors.gold : AppColors.darkSurface,
                foregroundColor:
                    hasActiveFilters ? AppColors.darkBackground : AppColors.gray400,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: hasActiveFilters
                        ? AppColors.gold
                        : AppColors.darkBorder,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }

  // ─── Active filter chips (removable) ───────────────────────────────────

  Widget _buildActiveFilterChips(
    BuildContext context,
    AdminDashboardState state,
  ) {
    final chips = <Widget>[];

    // Date filter chip
    if (state.checkinsDateFilter != DateFilter.all) {
      final label = state.checkinsDateFilter == DateFilter.customRange &&
              state.checkinsCustomDateStart != null &&
              state.checkinsCustomDateEnd != null
          ? _formatShortRange(
              state.checkinsCustomDateStart!, state.checkinsCustomDateEnd!)
          : state.checkinsDateFilter.label;

      chips.add(_buildRemovableChip(
        icon: Icons.calendar_today,
        label: label,
        onRemove: () => context.read<AdminDashboardBloc>().add(
              const AdminDashboardCheckinsDateFilterChanged(
                dateFilter: DateFilter.all,
              ),
            ),
      ));
    }

    // Status filter chip (only show if not default)
    if (state.checkinsStatusFilter != null &&
        state.checkinsStatusFilter != 'all' &&
        state.checkinsStatusFilter != 'submitted') {
      final statusLabels = {
        'draft': 'Sin empezar',
        'submitted': 'Por revisar',
        'validated': 'Validados',
        'rejected': 'Rechazados',
        'cancelled': 'Cancelados',
      };
      chips.add(_buildRemovableChip(
        icon: Icons.filter_list,
        label: statusLabels[state.checkinsStatusFilter] ?? state.checkinsStatusFilter!,
        onRemove: () => context.read<AdminDashboardBloc>().add(
              const AdminDashboardCheckinsFilterChanged('submitted'),
            ),
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: chips,
      ),
    );
  }

  Widget _buildRemovableChip({
    required IconData icon,
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.goldWithAlpha20,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.goldWithAlpha30),
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
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Professional Filter Dialog ────────────────────────────────────────

  Future<void> _showFilterDialog(
    BuildContext context,
    AdminDashboardState currentState,
  ) async {
    // Local state for the dialog
    var selectedDateFilter = currentState.checkinsDateFilter;
    var selectedStatusFilter = currentState.checkinsStatusFilter ?? 'submitted';
    var customStart = currentState.checkinsCustomDateStart;
    var customEnd = currentState.checkinsCustomDateEnd;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.darkSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.goldWithAlpha20,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tune,
                      color: AppColors.gold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Filtros',
                    style: TextStyle(
                      color: AppColors.white,
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
                    // ── Sección: Período ──
                    _buildSectionTitle('Período'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: DateFilter.values.map((filter) {
                        final isSelected = selectedDateFilter == filter;
                        return ChoiceChip(
                          label: Text(filter.label),
                          selected: isSelected,
                          onSelected: (_) async {
                            if (filter == DateFilter.customRange) {
                              final picked = await _pickDateRange(
                                context,
                                customStart,
                                customEnd,
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  selectedDateFilter =
                                      DateFilter.customRange;
                                  customStart = picked.start;
                                  customEnd = picked.end;
                                });
                              }
                            } else {
                              setDialogState(() {
                                selectedDateFilter = filter;
                                customStart = null;
                                customEnd = null;
                              });
                            }
                          },
                          backgroundColor: AppColors.darkBackground,
                          selectedColor: AppColors.goldWithAlpha20,
                          checkmarkColor: AppColors.gold,
                          labelStyle: TextStyle(
                            color:
                                isSelected ? AppColors.gold : AppColors.gray400,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 13,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.gold
                                : AppColors.darkBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }).toList(),
                    ),

                    // Custom range label
                    if (selectedDateFilter ==
                            DateFilter.customRange &&
                        customStart != null &&
                        customEnd != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.darkBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.goldWithAlpha30,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.date_range,
                                color: AppColors.gold, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              '${DateFormat('dd/MM/yyyy').format(customStart!)}  →  ${DateFormat('dd/MM/yyyy').format(customEnd!)}',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () async {
                                final picked = await _pickDateRange(
                                  context,
                                  customStart,
                                  customEnd,
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    customStart = picked.start;
                                    customEnd = picked.end;
                                  });
                                }
                              },
                              child: const Icon(
                                Icons.edit_calendar,
                                color: AppColors.gold,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Sección: Estado ──
                    _buildSectionTitle('Estado'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ('all', 'Todos', null),
                        ('draft', 'Sin empezar', const Color(0xFF6B7280)),
                        ('submitted', 'Por revisar', const Color(0xFFE67E22)),
                        ('validated', 'Validados', const Color(0xFF27AE60)),
                        ('rejected', 'Rechazados', const Color(0xFFC0392B)),
                        ('cancelled', 'Cancelados', const Color(0xFF7F8C8D)),
                      ].map((entry) {
                        final (value, label, accentColor) = entry;
                        final isSelected = selectedStatusFilter == value;
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
                          selected: isSelected,
                          onSelected: (_) {
                            setDialogState(() {
                              selectedStatusFilter = value;
                            });
                          },
                          backgroundColor: AppColors.darkBackground,
                          selectedColor: AppColors.goldWithAlpha20,
                          checkmarkColor: AppColors.gold,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.gold
                                : AppColors.gray400,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 13,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.gold
                                : AppColors.darkBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                // Clear all
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      selectedDateFilter = DateFilter.all;
                      selectedStatusFilter = 'submitted';
                      customStart = null;
                      customEnd = null;
                    });
                  },
                  child: const Text(
                    'Limpiar todo',
                    style: TextStyle(
                      color: AppColors.gray400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Cancel
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: AppColors.gray400),
                  ),
                ),

                // Apply
                ElevatedButton(
                  onPressed: () {
                    final bloc = context.read<AdminDashboardBloc>();

                    bloc.add(AdminDashboardCheckinsDateFilterChanged(
                      dateFilter: selectedDateFilter,
                      customDateStart: customStart,
                      customDateEnd: customEnd,
                    ));

                    bloc.add(AdminDashboardCheckinsFilterChanged(
                      selectedStatusFilter,
                    ));

                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.darkBackground,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: const Text(
                    'Aplicar',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.gray500,
        letterSpacing: 1.2,
      ),
    );
  }

  Future<DateTimeRange?> _pickDateRange(
    BuildContext context,
    DateTime? currentStart,
    DateTime? currentEnd,
  ) async {
    final now = DateTime.now();

    return showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: currentStart != null && currentEnd != null
          ? DateTimeRange(start: currentStart, end: currentEnd)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: AppColors.darkBackground,
              surface: AppColors.darkSurface,
              onSurface: AppColors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.darkSurface,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  // ─── Check-ins list ────────────────────────────────────────────────────

  Widget _buildCheckinsList(BuildContext context, AdminDashboardState state) {
    if (state.isLoadingCheckins) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    final checkins = state.filteredCheckins;

    if (checkins.isEmpty) {
      // El estado vacío también admite "tirar para refrescar": con el filtro
      // por defecto ("Por revisar") es lo habitual y el admin necesita poder
      // forzar la recarga sin salir del tab.
      return RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.darkSurface,
        onRefresh: () async {
          context.read<AdminDashboardBloc>().add(
                const AdminDashboardCheckinsLoadRequested(),
              );
        },
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: EmptyStateWidget(
                icon: Icons.how_to_reg_outlined,
                title: 'Sin check-ins',
                subtitle: state.checkinsDateFilter != DateFilter.all ||
                        (state.checkinsSearchQuery != null &&
                            state.checkinsSearchQuery!.isNotEmpty)
                    ? 'No hay resultados para los filtros aplicados'
                    : 'Los check-ins aparecerán cuando los huéspedes los envíen',
              ),
            ),
          ),
        ),
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
          final canDoManual = checkin.checkinId == null ||
              ['not_started', 'draft', 'in_progress', null]
                  .contains(checkin.checkinStatus);

          return _CheckinListTile(
            checkin: checkin,
            onTap: checkin.checkinId != null
                ? () => _navigateToDetail(
                    context, checkin.checkinId!, checkin.bookingCode)
                : null,
            onManualCheckin: canDoManual
                ? () => _showManualCheckinDialog(context, checkin)
                : null,
            onMoreActions: () => _showDangerActions(context, checkin),
          );
        },
      ),
    );
  }

  String _formatShortRange(DateTime start, DateTime end) {
    final fmt = DateFormat('dd/MM');
    return '${fmt.format(start)} - ${fmt.format(end)}';
  }

  Future<void> _navigateToDetail(
    BuildContext context,
    String checkinId,
    String bookingCode,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CheckinDetailScreen(
          checkinId: checkinId,
          bookingCode: bookingCode,
        ),
      ),
    );

    if (result == true && context.mounted) {
      context.read<AdminDashboardBloc>().add(
            const AdminDashboardCheckinsLoadRequested(),
          );
    }
  }

  /// Abre la hoja para borrar los datos del check-in o la reserva completa
  Future<void> _showDangerActions(BuildContext context, dynamic checkin) async {
    final authState = context.read<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;

    final result = await CheckinDangerActionsSheet.show(
      context: context,
      repository: getIt<AdminPanelRepository>(),
      bookingId: checkin.id as String,
      bookingCode: checkin.bookingCode as String,
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

    context.read<AdminDashboardBloc>().add(
          const AdminDashboardCheckinsLoadRequested(),
        );
  }

  /// Muestra diálogo de confirmación para check-in manual
  Future<void> _showManualCheckinDialog(
    BuildContext context,
    dynamic checkin,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success),
            const SizedBox(width: 12),
            const Text(
              'Check-in Manual',
              style: TextStyle(color: AppColors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Validar check-in manualmente?',
              style: TextStyle(color: AppColors.gray300, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: AppColors.gray500),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          checkin.guestFullName ?? 'Huésped',
                          style: const TextStyle(
                              color: AppColors.white, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.apartment,
                          size: 16, color: AppColors.gray500),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          checkin.unitName ?? 'Unidad',
                          style: TextStyle(
                              color: AppColors.gray300, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.confirmation_number,
                          size: 16, color: AppColors.gold),
                      const SizedBox(width: 8),
                      Text(
                        checkin.bookingCode ?? '',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 13,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El huésped podrá acceder a todas las funciones de la app sin completar el check-in online.',
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
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.gray400),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Validar Check-in'),
          ),
        ],
      ),
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
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );

      final repository = getIt<AdminPanelRepository>();
      await repository.manualCheckinValidate(bookingId);

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in manual validado correctamente'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.fixed,
          ),
        );

        context.read<AdminDashboardBloc>().add(
              const AdminDashboardCheckinsLoadRequested(),
            );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);

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

// ═══════════════════════════════════════════════════════════════════════════
// Check-in card
// ═══════════════════════════════════════════════════════════════════════════

class _CheckinListTile extends StatelessWidget {
  const _CheckinListTile({
    required this.checkin,
    this.onTap,
    this.onManualCheckin,
    this.onMoreActions,
  });

  final dynamic checkin;
  final VoidCallback? onTap;
  final VoidCallback? onManualCheckin;
  final VoidCallback? onMoreActions;

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

  bool _canDoManualCheckin(dynamic checkin) {
    if (checkin.checkinId == null) return true;
    final status = checkin.checkinStatus;
    if (status == null ||
        status == 'not_started' ||
        status == 'draft' ||
        status == 'in_progress') {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(checkin.checkinStatus);
    final statusText = _getStatusText(checkin.checkinStatus);
    final statusIcon = _getStatusIcon(checkin.checkinStatus);
    final guestName =
        checkin.guestFullName.isNotEmpty ? checkin.guestFullName : 'Huésped';

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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(statusIcon,
                            size: 20, color: AppColors.white),
                      ),
                      const SizedBox(width: 12),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
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
                      if (onMoreActions != null)
                        IconButton(
                          icon: const Icon(Icons.more_vert,
                              color: AppColors.darkBackground),
                          tooltip: S.of(context).admin_checkin_more_actions,
                          visualDensity: VisualDensity.compact,
                          onPressed: onMoreActions,
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _InfoRow(
                              icon: Icons.apartment_outlined,
                              label: checkin.hasMultipleUnits
                                  ? 'Unidades'
                                  : 'Unidad',
                              value: checkin.hasMultipleUnits &&
                                      checkin.units.isNotEmpty
                                  ? checkin.units
                                      .map((u) => u.name)
                                      .join(' · ')
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
                      if (checkin.hasDocsPending) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  AppColors.warning.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  size: 18, color: AppColors.warning),
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
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_canDoManualCheckin(checkin) &&
                          onManualCheckin != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onManualCheckin,
                            icon: const Icon(
                                Icons.check_circle_outline,
                                size: 18),
                            label: const Text('Check-in Manual'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: AppColors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        )
                      else if (checkin.checkinId != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ver detalle',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color:
                                    AppColors.gold.withValues(alpha: 0.8),
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

// ═══════════════════════════════════════════════════════════════════════════
// Info row widget
// ═══════════════════════════════════════════════════════════════════════════

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
        Icon(icon, size: 16, color: AppColors.gray500),
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
