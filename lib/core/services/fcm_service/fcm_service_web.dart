import 'package:flutter/foundation.dart';

import 'fcm_service.dart';

/// Implementación para Web - FCM con soporte limitado
/// En web, FCM funciona pero sin notificaciones locales
class FcmServiceWeb implements FcmService {
  String? _fcmToken;

  @override
  String? get fcmToken => _fcmToken;

  @override
  Future<void> initialize() async {
    debugPrint('🔧 FCM Web: Inicializando...');

    try {
      // En web, Firebase Messaging funciona de forma diferente
      // Por ahora, simplemente registramos que estamos en web
      debugPrint('✅ FCM Web: Servicio inicializado (modo web)');
    } catch (e) {
      debugPrint('❌ FCM Web Error: $e');
    }
  }

  @override
  Future<void> deleteToken() async {
    _fcmToken = null;
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    debugPrint('📦 FCM Web: subscribeToTopic($topic) - no soportado en web');
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    debugPrint('📦 FCM Web: unsubscribeFromTopic($topic) - no soportado en web');
  }

  @override
  void dispose() {}
}

/// Crea una instancia del servicio FCM Web
FcmService createFcmServiceWeb() => FcmServiceWeb();
