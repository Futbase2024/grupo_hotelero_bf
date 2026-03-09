import 'package:flutter/foundation.dart';

import 'fcm_service.dart';

/// Implementación stub para plataformas no soportadas
class FcmServiceStub implements FcmService {
  @override
  String? get fcmToken => null;

  @override
  Future<void> initialize() async {
    debugPrint('⚠️ FCM no está soportado en esta plataforma');
  }

  @override
  Future<void> deleteToken() async {}

  @override
  Future<void> subscribeToTopic(String topic) async {}

  @override
  Future<void> unsubscribeFromTopic(String topic) async {}

  @override
  void dispose() {}
}

/// Crea una instancia del servicio FCM stub
FcmService createFcmServiceStub() => FcmServiceStub();
