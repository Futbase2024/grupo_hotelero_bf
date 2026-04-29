import 'package:equatable/equatable.dart';
import '../entities/admin_entities.dart';
import 'admin_dashboard_state.dart';

/// Eventos del BLoC del dashboard de administración
abstract class AdminDashboardEvent extends Equatable {
  const AdminDashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar datos iniciales del dashboard
class AdminDashboardLoadRequested extends AdminDashboardEvent {
  const AdminDashboardLoadRequested();
}

/// Refrescar datos del dashboard
class AdminDashboardRefreshRequested extends AdminDashboardEvent {
  const AdminDashboardRefreshRequested();
}

/// Cambiar tab activo
class AdminDashboardTabChanged extends AdminDashboardEvent {
  const AdminDashboardTabChanged(this.tabIndex);

  final int tabIndex;

  @override
  List<Object?> get props => [tabIndex];
}

/// Cargar lista de reservas
class AdminDashboardBookingsLoadRequested extends AdminDashboardEvent {
  const AdminDashboardBookingsLoadRequested({
    this.statusFilter,
    this.searchQuery,
  });

  final String? statusFilter;
  final String? searchQuery;

  @override
  List<Object?> get props => [statusFilter, searchQuery];
}

/// Cargar lista de check-ins
class AdminDashboardCheckinsLoadRequested extends AdminDashboardEvent {
  const AdminDashboardCheckinsLoadRequested({
    this.statusFilter,
  });

  final String? statusFilter;

  @override
  List<Object?> get props => [statusFilter];
}

/// Cargar lista de propiedades (solo admin)
class AdminDashboardPropertiesLoadRequested extends AdminDashboardEvent {
  const AdminDashboardPropertiesLoadRequested();
}

/// Cambiar filtro de reservas
class AdminDashboardBookingsFilterChanged extends AdminDashboardEvent {
  const AdminDashboardBookingsFilterChanged(this.statusFilter);

  final String? statusFilter;

  @override
  List<Object?> get props => [statusFilter];
}

/// Cambiar búsqueda de reservas
class AdminDashboardBookingsSearchChanged extends AdminDashboardEvent {
  const AdminDashboardBookingsSearchChanged(this.searchQuery);

  final String? searchQuery;

  @override
  List<Object?> get props => [searchQuery];
}

/// Cambiar filtro de check-ins
class AdminDashboardCheckinsFilterChanged extends AdminDashboardEvent {
  const AdminDashboardCheckinsFilterChanged(this.statusFilter);

  final String? statusFilter;

  @override
  List<Object?> get props => [statusFilter];
}

/// Cargar unidades de una propiedad
class AdminDashboardUnitsLoadRequested extends AdminDashboardEvent {
  const AdminDashboardUnitsLoadRequested(this.propertyId);

  final String propertyId;

  @override
  List<Object?> get props => [propertyId];
}

/// Actualizar WiFi de una unidad
class AdminDashboardUnitWifiUpdateRequested extends AdminDashboardEvent {
  const AdminDashboardUnitWifiUpdateRequested({
    required this.unitId,
    required this.wifiNetwork,
    required this.wifiPassword,
  });

  final String unitId;
  final String wifiNetwork;
  final String wifiPassword;

  @override
  List<Object?> get props => [unitId, wifiNetwork, wifiPassword];
}

// ==================== EVENTOS DE NOTIFICACIONES ====================

/// Cargar todas las notificaciones
class AdminDashboardNotificationsLoadRequested extends AdminDashboardEvent {
  const AdminDashboardNotificationsLoadRequested();
}

/// Marcar una notificación como leída
class AdminDashboardNotificationMarkAsReadRequested extends AdminDashboardEvent {
  const AdminDashboardNotificationMarkAsReadRequested(this.notificationId);

  final String notificationId;

  @override
  List<Object?> get props => [notificationId];
}

/// Marcar todas las notificaciones como leídas
class AdminDashboardNotificationsMarkAllAsReadRequested extends AdminDashboardEvent {
  const AdminDashboardNotificationsMarkAllAsReadRequested();
}

/// Eliminar una notificación
class AdminDashboardNotificationDeleteRequested extends AdminDashboardEvent {
  const AdminDashboardNotificationDeleteRequested(this.notificationId);

  final String notificationId;

  @override
  List<Object?> get props => [notificationId];
}

/// Eliminar todas las notificaciones
class AdminDashboardNotificationsDeleteAllRequested extends AdminDashboardEvent {
  const AdminDashboardNotificationsDeleteAllRequested();
}

/// Notificación recibida en tiempo real
class AdminDashboardNotificationReceived extends AdminDashboardEvent {
  const AdminDashboardNotificationReceived(this.notification);

  final StaffNotificationEntity notification;

  @override
  List<Object?> get props => [notification];
}

/// Cambio detectado en checkins (realtime)
class AdminDashboardCheckinsChanged extends AdminDashboardEvent {
  const AdminDashboardCheckinsChanged();
}

/// Cambiar búsqueda de check-ins
class AdminDashboardCheckinsSearchChanged extends AdminDashboardEvent {
  const AdminDashboardCheckinsSearchChanged(this.searchQuery);

  final String? searchQuery;

  @override
  List<Object?> get props => [searchQuery];
}

/// Cambiar filtro de fecha de check-ins
class AdminDashboardCheckinsDateFilterChanged extends AdminDashboardEvent {
  const AdminDashboardCheckinsDateFilterChanged({
    required this.dateFilter,
    this.customDateStart,
    this.customDateEnd,
  });

  final DateFilter dateFilter;
  final DateTime? customDateStart;
  final DateTime? customDateEnd;

  @override
  List<Object?> get props => [dateFilter, customDateStart, customDateEnd];
}

/// Cambiar filtro de fecha de reservas
class AdminDashboardBookingsDateFilterChanged extends AdminDashboardEvent {
  const AdminDashboardBookingsDateFilterChanged({
    required this.dateFilter,
    this.customDateStart,
    this.customDateEnd,
  });

  final DateFilter dateFilter;
  final DateTime? customDateStart;
  final DateTime? customDateEnd;

  @override
  List<Object?> get props => [dateFilter, customDateStart, customDateEnd];
}
