import '../entities/conversation_entity.dart';
import '../entities/message_entity.dart';

/// Contrato del repositorio de Chat
/// La implementación está en data/repositories/chat_repository_impl.dart
abstract class ChatRepository {
  /// Obtiene o crea una conversación para un booking específico
  Future<ConversationEntity> getOrCreateConversation({
    required String propertyId,
    String? bookingId,
    required String guestUserId,
    required String guestName,
  });

  /// Obtiene una conversación por ID
  Future<ConversationEntity?> getConversation(String conversationId);

  /// Obtiene todas las conversaciones de una propiedad (para admin/staff)
  Future<List<ConversationEntity>> getConversationsByProperty({
    required String propertyId,
  });

  /// Obtiene todas las conversaciones donde el usuario es participante
  Future<List<ConversationEntity>> getConversationsForUser({
    required String userId,
    String? propertyId,
  });

  /// Obtiene la conversación activa para el usuario actual
  Future<ConversationEntity?> getActiveConversation({
    required String userId,
    required String propertyId,
  });

  /// Obtiene los mensajes de una conversación
  Future<List<MessageEntity>> getMessages({
    required String conversationId,
    int limit = 50,
    DateTime? before,
  });

  /// Envía un mensaje de texto
  Future<MessageEntity> sendTextMessage({
    required String conversationId,
    required String senderUserId,
    required String content,
  });

  /// Envía un mensaje con imagen
  Future<MessageEntity> sendImageMessage({
    required String conversationId,
    required String senderUserId,
    required String imagePath,
  });

  /// Suscribe a nuevos mensajes en tiempo real
  /// Solo emite cuando llega un mensaje nuevo (no re-emite mensajes existentes)
  Stream<MessageEntity> watchMessages(String conversationId);

  /// Marca mensajes como leídos
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  });

  /// Suscribe a cambios en las conversaciones del usuario en tiempo real
  /// Incluye actualización de unread_count y último mensaje
  Stream<List<ConversationEntity>> watchUserConversations({
    required String userId,
    String? propertyId,
  });

  /// Obtiene el conteo de mensajes no leídos
  Future<int> getUnreadCount({
    required String conversationId,
    required String userId,
  });

  /// Dispose de recursos (cancelar suscripciones)
  void dispose();
}
