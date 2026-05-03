import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/enums/enums.dart';
import '../../../../../core/di/injection.dart';
import '../../../bookings/data/services/bookings_pdf_service.dart';
import '../../../bookings/presentation/sheets/create_booking_bottom_sheet.dart';
import '../../../domain/bloc/bloc.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../../domain/repositories/admin_panel_repository.dart';
import '../../../shared/widgets/admin_widgets.dart';
import '../../../../guest/chat/domain/repositories/chat_repository.dart';

/// Tab de reservas del dashboard de administración
class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
      builder: (context, state) {
        return SizedBox.expand(
          child: Column(
            children: [
              _buildHeader(context, state),
              _buildSearchAndFilterBar(context, state),
              _buildActiveFilterChips(context, state),
              Expanded(
                child: _buildBookingsList(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, AdminDashboardState state) {
    final count = state.filteredBookings.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Text(
            'Reservas',
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
          const Spacer(),
          _SortButton(
            sortOrder: state.bookingsSortOrder,
            onPressed: () {
              final newOrder = state.bookingsSortOrder == SortOrder.descending
                  ? SortOrder.ascending
                  : SortOrder.descending;
              context.read<AdminDashboardBloc>().add(
                    AdminDashboardBookingsSortChanged(newOrder),
                  );
            },
          ),
          IconButton(
            onPressed: count > 0 ? () => _printBookings(context, state) : null,
            icon: const Icon(Icons.print, size: 22),
            color: AppColors.gray400,
            disabledColor: AppColors.gray600,
            tooltip: 'Imprimir reservas',
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
    final hasActiveFilters =
        state.bookingsDateFilter != DateFilter.all ||
            (state.bookingsStatusFilter != null &&
                state.bookingsStatusFilter != 'all');

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
                      AdminDashboardBookingsSearchChanged(
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
                suffixIcon: state.bookingsSearchQuery != null &&
                        state.bookingsSearchQuery!.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.gray500, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          context.read<AdminDashboardBloc>().add(
                                const AdminDashboardBookingsSearchChanged(
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
                  foregroundColor: hasActiveFilters
                      ? AppColors.darkBackground
                      : AppColors.gray400,
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
    if (state.bookingsDateFilter != DateFilter.all) {
      final label =
          state.bookingsDateFilter == DateFilter.customRange &&
                  state.bookingsCustomDateStart != null &&
                  state.bookingsCustomDateEnd != null
              ? _formatShortRange(
                  state.bookingsCustomDateStart!, state.bookingsCustomDateEnd!)
              : state.bookingsDateFilter.label;

      chips.add(_buildRemovableChip(
        icon: Icons.calendar_today,
        label: label,
        onRemove: () => context.read<AdminDashboardBloc>().add(
              const AdminDashboardBookingsDateFilterChanged(
                dateFilter: DateFilter.all,
              ),
            ),
      ));
    }

    // Status filter chip (only if non-default)
    if (state.bookingsStatusFilter != null &&
        state.bookingsStatusFilter != 'all') {
      final statusLabels = {
        'confirmed': 'Confirmadas',
        'active': 'Activas',
        'in_house': 'En casa',
        'checked_out': 'Finalizadas',
        'cancelled': 'Canceladas',
      };
      chips.add(_buildRemovableChip(
        icon: Icons.filter_list,
        label: statusLabels[state.bookingsStatusFilter] ??
            state.bookingsStatusFilter!,
        onRemove: () => context.read<AdminDashboardBloc>().add(
              const AdminDashboardBookingsFilterChanged(null),
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
            child: const Icon(Icons.close, size: 16, color: AppColors.gold),
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
    var selectedDateFilter = currentState.bookingsDateFilter;
    var selectedStatusFilter = currentState.bookingsStatusFilter ?? 'all';
    var customStart = currentState.bookingsCustomDateStart;
    var customEnd = currentState.bookingsCustomDateEnd;

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
                                  selectedDateFilter = DateFilter.customRange;
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

                    // Custom range label
                    if (selectedDateFilter == DateFilter.customRange &&
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
                        ('all', 'Todas', null),
                        ('confirmed', 'Confirmadas', const Color(0xFF27AE60)),
                        ('active', 'Activas', const Color(0xFF2980B9)),
                        ('in_house', 'En casa', const Color(0xFFE5C962)),
                        ('checked_out', 'Finalizadas', const Color(0xFF6B7280)),
                        ('cancelled', 'Canceladas', const Color(0xFFC0392B)),
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
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      selectedDateFilter = DateFilter.all;
                      selectedStatusFilter = 'all';
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
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: AppColors.gray400),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final bloc = context.read<AdminDashboardBloc>();

                    bloc.add(AdminDashboardBookingsDateFilterChanged(
                      dateFilter: selectedDateFilter,
                      customDateStart: customStart,
                      customDateEnd: customEnd,
                    ));

                    bloc.add(AdminDashboardBookingsFilterChanged(
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
      lastDate: DateTime(now.year + 2),
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

  String _formatShortRange(DateTime start, DateTime end) {
    final fmt = DateFormat('dd/MM');
    return '${fmt.format(start)} - ${fmt.format(end)}';
  }

  // ─── Bookings list ─────────────────────────────────────────────────────

  Widget _buildBookingsList(BuildContext context, AdminDashboardState state) {
    if (state.isLoadingBookings) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    final bookings = state.filteredBookings;

    if (bookings.isEmpty) {
      final hasFilters = state.bookingsDateFilter != DateFilter.all ||
          (state.bookingsSearchQuery != null &&
              state.bookingsSearchQuery!.isNotEmpty);

      return EmptyStateWidget(
        icon: Icons.calendar_today_outlined,
        title: 'Sin reservas',
        subtitle: hasFilters
            ? 'No hay resultados para los filtros aplicados'
            : 'Crea la primera reserva con el botón +',
        actionLabel: hasFilters ? null : 'Crear reserva',
        onAction: hasFilters
            ? null
            : () {
                CreateBookingBottomSheet.show(
                  context,
                  repository: getIt<AdminPanelRepository>(),
                  dashboardBloc: context.read<AdminDashboardBloc>(),
                );
              },
      );
    }

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.darkSurface,
      onRefresh: () async {
        context.read<AdminDashboardBloc>().add(
              const AdminDashboardBookingsLoadRequested(),
            );
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return BookingListTile(
            unitName: booking.unitName,
            numGuests: booking.numGuests,
            checkInDate: booking.checkInDate,
            checkOutDate: booking.checkOutDate,
            status: _mapStatus(booking.status),
            bookingCode: booking.bookingCode,
            guestName: booking.guestFullName,
            docsPending: booking.docsPending ?? 0,
            totalUnits: booking.totalUnits,
            canChat: booking.primaryGuestUserId != null &&
                booking.primaryGuestUserId!.isNotEmpty,
            onTap: () {
              context.push(
                AppRoutes.adminBookingDetail
                    .replaceFirst(':bookingId', booking.id),
              );
            },
            onChatTap: booking.primaryGuestUserId != null &&
                    booking.primaryGuestUserId!.isNotEmpty
                ? () => _startConversationWithGuest(context, booking)
                : null,
          );
        },
      ),
    );
  }

  /// Inicia o abre una conversación con el huésped de la reserva
  Future<void> _startConversationWithGuest(
    BuildContext context,
    AdminBookingEntity booking,
  ) async {
    final guestUserId = booking.primaryGuestUserId;

    if (guestUserId == null || guestUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Este huésped no tiene cuenta de usuario asociada'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final propertyId = booking.propertyId;

    if (propertyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La reserva no tiene propiedad asociada'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );

      final chatRepository = getIt<ChatRepository>();
      final conversation = await chatRepository.getOrCreateConversation(
        propertyId: propertyId,
        bookingId: booking.id,
        guestUserId: guestUserId,
        guestName: booking.guestFullName,
      );

      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        context.go('/admin/chat/${conversation.id}');
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir chat: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Genera e imprime el PDF de reservas filtradas
  Future<void> _printBookings(
    BuildContext context,
    AdminDashboardState state,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );

      final pdfService = BookingsPdfService();
      await pdfService.printBookingsReport(
        bookings: state.filteredBookings,
        dateFilter: state.bookingsDateFilter,
        customDateStart: state.bookingsCustomDateStart,
        customDateEnd: state.bookingsCustomDateEnd,
        statusFilter: state.bookingsStatusFilter,
      );

      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  BookingStatus _mapStatus(String status) {
    return switch (status) {
      'created' => BookingStatus.created,
      'confirmed' => BookingStatus.confirmed,
      'active' => BookingStatus.active,
      'in_house' => BookingStatus.inHouse,
      'checked_in' => BookingStatus.active,
      'checked_out' => BookingStatus.checkedOut,
      'closed' => BookingStatus.closed,
      'cancelled' => BookingStatus.cancelled,
      _ => BookingStatus.created,
    };
  }
}

/// Botón de ordenación por fecha (ascendente/descendente)
class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.sortOrder,
    required this.onPressed,
  });

  final SortOrder sortOrder;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDesc = sortOrder == SortOrder.descending;
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        isDesc ? Icons.arrow_downward : Icons.arrow_upward,
        size: 20,
      ),
      color: AppColors.gold,
      tooltip: isDesc ? 'Más recientes primero' : 'Más antiguos primero',
    );
  }
}
