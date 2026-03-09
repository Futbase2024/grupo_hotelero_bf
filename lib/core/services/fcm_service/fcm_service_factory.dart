import 'package:flutter/foundation.dart';

import 'fcm_service.dart';
import 'fcm_service_stub.dart' show createFcmServiceStub;
import 'fcm_service_io.dart' show createFcmServiceIo;
import 'fcm_service_web.dart' show createFcmServiceWeb;

/// Instancia singleton del servicio FCM
FcmService? _fcmServiceInstance;

/// Obtiene la instancia del servicio FCM
FcmService get fcmService {
  _fcmServiceInstance ??= _createFcmService();
  return _fcmServiceInstance!;
}

/// Crea la instancia apropiada según la plataforma
FcmService _createFcmService() {
  if (kIsWeb) {
    debugPrint('FCM: Usando implementación Web');
    return createFcmServiceWeb();
  }
  // En móvil (iOS/Android) usamos la implementación nativa
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android) {
    debugPrint('FCM: Usando implementación nativa (IO)');
    return createFcmServiceIo();
  }
  // Fallback para otras plataformas
  debugPrint('FCM: Usando implementación stub');
  return createFcmServiceStub();
}
