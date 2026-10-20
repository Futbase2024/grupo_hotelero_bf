import 'dart:async';

/// Bus global de señales de refresco disparadas por notificaciones FCM.
///
/// Permite que la UI (por ejemplo, la home del huésped) recargue sus datos al
/// instante cuando llega o se toca un push relevante, sin acoplar el
/// [FcmService] a los BLoCs de presentación.
///
/// El valor emitido es el `type` de la notificación (p. ej. `'checkin_status'`),
/// para que cada listener decida si le concierne.
class NotificationRefreshBus {
  NotificationRefreshBus._();

  static final NotificationRefreshBus instance = NotificationRefreshBus._();

  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  /// Stream de tipos de notificación recibidos.
  Stream<String> get stream => _controller.stream;

  /// Emite una señal de refresco con el [type] de la notificación.
  void emit(String type) {
    if (type.isEmpty) return;
    if (!_controller.isClosed) {
      _controller.add(type);
    }
  }
}
