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
    on<AdminDashboardSummaryRefreshRequested>(_onSummaryRefreshRequested);
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

  /// Carga de check-ins en vuelo y petición encolada mientras dura.
  /// Ver [_onCheckinsLoadRequested].
  bool _checkinsLoadInFlight = false;
  bool _checkinsReloadPending = false;
  bool _bookingsLoadInFlight = false;
  bool _bookingsReloadPending = false;

  /// Si ya se completó una carga del tab de check-ins. A partir de la segunda,
  /// el refresco es silencioso aunque la lista esté vacía (con el filtro
  /// "Por revisar" lo normal es que no haya ninguno pendiente).
  bool _checkinsLoadedOnce = false;

  /// Ventana deslizante por defecto del tab de reservas: solo se cargan las
  /// reservas cuyo check-in cae dentro de los últimos N días, más el futuro.
  /// Las búsquedas y los rangos de fecha personalizados IGNORAN esta ventana y
  /// consultan todo el histórico en el servidor.
  ///
  /// 30 días ≈ 210 reservas frente a las ~530 de los 90 días anteriores. Es el
  /// horizonte que se consulta a diario; lo anterior se busca por texto o rango.
  static const int _bookingsWindowDays = 30;

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
      return _repository.listBookings(searchQuery: search, lightweight: true);
    }
    if (state.bookingsDateFilter == DateFilter.customRange &&
        state.bookingsCustomDateStart != null &&
        state.bookingsCustomDateEnd != null) {
      return _repository.listBookings(
        fromDate: state.bookingsCustomDateStart,
        toDate: state.bookingsCustomDateEnd,
        lightweight: true,
      );
    }
    // Cada preset pide al servidor SU rango: si no, un filtro como "mes
    // anterior" solo vería la parte que cayera dentro de la ventana.
    // `allHistory` y `all` devuelven null; `all` cae en la ventana deslizante.
    return _repository.listBookings(
      fromDate: state.bookingsDateFilter == DateFilter.all
          ? _windowStart
          : state.bookingsDateFilter.serverFromDate(),
      lightweight: true,
    );
  }

  /// Igual que [_fetchBookings] pero usando los filtros del tab de CHECK-INS.
  ///
  /// El estado del check-in se filtra en el SERVIDOR (join interno sobre
  /// `checkins`): con el filtro por defecto ("Por revisar") la consulta baja de
  /// ~500 reservas a las pocas que están realmente pendientes.
  Future<List<AdminBookingEntity>> _fetchCheckinsSource() {
    final statusFilter = state.checkinsStatusFilter;
    final checkinStatusFilter =
        (statusFilter == null || statusFilter == 'all') ? null : statusFilter;

    final search = state.checkinsSearchQuery?.trim();
    if (search != null && search.isNotEmpty) {
      return _repository.listBookings(
        searchQuery: search,
        checkinStatusFilter: checkinStatusFilter,
        lightweight: true,
      );
    }
    if (state.checkinsDateFilter == DateFilter.customRange &&
        state.checkinsCustomDateStart != null &&
        state.checkinsCustomDateEnd != null) {
      return _repository.listBookings(
        fromDate: state.checkinsCustomDateStart,
        toDate: state.checkinsCustomDateEnd,
        checkinStatusFilter: checkinStatusFilter,
        lightweight: true,
      );
    }
    // Con filtro de estado la consulta ya va acotada por el join interno (unos
    // pocos check-ins), así que NO se aplica la ventana deslizante: un check-in
    // pendiente de una reserva antigua tiene que seguir apareciendo.
    final presetFrom = state.checkinsDateFilter.serverFromDate();
    return _repository.listBookings(
      fromDate: state.checkinsDateFilter == DateFilter.all
          ? (checkinStatusFilter == null ? _windowStart : null)
          : presetFrom,
      checkinStatusFilter: checkinStatusFilter,
      lightweight: true,
    );
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
    // `skip(1)` descarta el snapshot inicial del stream: al abrir el dashboard
    // los check-ins ya vienen en `AdminDashboardLoadRequested`, así que sin esto
    // se lanzaba una segunda consulta completa a los 3 s de arrancar.
    _checkinsSubscription = _repository.watchCheckins().skip(1).listen(
      (_) {
        if (isClosed) return;
        _checkinsDebounce?.cancel();
        _checkinsDebounce = Timer(const Duration(seconds: 1), () {
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
    // La reentrada la controla `_onCheckinsLoadRequested` (encola la petición
    // si hay otra en vuelo), así que aquí nunca se descarta la señal.
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
      // El tab de resumen solo necesita el RPC: sus KPIs (incluida la ocupación
      // de hoy) y los últimos check-ins vienen de ahí. La lista de reservas
      // (~500 filas, ~550 kB) ya NO se descarga en el arranque: cada tab la
      // carga al entrar. Las notificaciones van aparte para que un fallo suyo
      // no tumbe el dashboard.
      final summaryFuture = _repository.getDashboardSummary();
      final notificationsFuture = _repository
          .getNotifications(unreadOnly: true)
          .catchError((Object e) {
        debugPrint(
            '⚠️ [AdminDashboard] Error cargando notificaciones (no crítico): $e');
        return <StaffNotificationEntity>[];
      });

      final summary = await summaryFuture;
      final notifications = await notificationsFuture;

      emit(state.copyWith(
        summary: summary,
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

  /// Recarga solo los KPIs del resumen (RPC ligero), sin volver a traer la
  /// lista completa de reservas. No muestra spinner: los datos actuales siguen
  /// en pantalla hasta que llegan los nuevos.
  Future<void> _onSummaryRefreshRequested(
    AdminDashboardSummaryRefreshRequested event,
    Emitter<AdminDashboardState> emit,
  ) async {
    try {
      final summary = await _repository.getDashboardSummary();
      emit(state.copyWith(summary: summary));
    } catch (e) {
      debugPrint('⚠️ [AdminDashboard] Error refrescando resumen: $e');
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

    // Cargar datos según el tab.
    // Check-ins y reservas se refrescan SIEMPRE al entrar (refresco silencioso,
    // sin vaciar la lista): antes solo se cargaban si la lista estaba vacía, de
    // modo que un check-in enviado después de abrir el panel no aparecía hasta
    // reiniciar la app.
    switch (event.tabIndex) {
      case 0:
        if (state.summary == null) {
          add(const AdminDashboardLoadRequested());
        }
      case 1:
        add(const AdminDashboardBookingsLoadRequested());
      case 2:
        add(const AdminDashboardCheckinsLoadRequested());
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
    emit(working);

    // Mismo mecanismo que en check-ins: si hay una carga en vuelo se encola la
    // nueva en vez de lanzarla en paralelo (dos cambios de filtro seguidos
    // podían pintar el resultado de la consulta más lenta).
    if (_bookingsLoadInFlight) {
      _bookingsReloadPending = true;
      return;
    }
    _bookingsLoadInFlight = true;

    // Spinner solo en la primera carga; con datos en pantalla el refresco es
    // silencioso (ver [_onCheckinsLoadRequested]).
    emit(state.copyWith(
      isLoadingBookings: state.bookings.isEmpty,
      clearError: true,
    ));

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
    } finally {
      _bookingsLoadInFlight = false;
      if (_bookingsReloadPending) {
        _bookingsReloadPending = false;
        if (!isClosed) add(const AdminDashboardBookingsLoadRequested());
      }
    }
  }

  Future<void> _onCheckinsLoadRequested(
    AdminDashboardCheckinsLoadRequested event,
    Emitter<AdminDashboardState> emit,
  ) async {
    if (event.statusFilter != null &&
        event.statusFilter != state.checkinsStatusFilter) {
      emit(state.copyWith(checkinsStatusFilter: event.statusFilter));
    }

    // Si ya hay una carga en vuelo, NO se descarta la petición: se marca como
    // pendiente y se relanza al terminar. Descartarla dejaba la lista obsoleta
    // (el caso del check-in recién enviado que no aparecía).
    if (_checkinsLoadInFlight) {
      _checkinsReloadPending = true;
      return;
    }
    _checkinsLoadInFlight = true;

    // Spinner solo en la primera carga. Con datos ya en pantalla el refresco es
    // silencioso: la lista sigue visible y se sustituye al llegar los nuevos
    // datos (evita el parpadeo a "Sin check-ins" cada vez que se entra al tab).
    final isFirstLoad = !_checkinsLoadedOnce && state.checkins.isEmpty;
    emit(state.copyWith(
      isLoadingCheckins: isFirstLoad,
      isRefreshingCheckins: !isFirstLoad,
      clearError: true,
    ));

    try {
      // Cargar reservas según los filtros de check-ins y quedarnos con las que
      // tienen check-in. Solo actualiza `checkins`; no pisa `bookings` (el tab
      // de reservas tiene sus propios filtros).
      final source = await _fetchCheckinsSource();
      final checkins = source.where((b) => b.hasCheckin).toList();
      _checkinsLoadedOnce = true;

      emit(state.copyWith(
        checkins: checkins,
        isLoadingCheckins: false,
        isRefreshingCheckins: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingCheckins: false,
        isRefreshingCheckins: false,
        error: e.toString(),
      ));
    } finally {
      _checkinsLoadInFlight = false;
      if (_checkinsReloadPending) {
        _checkinsReloadPending = false;
        if (!isClosed) add(const AdminDashboardCheckinsLoadRequested());
      }
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
    if (state.checkinsStatusFilter == event.statusFilter) return;
    emit(state.copyWith(checkinsStatusFilter: event.statusFilter));
    // El estado del check-in se resuelve en el servidor, así que cambiarlo
    // implica recargar el conjunto de datos.
    add(const AdminDashboardCheckinsLoadRequested());
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
    emit(state.copyWith(
      checkinsDateFilter: event.dateFilter,
      checkinsCustomDateStart: event.customDateStart,
      checkinsCustomDateEnd: event.customDateEnd,
      clearCheckinsDates: event.dateFilter != DateFilter.customRange,
    ));
    // Cada preset define su propio rango server-side, así que cualquier cambio
    // implica recargar (antes solo recargaba el rango personalizado y los
    // presets se resolvían sobre lo que hubiera en memoria).
    add(const AdminDashboardCheckinsLoadRequested());
  }

  void _onBookingsDateFilterChanged(
    AdminDashboardBookingsDateFilterChanged event,
    Emitter<AdminDashboardState> emit,
  ) {
    emit(state.copyWith(
      bookingsDateFilter: event.dateFilter,
      bookingsCustomDateStart: event.customDateStart,
      bookingsCustomDateEnd: event.customDateEnd,
      clearBookingsDates: event.dateFilter != DateFilter.customRange,
    ));
    // Ver comentario en _onCheckinsDateFilterChanged.
    add(const AdminDashboardBookingsLoadRequested());
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
