import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../admin/domain/entities/admin_booking_entity.dart';
import '../../../../admin/domain/repositories/admin_panel_repository.dart';
import '../entities/guest_notification_entity.dart';
import 'guest_home_event.dart';
import 'guest_home_state.dart';

/// BLoC para la pantalla home del huésped
class GuestHomeBloc extends Bloc<GuestHomeEvent, GuestHomeState> {
  GuestHomeBloc({
    required AdminPanelRepository repository,
  })  : _repository = repository,
        super(const GuestHomeInitial()) {
    on<GuestHomeLoadBooking>(_onLoadBooking);
    on<GuestHomeRefreshBooking>(_onRefreshBooking);
    on<GuestHomeLoadNotifications>(_onLoadNotifications);
    on<GuestHomeNotificationMarkAsRead>(_onNotificationMarkAsRead);
    on<GuestHomeNotificationsMarkAllAsRead>(_onNotificationsMarkAllAsRead);
    on<GuestHomeNotificationDelete>(_onNotificationDelete);
    on<GuestHomeNotificationsDeleteAll>(_onNotificationsDeleteAll);
  }

  final AdminPanelRepository _repository;

  /// Notificaciones que llegaron antes que la reserva.
  ///
  /// `GuestHomeLoadBooking` y `GuestHomeLoadNotifications` se disparan a la vez
  /// desde la pantalla y corren en paralelo. La consulta de notificaciones suele
  /// ganar la carrera porque la de la reserva además resuelve `booking_units`.
  /// Se guardan aquí hasta que haya una reserva real con la que emitir `Loaded`.
  List<GuestNotificationEntity> _pendingNotifications = const [];
  int _pendingUnreadCount = 0;

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> _onLoadBooking(
    GuestHomeLoadBooking event,
    Emitter<GuestHomeState> emit,
  ) async {
    emit(const GuestHomeLoading());

    // Si no hay bookingId, mostrar estado de no booking
    if (event.bookingId == null || event.bookingId!.isEmpty) {
      debugPrint('🏠 [GuestHomeBloc] No hay bookingId, mostrando estado NoBooking');
      emit(const GuestHomeNoBooking());
      return;
    }

    try {
      debugPrint('🏠 [GuestHomeBloc] Cargando booking: ${event.bookingId}');
      final booking = await _repository.getBooking(event.bookingId!);

      if (booking == null) {
        debugPrint('🏠 [GuestHomeBloc] Booking no encontrado');
        emit(const GuestHomeNoBooking());
        return;
      }

      debugPrint('🏠 [GuestHomeBloc] Booking cargado: ${booking.bookingCode}, unitName: ${booking.unitName}');
      emit(GuestHomeLoaded(
        booking: booking,
        notifications: _pendingNotifications,
        unreadNotificationsCount: _pendingUnreadCount,
      ));
    } catch (e, stackTrace) {
      debugPrint('❌ [GuestHomeBloc] Error cargando booking: $e');
      debugPrint('❌ [GuestHomeBloc] StackTrace: $stackTrace');
      emit(GuestHomeError(e.toString()));
    }
  }

  Future<void> _onRefreshBooking(
    GuestHomeRefreshBooking event,
    Emitter<GuestHomeState> emit,
  ) async {
    // Mantener los datos anteriores mientras se refresca
    AdminBookingEntity? currentBooking;
    List<GuestNotificationEntity>? currentNotifications;
    int? currentUnreadCount;

    if (state is GuestHomeLoaded) {
      currentBooking = (state as GuestHomeLoaded).booking;
      currentNotifications = (state as GuestHomeLoaded).notifications;
      currentUnreadCount = (state as GuestHomeLoaded).unreadNotificationsCount;
    }

    if (currentBooking != null) {
      emit(GuestHomeLoaded(
        booking: currentBooking,
        notifications: currentNotifications ?? [],
        unreadNotificationsCount: currentUnreadCount ?? 0,
        isRefreshing: true,
      ));
    }

    try {
      final booking = await _repository.getBooking(event.bookingId);

      if (booking == null) {
        emit(const GuestHomeNoBooking());
        return;
      }

      emit(GuestHomeLoaded(
        booking: booking,
        notifications: currentNotifications ?? _pendingNotifications,
        unreadNotificationsCount: currentUnreadCount ?? _pendingUnreadCount,
      ));
    } catch (e) {
      // Si hay error, volver al estado anterior sin isRefreshing
      if (currentBooking != null) {
        emit(GuestHomeLoaded(
          booking: currentBooking,
          notifications: currentNotifications ?? [],
          unreadNotificationsCount: currentUnreadCount ?? 0,
        ));
      } else {
        emit(GuestHomeError(e.toString()));
      }
    }
  }

