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

  /// Sin límite de fechas: consulta el histórico completo en el servidor,
  /// ignorando la ventana deslizante. Bajo demanda, no por defecto.
  allHistory,
}

/// Orden de clasificación por fecha
enum SortOrder {
  descending,
  ascending,
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
      case DateFilter.allHistory:
        return 'Todo el histórico';
    }
  }

  /// Fecha desde la que hay que consultar en el SERVIDOR para que el filtro
  /// pueda resolverse después en cliente.
  ///
  /// `null` = sin límite (histórico completo). Para [DateFilter.all] devuelve
  /// `null` y es quien llama (el BLoC) quien aplica su ventana deslizante.
  DateTime? serverFromDate({DateTime? customStart}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case DateFilter.all:
      case DateFilter.allHistory:
        return null;
      case DateFilter.today:
        return today;
      case DateFilter.yesterday:
        return today.subtract(const Duration(days: 1));
      case DateFilter.thisWeek:
        return today.subtract(Duration(days: now.weekday - 1));
      case DateFilter.thisMonth:
        return DateTime(now.year, now.month);
      case DateFilter.lastMonth:
        return DateTime(now.year, now.month - 1);
      case DateFilter.customRange:
        return customStart;
    }
  }
}

/// Estado del BLoC del dashboard de administración
// ignore: must_be_immutable
class AdminDashboardState extends Equatable {
  // Nota: el constructor no es `const` porque el estado memoiza de forma
  // perezosa los resultados de `filteredBookings`/`filteredCheckins` (campos
  // mutables privados que NO participan en la igualdad de Equatable).
  AdminDashboardState({
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
    this.bookingsSortOrder = SortOrder.descending,
    this.checkinsStatusFilter = 'submitted',
    this.checkinsSearchQuery,
    this.checkinsDateFilter = DateFilter.all,
    this.checkinsCustomDateStart,
    this.checkinsCustomDateEnd,
    this.checkinsSortOrder = SortOrder.descending,
    this.isLoading = false,
    this.isLoadingBookings = false,
    this.isLoadingCheckins = false,
    this.isRefreshingCheckins = false,
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

  /// Orden de clasificación de reservas
  final SortOrder bookingsSortOrder;

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

  /// Orden de clasificación de check-ins
  final SortOrder checkinsSortOrder;

  /// Estados de carga
  final bool isLoading;
  final bool isLoadingBookings;
  final bool isLoadingCheckins;

  /// Refresco de check-ins en segundo plano: la lista actual sigue visible y
  /// solo se muestra un indicador discreto en la cabecera.
  final bool isRefreshingCheckins;
  final bool isLoadingProperties;
  final bool isLoadingUnits;

  /// Error general
  final String? error;

  // ── Caché perezoso de listas filtradas ──
  // Se calculan una sola vez por instancia de estado (la primera vez que se
  // accede al getter) y se reutilizan en los siguientes accesos dentro del
  // mismo build. NO forman parte de `props` (no afectan a la igualdad).
  List<AdminBookingEntity>? _filteredBookingsCache;
  List<AdminBookingEntity>? _filteredCheckinsCache;

  /// Factory para estado inicial
  factory AdminDashboardState.initial() => AdminDashboardState();

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
    bool clearBookingsSearchQuery = false,
    SortOrder? bookingsSortOrder,
    String? checkinsStatusFilter,
    String? checkinsSearchQuery,
    bool clearCheckinsSearchQuery = false,
    DateFilter? checkinsDateFilter,
    DateTime? checkinsCustomDateStart,
    DateTime? checkinsCustomDateEnd,
    bool clearCheckinsDates = false,
    SortOrder? checkinsSortOrder,
    bool? isLoading,
    bool? isLoadingBookings,
    bool? isLoadingCheckins,
    bool? isRefreshingCheckins,
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
          clearFilters || clearBookingsSearchQuery
              ? null
              : (bookingsSearchQuery ?? this.bookingsSearchQuery),
      bookingsDateFilter: clearFilters
          ? DateFilter.all
          : (bookingsDateFilter ?? this.bookingsDateFilter),
      bookingsCustomDateStart: clearFilters || clearBookingsDates
          ? null
          : (bookingsCustomDateStart ?? this.bookingsCustomDateStart),
      bookingsCustomDateEnd: clearFilters || clearBookingsDates
          ? null
          : (bookingsCustomDateEnd ?? this.bookingsCustomDateEnd),
      bookingsSortOrder: clearFilters
          ? SortOrder.descending
          : (bookingsSortOrder ?? this.bookingsSortOrder),
      // Checkins filters
      checkinsStatusFilter: clearFilters
          ? null
          : (checkinsStatusFilter ?? this.checkinsStatusFilter),
      checkinsSearchQuery: clearFilters || clearCheckinsSearchQuery
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
      checkinsSortOrder: clearFilters
          ? SortOrder.descending
          : (checkinsSortOrder ?? this.checkinsSortOrder),
      // Loading
      isLoading: isLoading ?? this.isLoading,
      isLoadingBookings: isLoadingBookings ?? this.isLoadingBookings,
      isLoadingCheckins: isLoadingCheckins ?? this.isLoadingCheckins,
      isRefreshingCheckins:
          isRefreshingCheckins ?? this.isRefreshingCheckins,
      isLoadingProperties: isLoadingProperties ?? this.isLoadingProperties,
      isLoadingUnits: isLoadingUnits ?? this.isLoadingUnits,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Filtra las reservas según el filtro y búsqueda actuales.
  /// Memoizado: se calcula una vez por instancia de estado.
  List<AdminBookingEntity> get filteredBookings =>
      _filteredBookingsCache ??= _computeFilteredBookings();

  List<AdminBookingEntity> _computeFilteredBookings() {
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

    // Ordenar por fecha de check-in
    final sorted = List<AdminBookingEntity>.from(result);
    sorted.sort((a, b) {
      final cmp = a.checkInDate.compareTo(b.checkInDate);
      return bookingsSortOrder == SortOrder.ascending ? cmp : -cmp;
    });

    return sorted;
  }

  /// Filtra los check-ins según el filtro actual.
  /// Memoizado: se calcula una vez por instancia de estado.
  List<AdminBookingEntity> get filteredCheckins =>
      _filteredCheckinsCache ??= _computeFilteredCheckins();

  List<AdminBookingEntity> _computeFilteredCheckins() {
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

    // Ordenar: submitted primero (requieren acción), luego por fecha
    final sortedResult = List<AdminBookingEntity>.from(result);
    sortedResult.sort((a, b) {
      if (a.checkinStatus == 'submitted' && b.checkinStatus != 'submitted') {
        return -1;
      }
      if (a.checkinStatus != 'submitted' && b.checkinStatus == 'submitted') {
        return 1;
      }
      final cmp = a.checkInDate.compareTo(b.checkInDate);
      return checkinsSortOrder == SortOrder.ascending ? cmp : -cmp;
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
      case DateFilter.allHistory:
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
        bookingsSortOrder,
        checkinsStatusFilter,
        checkinsSearchQuery,
        checkinsDateFilter,
        checkinsCustomDateStart,
        checkinsCustomDateEnd,
        checkinsSortOrder,
        isLoading,
        isLoadingBookings,
        isLoadingCheckins,
        isRefreshingCheckins,
        isLoadingProperties,
        isLoadingUnits,
        error,
      ];
}
