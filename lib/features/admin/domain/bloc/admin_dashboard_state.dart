import 'package:equatable/equatable.dart';
import '../entities/admin_entities.dart';

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
    this.checkinsStatusFilter = 'submitted',
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

  /// Filtro de estado de reservas
  final String? bookingsStatusFilter;

  /// Búsqueda de reservas
  final String? bookingsSearchQuery;

  /// Filtro de estado de check-ins
  final String? checkinsStatusFilter;

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
    String? checkinsStatusFilter,
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
      bookingsStatusFilter:
          clearFilters ? null : (bookingsStatusFilter ?? this.bookingsStatusFilter),
      bookingsSearchQuery:
          clearFilters ? null : (bookingsSearchQuery ?? this.bookingsSearchQuery),
      checkinsStatusFilter: clearFilters
          ? null
          : (checkinsStatusFilter ?? this.checkinsStatusFilter),
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
      result = result.where((b) => b.status == bookingsStatusFilter).toList();
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

    return result;
  }

  /// Filtra los check-ins según el filtro actual
  List<AdminBookingEntity> get filteredCheckins {
    var result = checkins;

    if (checkinsStatusFilter != null && checkinsStatusFilter != 'all') {
      result = result.where((b) => b.checkinStatus == checkinsStatusFilter).toList();
    }

    // Ordenar: submitted primero (requieren acción)
    // Crear una copia mutable antes de ordenar para evitar error con listas inmutables
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
        checkinsStatusFilter,
        isLoading,
        isLoadingBookings,
        isLoadingCheckins,
        isLoadingProperties,
        isLoadingUnits,
        error,
      ];
}
