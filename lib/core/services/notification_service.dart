import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio centralizado para gestionar notificaciones push e in-app
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  SupabaseClient get _client => Supabase.instance.client;

  /// Obtiene el token FCM de un usuario usando la función RPC segura
  /// Esta función usa SECURITY DEFINER para evitar problemas de RLS
  Future<String?> _getFcmTokenSecure(String userId) async {
    try {
      final response = await _client.rpc(
        'get_fcm_token_for_user',
        params: {'target_user_id': userId},
      );
      return response as String?;
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Error obteniendo token FCM seguro: $e');
      return null;
    }
  }

  /// Obtiene los tokens FCM de múltiples usuarios usando la función RPC segura
  /// Retorna un mapa de user_id -> token
  Future<Map<String, String>> _getFcmTokensSecure(List<String> userIds) async {
    try {
      final response = await _client.rpc(
        'get_fcm_tokens_for_users',
        params: {'target_user_ids': userIds},
      );

      final tokens = <String, String>{};
      if (response is List) {
        for (final row in response) {
          if (row is Map) {
            final userId = row['user_id'] as String?;
            final token = row['token'] as String?;
            if (userId != null && token != null) {
              tokens[userId] = token;
            }
          }
        }
      }
      return tokens;
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Error obteniendo tokens FCM seguros: $e');
      return {};
    }
  }

  /// Encola una notificación push para ser enviada vía FCM
  /// La notificación será procesada por la Edge Function send-fcm-notifications
  /// Si no se pasa el token, se obtendrá usando la función RPC segura (sin problemas de RLS)
  Future<bool> queuePushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? fcmToken,
  }) async {
    try {
      debugPrint('📬 [NotificationService] Encolando push para usuario: $userId');

      // 1. Usar el token pasado o obtenerlo usando la función RPC segura
      String token;
      if (fcmToken != null && fcmToken.isNotEmpty) {
        token = fcmToken;
        debugPrint('📬 [NotificationService] Usando token proporcionado directamente');
      } else {
        // Obtener el token FCM usando la función RPC segura (SECURITY DEFINER)
        // Esto evita problemas de RLS cuando un usuario necesita obtener tokens de otros
        token = await _getFcmTokenSecure(userId) ?? '';

        if (token.isEmpty) {
          debugPrint('⚠️ [NotificationService] Usuario sin token FCM: $userId');
          return false;
        }
        debugPrint('📬 [NotificationService] Token obtenido vía RPC segura');
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
  /// Usa la función RPC segura para obtener tokens FCM
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

      // 3. Obtener los tokens FCM de los admins usando la función RPC segura
      final adminUserIds = adminsList.map((a) => a['user_id'] as String).toList();
      final userTokens = await _getFcmTokensSecure(adminUserIds);

      debugPrint('📬 [NotificationService] Tokens FCM encontrados vía RPC: ${userTokens.length}');

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
          title = '✅ Check-in Validado';
          body = 'Tu check-in ha sido validado correctamente. ¡Bienvenido!';
          notificationType = 'checkin_validated';
          break;
        case 'rejected':
          title = '❌ Check-in Rechazado';
          body = reason != null
              ? 'Tu check-in ha sido rechazado: $reason'
              : 'Tu check-in ha sido rechazado. Por favor, revisa tu documentación.';
          notificationType = 'checkin_rejected';
          break;
        case 'cancelled':
          title = '🚫 Reserva Cancelada';
          body = reason != null
              ? 'Tu reserva ha sido cancelada: $reason'
              : 'Tu reserva ha sido cancelada. Contacta con recepción.';
          notificationType = 'booking_cancelled';
          break;
        default:
          title = '📋 Actualización de Check-in';
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

      // 4. Encolar push notification usando la función RPC segura
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
      title: '📝 Nuevo Check-in Pendiente',
      body: '$guestName ha enviado su check-in para $unitName. Pendiente de revisión.',
      bookingId: bookingId,
      data: {
        'action': 'review_checkin',
      },
    );
  }

  /// Envía email de notificación al admin cuando un huésped completa el check-in
  /// El email va a ghotelerobf@gmail.com vía Brevo
  Future<bool> sendCheckinCompletedEmail({
    required String bookingId,
    required String guestName,
    required String propertyName,
    required String bookingCode,
    required DateTime checkInDate,
    required DateTime checkOutDate,
  }) async {
    try {
      debugPrint('📧 [NotificationService] Enviando email de check-in completado...');
      debugPrint('📧 [NotificationService] Huésped: $guestName');
      debugPrint('📧 [NotificationService] Propiedad: $propertyName');
      debugPrint('📧 [NotificationService] Reserva: $bookingCode');

      final response = await _client.functions.invoke(
        'send-checkin-notification',
        body: {
          'checkin_id': bookingId,
          'guest_name': guestName,
          'property_name': propertyName,
          'booking_code': bookingCode,
          'check_in_date': checkInDate.toIso8601String(),
          'check_out_date': checkOutDate.toIso8601String(),
        },
      );

      if (response.status == 200) {
        debugPrint('✅ [NotificationService] Email de check-in completado enviado');
        return true;
      } else {
        debugPrint('❌ [NotificationService] Error enviando email: ${response.status}');
        debugPrint('❌ [NotificationService] Response: ${response.data}');
        return false;
      }
    } catch (e, s) {
      debugPrint('❌ [NotificationService] Excepción enviando email: $e');
      debugPrint('❌ [NotificationService] StackTrace: $s');
      return false;
    }
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
