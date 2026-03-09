// Interfaz del servicio FCM
// La implementación real depende de la plataforma:
// - fcm_service_io.dart para iOS/Android (usa dart:io)
// - fcm_service_web.dart para Web (sin dart:io)
// - fcm_service_stub.dart para plataformas no soportadas
abstract class FcmService {
  /// Token FCM actual
  String? get fcmToken;

  /// Inicializa el servicio FCM
  Future<void> initialize();

  /// Elimina el token del dispositivo (logout)
  Future<void> deleteToken();

  /// Suscribe a un topic
  Future<void> subscribeToTopic(String topic);

  /// Desuscribe de un topic
  Future<void> unsubscribeFromTopic(String topic);

  /// Libera recursos
  void dispose();
}
