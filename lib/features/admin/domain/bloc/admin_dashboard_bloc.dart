import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../entities/admin_entities.dart';
import '../repositories/admin_panel_repository.dart';
import 'admin_dashboard_event.dart';
import 'admin_dashboard_state.dart';

/// BLoC del dashboard de administración
class AdminDashboardBloc extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  AdminDashboardBloc({
    required AdminPanelRepository repository,
  })  : _repository = repository,
        super(AdminDashboardState.initial()) {
    on<AdminDashboardLoadRequested>(_onLoadRequested);
    on<AdminDashboardRefreshRequested>(_onRefreshRequested);
    on<AdminDashboardTabChanged>(_onTabChanged);
    on<AdminDashboardBookingsLoadRequested>(_onBookingsLoadRequested);
    on<AdminDashboardCheckinsLoadRequested>(_onCheckinsLoadRequested);
    on<AdminDashboardPropertiesLoadRequested>(_onPropertiesLoadRequested);
    on<AdminDashboardBookingsFilterChanged>(_onBookingsFilterChanged);
    on<AdminDashboardBookingsSearchChanged>(_onBookingsSearchChanged);
    on<AdminDashboardBookingsDateFilterChanged>(_onBookingsDateFilterChanged);
    on<AdminDashboardBookingsSortChanged>(_onBookingsSortChanged);
    on<AdminDashboardCheckinsFilterChanged>(_onCheckinsFilterChanged);
    on<AdminDashboardCheckinsSearchChanged>(_onCheckinsSearchChanged);
    on<AdminDashboardCheckinsDateFilterChanged>(_onCheckinsDateFilterChanged);
    on<AdminDashboardCheckinsSortChanged>(_onCheckinsSortChanged);
    on<AdminDashboardUnitsLoadRequested>(_onUnitsLoadRequested);
    on<AdminDashboardUnitWifiUpdateRequested>(_onUnitWifiUpdateRequested);
    // Eventos de notificaciones
    on<AdminDashboardNotificationsLoadRequested>(_onNotificationsLoadRequested);
    on<AdminDashboardNotificationMarkAsReadRequested>(_onNotificationMarkAsReadRequested);
    on<AdminDashboardNotificationsMarkAllAsReadRequested>(_onNotificationsMarkAllAsReadRequested);
    on<AdminDashboardNotificationDeleteRequested>(_onNotificationDeleteRequested);
    on<AdminDashboardNotificationsDeleteAllRequested>(_onNotificationsDeleteAllRequested);
    on<AdminDashboardNotificationReceived>(_onNotificationReceived);
    on<AdminDashboardCheckinsChanged>(_onCheckinsChanged);

    // Suscribirse a notificaciones en tiempo real
    _subscribeToNotifications();
    // Suscribirse a cambios en checkins
    _subscribeToCheckins();
  }

  final AdminPanelRepository _repository;
  StreamSubscription<StaffNotificationEntity>? _notificationSubscription;
  StreamSubscription<void>? _checkinsSubscription;

  /// Ventana deslizante por defecto para la carga inicial de reservas/check-ins.
  /// Al abrir el dashboard solo se cargan las reservas cuyo check-in cae dentro
  /// de esta ventana (últimos N días) más el futuro. La carga deja así de crecer
  /// con el histórico total. Las búsquedas y los rangos de fecha personalizados
  /// IGNORAN esta ventana y consultan todo el histórico en el servidor.
  static const int _bookingsWindowDays = 90;

  /// Debounce de la búsqueda server-side (evita una query por pulsación).
  static const Duration _searchDebounceDuration = Duration(milliseconds: 350);
  Timer? _bookingsSearchDebounce;
  Timer? _checkinsSearchDebounce;

  /// Inicio de la ventana deslizante (medianoche de hace [_bookingsWindowDays]).
  DateTime get _windowStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: _bookingsWindowDays));
  }

  /// Decide los parámetros server-side para cargar RESERVAS según los filtros
  /// activos:
  /// - búsqueda activa → consulta todo el histórico por texto (ignora ventana);
  /// - rango de fechas personalizado → consulta ese rango exacto (histórico);
  /// - resto → ventana deslizante de [_bookingsWindowDays] días.
  Future<List<AdminBookingEntity>> _fetchBookings() {
    final search = state.bookingsSearchQuery?.trim();
    if (search != null && search.isNotEmpty) {
      return _repository.listBookings(searchQuery: search);
    }
    if (state.bookingsDateFilter == DateFilter.customRange &&
        state.bookingsCustomDateStart != null &&
        state.bookingsCustomDateEnd != null) {
      return _repository.listBookings(
        fromDate: state.bookingsCustomDateStart,
        toDate: state.bookingsCustomDateEnd,
      );
    }
    return _repository.listBookings(fromDate: _windowStart);
  }

  /// Igual que [_fetchBookings] pero usando los filtros del tab de CHECK-INS.
  Future<List<AdminBookingEntity>> _fetchCheckinsSource() {
    final search = state.checkinsSearchQuery?.trim();
    if (search != null && search.isNotEmpty) {
      return _repository.listBookings(searchQuery: search);
    }
    if (state.checkinsDateFilter == DateFilter.customRange &&
        state.checkinsCustomDateStart != null &&
        state.checkinsCustomDateEnd != null) {
      return _repository.listBookings(
        fromDate: state.checkinsCustomDateStart,
        toDate: state.checkinsCustomDateEnd,
      );
    }
    return _repository.listBookings(fromDate: _windowStart);
  }

  Timer? _notificationsDebounce;

  void _subscribeToNotifications() {
    _notificationSubscription = _repository.watchNotifications().listen(
      (notification) {
        if (isClosed) return;
        _notificationsDebounce?.cancel();
        _notificationsDebounce = Timer(const Duration(seconds: 3), () {
          if (!isClosed) {
            add(AdminDashboardNotificationReceived(notification));
          }
        });
      },
      onError: (error) {
        debugPrint('Error en stream de notificaciones: $error');
      },
    );
  }

  Timer? _checkinsDebounce;

  void _subscribeToCheckins() {
    _checkinsSubscription = _repository.watchCheckins().listen(
      (_) {
        if (isClosed) return;
        _checkinsDebounce?.cancel();
        _checkinsDebounce = Timer(const Duration(seconds: 3), () {
          if (!isClosed) {
            add(const AdminDashboardCheckinsChanged());
          }
        });
      },
      onError: (error) {
        debugPrint('Error en stream de checkins: $error');
      },
    );
  }

  @override
  Future<void> close() {
    _notificationsDebounce?.cancel();
    _checkinsDebounce?.cancel();
    _bookingsSearchDebounce?.cancel();
    _checkinsSearchDebounce?.cancel();
    _notificationSubscription?.cancel();
    _checkinsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onCheckinsChanged(
    AdminDashboardCheckinsChanged event,
    Emitter<AdminDashboardState> emit,
  ) async {
    // Evitar recarga si ya está cargando (previene bucle infinito)
    if (state.isLoadingCheckins) return;
    add(const AdminDashboardCheckinsLoadRequested());
  }

  Future<void> _onNotificationReceived(
    AdminDashboardNotificationReceived event,
    Emitter<AdminDashboardState> emit,
  ) async {
    // Añadir la nueva notificación a la lista
    final currentNotifications = List<StaffNotificationEntity>.from(state.notifications);

    // Evitar duplicados
    if (!currentNotifications.any((n) => n.id == event.notification.id)) {
      currentNotifications.insert(0, event.notification);
    }

    final unreadCount = currentNotifications.where((n) => !n.read).length;

    emit(state.copyWith(
      notifications: currentNotifications,
      unreadNotificationsCount: unreadCount,
    ));

    // NOTA: no recargamos check-ins aquí aunque la notificación sea de check-in.
    // La suscripción realtime a la tabla `checkins` (`_subscribeToCheckins`) ya
    // dispara `AdminDashboardCheckinsLoadRequested` ante el mismo cambio, así que
    // hacerlo también aquí provocaba un doble refetch (dos veces la lista completa
    // de reservas) por cada check-in. Se deja un único punto de recarga.
  }

  Future<void> _onLoadRequested(
    AdminDashboardLoadRequested event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      // Cargar datos principales y notificaciones por separado
      // para que un fallo de notificaciones no bloquee todo el dashboard
      final mainResults = await Future.wait<dynamic>([
        _repository.getDashboardSummary(),
        // Carga inicial acotada a la ventana deslizante (últimos 90 días + futuro).
        _fetchBookings(),
      ]);

      final summary = mainResults[0] as DashboardSummaryEntity;
      final bookings = mainResults[1] as List<AdminBookingEntity>;

      // Cargar notificaciones de forma independiente (no bloquea el dashboard)
      List<StaffNotificationEntity> notifications = [];
      try {
        notifications = await _repository.getNotifications(unreadOnly: true);
      } catch (e) {
        debugPrint('⚠️ [AdminDashboard] Error cargando notificaciones (no crítico): $e');
      }

      // Extraer check-ins de las reservas
      final checkins = bookings.where((b) => b.hasCheckin).toList();

      emit(state.copyWith(
        summary: summary,
        bookings: bookings,
        checkins: checkins,
        notifications: notifications,
        unreadNotificationsCount: notifications.length,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshRequested(
    AdminDashboardRefreshRequested event,
    Emitter<AdminDashboardState> emit,
  ) async {
    try {
      // Recargar según el tab actual
      switch (state.currentTabIndex) {
        case 0:
          add(const AdminDashboardLoadRequested());
        case 1:
          add(const AdminDashboardBookingsLoadRequested());
        case 2:
          add(const AdminDashboardCheckinsLoadRequested());
        case 3:
          add(const AdminDashboardPropertiesLoadRequested());
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onTabChanged(
    AdminDashboardTabChanged event,
    Emitter<AdminDashboardState> emit,
  ) {
    emit(state.copyWith(currentTabIndex: event.tabIndex));

    // Cargar datos según el tab
    switch (event.tabIndex) {
      case 0:
        if (state.summary == null) {
          add(const AdminDashboardLoadRequested());
        }
      case 1:
        if (state.bookings.isEmpty) {
          add(const AdminDashboardBookingsLoadRequested());
        }
      case 2:
        if (state.checkins.isEmpty) {
          add(const AdminDashboardCheckinsLoadRequested());
        }
      case 3:
        if (state.properties.isEmpty) {
          add(const AdminDashboardPropertiesLoadRequested());
        }
    }
  }

  Future<void> _onBookingsLoadRequested(
    AdminDashboardBookingsLoadRequested event,
    Emitter<AdminDashboardState> emit,
  ) async {
    // Aplicar filtros que vengan en el evento (compatibilidad con llamadas
    // directas). Cuando el load lo dispara el debounce de búsqueda o un cambio
    // de filtro, el estado ya trae los filtros correctos y el evento va vacío.
    var working = state;
    if (event.statusFilter != null) {
      working = working.copyWith(bookingsStatusFilter: event.statusFilter);
    }
    if (event.searchQuery != null) {
      working = working.copyWith(bookingsSearchQuery: event.searchQuery);
    }
    emit(working.copyWith(isLoadingBookings: true, clearError: true));

    try {
      // Solo actualiza `bookings`; no toca la lista de check-ins (tienen
      // filtros independientes).
      final bookings = await _fetchBookings();

      emit(state.copyWith(
        bookings: bookings,
        isLoadingBookings: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingBookings: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCheckinsLoadRequested(
    AdminDashboardCheckinsLoadRequested event,
    Emitter<AdminDashboardState> emit,
  ) async {
    // Evitar recargas solapadas
    if (state.isLoadingCheckins) return;

    var working = state;
    if (event.statusFilter != null) {
      working = working.copyWith(checkinsStatusFilter: event.statusFilter);
    }
    emit(working.copyWith(isLoadingCheckins: true, clearError: true));

    try {
      // Cargar reservas según los filtros de check-ins y quedarnos con las que
      // tienen check-in. Solo actualiza `checkins`; no pisa `bookings` (el tab
      // de reservas tiene sus propios filtros).
      final source = await _fetchCheckinsSource();
      final checkins = source.where((b) => b.hasCheckin).toList();

      emit(state.copyWith(
        checkins: checkins,
        isLoadingCheckins: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingCheckins: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onPropertiesLoadRequested(
    AdminDashboardPropertiesLoadRequested event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(state.copyWith(isLoadingProperties: true, clearError: true));

    try {
      // Por ahora, cargar las propiedades desde las reservas existentes
      // TODO: Crear endpoint específico para listar propiedades
      final propertyMap = <String, Map<String, dynamic>>{};

      for (final booking in state.bookings) {
        if (!propertyMap.containsKey(booking.propertyId)) {
          propertyMap[booking.propertyId] = {
            'id': booking.propertyId,
            'name': booking.propertyName,
          };
        }
      }

      emit(state.copyWith(
        properties: propertyMap.values.toList(),
        isLoadingProperties: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingProperties: false,
        error: e.toString(),
      ));
    }
  }

  void _onBookingsFilterChanged(
    AdminDashboardBookingsFilterChanged event,
    Emitter<AdminDashboardState> emit,
  ) {
    emit(state.copyWith(bookingsStatusFilter: event.statusFilter));
  }

  void _onBookingsSearchChanged(
    AdminDashboardBookingsSearchChanged event,
    Emitter<AdminDashboardState> emit,
  ) {
    // Feedback inmediato del texto en el input.
    emit(state.copyWith(
      bookingsSearchQuery: event.searchQuery,
      clearBookingsSearchQuery: event.searchQuery == null,
    ));
    // Recargar desde el servidor con debounce: la búsqueda consulta el
    // histórico completo (ignora la ventana deslizante), así se encuentran
    // reservas de meses anteriores. Al borrar el texto vuelve a la ventana.
    _bookingsSearchDebounce?.cancel();
    _bookingsSearchDebounce = Timer(_searchDebounceDuration, () {
      if (!isClosed) add(const AdminDashboardBookingsLoadRequested());
    });
  }

  void _onCheckinsFilterChanged(
    AdminDashboardCheckinsFilterChanged event,
    Emitter<AdminDashboardState> emit,
  ) {
    emit(state.copyWith(checkinsStatusFilter: event.statusFilter));
  }

  void _onCheckinsSearchChanged(
    AdminDashboardCheckinsSearchChanged event,
    Emitter<AdminDashboardState> emit,
  ) {
    emit(state.copyWith(
      checkinsSearchQuery: event.searchQuery,
      clearCheckinsSearchQuery: event.searchQuery == null,
    ));
    // Búsqueda server-side con debounce sobre el histórico completo.
    _checkinsSearchDebounce?.cancel();
    _checkinsSearchDebounce = Timer(_searchDebounceDuration, () {
      if (!isClosed) add(const AdminDashboardCheckinsLoadRequested());
    });
  }

  void _onCheckinsDateFilterChanged(
    AdminDashboardCheckinsDateFilterChanged event,
    Emitter<AdminDashboardState> emit,
  ) {
    final wasCustom = state.checkinsDateFilter == DateFilter.customRange;
    final isCustom = event.dateFilter == DateFilter.customRange;
    emit(state.copyWith(
      checkinsDateFilter: event.dateFilter,
      checkinsCustomDateStart: event.customDateStart,
      checkinsCustomDateEnd: event.customDateEnd,
      clearCheckinsDates: event.dateFilter != DateFilter.customRange,
    ));
    // Entrar o salir de un rango personalizado cambia el conjunto server-side
    // (histórico vs ventana). Los demás filtros de fecha caen dentro de la
    // ventana y se resuelven en cliente sin recargar.
    if (isCustom || wasCustom) {
      add(const AdminDashboardCheckinsLoadRequested());
    }
  }

  void _onBookingsDateFilterChanged(
    AdminDashboardBookingsDateFilterChanged event,
    Emitter<AdminDashboardState> emit,
  ) {
    final wasCustom = state.bookingsDateFilter == DateFilter.customRange;
    final isCustom = event.dateFilter == DateFilter.customRange;
    emit(state.copyWith(
      bookingsDateFilter: event.dateFilter,
      bookingsCustomDateStart: event.customDateStart,
      bookingsCustomDateEnd: event.customDateEnd,
      clearBookingsDates: event.dateFilter != DateFilter.customRange,
    ));
    // Ver comentario en _onCheckinsDateFilterChanged.
    if (isCustom || wasCustom) {
      add(const AdminDashboardBookingsLoadRequested());
    }
  }

  void _onBookingsSortChanged(
    AdminDashboardBookingsSortChanged event,
    Emitter<AdminDashboardState> emit,
  ) {
    emit(state.copyWith(bookingsSortOrder: event.sortOrder));
  }

  void _onCheckinsSortChanged(
    AdminDashboardCheckinsSortChanged event,
    Emitter<AdminDashboardState> emit,
  ) {
    emit(state.copyWith(checkinsSortOrder: event.sortOrder));
  }

  Future<void> _onUnitsLoadRequested(
    AdminDashboardUnitsLoadRequested event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(state.copyWith(isLoadingUnits: true, clearError: true));

    try {
      final units = await _repository.listUnits(event.propertyId);

      emit(state.copyWith(
        units: units,
        selectedPropertyId: event.propertyId,
        isLoadingUnits: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingUnits: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUnitWifiUpdateRequested(
    AdminDashboardUnitWifiUpdateRequested event,
    Emitter<AdminDashboardState> emit,
  ) async {
    try {
      await _repository.updateUnitWifi(
        unitId: event.unitId,
        wifiNetwork: event.wifiNetwork,
        wifiPassword: event.wifiPassword,
      );

      // Actualizar la unidad en la lista local
      final updatedUnits = state.units.map((unit) {
        if (unit.id == event.unitId) {
          return AdminUnitEntity(
            id: unit.id,
            propertyId: unit.propertyId,
            name: unit.name,
            unitType: unit.unitType,
            addressLine1: unit.addressLine1,
            city: unit.city,
            postalCode: unit.postalCode,
            boxCode: unit.boxCode,
            accessInstructions: unit.accessInstructions,
            wifiNetwork: event.wifiNetwork,
            wifiPassword: event.wifiPassword,
            activeBookingsCount: unit.activeBookingsCount,
            createdAt: unit.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        return unit;
      }).toList();

      emit(state.copyWith(units: updatedUnits));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      rethrow;
    }
  }

  // ==================== MANEJADORES DE NOTIFICACIONES ====================

  Future<void> _onNotificationsLoadRequested(
    AdminDashboardNotificationsLoadRequested event,
    Emitter<AdminDashboardState> emit,
  ) async {
    // Limpiar error previo para que la UI no muestre estado de error viejo
    emit(state.copyWith(clearError: true));
    try {
      final notifications = await _repository.getNotifications(unreadOnly: false);
      final unreadCount = notifications.where((n) => !n.read).length;

      emit(state.copyWith(
        notifications: notifications,
        unreadNotificationsCount: unreadCount,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onNotificationMarkAsReadRequested(
    AdminDashboardNotificationMarkAsReadRequested event,
    Emitter<AdminDashboardState> emit,
  ) async {
    try {
      await _repository.markNotificationsAsRead([event.notificationId]);

      final updatedNotifications = state.notifications.map((n) {
        if (n.id == event.notificationId) {
          return n.copyWith(read: true);
        }
        return n;
      }).toList();

      final unreadCount = updatedNotifications.where((n) => !n.read).length;

      emit(state.copyWith(
        notifications: updatedNotifications,
        unreadNotificationsCount: unreadCount,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onNotificationsMarkAllAsReadRequested(
    AdminDashboardNotificationsMarkAllAsReadRequested event,
    Emitter<AdminDashboardState> emit,
  ) async {
    try {
      await _repository.markAllNotificationsAsRead();

      final updatedNotifications = state.notifications
          .map((n) => n.copyWith(read: true))
          .toList();

      emit(state.copyWith(
        notifications: updatedNotifications,
        unreadNotificationsCount: 0,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onNotificationDeleteRequested(
    AdminDashboardNotificationDeleteRequested event,
    Emitter<AdminDashboardState> emit,
  ) async {
    try {
      await _repository.deleteNotification(event.notificationId);

      final updatedNotifications = state.notifications
          .where((n) => n.id != event.notificationId)
          .toList();

      final unreadCount = updatedNotifications.where((n) => !n.read).length;

      emit(state.copyWith(
        notifications: updatedNotifications,
        unreadNotificationsCount: unreadCount,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onNotificationsDeleteAllRequested(
    AdminDashboardNotificationsDeleteAllRequested event,
    Emitter<AdminDashboardState> emit,
  ) async {
    try {
      await _repository.deleteAllNotifications();

      emit(state.copyWith(
        notifications: [],
        unreadNotificationsCount: 0,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
