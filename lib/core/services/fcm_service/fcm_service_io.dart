import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../notification_refresh_bus.dart';
import 'fcm_service.dart';

/// Handler para mensajes en background (debe ser top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📦 FCM Background: ${message.messageId}');
}

/// Implementación para iOS/Android con soporte completo de FCM
class FcmServiceIo implements FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;

  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  String? get fcmToken => _fcmToken;

  @override
  Future<void> initialize() async {
    debugPrint('🔧 Iniciando FCM Service...');

    // Registrar handler de background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint('✅ Background handler registrado');

    // Solicitar permisos (iOS y Android)
    await _requestPermissions();

    // Obtener token
    await _getToken();

    // Configurar notificaciones locales para Android
    await _setupLocalNotifications();

    // Listeners para mensajes
    _setupMessageListeners();

    // Guardar token en Supabase
    await _saveTokenToSupabase();

    // Escuchar cambios de token FCM
    _messaging.onTokenRefresh.listen((token) async {
      debugPrint('📦 Token FCM actualizado: $token');
      _fcmToken = token;
      await _saveTokenToSupabase();
    });

    // Escuchar cambios de auth para guardar token después del login
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn && _fcmToken != null) {
        debugPrint('📦 Usuario logueado, guardando token FCM pendiente');
        _saveTokenToSupabase();
      }
    });

    debugPrint('✅ FCM Service completamente inicializado');
  }

  Future<void> _requestPermissions() async {
    debugPrint('🔧 Solicitando permisos de notificación...');

    if (Platform.isIOS) {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('📱 iOS Permiso: ${settings.authorizationStatus}');

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      // Android 13+ requiere permiso explícito de POST_NOTIFICATIONS
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      debugPrint('📱 Android Permiso notificaciones: $granted');

      final settings = await _messaging.requestPermission();
      debugPrint('📱 Android FCM Permiso: ${settings.authorizationStatus}');
    }
  }

  Future<void> _getToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken == null) {
        // Retry después de un breve delay por timing en release mode
        await Future<void>.delayed(const Duration(seconds: 2));
        _fcmToken = await _messaging.getToken();
      }
      // El guardado en Supabase lo hace initialize() tras configurar los
      // listeners, para no escribir el token dos veces
    } catch (e) {
      debugPrint('❌ Error obteniendo token FCM: $e');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('📱 Notificación tocada: ${response.payload}');
      },
    );

    // Crear canal de notificación para Android 13+
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'bf_stay_channel',
          'BF Stay Notificaciones',
          description: 'Canal de notificaciones de BF Stay',
          importance: Importance.high,
        ),
      );
    }
  }

  void _setupMessageListeners() {
    // Mensaje mientras la app está en foreground
    _onMessageSubscription = FirebaseMessaging.onMessage.listen((message) {
      debugPrint('📦 FCM Foreground: ${message.messageId}');
      _showLocalNotification(message);
      _emitRefreshSignal(message);
    });

    // Mensaje cuando la app se abre desde una notificación (background)
    _onMessageOpenedAppSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('📦 FCM Opened from background: ${message.messageId}');
      _handleMessageTap(message);
      _emitRefreshSignal(message);
    });

    // Mensaje cuando la app se abre desde terminated state
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('📦 FCM Opened from terminated: ${message.messageId}');
        _handleMessageTap(message);
        _emitRefreshSignal(message);
      }
    });
  }

  /// Notifica a la UI (vía [NotificationRefreshBus]) que llegó un push, para que
  /// pueda recargar sus datos al instante (p. ej. el estado del check-in).
  void _emitRefreshSignal(RemoteMessage message) {
    final type = message.data['type'] as String? ?? '';
    if (type.isNotEmpty) {
      NotificationRefreshBus.instance.emit(type);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    debugPrint('📬 Notificación recibida:');
    debugPrint('   Title: ${notification?.title}');
    debugPrint('   Body: ${notification?.body}');
    debugPrint('   Data: $data');

    // Mostrar notificación local en TODAS las plataformas.
    // En release/profile mode, el plugin firebase_messaging puede no mostrar
    // el banner automáticamente en iOS, así que SIEMPRE mostramos local.
    // Si FCM también la muestra, iOS deduplica automáticamente.
    String title;
    String body;

    if (notification?.title != null && notification?.body != null) {
      // Notificación con payload de notificación (Android)
      title = notification!.title!;
      body = notification.body!;
      debugPrint('📱 Android: Mostrando notificación local');
    } else {
      // Data-only message: título y cuerpo vienen en data
      title = data['title'] as String? ?? 'BF Stay';
      body = data['body'] as String? ?? '';
      debugPrint('📱 Data-only message: Mostrando notificación local');
    }

    if (body.isEmpty) {
      debugPrint('⚠️ Notificación sin contenido');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'bf_stay_channel',
      'BF Stay Notificaciones',
      channelDescription: 'Canal de notificaciones de BF Stay',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      title.hashCode,
      title,
      body,
      details,
      payload: message.data.toString(),
    );
    debugPrint('✅ Notificación local mostrada: $title - $body');
  }

  void _handleMessageTap(RemoteMessage message) {
    final data = message.data;
    debugPrint('📱 Data: $data');
    // Aquí puedes navegar a pantallas específicas según los datos
    // Por ejemplo: si data['type'] == 'chat', navegar al chat
  }

  Future<void> _saveTokenToSupabase() async {
    if (_fcmToken == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('⚠️ No hay usuario autenticado para guardar token FCM');
      return;
    }

    try {
      await Supabase.instance.client.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': _fcmToken,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,token');
      debugPrint('✅ Token FCM guardado en Supabase');
    } catch (e) {
      debugPrint('❌ Error guardando token FCM: $e');
    }
  }

  @override
  Future<void> deleteToken() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await Supabase.instance.client
            .from('fcm_tokens')
            .delete()
            .eq('user_id', userId);
        debugPrint('✅ Token FCM eliminado de Supabase');
      } catch (e) {
        debugPrint('❌ Error eliminando token FCM: $e');
      }
    }

    await _messaging.deleteToken();
    _fcmToken = null;
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Suscrito al topic: $topic');
    } catch (e) {
      debugPrint('❌ Error suscribiendo al topic: $e');
    }
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Desuscrito del topic: $topic');
    } catch (e) {
      debugPrint('❌ Error desuscribiendo del topic: $e');
    }
  }

  @override
  void dispose() {
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    _authStateSubscription?.cancel();
  }
}

/// Crea una instancia del servicio FCM para IO (iOS/Android)
FcmService createFcmServiceIo() => FcmServiceIo();
