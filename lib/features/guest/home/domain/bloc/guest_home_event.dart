import 'package:equatable/equatable.dart';

/// Eventos del BLoC de la pantalla home del huésped
abstract class GuestHomeEvent extends Equatable {
  const GuestHomeEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar los datos de la reserva
class GuestHomeLoadBooking extends GuestHomeEvent {
  const GuestHomeLoadBooking(this.bookingId);

  final String? bookingId;

  @override
  List<Object?> get props => [bookingId];
}

/// Evento para refrescar los datos de la reserva
class GuestHomeRefreshBooking extends GuestHomeEvent {
  const GuestHomeRefreshBooking(this.bookingId);

  final String bookingId;

  @override
  List<Object?> get props => [bookingId];
}

/// Evento para cargar las notificaciones del huésped
class GuestHomeLoadNotifications extends GuestHomeEvent {
  const GuestHomeLoadNotifications(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Evento para marcar una notificación como leída
class GuestHomeNotificationMarkAsRead extends GuestHomeEvent {
  const GuestHomeNotificationMarkAsRead(this.notificationId);

  final String notificationId;

  @override
  List<Object?> get props => [notificationId];
}

/// Evento para marcar todas las notificaciones como leídas
class GuestHomeNotificationsMarkAllAsRead extends GuestHomeEvent {
  const GuestHomeNotificationsMarkAllAsRead();
}

/// Evento para eliminar una notificación
class GuestHomeNotificationDelete extends GuestHomeEvent {
  const GuestHomeNotificationDelete(this.notificationId);

  final String notificationId;

  @override
  List<Object?> get props => [notificationId];
}

/// Evento para eliminar todas las notificaciones
class GuestHomeNotificationsDeleteAll extends GuestHomeEvent {
  const GuestHomeNotificationsDeleteAll();
}
