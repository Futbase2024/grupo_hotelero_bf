import 'package:equatable/equatable.dart';
import '../entities/admin_entities.dart';

/// Filtro de fechas genérico (usado en reservas y check-ins)
enum DateFilter {
  all,
  today,
  yesterday,
  thisWeek,
  thisMonth,
  lastMonth,
  customRange,
}

/// Extensión para obtener label del filtro de fechas
extension DateFilterLabel on DateFilter {
  String get label {
    switch (this) {
      case DateFilter.all:
        return 'Todos';
      case DateFilter.today:
        return 'Hoy';
      case DateFilter.yesterday:
        return 'Ayer';
      case DateFilter.thisWeek:
        return 'Semana';
      case DateFilter.thisMonth:
        return 'Mes';
      case DateFilter.lastMonth:
        return 'Anterior';
      case DateFilter.customRange:
        return 'Rango';
    }
  }
}

/// Estado del BLoC del dashboard de administración
class AdminDashboardState extends Equatable {
  const AdminDashboardState({
    this.currentTabIndex = 0,
    this.summary,
    this.bookings = const [],
    this.checkins = const [],
    this.properties = const [],
    this.units = const [],
    this.selectedPropertyId,
    this.notifications = const [],
    this.unreadNotificationsCount = 0,
    this.bookingsStatusFilter,
    this.bookingsSearchQuery,
    this.bookingsDateFilter = DateFilter.all,
    this.bookingsCustomDateStart,
    this.bookingsCustomDateEnd,
    this.checkinsStatusFilter = 'submitted',
    this.checkinsSearchQuery,
    this.checkinsDateFilter = DateFilter.all,
    this.checkinsCustomDateStart,
    this.checkinsCustomDateEnd,
    this.isLoading = false,
    this.isLoadingBookings = false,
    this.isLoadingCheckins = false,
    this.isLoadingProperties = false,
    this.isLoadingUnits = false,
    this.error,
  });

  /// Tab actual (0: Resumen, 1: Reservas, 2: Check-ins, 3: Alojamientos)
  final int currentTabIndex;

  /// Resumen del dashboard
  final DashboardSummaryEntity? summary;

  /// Lista de reservas
  final List<AdminBookingEntity> bookings;

  /// Lista de check-ins (extraídos de bookings con checkin)
  final List<AdminBookingEntity> checkins;

  /// Lista de propiedades (solo admin)
  final List<Map<String, dynamic>> properties;

  /// Lista de unidades de la propiedad seleccionada
  final List<AdminUnitEntity> units;

  /// ID de la propiedad seleccionada para ver unidades
  final String? selectedPropertyId;

  /// Lista de notificaciones
  final List<StaffNotificationEntity> notifications;

  /// Contador de notificaciones no leídas
  final int unreadNotificationsCount;

  // ── Filtros de reservas ──

  /// Filtro de estado de reservas
  final String? bookingsStatusFilter;

  /// Búsqueda de reservas
  final String? bookingsSearchQuery;

  /// Filtro de fecha de reservas
  final DateFilter bookingsDateFilter;

  /// Fecha inicio rango personalizado (reservas)
  final DateTime? bookingsCustomDateStart;

  /// Fecha fin rango personalizado (reservas)
  final DateTime? bookingsCustomDateEnd;

  // ── Filtros de check-ins ──

  /// Filtro de estado de check-ins
  final String? checkinsStatusFilter;

  /// Búsqueda de check-ins
  final String? checkinsSearchQuery;

  /// Filtro de fecha de check-ins
  final DateFilter checkinsDateFilter;

  /// Fecha inicio rango personalizado (check-ins)
  final DateTime? checkinsCustomDateStart;

  /// Fecha fin rango personalizado (check-ins)
  final DateTime? checkinsCustomDateEnd;

  /// Estados de carga
  final bool isLoading;
  final bool isLoadingBookings;
  final bool isLoadingCheckins;
  final bool isLoadingProperties;
  final bool isLoadingUnits;

  /// Error general
  final String? error;

  /// Factory para estado inicial
  factory AdminDashboardState.initial() => const AdminDashboardState();

