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
    on<AdminDashboardCheckinsFilterChanged>(_onCheckinsFilterChanged);
  }

  final AdminPanelRepository _repository;

  Future<void> _onLoadRequested(
    AdminDashboardLoadRequested event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      // Cargar resumen y reservas en paralelo
      final results = await Future.wait([
        _repository.getDashboardSummary(),
        _repository.listBookings(),
        _repository.getNotifications(unreadOnly: true),
      ]);

      final summary = results[0] as DashboardSummaryEntity;
      final bookings = results[1] as List<AdminBookingEntity>;
      final notifications = results[2] as List<StaffNotificationEntity>;

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
    emit(state.copyWith(isLoadingBookings: true, clearError: true));

    try {
      final bookings = await _repository.listBookings(
        statusFilter: event.statusFilter,
        searchQuery: event.searchQuery,
      );

      emit(state.copyWith(
        bookings: bookings,
        isLoadingBookings: false,
        bookingsStatusFilter: event.statusFilter,
        bookingsSearchQuery: event.searchQuery,
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
    emit(state.copyWith(isLoadingCheckins: true, clearError: true));

    try {
      // Cargar todas las reservas y filtrar las que tienen check-in
      final bookings = await _repository.listBookings();
      final checkins = bookings.where((b) => b.hasCheckin).toList();

      emit(state.copyWith(
        bookings: bookings,
        checkins: checkins,
        isLoadingCheckins: false,
        checkinsStatusFilter: event.statusFilter,
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
    emit(state.copyWith(bookingsSearchQuery: event.searchQuery));
  }

  void _onCheckinsFilterChanged(
    AdminDashboardCheckinsFilterChanged event,
    Emitter<AdminDashboardState> emit,
  ) {
    emit(state.copyWith(checkinsStatusFilter: event.statusFilter));
  }
}
