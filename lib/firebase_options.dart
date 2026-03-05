import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Configuración de Firebase para BF Stay
///
/// Para obtener estos valores:
/// 1. Ve a Firebase Console > Project Settings
/// 2. Descarga google-services.json (Android) y GoogleService-Info.plist (iOS)
/// 3. Los valores están dentro de esos archivos
///
/// IMPORTANTE: No subas este archivo a repositorios públicos si contiene
/// datos sensibles. Usa variables de entorno para producción.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no está soportado para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB-WL4jfhbha9kXQKqRQEVZyiWxd1DGpYc',
    appId: '1:949013046522:android:1431c447acc8c2e1299543',
    messagingSenderId: '949013046522',
    projectId: 'bf-stay',
    storageBucket: 'bf-stay.firebasestorage.app',
  );

  /// REEMPLAZAR con tus valores de google-services.json

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDy-DT6LmFxRFw036OBY3OXo5RSCLUYr48',
    appId: '1:949013046522:ios:fe4cc401cca70a0e299543',
    messagingSenderId: '949013046522',
    projectId: 'bf-stay',
    storageBucket: 'bf-stay.firebasestorage.app',
    iosBundleId: 'com.grupobf.bfstay',
  );

  /// REEMPLAZAR con tus valores de GoogleService-Info.plist

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCVc0ynF06CXJRyg8uYzP9Hixm-ebsOYZ4',
    appId: '1:949013046522:web:7819b19614ac5969299543',
    messagingSenderId: '949013046522',
    projectId: 'bf-stay',
    authDomain: 'bf-stay.firebaseapp.com',
    storageBucket: 'bf-stay.firebasestorage.app',
    measurementId: 'G-BB4CMLTK4B',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'TU_API_KEY_IOS',
    appId: 'TU_APP_ID_IOS',
    messagingSenderId: 'TU_MESSAGING_SENDER_ID',
    projectId: 'TU_PROJECT_ID',
    storageBucket: 'TU_STORAGE_BUCKET',
    iosBundleId: 'com.bfstay.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCVc0ynF06CXJRyg8uYzP9Hixm-ebsOYZ4',
    appId: '1:949013046522:web:5ad0b49ae5e677bc299543',
    messagingSenderId: '949013046522',
    projectId: 'bf-stay',
    authDomain: 'bf-stay.firebaseapp.com',
    storageBucket: 'bf-stay.firebasestorage.app',
    measurementId: 'G-SW3KK5L1LP',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'TU_API_KEY_WEB',
    appId: 'TU_APP_ID_WEB',
    messagingSenderId: 'TU_MESSAGING_SENDER_ID',
    projectId: 'TU_PROJECT_ID',
    storageBucket: 'TU_STORAGE_BUCKET',
  );
}