  /// Copia con nuevos valores
  AdminDashboardState copyWith({
    int? currentTabIndex,
    DashboardSummaryEntity? summary,
    List<AdminBookingEntity>? bookings,
    List<AdminBookingEntity>? checkins,
    List<Map<String, dynamic>>? properties,
    List<AdminUnitEntity>? units,
    String? selectedPropertyId,
    List<StaffNotificationEntity>? notifications,
    int? unreadNotificationsCount,
    String? bookingsStatusFilter,
    String? bookingsSearchQuery,
    DateFilter? bookingsDateFilter,
    DateTime? bookingsCustomDateStart,
    DateTime? bookingsCustomDateEnd,
    bool clearBookingsDates = false,
    String? checkinsStatusFilter,
    String? checkinsSearchQuery,
    DateFilter? checkinsDateFilter,
    DateTime? checkinsCustomDateStart,
    DateTime? checkinsCustomDateEnd,
    bool clearCheckinsDates = false,
    bool? isLoading,
    bool? isLoadingBookings,
    bool? isLoadingCheckins,
    bool? isLoadingProperties,
    bool? isLoadingUnits,
    String? error,
    bool clearError = false,
    bool clearFilters = false,
    bool clearSelectedProperty = false,
  }) {
    return AdminDashboardState(
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      summary: summary ?? this.summary,
      bookings: bookings ?? this.bookings,
      checkins: checkins ?? this.checkins,
      properties: properties ?? this.properties,
      units: units ?? this.units,
      selectedPropertyId:
          clearSelectedProperty ? null : (selectedPropertyId ?? this.selectedPropertyId),
      notifications: notifications ?? this.notifications,
      unreadNotificationsCount:
          unreadNotificationsCount ?? this.unreadNotificationsCount,
      // Bookings filters
      bookingsStatusFilter:
          clearFilters ? null : (bookingsStatusFilter ?? this.bookingsStatusFilter),
      bookingsSearchQuery:
          clearFilters ? null : (bookingsSearchQuery ?? this.bookingsSearchQuery),
      bookingsDateFilter: clearFilters
          ? DateFilter.all
          : (bookingsDateFilter ?? this.bookingsDateFilter),
      bookingsCustomDateStart: clearFilters || clearBookingsDates
          ? null
          : (bookingsCustomDateStart ?? this.bookingsCustomDateStart),
      bookingsCustomDateEnd: clearFilters || clearBookingsDates
          ? null
          : (bookingsCustomDateEnd ?? this.bookingsCustomDateEnd),
      // Checkins filters
      checkinsStatusFilter: clearFilters
          ? null
          : (checkinsStatusFilter ?? this.checkinsStatusFilter),
      checkinsSearchQuery: clearFilters
          ? null
          : (checkinsSearchQuery ?? this.checkinsSearchQuery),
      checkinsDateFilter: clearFilters
          ? DateFilter.all
          : (checkinsDateFilter ?? this.checkinsDateFilter),
      checkinsCustomDateStart: clearFilters || clearCheckinsDates
          ? null
          : (checkinsCustomDateStart ?? this.checkinsCustomDateStart),
      checkinsCustomDateEnd: clearFilters || clearCheckinsDates
          ? null
          : (checkinsCustomDateEnd ?? this.checkinsCustomDateEnd),
      // Loading
      isLoading: isLoading ?? this.isLoading,
      isLoadingBookings: isLoadingBookings ?? this.isLoadingBookings,
      isLoadingCheckins: isLoadingCheckins ?? this.isLoadingCheckins,
      isLoadingProperties: isLoadingProperties ?? this.isLoadingProperties,
      isLoadingUnits: isLoadingUnits ?? this.isLoadingUnits,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Filtra las reservas según el filtro y búsqueda actuales
  List<AdminBookingEntity> get filteredBookings {
    var result = bookings;

    // Filtrar por estado
    if (bookingsStatusFilter != null && bookingsStatusFilter != 'all') {
      result = result.where((b) {
        return b.bookingStatus.toDbString() == bookingsStatusFilter;
      }).toList();
    }

    // Filtrar por búsqueda
    if (bookingsSearchQuery != null && bookingsSearchQuery!.isNotEmpty) {
      final query = bookingsSearchQuery!.toLowerCase();
      result = result.where((b) {
        return b.guestFullName.toLowerCase().contains(query) ||
            b.bookingCode.toLowerCase().contains(query) ||
            b.unitName.toLowerCase().contains(query);
      }).toList();
    }

    // Filtrar por fecha (sobre checkInDate)
    result = result.where((b) => _matchesDateFilter(
          b.checkInDate,
          dateFilter: bookingsDateFilter,
          customStart: bookingsCustomDateStart,
          customEnd: bookingsCustomDateEnd,
        )).toList();

    return result;
  }

  /// Filtra los check-ins según el filtro actual
  List<AdminBookingEntity> get filteredCheckins {
    var result = checkins;

    // Filtrar por estado
    if (checkinsStatusFilter != null && checkinsStatusFilter != 'all') {
      result = result.where((b) => b.checkinStatus == checkinsStatusFilter).toList();
    }

    // Filtrar por búsqueda
    if (checkinsSearchQuery != null && checkinsSearchQuery!.isNotEmpty) {
      final query = checkinsSearchQuery!.toLowerCase();
      result = result.where((b) {
        return b.guestFullName.toLowerCase().contains(query) ||
            b.bookingCode.toLowerCase().contains(query) ||
            b.unitName.toLowerCase().contains(query);
      }).toList();
    }

    // Filtrar por fecha (sobre checkInDate)
    result = result.where((b) => _matchesDateFilter(
          b.checkInDate,
          dateFilter: checkinsDateFilter,
          customStart: checkinsCustomDateStart,
          customEnd: checkinsCustomDateEnd,
        )).toList();

    // Ordenar: submitted primero (requieren acción)
    final sortedResult = List<AdminBookingEntity>.from(result);
    sortedResult.sort((a, b) {
      if (a.checkinStatus == 'submitted' && b.checkinStatus != 'submitted') {
        return -1;
      }
      if (a.checkinStatus != 'submitted' && b.checkinStatus == 'submitted') {
        return 1;
      }
      return 0;
    });

    return sortedResult;
  }

  /// Comprueba si una fecha coincide con el filtro de fechas dado
  static bool _matchesDateFilter(
    DateTime date, {
    required DateFilter dateFilter,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final now = DateTime.now();

    switch (dateFilter) {
      case DateFilter.all:
        return true;

      case DateFilter.today:
        return date.year == now.year && date.month == now.month && date.day == now.day;

      case DateFilter.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        return date.year == yesterday.year &&
            date.month == yesterday.month &&
            date.day == yesterday.day;

      case DateFilter.thisWeek:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        final start = DateTime(monday.year, monday.month, monday.day);
        final end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
        return !date.isBefore(start) && !date.isAfter(end);

      case DateFilter.thisMonth:
        return date.year == now.year && date.month == now.month;

      case DateFilter.lastMonth:
        final last = DateTime(now.year, now.month - 1);
        return date.year == last.year && date.month == last.month;

      case DateFilter.customRange:
        if (customStart == null || customEnd == null) return true;
        final start = DateTime(customStart.year, customStart.month, customStart.day);
        final end = DateTime(customEnd.year, customEnd.month, customEnd.day, 23, 59, 59);
        return !date.isBefore(start) && !date.isAfter(end);
    }
  }

  @override
  List<Object?> get props => [
        currentTabIndex,
        summary,
        bookings,
        checkins,
        properties,
        units,
        selectedPropertyId,
        notifications,
        unreadNotificationsCount,
        bookingsStatusFilter,
        bookingsSearchQuery,
        bookingsDateFilter,
        bookingsCustomDateStart,
        bookingsCustomDateEnd,
        checkinsStatusFilter,
        checkinsSearchQuery,
        checkinsDateFilter,
        checkinsCustomDateStart,
        checkinsCustomDateEnd,
        isLoading,
        isLoadingBookings,
        isLoadingCheckins,
        isLoadingProperties,
        isLoadingUnits,
        error,
      ];
}
