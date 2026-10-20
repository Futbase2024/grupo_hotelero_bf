// Tests del buscador de la lista de conversaciones (filtrado local).

import 'dart:async';

import 'package:bf_stay/features/admin/chat/domain/bloc/conversations_bloc.dart';
import 'package:bf_stay/features/guest/chat/domain/entities/conversation_entity.dart';
import 'package:bf_stay/features/guest/chat/domain/entities/message_change.dart';
import 'package:bf_stay/features/guest/chat/domain/entities/message_entity.dart';
import 'package:bf_stay/features/guest/chat/domain/repositories/chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MessageEntity buildMessage({
    required String content,
    MessageType msgType = MessageType.text,
    int minutesAgo = 0,
  }) =>
      MessageEntity(
        id: 'msg-$content',
        conversationId: 'conv',
        senderUserId: 'user',
        msgType: msgType,
        content: content,
        createdAt: DateTime(2026, 1, 1, 12).subtract(
          Duration(minutes: minutesAgo),
        ),
      );

  ConversationEntity buildConversation({
    required String id,
    String? guestName,
    String? bookingCode,
    MessageEntity? lastMessage,
  }) =>
      ConversationEntity(
        id: id,
        propertyId: 'prop-1',
        createdAt: DateTime(2026, 1, 1),
        guestName: guestName,
        bookingCode: bookingCode,
        lastMessage: lastMessage,
      );

  final roberta = buildConversation(
    id: 'c1',
    guestName: 'Roberta Milone',
    bookingCode: 'BF-9KGF-9NYN',
    lastMessage: buildMessage(content: 'ya nos ha llegado', minutesAgo: 1),
  );
  final jesus = buildConversation(
    id: 'c2',
    guestName: 'Jesús García',
    bookingCode: 'BF-635N-H3AX',
    lastMessage: buildMessage(content: 'no abre el codigo', minutesAgo: 2),
  );
  final lidia = buildConversation(
    id: 'c3',
    guestName: 'Lidia Domínguez',
    bookingCode: 'BF-H3EB-4Y6U',
    lastMessage: buildMessage(content: 'vale espero las coordenadas', minutesAgo: 3),
  );

  ConversationsLoaded buildState(String query) => ConversationsLoaded(
        conversations: [roberta, jesus, lidia],
        propertyId: 'prop-1',
        searchQuery: query,
      );

  List<String> idsFor(String query) =>
      buildState(query).visibleConversations.map((c) => c.id).toList();

  group('filtrado del buscador', () {
    test('sin búsqueda devuelve todas, ordenadas por último mensaje', () {
      expect(idsFor(''), ['c1', 'c2', 'c3']);
      expect(buildState('').hasNoSearchResults, isFalse);
    });

    test('busca por nombre, sin distinguir mayúsculas', () {
      expect(idsFor('roberta'), ['c1']);
      expect(idsFor('MILONE'), ['c1']);
    });

    test('ignora los acentos en ambos sentidos', () {
      // El huésped es «Jesús García»: debe encontrarse escribiendo sin tildes
      expect(idsFor('jesus'), ['c2']);
      expect(idsFor('garcia'), ['c2']);
      // Y con ellas
      expect(idsFor('Domínguez'), ['c3']);
      expect(idsFor('dominguez'), ['c3']);
    });

    test('busca por código de reserva, con y sin guiones', () {
      expect(idsFor('BF-9KGF-9NYN'), ['c1']);
      expect(idsFor('9kgf9nyn'), ['c1']);
      expect(idsFor('635n'), ['c2']);
    });

    test('busca en el texto del último mensaje', () {
      expect(idsFor('coordenadas'), ['c3']);
    });

    test('marca "sin resultados" solo si hay búsqueda activa', () {
      expect(idsFor('inexistente'), isEmpty);
      expect(buildState('inexistente').hasNoSearchResults, isTrue);
      // Lista vacía sin búsqueda no es "sin resultados", es "sin conversaciones"
      final vacio = ConversationsLoaded(
        conversations: const [],
        propertyId: 'prop-1',
      );
      expect(vacio.hasNoSearchResults, isFalse);
    });

    test('un mensaje entrante por realtime no borra la búsqueda activa',
        () async {
      final repository = _FakeChatRepository([roberta, jesus, lidia]);
      final bloc = ConversationsBloc(chatRepository: repository);
      addTearDown(bloc.close);

      bloc.add(const ConversationsLoadForUser(userId: 'staff-1'));
      await bloc.stream.firstWhere((s) => s is ConversationsLoaded);

      bloc.add(const ConversationsSearchChanged(query: 'roberta'));
      await bloc.stream.firstWhere(
        (s) => s is ConversationsLoaded && s.searchQuery == 'roberta',
      );

      // Llega un mensaje nuevo de otro huésped mientras el filtro está puesto
      repository.emit([
        roberta,
        jesus,
        lidia,
        buildConversation(id: 'c9', guestName: 'Nuevo Huésped'),
      ]);

      final state = await bloc.stream.firstWhere(
        (s) => s is ConversationsLoaded && s.conversations.length == 4,
      ) as ConversationsLoaded;

      // El filtro sobrevive: se ven 4 conversaciones pero solo 1 visible
      expect(state.searchQuery, 'roberta');
      expect(state.visibleConversations.map((c) => c.id), ['c1']);
    });

    test('no busca dentro del storage path de los adjuntos', () {
      final conAdjunto = buildConversation(
        id: 'c4',
        guestName: 'Ana López',
        bookingCode: 'BF-1111-2222',
        lastMessage: buildMessage(
          content: 'conv-99/8f14e45f-ea8d-4b9c-b7a1-000000000000.jpg',
          msgType: MessageType.image,
        ),
      );

      final state = ConversationsLoaded(
        conversations: [conAdjunto],
        propertyId: 'prop-1',
        searchQuery: '8f14e45f',
      );

      // Buscar un UUID no aporta nada a quien usa la pantalla
      expect(state.visibleConversations, isEmpty);
      // Pero la conversación sigue siendo localizable por su nombre
      expect(
        ConversationsLoaded(
          conversations: [conAdjunto],
          propertyId: 'prop-1',
          searchQuery: 'ana',
        ).visibleConversations.map((c) => c.id),
        ['c4'],
      );
    });
  });
}

