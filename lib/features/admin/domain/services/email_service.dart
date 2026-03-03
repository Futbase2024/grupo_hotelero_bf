import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

/// Servicio para enviar emails a través de Edge Functions de Brevo
class EmailService {
  EmailService._();

  static final EmailService _instance = EmailService._();
  factory EmailService() => _instance;

  SupabaseClient get _client => Supabase.instance.client;

  /// Envía email de confirmación de check-in validado
  Future<bool> sendCheckinConfirmationEmail({
    required String toEmail,
    required String guestName,
    required String propertyName,
    required String unitName,
    required DateTime checkinDate,
    required DateTime checkoutDate,
    required String bookingCode,
    String? accessInstructions,
    String? wifiNetwork,
    String? wifiPassword,
    String? fullAddress,
    String? bookingId,
    String? unitId,
  }) async {
    try {
      debugPrint('📧 [EmailService] Enviando email de confirmación a: $toEmail');

      final response = await _client.functions.invoke(
        'send-checkin-email',
        body: {
          'to_email': toEmail,
          'to_name': guestName,
          'params': {
            'nombre_huesped': guestName,
            'nombre_propiedad': '$propertyName - $unitName',
            'fecha_entrada': DateFormat('dd/MM/yyyy').format(checkinDate),
            'fecha_salida': DateFormat('dd/MM/yyyy').format(checkoutDate),
            'codigo_acceso': bookingCode,
            'link_app': 'https://bf-stay.pages.dev/',
            'telefono_soporte': '+34 900 000 000',
          },
          'booking_id': bookingId,
          'unit_id': unitId,
        },
      );

      if (response.status == 200) {
        debugPrint('✅ [EmailService] Email enviado correctamente');
        return true;
      } else {
        debugPrint('❌ [EmailService] Error enviando email: ${response.status}');
        debugPrint('❌ [EmailService] Response: ${response.data}');
        return false;
      }
    } catch (e, s) {
      debugPrint('❌ [EmailService] Excepción enviando email: $e');
      debugPrint('❌ [EmailService] StackTrace: $s');
      return false;
    }
  }

  /// Envía email de cancelación de check-in
  Future<bool> sendCheckinCancellationEmail({
    required String toEmail,
    required String guestName,
    required String propertyName,
    required String unitName,
    required DateTime checkinDate,
    required DateTime checkoutDate,
    String? reason,
    String? bookingId,
    String? unitId,
  }) async {
    try {
      debugPrint('📧 [EmailService] Enviando email de cancelación a: $toEmail');

      final response = await _client.functions.invoke(
        'send-checkin-cancellation-email',
        body: {
          'to_email': toEmail,
          'to_name': guestName,
          'params': {
            'nombre_huesped': guestName,
            'nombre_propiedad': '$propertyName - $unitName',
            'fecha_entrada': DateFormat('dd/MM/yyyy').format(checkinDate),
            'fecha_salida': DateFormat('dd/MM/yyyy').format(checkoutDate),
            'motivo_cancelacion': reason ?? 'No especificado',
            'telefono_soporte': '+34 900 000 000',
          },
          'booking_id': bookingId,
          'unit_id': unitId,
        },
      );

      if (response.status == 200) {
        debugPrint('✅ [EmailService] Email de cancelación enviado');
        return true;
      } else {
        debugPrint('❌ [EmailService] Error enviando email: ${response.status}');
        return false;
      }
    } catch (e, s) {
      debugPrint('❌ [EmailService] Excepción: $e');
      debugPrint('❌ [EmailService] StackTrace: $s');
      return false;
    }
  }

  /// Envía email de rechazo de check-in
  Future<bool> sendCheckinRejectionEmail({
    required String toEmail,
    required String guestName,
    required String propertyName,
    required String unitName,
    required DateTime checkinDate,
    required DateTime checkoutDate,
    String? reason,
    String? bookingId,
    String? unitId,
  }) async {
    try {
      debugPrint('📧 [EmailService] Enviando email de rechazo a: $toEmail');

      final response = await _client.functions.invoke(
        'send-cancellation-email',
        body: {
          'to_email': toEmail,
          'to_name': guestName,
          'params': {
            'nombre_huesped': guestName,
            'nombre_propiedad': '$propertyName - $unitName',
            'fecha_entrada': DateFormat('dd/MM/yyyy').format(checkinDate),
            'fecha_salida': DateFormat('dd/MM/yyyy').format(checkoutDate),
            'motivo_cancelacion': reason ?? 'Documentación incorrecta',
            'telefono_soporte': '+34 900 000 000',
          },
          'booking_id': bookingId,
          'unit_id': unitId,
        },
      );

      if (response.status == 200) {
        debugPrint('✅ [EmailService] Email de rechazo enviado');
        return true;
      } else {
        debugPrint('❌ [EmailService] Error enviando email: ${response.status}');
        return false;
      }
    } catch (e, s) {
      debugPrint('❌ [EmailService] Excepción: $e');
      debugPrint('❌ [EmailService] StackTrace: $s');
      return false;
    }
  }

  /// Envía email con información de acceso
  Future<bool> sendAccessInfoEmail({
    required String toEmail,
    required String guestName,
    required String propertyName,
    required String unitName,
    String? boxCode,
    String? accessInstructions,
    String? fullAddress,
    String? bookingId,
    String? unitId,
  }) async {
    try {
      debugPrint('📧 [EmailService] Enviando info de acceso a: $toEmail');

      final response = await _client.functions.invoke(
        'send-access-code-email',
        body: {
          'to_email': toEmail,
          'to_name': guestName,
          'params': {
            'nombre_huesped': guestName,
            'nombre_propiedad': '$propertyName - $unitName',
            'codigo_acceso': boxCode ?? 'Consultar en recepción',
            'instrucciones_acceso': accessInstructions ?? '',
            'telefono_soporte': '+34 900 000 000',
          },
          'booking_id': bookingId,
          'unit_id': unitId,
        },
      );

      return response.status == 200;
    } catch (e) {
      debugPrint('❌ [EmailService] Error: $e');
      return false;
    }
  }
}