  /// Carga las notificaciones del huésped
  Future<void> _onLoadNotifications(
    GuestHomeLoadNotifications event,
    Emitter<GuestHomeState> emit,
  ) async {
    try {
      debugPrint('🔔 [GuestHomeBloc] Cargando notificaciones para usuario: ${event.userId}');

      // Verificar que el usuario esté autenticado en Supabase
      final currentAuthUser = _client.auth.currentUser;
      final session = _client.auth.currentSession;
      debugPrint('🔔 [GuestHomeBloc] Supabase auth.currentUser: ${currentAuthUser?.id}');
      debugPrint('🔔 [GuestHomeBloc] Sesión activa: ${session != null}');
      if (session != null) {
        debugPrint('🔔 [GuestHomeBloc] Session user ID: ${session.user.id}');
      }

      debugPrint('🔔 [GuestHomeBloc] Ejecutando consulta con user_id: ${event.userId}');

      final response = await _client
          .from('guest_notifications')
          .select('*')
          .eq('user_id', event.userId)
          .order('created_at', ascending: false);

      debugPrint('🔔 [GuestHomeBloc] Response length: ${response.length}');
      if (response.isNotEmpty) {
        debugPrint('🔔 [GuestHomeBloc] Response data: $response');
      }

      final notifications = (response as List)
          .map((json) => GuestNotificationEntity.fromJson(json))
          .toList();

      final unreadCount = notifications.where((n) => !n.isRead).length;

      debugPrint('🔔 [GuestHomeBloc] ${notifications.length} notificaciones cargadas, $unreadCount no leídas');

      final currentState = state;

      // Si la reserva todavía no ha cargado, NO emitir un booking placeholder:
      // `AdminBookingEntity.empty()` tiene fechas de hoy/mañana y 1 huésped, y la
      // pantalla llegaba a pintar ese "1 noche · 1 huésped" antes de recibir los
      // datos reales. Se guardan y las aplica `_onLoadBooking` al terminar.
      if (currentState is! GuestHomeLoaded) {
        debugPrint(
          '🔔 [GuestHomeBloc] Reserva aún sin cargar: '
          '${notifications.length} notificaciones quedan pendientes',
        );
        _pendingNotifications = notifications;
        _pendingUnreadCount = unreadCount;
        return;
      }

      emit(currentState.copyWith(
        notifications: notifications,
        unreadNotificationsCount: unreadCount,
      ));
    } catch (e, stackTrace) {
      debugPrint('❌ [GuestHomeBloc] Error cargando notificaciones: $e');
      debugPrint('❌ [GuestHomeBloc] StackTrace: $stackTrace');
    }
  }

  /// Marca una notificación como leída
  Future<void> _onNotificationMarkAsRead(
    GuestHomeNotificationMarkAsRead event,
    Emitter<GuestHomeState> emit,
  ) async {
    try {
      await _client
          .from('guest_notifications')
          .update({'is_read': true})
          .eq('id', event.notificationId);

      // Actualizar estado
      final currentState = state;
      if (currentState is GuestHomeLoaded) {
        final updatedNotifications = currentState.notifications
            .map((n) => n.id == event.notificationId
                ? n.copyWith(isRead: true)
                : n)
            .toList();
        final newUnreadCount = updatedNotifications
            .where((n) => !n.isRead)
            .length;

        emit(currentState.copyWith(
          notifications: updatedNotifications,
          unreadNotificationsCount: newUnreadCount,
        ));
      }
    } catch (e) {
      debugPrint('❌ [GuestHomeBloc] Error marcando notificación como leída: $e');
    }
  }

  /// Marca todas las notificaciones como leídas
  Future<void> _onNotificationsMarkAllAsRead(
    GuestHomeNotificationsMarkAllAsRead event,
    Emitter<GuestHomeState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! GuestHomeLoaded) return;

      // Obtener IDs de notificaciones no leídas
      final unreadIds = currentState.notifications
          .where((n) => !n.isRead)
          .map((n) => n.id)
          .toList();

      if (unreadIds.isEmpty) return;

      for (final notificationId in unreadIds) {
        await _client
            .from('guest_notifications')
            .update({'is_read': true})
            .eq('id', notificationId);
      }

      // Actualizar estado
      emit(currentState.copyWith(
        notifications: currentState.notifications
            .map((n) => n.copyWith(isRead: true))
            .toList(),
        unreadNotificationsCount: 0,
      ));
    } catch (e) {
      debugPrint('❌ [GuestHomeBloc] Error marcando todas como leídas: $e');
    }
  }

  /// Elimina una notificación
  Future<void> _onNotificationDelete(
    GuestHomeNotificationDelete event,
    Emitter<GuestHomeState> emit,
  ) async {
    try {
      await _client
          .from('guest_notifications')
          .delete()
          .eq('id', event.notificationId);

      // Recargar notificaciones
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        add(GuestHomeLoadNotifications(userId));
      }
    } catch (e) {
      debugPrint('❌ [GuestHomeBloc] Error eliminando notificación: $e');
    }
  }

  /// Elimina todas las notificaciones
  Future<void> _onNotificationsDeleteAll(
    GuestHomeNotificationsDeleteAll event,
    Emitter<GuestHomeState> emit,
  ) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client
          .from('guest_notifications')
          .delete()
          .eq('user_id', userId);

      // Actualizar estado
      final currentState = state;
      if (currentState is GuestHomeLoaded) {
        emit(currentState.copyWith(
          notifications: [],
          unreadNotificationsCount: 0,
        ));
      }
    } catch (e) {
      debugPrint('❌ [GuestHomeBloc] Error eliminando todas las notificaciones: $e');
    }
  }
}
