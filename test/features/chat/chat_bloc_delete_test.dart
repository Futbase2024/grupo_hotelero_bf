// Tests de la lógica de borrado de mensajes en ChatBloc.
//
// El proyecto no usa mocktail/bloc_test, así que se emplea un fake manual del
// ChatRepository y solo `flutter_test`.

import 'dart:async';
import 'dart:typed_data';

import 'package:bf_stay/features/guest/chat/data/services/chat_media_service.dart';
import 'package:bf_stay/features/guest/chat/domain/bloc/chat_bloc.dart';
import 'package:bf_stay/features/guest/chat/domain/entities/conversation_entity.dart';
import 'package:bf_stay/features/guest/chat/domain/entities/message_change.dart';
import 'package:bf_stay/features/guest/chat/domain/entities/message_entity.dart';
import 'package:bf_stay/features/guest/chat/domain/repositories/chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  const conversationId = 'conv-1';
  const currentUserId = 'user-1';

  ConversationEntity buildConversation() => ConversationEntity(
        id: conversationId,
        propertyId: 'prop-1',
        createdAt: DateTime(2026, 1, 1),
      );

  MessageEntity buildMessage(String id, {String sender = currentUserId}) =>
      MessageEntity(
        id: id,
        conversationId: conversationId,
        senderUserId: sender,
        msgType: MessageType.text,
        content: 'msg $id',
        createdAt: DateTime(2026, 1, 1, 12, 0),
      );

  late _FakeChatRepository repository;
  late _FakeChatMediaService mediaService;
  late ChatBloc bloc;

  setUp(() {
    repository = _FakeChatRepository(
      conversation: buildConversation(),
      messages: [
        buildMessage('m1'),
        buildMessage('m2'),
      ],
    );
    mediaService = _FakeChatMediaService();
    bloc = ChatBloc(chatRepository: repository, mediaService: mediaService);
  });

  tearDown(() async {
    await bloc.close();
  });

  /// Lleva al bloc hasta ChatLoaded esperando a que se procese ChatStarted.
  Future<void> loadChat() async {
    bloc.add(const ChatStarted(
      propertyId: 'prop-1',
      userId: currentUserId,
      userName: 'Tester',
      conversationId: conversationId,
    ));
    await bloc.stream.firstWhere((s) => s is ChatLoaded);
  }

  group('ChatDeleteMessage', () {
    test('elimina el mensaje de la lista y llama al repositorio', () async {
      await loadChat();

      bloc.add(const ChatDeleteMessage(messageId: 'm1'));
      final state = await bloc.stream.firstWhere(
        (s) => s is ChatLoaded && s.messages.every((m) => m.id != 'm1'),
      ) as ChatLoaded;

      expect(state.messages.map((m) => m.id), ['m2']);
      expect(repository.deletedMessageIds, ['m1']);
    });

    test('si el borrado falla, restaura la lista original', () async {
      repository.failDelete = true;
      await loadChat();

      bloc.add(const ChatDeleteMessage(messageId: 'm1'));

      // Espera a que el bloc vuelva a un ChatLoaded que contenga de nuevo m1
      final restored = await bloc.stream.firstWhere(
        (s) => s is ChatLoaded && s.messages.any((m) => m.id == 'm1'),
      ) as ChatLoaded;

      expect(restored.messages.map((m) => m.id), ['m1', 'm2']);
    });
  });

  group('ChatSendAttachment', () {
    ChatAttachmentDraft buildDraft({required bool isImage}) =>
        ChatAttachmentDraft(
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: isImage ? 'foto.jpg' : 'contrato.pdf',
          mimeType: isImage ? 'image/jpeg' : 'application/pdf',
          isImage: isImage,
        );

    test('sube la imagen y añade el mensaje a la lista', () async {
      await loadChat();

      bloc.add(ChatSendAttachment.single(buildDraft(isImage: true)));
      final state = await bloc.stream.firstWhere(
        (s) => s is ChatLoaded && s.messages.any((m) => m.isImage),
      ) as ChatLoaded;

      expect(mediaService.uploadedPaths, ['$conversationId/uploaded-foto.jpg']);
      expect(state.messages.last.msgType, MessageType.image);
      // En content se guarda el storage path, nunca una URL
      expect(state.messages.last.content, startsWith(conversationId));
    });

    test('sube el documento conservando nombre y tamaño', () async {
      await loadChat();

      bloc.add(ChatSendAttachment.single(buildDraft(isImage: false)));
      final state = await bloc.stream.firstWhere(
        (s) => s is ChatLoaded && s.messages.any((m) => m.isFile),
      ) as ChatLoaded;

      final message = state.messages.last;
      expect(message.msgType, MessageType.file);
      expect(message.fileName, 'contrato.pdf');
      expect(message.fileSize, 3);
      expect(message.mimeType, 'application/pdf');
    });

    test('borra el archivo subido si falla la creación del mensaje', () async {
      await loadChat();
      repository.failSend = true;

      bloc.add(ChatSendAttachment.single(buildDraft(isImage: true)));
      await bloc.stream.firstWhere((s) => s is ChatError);

      // El archivo llegó al bucket pero el mensaje no: no debe quedar huérfano
      expect(mediaService.deletedPaths, mediaService.uploadedPaths);
      expect(repository.sentMessages, isEmpty);
    });

    test('envía un lote completo en orden y reporta el progreso', () async {
      await loadChat();

      final progreso = <String>[];
      final sub = bloc.stream.listen((s) {
        if (s is ChatUploadingAttachment) {
          progreso.add('${s.currentIndex}/${s.total} ${s.fileName}');
        }
      });

      bloc.add(ChatSendAttachment(drafts: [
        buildDraft(isImage: true),
        buildDraft(isImage: false),
      ]));

      final state = await bloc.stream.firstWhere(
        (s) => s is ChatLoaded && s.messages.length == 4,
      ) as ChatLoaded;
      await sub.cancel();

      expect(progreso, ['1/2 foto.jpg', '2/2 contrato.pdf']);
      // Los adjuntos se añaden en el mismo orden en que se eligieron
      expect(state.messages.map((m) => m.msgType).toList().sublist(2), [
        MessageType.image,
        MessageType.file,
      ]);
    });

    test('si un archivo del lote falla, conserva los ya enviados y para',
        () async {
      await loadChat();
      mediaService.failUploadFrom = 1; // falla el segundo archivo

      bloc.add(ChatSendAttachment(drafts: [
        buildDraft(isImage: true),
        buildDraft(isImage: false),
        buildDraft(isImage: true),
      ]));

      // Se espera directamente al ChatLoaded final: encadenar dos `firstWhere`
      // perdería el estado emitido entre ambas suscripciones.
      final state = await bloc.stream.firstWhere(
        (s) => s is ChatLoaded && s.messages.length == 3,
      ) as ChatLoaded;

      // El primero se conserva; el tercero ni se intenta
      expect(state.messages.length, 3);
      expect(mediaService.uploadedPaths.length, 1);
      expect(repository.sentMessages.length, 1);
    });

    test('al borrar un mensaje con adjunto se propaga su storage path',
        () async {
      await loadChat();

      bloc.add(ChatSendAttachment.single(buildDraft(isImage: true)));
      final loaded = await bloc.stream.firstWhere(
        (s) => s is ChatLoaded && s.messages.any((m) => m.isImage),
      ) as ChatLoaded;

      final attachment = loaded.messages.firstWhere((m) => m.isImage);
      bloc.add(ChatDeleteMessage(messageId: attachment.id));
      await bloc.stream.firstWhere(
        (s) => s is ChatLoaded && s.messages.every((m) => !m.isImage),
      );

      expect(repository.deletedAttachmentPaths, [attachment.content]);
    });
  });

  group('ChatMessageDeleted (realtime)', () {
    test('elimina el mensaje si está en la lista', () async {
      await loadChat();

      bloc.add(const ChatMessageDeleted(messageId: 'm2'));
      final state = await bloc.stream.firstWhere(
        (s) => s is ChatLoaded && s.messages.every((m) => m.id != 'm2'),
      ) as ChatLoaded;

      expect(state.messages.map((m) => m.id), ['m1']);
      // No debe intentar borrar en el repositorio (viene de realtime)
      expect(repository.deletedMessageIds, isEmpty);
    });

    test('es no-op si el mensaje no está en la lista', () async {
      await loadChat();
      final before = (bloc.state as ChatLoaded).messages.map((m) => m.id).toList();

      bloc.add(const ChatMessageDeleted(messageId: 'inexistente'));
      // Da tiempo a procesar el evento
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final after = (bloc.state as ChatLoaded).messages.map((m) => m.id).toList();
      expect(after, before);
    });
  });
}

