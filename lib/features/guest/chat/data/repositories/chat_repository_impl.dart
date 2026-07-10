import '../datasources/chat_datasource.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_change.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';

/// Implementación del repositorio de Chat
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({ChatDatasource? datasource})
      : _datasource = datasource ?? ChatDatasource();

  final ChatDatasource _datasource;

  @override
  Future<ConversationEntity> getOrCreateConversation({
    required String propertyId,
    String? bookingId,
    required String guestUserId,
    required String guestName,
  }) async {
    return await _datasource.getOrCreateConversation(
      propertyId: propertyId,
      bookingId: bookingId,
      guestUserId: guestUserId,
      guestName: guestName,
    );
  }

  @override
  Future<ConversationEntity?> getConversation(String conversationId) async {
    return await _datasource.getConversation(conversationId);
  }

  @override
  Future<List<ConversationEntity>> getConversationsByProperty({
    required String propertyId,
  }) async {
    return await _datasource.getConversationsByProperty(
      propertyId: propertyId,
    );
  }

  @override
  Future<List<ConversationEntity>> getConversationsForUser({
    required String userId,
    String? propertyId,
  }) async {
    return await _datasource.getConversationsForUser(
      userId: userId,
      propertyId: propertyId,
    );
  }

  @override
  Future<ConversationEntity?> getActiveConversation({
    required String userId,
    required String propertyId,
  }) async {
    // Por ahora retorna null, se implementa con el datasource
    return null;
  }

  @override
  Future<List<MessageEntity>> getMessages({
    required String conversationId,
    int limit = 50,
    DateTime? before,
  }) async {
    return await _datasource.getMessages(
      conversationId: conversationId,
      limit: limit,
      before: before,
    );
  }

  @override
  Future<MessageEntity> sendTextMessage({
    required String conversationId,
    required String senderUserId,
    required String content,
  }) async {
    return await _datasource.sendTextMessage(
      conversationId: conversationId,
      senderUserId: senderUserId,
      content: content,
    );
  }

  @override
  Future<MessageEntity> sendImageMessage({
    required String conversationId,
    required String senderUserId,
    required String imagePath,
  }) async {
    return await _datasource.sendImageMessage(
      conversationId: conversationId,
      senderUserId: senderUserId,
      imagePath: imagePath,
    );
  }

  @override
  Stream<MessageChange> watchMessages(String conversationId) {
    return _datasource.watchMessages(conversationId);
  }

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  }) async {
    return await _datasource.markAsRead(
      conversationId: conversationId,
      userId: userId,
    );
  }

  @override
  Future<int> getUnreadCount({
    required String conversationId,
    required String userId,
  }) async {
    return await _datasource.getUnreadCount(
      conversationId: conversationId,
      userId: userId,
    );
  }

  @override
  Stream<List<ConversationEntity>> watchUserConversations({
    required String userId,
    String? propertyId,
  }) {
    return _datasource.watchUserConversations(
      userId: userId,
      propertyId: propertyId,
    );
  }

  @override
  Future<void> deleteConversation({
    required String conversationId,
  }) async {
    return await _datasource.deleteConversation(
      conversationId: conversationId,
    );
  }

  @override
  Future<void> deleteMessage({
    required String messageId,
  }) async {
    return await _datasource.deleteMessage(
      messageId: messageId,
    );
  }

  @override
  void dispose() {
    _datasource.dispose();
  }
}
