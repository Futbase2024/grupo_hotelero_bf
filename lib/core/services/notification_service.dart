import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio centralizado para gestionar notificaciones push e in-app
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  SupabaseClient get _client => Supabase.instance.client;

  /// Encola una notificación push para ser enviada vía FCM
  /// La notificación será procesada por la Edge Function send-fcm-notifications
  /// Si no se pasa el token, se obtendrá desde la base de datos (requiere permisos RLS)
  Future<bool> queuePushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? fcmToken,
  }) async {
    try {
      debugPrint('📬 [NotificationService] Encolando push para usuario: $userId');

      // 1. Usar el token pasado o intentar obtenerlo de la base de datos
      String token;
      if (fcmToken != null && fcmToken.isNotEmpty) {
        token = fcmToken;
        debugPrint('📬 [NotificationService] Usando token proporcionado directamente');
      } else {
        // Intentar obtener el token FCM activo del usuario
        // NOTA: Esto puede fallar por RLS si el usuario no tiene permisos para leer tokens ajenos
        final tokenResponse = await _client
            .from('fcm_tokens')
            .select('token')
            .eq('user_id', userId)
            .eq('is_active', true)
            .maybeSingle();

        if (tokenResponse == null) {
          debugPrint('⚠️ [NotificationService] Usuario sin token FCM: $userId');
          return false;
        }

        token = tokenResponse['token'] as String;
      }

      // 2. Insertar en la cola de notificaciones
      await _client.from('notification_queue').insert({
        'user_id': userId,
        'token': token,
        'title': title,
        'body': body,
        'data': data ?? {},
        'processed': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ [NotificationService] Push encolado: $title');

      // 3. Disparar el procesamiento de la cola (llamar a Edge Function)
      await _triggerNotificationProcessing();

      return true;
    } catch (e, s) {
      debugPrint('❌ [NotificationService] Error encolando push: $e');
      debugPrint('❌ [NotificationService] StackTrace: $s');
      return false;
    }
  }

  /// Crea una notificación in-app para staff/admin
  /// Estas notificaciones se muestran en el panel de administración
  Future<bool> createStaffNotification({
    required String type,
    required String title,
    required String body,
    String? bookingId,
    String? propertyId,
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('📬 [NotificationService] Creando notificación staff: $type');

      await _client.from('staff_notifications').insert({
        'type': type,
        'title': title,
        'body': body,
        'booking_id': bookingId,
        'property_id': propertyId,
        'data': data ?? {},
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ [NotificationService] Notificación staff creada');
      return true;
    } catch (e, s) {
      debugPrint('❌ [NotificationService] Error creando notificación staff: $e');
      debugPrint('❌ [NotificationService] StackTrace: $s');
      return false;
    }
  }

  /// Notifica a todos los administradores de una propiedad
  /// Envía tanto notificación push como in-app
  Future<void> notifyAdmins({
    required String propertyId,
    required String type,
    required String title,
    required String body,
    String? bookingId,
    Map<String, dynamic>? data,
  }) async {
    try {
      // 1. Obtener todos los admins y filtrar en Dart (más confiable que .filter() con null)
      final allAdmins = await _client
          .from('user_roles')
          .select('user_id, property_id')
          .eq('role', 'admin');

      // 2. Filtrar: admins de la propiedad O admins globales (property_id null)
      final adminsList = allAdmins.where((admin) {
        final adminPropertyId = admin['property_id'] as String?;
        // Es admin global (property_id null) O es admin de esta propiedad
        return adminPropertyId == null || adminPropertyId == propertyId;
      }).toList();

      debugPrint('📬 [NotificationService] Total admins encontrados: ${allAdmins.length}');
      debugPrint('📬 [NotificationService] Admins filtrados para propiedad: ${adminsList.length}');

      if (adminsList.isEmpty) {
        debugPrint('⚠️ [NotificationService] No hay admins para la propiedad');
        return;
      }

      // 3. Obtener los tokens FCM de los admins
      final adminUserIds = adminsList.map((a) => a['user_id'] as String).toList();
      final tokensResponse = await _client
          .from('fcm_tokens')
          .select('user_id, token')
          .inFilter('user_id', adminUserIds)
          .eq('is_active', true);

      // Crear mapa de user_id -> token
      final userTokens = <String, String>{};
      for (final row in tokensResponse) {
        userTokens[row['user_id'] as String] = row['token'] as String;
      }
      debugPrint('📬 [NotificationService] Tokens FCM encontrados: ${userTokens.length}');

      // 4. Crear notificación in-app (una sola vez, visible para todos los admins)
      await createStaffNotification(
        type: type,
        title: title,
        body: body,
        bookingId: bookingId,
        propertyId: propertyId,
        data: data,
      );

      // 5. Encolar push notification para cada admin con token
      int successCount = 0;
      for (final admin in adminsList) {
        final userId = admin['user_id'] as String;
        final token = userTokens[userId];

        if (token == null) {
          debugPrint('⚠️ [NotificationService] Admin $userId sin token FCM, saltando push');
          continue;
        }

        final success = await queuePushNotification(
          userId: userId,
          title: title,
          body: body,
          data: {
            ...?data,
            'type': type,
            'booking_id': bookingId,
            'property_id': propertyId,
          },
          fcmToken: token, // Pasar el token directamente para evitar problemas de RLS
        );
        if (success) successCount++;
      }

      debugPrint('✅ [NotificationService] $successCount/${adminsList.length} admins notificados con push');
    } catch (e, s) {
      debugPrint('❌ [NotificationService] Error notificando admins: $e');
      debugPrint('❌ [NotificationService] StackTrace: $s');
    }
  }

  /// Notifica al huésped del cambio de estado de su check-in
  /// Envía push notification si tiene la app instalada y crea notificación in-app
  Future<void> notifyGuestCheckinStatus({
    required String bookingId,
    required String status,
    String? reason,
  }) async {
    try {
      debugPrint('📬 [NotificationService] Notificando huésped: $status');

      // 1. Obtener el primary_guest_user_id de la reserva
      final bookingResponse = await _client
          .from('bookings')
          .select('primary_guest_user_id, booking_code, guest_first_name')
          .eq('id', bookingId)
          .maybeSingle();

      if (bookingResponse == null) {
        debugPrint('⚠️ [NotificationService] Reserva no encontrada');
        return;
      }

      final guestUserId = bookingResponse['primary_guest_user_id'] as String?;
      if (guestUserId == null) {
        debugPrint('⚠️ [NotificationService] Reserva sin huésped principal');
        return;
      }

      // 2. Determinar título y cuerpo según el estado
      String title;
      String body;
      String notificationType;

      switch (status) {
        case 'validated':
          title = 'Check-in Validado';
          body = 'Tu check-in ha sido validado correctamente. ¡Bienvenido!';
          notificationType = 'checkin_validated';
          break;
        case 'rejected':
          title = 'Check-in Rechazado';
          body = reason != null
              ? 'Tu check-in ha sido rechazado: $reason'
              : 'Tu check-in ha sido rechazado. Por favor, revisa tu documentación.';
          notificationType = 'checkin_rejected';
          break;
        case 'cancelled':
          title = 'Reserva Cancelada';
          body = reason != null
              ? 'Tu reserva ha sido cancelada: $reason'
              : 'Tu reserva ha sido cancelada. Contacta con recepción.';
          notificationType = 'booking_cancelled';
          break;
        default:
          title = 'Actualización de Check-in';
          body = 'El estado de tu check-in ha cambiado a: $status';
          notificationType = 'checkin_status_update';
      }

      // 3. Crear notificación in-app para el huésped
      await _createGuestNotification(
        userId: guestUserId,
        type: notificationType,
        title: title,
        body: body,
        bookingId: bookingId,
        data: {
          'status': status,
          if (reason != null) 'reason': reason,
        },
      );

      // 4. Encolar push notification
      final notificationData = <String, dynamic>{
        'type': 'checkin_status_update',
        'status': status,
        'booking_id': bookingId,
      };
      if (reason != null) {
        notificationData['reason'] = reason;
      }

      await queuePushNotification(
        userId: guestUserId,
        title: title,
        body: body,
        data: notificationData,
      );

      debugPrint('✅ [NotificationService] Huésped notificado: $status');
    } catch (e, s) {
      debugPrint('❌ [NotificationService] Error notificando huésped: $e');
      debugPrint('❌ [NotificationService] StackTrace: $s');
    }
  }

  /// Crea una notificación in-app para el huésped
  Future<void> _createGuestNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? bookingId,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _client.from('guest_notifications').insert({
        'user_id': userId,
        'type': type,
        'title': title,
        'body': body,
        'booking_id': bookingId,
        'data': data ?? {},
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ [NotificationService] Notificación in-app creada para huésped');
    } catch (e) {
      debugPrint('❌ [NotificationService] Error creando notificación in-app: $e');
    }
  }

  /// Notifica al admin cuando un huésped hace check-in
  Future<void> notifyAdminCheckinSubmitted({
    required String bookingId,
    required String propertyId,
    required String guestName,
    required String unitName,
  }) async {
    await notifyAdmins(
      propertyId: propertyId,
      type: 'checkin_submitted',
      title: 'Nuevo Check-in Pendiente',
      body: '$guestName ha enviado su check-in para $unitName. Pendiente de revisión.',
      bookingId: bookingId,
      data: {
        'action': 'review_checkin',
      },
    );
  }

  /// Dispara el procesamiento de la cola de notificaciones
  /// Llama a la Edge Function que envía las notificaciones vía FCM
  Future<void> _triggerNotificationProcessing() async {
    try {
      // Llamar a la Edge Function para procesar la cola
      await _client.functions.invoke('send-fcm-notifications');
      debugPrint('✅ [NotificationService] Procesamiento de cola disparado');
    } catch (e) {
      // No es crítico si falla, la cola se procesará en el siguiente intento
      debugPrint('⚠️ [NotificationService] No se pudo disparar procesamiento: $e');
    }
  }
}
