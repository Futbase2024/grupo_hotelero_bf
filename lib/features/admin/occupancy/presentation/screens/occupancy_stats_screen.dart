import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../features/admin/domain/repositories/admin_panel_repository.dart';
import '../../../../../core/di/injection.dart';
import '../../domain/entities/occupancy_stats_entity.dart';
import '../bloc/occupancy_bloc.dart';
import '../bloc/occupancy_event.dart';
import '../bloc/occupancy_state.dart';

/// Pantalla de estadísticas de ocupación por período
class OccupancyStatsScreen extends StatelessWidget {
  const OccupancyStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OccupancyBloc(
        repository: getIt<AdminPanelRepository>(),
      )..add(const OccupancyLoadRequested()),
      child: const _OccupancyStatsView(),
    );
  }
}

class _OccupancyStatsView extends StatelessWidget {
  const _OccupancyStatsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Estadísticas de Ocupación',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          BlocBuilder<OccupancyBloc, OccupancyState>(
            builder: (context, state) {
              if (state.isRefreshing) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.gold,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              return IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.gold),
                onPressed: () => context
                    .read<OccupancyBloc>()
                    .add(const OccupancyRefreshRequested()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<OccupancyBloc, OccupancyState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.gold),
                    SizedBox(height: 16),
                    Text(
                      'Calculando ocupación...',
                      style: TextStyle(color: AppColors.whiteWithAlpha70, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            if (state.error != null && !state.hasData) {
              return _ErrorView(
                message: state.error!,
                onRetry: () => context
                    .read<OccupancyBloc>()
                    .add(const OccupancyLoadRequested()),
              );
            }

            return RefreshIndicator(
              color: AppColors.gold,
              backgroundColor: AppColors.darkSurface,
              onRefresh: () async {
                context
                    .read<OccupancyBloc>()
                    .add(const OccupancyRefreshRequested());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumen de los 4 períodos en miniatura
                    _PeriodSummaryRow(state: state),
                    const SizedBox(height: 20),

                    // Selector de período
                    _PeriodSelector(selectedPeriod: state.selectedPeriod),
                    const SizedBox(height: 20),

                    // KPI principal del período seleccionado
                    if (state.currentStats != null) ...[
                      _MainKpiCard(stats: state.currentStats!),
                      const SizedBox(height: 16),

                      // Gráfico de barras diario
                      _DailyBarChart(stats: state.currentStats!),
                      const SizedBox(height: 16),

                      // Lista de reservas activas hoy
                      _ActiveBookingsList(stats: state.currentStats!),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Resumen de 4 períodos en miniatura
// ---------------------------------------------------------------------------

class _PeriodSummaryRow extends StatelessWidget {
  const _PeriodSummaryRow({required this.state});

  final OccupancyState state;

  @override
  Widget build(BuildContext context) {
    final periods = [
      (OccupancyPeriod.today, state.todayStats),
      (OccupancyPeriod.week, state.weekStats),
      (OccupancyPeriod.month, state.monthStats),
      (OccupancyPeriod.year, state.yearStats),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen general',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.whiteWithAlpha70,
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            children: [
              for (int i = 0; i < periods.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _MiniPeriodCard(
                    period: periods[i].$1,
                    stats: periods[i].$2,
                    isSelected: state.selectedPeriod == periods[i].$1,
                    onTap: () => context
                        .read<OccupancyBloc>()
                        .add(OccupancyPeriodChanged(periods[i].$1)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniPeriodCard extends StatelessWidget {
  const _MiniPeriodCard({
    required this.period,
    required this.stats,
    required this.isSelected,
    required this.onTap,
  });

  final OccupancyPeriod period;
  final OccupancyPeriodStats? stats;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rate = stats?.occupancyRate ?? 0.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldWithAlpha20 : AppColors.darkSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.darkBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              period.label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.gold : AppColors.whiteWithAlpha70,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              stats != null ? '${rate.toStringAsFixed(0)}%' : '--',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.gold : AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Selector de período
// ---------------------------------------------------------------------------

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selectedPeriod});

  final OccupancyPeriod selectedPeriod;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: OccupancyPeriod.values.map((p) {
          final isSelected = p == selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => context
                  .read<OccupancyBloc>()
                  .add(OccupancyPeriodChanged(p)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  p.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.darkBackground : AppColors.whiteWithAlpha70,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// KPI principal
// ---------------------------------------------------------------------------

class _MainKpiCard extends StatelessWidget {
  const _MainKpiCard({required this.stats});

  final OccupancyPeriodStats stats;

  Color get _rateColor {
    if (stats.occupancyRate >= 80) return const Color(0xFF27AE60);
    if (stats.occupancyRate >= 50) return AppColors.gold;
    return const Color(0xFFE67E22);
  }

  String get _periodLabel {
    switch (stats.period) {
      case OccupancyPeriod.today:
        return 'Ocupación actual';
      case OccupancyPeriod.week:
        return 'Últimos 7 días';
      case OccupancyPeriod.month:
        return 'Mes completo (reservas confirmadas)';
      case OccupancyPeriod.year:
        return 'Año completo (reservas confirmadas)';
    }
  }

  /// Línea principal de ocupación según período:
  /// - Hoy:     "5 / 14 unidades"
  /// - Semana:  "40 / 98 noches"     (14×7)
  /// - Mes:     "120 / 420 noches"   (14×30)
  /// - Año:     "1500 / 5110 noches" (14×365)
  String get _occupancyValue {
    if (stats.period == OccupancyPeriod.today) {
      return '${stats.occupiedUnitsToday} / ${stats.totalUnits}';
    }
    return '${stats.totalOccupiedNights} / ${stats.totalCapacityNights}';
  }

  String get _occupancyLabel {
    return stats.period == OccupancyPeriod.today ? 'unidades hoy' : 'noches';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _periodLabel,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.whiteWithAlpha70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Porcentaje grande
              Text(
                '${stats.occupancyRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  color: _rateColor,
                  height: 1,
                ),
              ),
              const SizedBox(width: 20),
              // Columna de métricas secundarias
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetricRow(
                      icon: Icons.hotel_outlined,
                      label: _occupancyLabel,
                      value: _occupancyValue,
                      valueColor: _rateColor,
                    ),
                    const SizedBox(height: 8),
                    _MetricRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Período',
                      value: stats.period == OccupancyPeriod.today
                          ? DateFormat('d MMM yyyy', 'es').format(DateTime.now())
                          : '${stats.daysInPeriod} días',
                      valueColor: AppColors.whiteWithAlpha70,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barra de progreso
          _OccupancyProgressBar(rate: stats.occupancyRate, color: _rateColor),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.whiteWithAlpha50),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.whiteWithAlpha50,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OccupancyProgressBar extends StatelessWidget {
  const _OccupancyProgressBar({required this.rate, required this.color});

  final double rate;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (rate / 100).clamp(0.0, 1.0),
            backgroundColor: AppColors.darkBorder,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0%',
              style: const TextStyle(fontSize: 10, color: AppColors.whiteWithAlpha50),
            ),
            Text(
              '50%',
              style: const TextStyle(fontSize: 10, color: AppColors.whiteWithAlpha50),
            ),
            Text(
              '100%',
              style: const TextStyle(fontSize: 10, color: AppColors.whiteWithAlpha50),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Gráfico de barras diario
// ---------------------------------------------------------------------------

class _DailyBarChart extends StatelessWidget {
  const _DailyBarChart({required this.stats});

  final OccupancyPeriodStats stats;

  void _showBarDetail(BuildContext context, DailyOccupancy day) {
    final dateFormat = DateFormat('d MMMM yyyy', 'es');
    final title = stats.period == OccupancyPeriod.year
        ? DateFormat('MMMM yyyy', 'es').format(day.date)
        : dateFormat.format(day.date);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BarDetailSheet(
        title: title[0].toUpperCase() + title.substring(1),
        day: day,
      ),
    );
  }

  String _labelForPeriod(DateTime date, OccupancyPeriod period) {
    switch (period) {
      case OccupancyPeriod.today:
        return DateFormat('HH:mm').format(date);
      case OccupancyPeriod.week:
        return DateFormat('E', 'es').format(date).substring(0, 2).toUpperCase();
      case OccupancyPeriod.month:
        return DateFormat('d').format(date);
      case OccupancyPeriod.year:
        return DateFormat('MMM', 'es').format(date).substring(0, 3).toUpperCase();
    }
  }

  String get _chartTitle {
    switch (stats.period) {
      case OccupancyPeriod.today:
        return 'Ocupación de hoy';
      case OccupancyPeriod.week:
        return 'Últimos 7 días';
      case OccupancyPeriod.month:
        return 'Días del mes';
      case OccupancyPeriod.year:
        return 'Meses del año';
    }
  }

  List<DailyOccupancy> _aggregateData() {
    if (stats.period != OccupancyPeriod.year) {
      return stats.dailyBreakdown;
    }
    // Para año, agrupar por mes
    final Map<int, List<DailyOccupancy>> byMonth = {};
    for (final d in stats.dailyBreakdown) {
      byMonth.putIfAbsent(d.date.month, () => []).add(d);
    }
    return byMonth.entries.map((e) {
      final days = e.value;
      final avgOccupied =
          days.fold(0, (s, d) => s + d.occupiedUnits) ~/ days.length;
      // Recopilar reservas únicas del mes
      final seenIds = <String>{};
      final monthBookings = <OccupancyBookingItem>[];
      for (final d in days) {
        for (final b in d.bookings) {
          if (seenIds.add(b.bookingId)) {
            monthBookings.add(b);
          }
        }
      }
      return DailyOccupancy(
        date: DateTime(days.first.date.year, e.key),
        occupiedUnits: avgOccupied,
        totalUnits: stats.totalUnits,
        bookings: monthBookings,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = _aggregateData();
    if (data.isEmpty) return const SizedBox.shrink();

    final maxRate = data.fold(0.0, (m, d) => m > d.rate ? m : d.rate);
    final displayMax = maxRate > 0 ? maxRate : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _chartTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                final barHeight = displayMax > 0
                    ? (d.rate / displayMax) * 64
                    : 4.0;
                final isToday = d.date.year == DateTime.now().year &&
                    d.date.month == DateTime.now().month &&
                    d.date.day == DateTime.now().day;
                final barColor =
                    isToday ? AppColors.gold : AppColors.goldWithAlpha50;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _showBarDetail(context, d),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: barHeight.clamp(3.0, 64.0),
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _labelForPeriod(d.date, stats.period),
                            style: TextStyle(
                              fontSize: data.length > 20 ? 7 : 9,
                              color: isToday
                                  ? AppColors.gold
                                  : AppColors.whiteWithAlpha50,
                              fontWeight: isToday
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lista de reservas activas hoy
// ---------------------------------------------------------------------------

class _ActiveBookingsList extends StatelessWidget {
  const _ActiveBookingsList({required this.stats});

  final OccupancyPeriodStats stats;

  @override
  Widget build(BuildContext context) {
    final bookings = stats.activeBookings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Huéspedes actuales',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.goldWithAlpha20,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold),
              ),
              child: Text(
                '${bookings.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (bookings.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.hotel_outlined, size: 36, color: AppColors.gray500),
                  SizedBox(height: 10),
                  Text(
                    'No hay huéspedes actualmente',
                    style: TextStyle(
                      color: AppColors.whiteWithAlpha50,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...bookings.map((b) => _BookingItem(booking: b)),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _BookingItem extends StatelessWidget {
  const _BookingItem({required this.booking});

  final OccupancyBookingItem booking;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM', 'es');
    final nightsLeft = booking.nightsRemaining;
    final statusColor = booking.isInHouse
        ? const Color(0xFF27AE60)
        : AppColors.gold;
    final statusLabel = booking.isInHouse ? 'En casa' : 'Confirmado';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          // Indicador de estado
          Container(
            width: 3,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // Info principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        booking.guestName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Badge estado
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor.withAlpha(80)),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.apartment_outlined,
                        size: 12, color: AppColors.whiteWithAlpha50),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.unitName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.whiteWithAlpha70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${dateFormat.format(booking.checkInDate)} → ${dateFormat.format(booking.checkOutDate)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.whiteWithAlpha50,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Noches restantes
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                nightsLeft.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
              const Text(
                'noches',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.whiteWithAlpha50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet al pulsar una barra del gráfico
// ---------------------------------------------------------------------------

class _BarDetailSheet extends StatelessWidget {
  const _BarDetailSheet({
    required this.title,
    required this.day,
  });

  final String title;
  final DailyOccupancy day;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.whiteWithAlpha30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                        Icons.close, color: AppColors.whiteWithAlpha70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // KPI del día
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  _DayKpiChip(
                    icon: Icons.hotel_outlined,
                    value: '${day.occupiedUnits} / ${day.totalUnits}',
                    label: 'unidades',
                  ),
                  const SizedBox(width: 12),
                  _DayKpiChip(
                    icon: Icons.pie_chart_outline,
                    value: '${day.ratePercent.toStringAsFixed(1)}%',
                    label: 'ocupación',
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.darkBorder, height: 1),
            // Lista de reservas
            Flexible(
              child: day.bookings.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.hotel_outlined,
                              size: 36, color: AppColors.gray500),
                          SizedBox(height: 10),
                          Text(
                            'Sin reservas este día',
                            style: TextStyle(
                              color: AppColors.whiteWithAlpha50,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      shrinkWrap: true,
                      itemCount: day.bookings.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) =>
                          _BookingItem(booking: day.bookings[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayKpiChip extends StatelessWidget {
  const _DayKpiChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.goldWithAlpha20,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gold),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.gold),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.whiteWithAlpha50,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vista de error
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar datos',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.whiteWithAlpha70,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.darkBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
