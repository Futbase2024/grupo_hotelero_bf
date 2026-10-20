import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio centralizado para gestionar notificaciones push e in-app
///
/// Los avisos del huésped al staff (check-in enviado o auto-validado, solicitud
/// de extra) los genera el servidor con triggers; aquí solo quedan los que
/// manda el staff al huésped y el email de check-in completado.
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  SupabaseClient get _client => Supabase.instance.client;

  /// Obtiene TODOS los tokens FCM de un usuario usando la función RPC segura
  /// Retorna una lista de tokens (un usuario puede tener múltiples dispositivos)
  Future<List<String>> _getFcmTokensForUser(String userId) async {
    try {
      final response = await _client.rpc(
        'get_fcm_tokens_for_users',
        params: {'target_user_ids': [userId]},
      );

      final tokens = <String>[];
      if (response is List) {
        for (final row in response) {
          if (row is Map) {
            final token = row['token'] as String?;
            if (token != null && token.isNotEmpty) {
              tokens.add(token);
            }
          }
        }
      }
      return tokens;
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Error obteniendo tokens FCM: $e');
      return [];
    }
  }

  /// Encola una notificación push para ser enviada vía FCM a TODOS los dispositivos del usuario
  /// La notificación será procesada por la Edge Function send-fcm-notifications
  Future<bool> queuePushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? fcmToken,
  }) async {
    try {
      debugPrint('📬 [NotificationService] Encolando push para usuario: $userId');

      // 1. Determinar los tokens a usar
      List<String> tokens;
      if (fcmToken != null && fcmToken.isNotEmpty) {
        tokens = [fcmToken];
        debugPrint('📬 [NotificationService] Usando token proporcionado directamente');
      } else {
        // Obtener TODOS los tokens del usuario (múltiples dispositivos)
        tokens = await _getFcmTokensForUser(userId);

        if (tokens.isEmpty) {
          debugPrint('⚠️ [NotificationService] Usuario sin tokens FCM: $userId');
          return false;
        }
        debugPrint('📬 [NotificationService] ${tokens.length} tokens encontrados vía RPC');
      }

      // 2. Insertar en la cola una notificación por cada token
      int successCount = 0;
      for (final token in tokens) {
        try {
          await _client.from('notification_queue').insert({
            'user_id': userId,
            'token': token,
            'title': title,
            'body': body,
            'data': data ?? {},
            'processed': false,
          });
          successCount++;
        } catch (e) {
          debugPrint('⚠️ [NotificationService] Error encolando para token ${token.substring(0, 10)}...: $e');
        }
      }

      debugPrint('✅ [NotificationService] $successCount/${tokens.length} push encolados: $title');

      // 3. Disparar el procesamiento de la cola (llamar a Edge Function)
      if (successCount > 0) {
        await _triggerNotificationProcessing();
      }

      return successCount > 0;
    } catch (e, s) {
      debugPrint('❌ [NotificationService] Error encolando push: $e');
      debugPrint('❌ [NotificationService] StackTrace: $s');
      return false;
    }
  }

  /// Notifica al huésped del cambio de estado de su check-in
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

      // 4. Encolar push notification (a todos los dispositivos del huésped)
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

  /// Envía email de notificación al admin cuando un huésped completa el check-in
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
        return false;
      }
    } catch (e, s) {
      debugPrint('❌ [NotificationService] Excepción enviando email: $e');
      debugPrint('❌ [NotificationService] StackTrace: $s');
      return false;
    }
  }

  /// Dispara el procesamiento de la cola de notificaciones
  Future<void> _triggerNotificationProcessing() async {
    try {
      await _client.functions.invoke('send-fcm-notifications');
      debugPrint('✅ [NotificationService] Procesamiento de cola disparado');
    } catch (e) {
      debugPrint('⚠️ [NotificationService] No se pudo disparar procesamiento: $e');
    }
  }
}