/// Fake de ChatRepository que permite empujar actualizaciones «de realtime».
class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository(this._initial);

  final List<ConversationEntity> _initial;
  final _controller = StreamController<List<ConversationEntity>>.broadcast();

  /// Simula una actualización llegada por realtime.
  void emit(List<ConversationEntity> conversations) =>
      _controller.add(conversations);

  @override
  Future<List<ConversationEntity>> getConversationsForUser({
    required String userId,
    String? propertyId,
  }) async =>
      _initial;

  @override
  Stream<List<ConversationEntity>> watchUserConversations({
    required String userId,
    String? propertyId,
  }) =>
      _controller.stream;

  @override
  void dispose() => _controller.close();

  // ── No usados en estos tests ──
  @override
  Future<List<ConversationEntity>> getConversationsByProperty({
    required String propertyId,
  }) async =>
      _initial;

  @override
  Future<ConversationEntity?> getConversation(String conversationId) async =>
      null;

  @override
  Future<ConversationEntity> getOrCreateConversation({
    required String propertyId,
    String? bookingId,
    required String guestUserId,
    required String guestName,
  }) =>
      throw UnimplementedError();

  @override
  Future<ConversationEntity?> getActiveConversation({
    required String userId,
    required String propertyId,
  }) async =>
      null;

  @override
  Future<List<MessageEntity>> getMessages({
    required String conversationId,
    int limit = 50,
    DateTime? before,
  }) async =>
      const [];

  @override
  Future<MessageEntity> sendTextMessage({
    required String conversationId,
    required String senderUserId,
    required String content,
  }) =>
      throw UnimplementedError();

  @override
  Future<MessageEntity> sendImageMessage({
    required String conversationId,
    required String senderUserId,
    required String imagePath,
    String? mimeType,
    int? fileSize,
  }) =>
      throw UnimplementedError();

  @override
  Future<MessageEntity> sendFileMessage({
    required String conversationId,
    required String senderUserId,
    required String filePath,
    required String fileName,
    required int fileSize,
    required String mimeType,
  }) =>
      throw UnimplementedError();

  @override
  Stream<MessageChange> watchMessages(String conversationId) =>
      const Stream<MessageChange>.empty();

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  }) async {}

  @override
  Future<int> getUnreadCount({
    required String conversationId,
    required String userId,
  }) async =>
      0;

  @override
  Future<void> deleteConversation({required String conversationId}) async {}

  @override
  Future<void> deleteMessage({
    required String messageId,
    String? attachmentPath,
  }) async {}
}