/// Fake mínimo de ChatRepository para las pruebas de borrado.
class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository({
    required ConversationEntity conversation,
    required List<MessageEntity> messages,
  })  : _conversation = conversation,
        _messages = messages;

  final ConversationEntity _conversation;
  final List<MessageEntity> _messages;

  final List<String> deletedMessageIds = [];
  final List<String?> deletedAttachmentPaths = [];
  final List<MessageEntity> sentMessages = [];
  bool failDelete = false;
  bool failSend = false;

  @override
  Future<ConversationEntity?> getConversation(String conversationId) async =>
      _conversation;

  @override
  Future<List<MessageEntity>> getMessages({
    required String conversationId,
    int limit = 50,
    DateTime? before,
  }) async =>
      List<MessageEntity>.from(_messages);

  @override
  Stream<MessageChange> watchMessages(String conversationId) =>
      const Stream<MessageChange>.empty();

  @override
  Future<void> deleteMessage({
    required String messageId,
    String? attachmentPath,
  }) async {
    if (failDelete) {
      throw Exception('delete failed');
    }
    deletedMessageIds.add(messageId);
    deletedAttachmentPaths.add(attachmentPath);
  }

  @override
  void dispose() {}

  // ── Métodos no usados en estos tests ──
  @override
  Future<ConversationEntity> getOrCreateConversation({
    required String propertyId,
    String? bookingId,
    required String guestUserId,
    required String guestName,
  }) async =>
      _conversation;

  @override
  Future<List<ConversationEntity>> getConversationsByProperty({
    required String propertyId,
  }) async =>
      [_conversation];

  @override
  Future<List<ConversationEntity>> getConversationsForUser({
    required String userId,
    String? propertyId,
  }) async =>
      [_conversation];

  @override
  Future<ConversationEntity?> getActiveConversation({
    required String userId,
    required String propertyId,
  }) async =>
      _conversation;

  @override
  Future<MessageEntity> sendTextMessage({
    required String conversationId,
    required String senderUserId,
    required String content,
  }) async =>
      buildMessageStub(conversationId, senderUserId, content);

  @override
  Future<MessageEntity> sendImageMessage({
    required String conversationId,
    required String senderUserId,
    required String imagePath,
    String? mimeType,
    int? fileSize,
  }) async {
    if (failSend) throw Exception('send failed');

    final message = buildMessageStub(
      conversationId,
      senderUserId,
      imagePath,
      msgType: MessageType.image,
      mimeType: mimeType,
      fileSize: fileSize,
    );
    sentMessages.add(message);
    return message;
  }

  @override
  Future<MessageEntity> sendFileMessage({
    required String conversationId,
    required String senderUserId,
    required String filePath,
    required String fileName,
    required int fileSize,
    required String mimeType,
  }) async {
    if (failSend) throw Exception('send failed');

    final message = buildMessageStub(
      conversationId,
      senderUserId,
      filePath,
      msgType: MessageType.file,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
    );
    sentMessages.add(message);
    return message;
  }

  MessageEntity buildMessageStub(
    String conversationId,
    String senderUserId,
    String content, {
    MessageType msgType = MessageType.text,
    String? fileName,
    int? fileSize,
    String? mimeType,
  }) =>
      MessageEntity(
        id: 'stub',
        conversationId: conversationId,
        senderUserId: senderUserId,
        msgType: msgType,
        content: content,
        createdAt: DateTime(2026, 1, 1),
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
      );

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  }) async {}

  @override
  Stream<List<ConversationEntity>> watchUserConversations({
    required String userId,
    String? propertyId,
  }) =>
      const Stream<List<ConversationEntity>>.empty();

  @override
  Future<int> getUnreadCount({
    required String conversationId,
    required String userId,
  }) async =>
      0;

  @override
  Future<void> deleteConversation({required String conversationId}) async {}
}

