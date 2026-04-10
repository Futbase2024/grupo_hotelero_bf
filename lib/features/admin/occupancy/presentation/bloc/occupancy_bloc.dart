import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/enums/booking_status.dart';
import '../../../../../features/admin/domain/repositories/admin_panel_repository.dart';
import '../../../../../features/admin/domain/entities/admin_entities.dart';
import '../../domain/entities/occupancy_stats_entity.dart';
import 'occupancy_event.dart';
import 'occupancy_state.dart';

class OccupancyBloc extends Bloc<OccupancyEvent, OccupancyState> {
  OccupancyBloc({required AdminPanelRepository repository})
      : _repository = repository,
        super(const OccupancyState()) {
    on<OccupancyLoadRequested>(_onLoad);
    on<OccupancyRefreshRequested>(_onRefresh);
    on<OccupancyPeriodChanged>(_onPeriodChanged);
  }

  final AdminPanelRepository _repository;

  Future<void> _onLoad(
    OccupancyLoadRequested event,
    Emitter<OccupancyState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    await _loadStats(emit);
  }

  Future<void> _onRefresh(
    OccupancyRefreshRequested event,
    Emitter<OccupancyState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, clearError: true));
    await _loadStats(emit);
  }

  Future<void> _onPeriodChanged(
    OccupancyPeriodChanged event,
    Emitter<OccupancyState> emit,
  ) async {
    emit(state.copyWith(selectedPeriod: event.period));
  }

  Future<void> _loadStats(Emitter<OccupancyState> emit) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      // Cargar en paralelo: todas las reservas (sin filtro de fecha para no
      // perder reservas activas con check-in anterior al año en curso) y el
      // resumen para obtener el total de unidades coherente con el dashboard.
      final results = await Future.wait([
        _repository.listBookings(),
        _repository.getDashboardSummary(),
      ]);

      final bookings = results[0] as List<AdminBookingEntity>;
      final summary = results[1] as DashboardSummaryEntity;
      final totalUnits = summary.totalUnits > 0 ? summary.totalUnits : 1;

      // ── Hoy: 1 día ────────────────────────────────────────────────────────
      // Capacidad = 14 × 1
      final todayStats = _calculateStats(
        period: OccupancyPeriod.today,
        bookings: bookings,
        periodStart: today,
        periodEnd: tomorrow,
        totalUnits: totalUnits,
        today: today,
      );

      // ── Semana: últimos 7 días completos ──────────────────────────────────
      // Capacidad = 14 × 7
      final weekStart = today.subtract(const Duration(days: 6));
      final weekStats = _calculateStats(
        period: OccupancyPeriod.week,
        bookings: bookings,
        periodStart: weekStart,
        periodEnd: tomorrow,
        totalUnits: totalUnits,
        today: today,
      );

      // ── Mes: mes natural completo (pasado + futuro confirmado) ────────────
      // Capacidad = 14 × días_totales_del_mes (ej: abril = 14 × 30 = 420)
      final monthStart = DateTime(now.year, now.month, 1);
      final nextMonthStart = DateTime(now.year, now.month + 1, 1);
      final monthStats = _calculateStats(
        period: OccupancyPeriod.month,
        bookings: bookings,
        periodStart: monthStart,
        periodEnd: nextMonthStart,
        totalUnits: totalUnits,
        today: today,
      );

      // ── Año: año natural completo (pasado + futuro confirmado) ────────────
      // Capacidad = 14 × 365 (o 366 si bisiesto)
      final yearStart = DateTime(now.year, 1, 1);
      final nextYearStart = DateTime(now.year + 1, 1, 1);
      final yearStats = _calculateStats(
        period: OccupancyPeriod.year,
        bookings: bookings,
        periodStart: yearStart,
        periodEnd: nextYearStart,
        totalUnits: totalUnits,
        today: today,
      );

      emit(state.copyWith(
        isLoading: false,
        isRefreshing: false,
        todayStats: todayStats,
        weekStats: weekStats,
        monthStats: monthStats,
        yearStats: yearStats,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: 'Error al cargar estadísticas: $e',
      ));
    }
  }

  OccupancyPeriodStats _calculateStats({
    required OccupancyPeriod period,
    required List<AdminBookingEntity> bookings,
    required DateTime periodStart,
    required DateTime periodEnd,
    required int totalUnits,
    required DateTime today,
  }) {
    // Solo estados que representan ocupación real:
    // confirmed / active / inHouse / checkedOut / closed
    // Se excluyen: created (no confirmada) y cancelled
    final activeBookings = bookings.where((b) {
      final s = b.bookingStatus;
      return s == BookingStatus.confirmed ||
          s == BookingStatus.active ||
          s == BookingStatus.inHouse ||
          // ignore: deprecated_member_use
          s == BookingStatus.checkedIn || // legacy
          s == BookingStatus.checkedOut ||
          s == BookingStatus.closed;
    }).toList();

    // Construir breakdown diario
    final dailyBreakdown = <DailyOccupancy>[];
    var current = periodStart;
    int totalOccupiedDays = 0;

    while (current.isBefore(periodEnd)) {
      final dayEnd = current.add(const Duration(days: 1));
      final dayBookings = activeBookings.where((b) {
        return b.checkInDate.isBefore(dayEnd) &&
            b.checkOutDate.isAfter(current);
      }).toList();

      final clamped = dayBookings.length.clamp(0, totalUnits);
      dailyBreakdown.add(DailyOccupancy(
        date: current,
        occupiedUnits: clamped,
        totalUnits: totalUnits,
        bookings: dayBookings.map((b) => OccupancyBookingItem(
          bookingId: b.id,
          bookingCode: b.bookingCode,
          guestName: b.guestFullName.isNotEmpty ? b.guestFullName : b.guestEmail,
          unitName: b.allUnitNames,
          propertyName: b.propertyName,
          checkInDate: b.checkInDate,
          checkOutDate: b.checkOutDate,
          isInHouse: b.isInHouse,
          numGuests: b.numGuests,
        )).toList(),
      ));
      totalOccupiedDays += clamped;
      current = dayEnd;
    }

    final daysInPeriod = dailyBreakdown.length;
    // Capacidad total = totalUnits × daysInPeriod (ej: 14×30=420 para un mes)
    final occupancyRate = daysInPeriod > 0 && totalUnits > 0
        ? (totalOccupiedDays / (daysInPeriod * totalUnits)) * 100
        : 0.0;

    // Unidades ocupadas físicamente HOY
    final tomorrow = today.add(const Duration(days: 1));
    final occupiedUnitsToday = activeBookings.where((b) =>
        b.checkInDate.isBefore(tomorrow) &&
        b.checkOutDate.isAfter(today)).length.clamp(0, totalUnits);

    // Reservas activas hoy para la lista de detalle
    final todayBookings = activeBookings
        .where((b) =>
            b.checkInDate.isBefore(tomorrow) &&
            b.checkOutDate.isAfter(today))
        .map((b) => OccupancyBookingItem(
              bookingId: b.id,
              bookingCode: b.bookingCode,
              guestName: b.guestFullName.isNotEmpty
                  ? b.guestFullName
                  : b.guestEmail,
              unitName: b.allUnitNames,
              propertyName: b.propertyName,
              checkInDate: b.checkInDate,
              checkOutDate: b.checkOutDate,
              isInHouse: b.isInHouse,
              numGuests: b.numGuests,
            ))
        .toList();

    return OccupancyPeriodStats(
      period: period,
      occupancyRate: occupancyRate,
      occupiedUnitsToday: occupiedUnitsToday,
      totalUnits: totalUnits,
      daysInPeriod: daysInPeriod,
      totalOccupiedNights: totalOccupiedDays,
      dailyBreakdown: dailyBreakdown,
      activeBookings: todayBookings,
    );
  }
}
