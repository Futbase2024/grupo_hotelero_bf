import 'package:equatable/equatable.dart';

/// Períodos disponibles para estadísticas de ocupación
enum OccupancyPeriod {
  today('Hoy'),
  week('Semana'),
  month('Mes'),
  year('Año');

  const OccupancyPeriod(this.label);
  final String label;
}

/// Ocupación para un día específico
class DailyOccupancy extends Equatable {
  const DailyOccupancy({
    required this.date,
    required this.occupiedUnits,
    required this.totalUnits,
    this.bookings = const [],
  });

  final DateTime date;
  final int occupiedUnits;
  final int totalUnits;

  /// Reservas activas en este día (para mostrar al pulsar la barra)
  final List<OccupancyBookingItem> bookings;

  double get rate => totalUnits > 0 ? occupiedUnits / totalUnits : 0.0;
  double get ratePercent => rate * 100;

  @override
  List<Object?> get props => [date, occupiedUnits, totalUnits, bookings];
}

/// Item de reserva para mostrar en la lista de ocupación
class OccupancyBookingItem extends Equatable {
  const OccupancyBookingItem({
    required this.bookingId,
    required this.bookingCode,
    required this.guestName,
    required this.unitName,
    required this.propertyName,
    required this.checkInDate,
    required this.checkOutDate,
    required this.isInHouse,
    required this.numGuests,
  });

  final String bookingId;
  final String bookingCode;
  final String guestName;
  final String unitName;
  final String propertyName;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final bool isInHouse;
  final int numGuests;

  int get nightsTotal => checkOutDate.difference(checkInDate).inDays;

  int get nightsRemaining {
    final now = DateTime.now();
    if (now.isAfter(checkOutDate)) return 0;
    return checkOutDate.difference(now).inDays;
  }

  @override
  List<Object?> get props => [
        bookingId,
        bookingCode,
        guestName,
        unitName,
        propertyName,
        checkInDate,
        checkOutDate,
        isInHouse,
        numGuests,
      ];
}

/// Estadísticas de ocupación para un período dado
class OccupancyPeriodStats extends Equatable {
  const OccupancyPeriodStats({
    required this.period,
    required this.occupancyRate,
    required this.occupiedUnitsToday,
    required this.totalUnits,
    required this.daysInPeriod,
    required this.totalOccupiedNights,
    required this.dailyBreakdown,
    required this.activeBookings,
  });

  final OccupancyPeriod period;

  /// Tasa de ocupación del período (0–100)
  /// = totalOccupiedNights / (totalUnits × daysInPeriod) × 100
  final double occupancyRate;

  /// Unidades físicamente ocupadas HOY (para el snapshot del día actual)
  final int occupiedUnitsToday;

  /// Número total de alojamientos (ej: 14)
  final int totalUnits;

  /// Días del período completo:
  /// - Hoy: 1
  /// - Semana: 7
  /// - Mes: días totales del mes (28–31)
  /// - Año: 365 o 366
  final int daysInPeriod;

  /// Noches-unidad ocupadas en el período
  /// Hoy: unidades ocupadas (= occupiedUnitsToday × 1)
  /// Semana/Mes/Año: suma de (unidades ocupadas × día)
  final int totalOccupiedNights;

  /// Capacidad total del período en noches-unidad = totalUnits × daysInPeriod
  int get totalCapacityNights => totalUnits * daysInPeriod;

  String get occupancyRateFormatted => '${occupancyRate.toStringAsFixed(1)}%';

  final List<DailyOccupancy> dailyBreakdown;

  /// Reservas activas hoy (para mostrar en detalle)
  final List<OccupancyBookingItem> activeBookings;

  @override
  List<Object?> get props => [
        period,
        occupancyRate,
        occupiedUnitsToday,
        totalUnits,
        daysInPeriod,
        totalOccupiedNights,
        dailyBreakdown,
        activeBookings,
      ];
}