/// Fake de ChatMediaService: no toca Storage, solo registra lo que le piden.
class _FakeChatMediaService implements ChatMediaService {
  final List<String> uploadedPaths = [];
  final List<String> deletedPaths = [];
  bool failUpload = false;

  /// Índice (0-based) a partir del cual las subidas fallan. `null` = ninguna.
  int? failUploadFrom;

  int _uploadCount = 0;

  @override
  Future<ChatAttachmentUpload> upload({
    required String conversationId,
    required ChatAttachmentDraft draft,
  }) async {
    final index = _uploadCount++;
    if (failUpload || (failUploadFrom != null && index >= failUploadFrom!)) {
      throw const ChatMediaException('upload failed');
    }

    final path = '$conversationId/uploaded-${draft.fileName}';
    uploadedPaths.add(path);

    return ChatAttachmentUpload(
      storagePath: path,
      fileName: draft.fileName,
      mimeType: draft.mimeType,
      size: draft.size,
      isImage: draft.isImage,
    );
  }

  @override
  Future<void> deleteAttachment(String storagePath) async {
    deletedPaths.add(storagePath);
  }

  @override
  Future<void> deleteConversationAttachments(String conversationId) async {}

  @override
  Future<String> resolveUrl(String pathOrUrl) async =>
      'https://example.test/$pathOrUrl';

  @override
  Future<void> saveImageToGallery({
    required String storagePath,
    required String fileName,
  }) async {}

  @override
  Future<ChatAttachmentDraft?> pickImage({required ImageSource source}) async =>
      null;

  @override
  Future<List<ChatAttachmentDraft>> pickImages() async => const [];

  @override
  Future<List<ChatAttachmentDraft>> pickDocuments() async => const [];
}
