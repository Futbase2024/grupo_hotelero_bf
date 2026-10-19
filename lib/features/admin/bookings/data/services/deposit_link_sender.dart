import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/config/supabase_config.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/utils/whatsapp_phone.dart';
import '../../../../guest/chat/domain/repositories/chat_repository.dart';
import '../../../domain/entities/booking_deposit_entity.dart';

/// Canal externo (fuera de la app) por el que se envía el enlace de la fianza
enum DepositExternalChannel {
  none,
  whatsapp,
  email;

  /// Valor guardado en `bookings.deposit_sent_via`
  String? get dbValue => this == none ? null : name;
}

/// Envía al huésped el enlace de pago de la fianza.
///
/// El pago no pasa por la app: el admin genera el enlace en la pasarela de su
/// banco y aquí solo se hace llegar al huésped.
///  · Chat de la app: se inserta el mensaje en la conversación de la reserva.
///  · Email: lo envía el servidor con la plantilla de Brevo "Fianza pendiente".
///  · WhatsApp: se abre la app con el mensaje ya redactado para que el admin
///    solo tenga que pulsar enviar.
class DepositLinkSender {
  const DepositLinkSender();

  /// Envía el mensaje por el chat de la app
  Future<void> sendViaChat({
    required BookingDepositEntity deposit,
    required String message,
  }) async {
    final senderId = SupabaseConfig.currentUser?.id;
    if (senderId == null || !deposit.hasGuestAppUser) {
      throw StateError('Sin usuario para enviar por el chat');
    }

    final chatRepository = getIt<ChatRepository>();
    final conversation = await chatRepository.getOrCreateConversation(
      propertyId: deposit.propertyId,
      bookingId: deposit.bookingId,
      guestUserId: deposit.guestUserId!,
      guestName: deposit.guestName,
    );

    await chatRepository.sendTextMessage(
      conversationId: conversation.id,
      senderUserId: senderId,
      content: message,
    );
  }

  /// Abre WhatsApp con el mensaje redactado. Retorna `false` si no se pudo abrir
  Future<bool> openWhatsApp({
    required String phone,
    required String message,
  }) async {
    final phoneWithCode = normalizePhoneForWhatsApp(phone);
    final text = Uri.encodeComponent(message);

    final candidates = [
      Uri.parse('whatsapp://send?phone=$phoneWithCode&text=$text'),
      Uri.parse('https://wa.me/$phoneWithCode?text=$text'),
    ];

    for (final uri in candidates) {
      try {
        if (await canLaunchUrl(uri) &&
            await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return true;
        }
      } catch (e) {
        debugPrint('⚠️ [DepositLinkSender] No se pudo abrir $uri: $e');
      }
    }
    return false;
  }

  /// Envía el email "Fianza pendiente" desde el servidor (plantilla Brevo).
  ///
  /// La Edge Function `send-deposit-email` lee destinatario, importe y enlace
  /// de la base de datos: aquí solo se indica la reserva.
  /// Retorna `false` si no se pudo enviar.
  Future<bool> sendEmail({required String bookingId}) async {
    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'send-deposit-email',
        body: {'booking_id': bookingId},
      );
      return response.status == 200;
    } catch (e) {
      debugPrint('⚠️ [DepositLinkSender] No se pudo enviar el email: $e');
      return false;
    }
  }
}
