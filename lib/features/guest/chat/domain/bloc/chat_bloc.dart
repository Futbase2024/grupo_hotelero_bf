import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/chat_media_service.dart';
import '../entities/conversation_entity.dart';
import '../entities/message_change.dart';
import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

// ============== EVENTS ==============

/// Eventos base del ChatBloc
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para inicializar el chat
class ChatStarted extends ChatEvent {
  const ChatStarted({
    required this.propertyId,
    this.bookingId,
    required this.userId,
    required this.userName,
    this.conversationId,
  });

  final String propertyId;
  final String? bookingId;
  final String userId;
  final String userName;
  final String? conversationId;

  @override
  List<Object?> get props => [propertyId, bookingId, userId, userName, conversationId];
}

/// Evento para cargar mensajes
class ChatLoadMessages extends ChatEvent {
  const ChatLoadMessages();
}

/// Evento para enviar un mensaje de texto
class ChatSendMessage extends ChatEvent {
  const ChatSendMessage({
    required this.content,
  });

  final String content;

  @override
  List<Object?> get props => [content];
}

/// Evento para enviar uno o varios adjuntos ya seleccionados.
///
/// La selección de los archivos ocurre en la UI; el BLoC se encarga de subirlos
/// al bucket, en orden, y de crear un mensaje por cada uno.
class ChatSendAttachment extends ChatEvent {
  const ChatSendAttachment({required this.drafts});

  /// Atajo para el caso de un único archivo.
  ChatSendAttachment.single(ChatAttachmentDraft draft) : drafts = [draft];

  final List<ChatAttachmentDraft> drafts;

  @override
  List<Object?> get props =>
      [for (final d in drafts) '${d.fileName}:${d.size}'];
}

/// Evento cuando llega un nuevo mensaje por realtime
class ChatMessageReceived extends ChatEvent {
  const ChatMessageReceived({required this.message});

  final MessageEntity message;

  @override
  List<Object?> get props => [message];
}

/// Evento para eliminar un mensaje propio (acción del usuario)
class ChatDeleteMessage extends ChatEvent {
  const ChatDeleteMessage({required this.messageId});

  final String messageId;

  @override
  List<Object?> get props => [messageId];
}

/// Evento cuando un mensaje es eliminado (detectado por realtime)
class ChatMessageDeleted extends ChatEvent {
  const ChatMessageDeleted({required this.messageId});

  final String messageId;

  @override
  List<Object?> get props => [messageId];
}

/// Evento para marcar mensajes como leídos
class ChatMarkAsRead extends ChatEvent {
  const ChatMarkAsRead();
}

/// Evento para cerrar/dispose del chat
class ChatDisposed extends ChatEvent {
  const ChatDisposed();
}

// ============== STATES ==============

/// Estados base del ChatBloc
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ChatInitial extends ChatState {
  const ChatInitial();
}

/// Estado de carga inicial
class ChatLoading extends ChatState {
  const ChatLoading();
}

/// Estado con conversación y mensajes cargados
class ChatLoaded extends ChatState {
  ChatLoaded({
    required this.conversation,
    required this.messages,
    required this.currentUserId,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
  }) : sortedMessages = messages.sortedByDate(ascending: true);

  final ConversationEntity conversation;
  final List<MessageEntity> messages;
  /// Mensajes ordenados por fecha (calculados una sola vez al crear el estado)
  final List<MessageEntity> sortedMessages;
  final String currentUserId;
  final bool isLoadingMore;
  final bool hasMoreMessages;

  bool get hasMessages => messages.isNotEmpty;
  MessageEntity? get lastMessage => messages.isNotEmpty ? messages.last : null;
  int get messageCount => messages.length;
  String get otherParticipantName =>
      conversation.getOtherParticipantName(currentUserId);

  @override
  List<Object?> get props => [
        conversation,
        messages,
        currentUserId,
        isLoadingMore,
        hasMoreMessages,
      ];
}

/// Estado enviando mensaje
class ChatSending extends ChatState {
  const ChatSending({
    required this.conversation,
    required this.messages,
    required this.currentUserId,
  });

  final ConversationEntity conversation;
  final List<MessageEntity> messages;
  final String currentUserId;

  @override
  List<Object?> get props => [conversation, messages, currentUserId];
}

/// Estado mientras se sube un adjunto al bucket.
///
/// Mantiene los mensajes actuales para que la lista no parpadee durante la
/// subida, que puede tardar varios segundos.
class ChatUploadingAttachment extends ChatState {
  const ChatUploadingAttachment({
    required this.conversation,
    required this.messages,
    required this.currentUserId,
    required this.fileName,
    this.currentIndex = 1,
    this.total = 1,
  });

  final ConversationEntity conversation;
  final List<MessageEntity> messages;
  final String currentUserId;

  /// Archivo que se está subiendo ahora mismo.
  final String fileName;

  /// Posición del archivo actual dentro del lote (1-based).
  final int currentIndex;

  /// Número total de archivos del lote.
  final int total;

  /// Hay más de un archivo en curso.
  bool get isBatch => total > 1;

  @override
  List<Object?> get props => [
        conversation,
        messages,
        currentUserId,
        fileName,
        currentIndex,
        total,
      ];
}

/// Estado de error
class ChatError extends ChatState {
  const ChatError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Accesos comunes a los estados que ya tienen conversación activa
/// ([ChatLoaded], [ChatSending] y [ChatUploadingAttachment]), para que las
/// pantallas no tengan que encadenar comprobaciones de tipo.
extension ChatStateX on ChatState {
  /// Mensajes del estado actual, o `null` si aún no hay conversación.
  List<MessageEntity>? get messagesOrNull => switch (this) {
        final ChatLoaded s => s.messages,
        final ChatSending s => s.messages,
        final ChatUploadingAttachment s => s.messages,
        _ => null,
      };

  /// Usuario actual, o `null` si aún no hay conversación.
  String? get currentUserIdOrNull => switch (this) {
        final ChatLoaded s => s.currentUserId,
        final ChatSending s => s.currentUserId,
        final ChatUploadingAttachment s => s.currentUserId,
        _ => null,
      };

  /// La conversación está lista para escribir en ella.
  bool get isConversationReady => messagesOrNull != null;

  /// Hay un adjunto subiéndose ahora mismo.
  bool get isUploadingAttachment => this is ChatUploadingAttachment;
}

// ============== BLOC ==============

/// BLoC para gestionar el estado del chat
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required ChatRepository chatRepository,
    required ChatMediaService mediaService,
  })  : _chatRepository = chatRepository,
        _mediaService = mediaService,
        super(const ChatInitial()) {
    on<ChatStarted>(_onStarted);
    on<ChatLoadMessages>(_onLoadMessages);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatSendAttachment>(_onSendAttachment);
    on<ChatMessageReceived>(_onMessageReceived);
    on<ChatDeleteMessage>(_onDeleteMessage);
    on<ChatMessageDeleted>(_onMessageDeleted);
    on<ChatMarkAsRead>(_onMarkAsRead);
    on<ChatDisposed>(_onDisposed);
  }

  final ChatRepository _chatRepository;
  final ChatMediaService _mediaService;

  StreamSubscription<MessageChange>? _messagesSubscription;

  /// Maneja el evento de inicio
  Future<void> _onStarted(
    ChatStarted event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());

    try {
      ConversationEntity conversation;

      // Si se proporciona un conversationId, cargar esa conversación específica
      if (event.conversationId != null && event.conversationId!.isNotEmpty) {
        final existingConversation = await _chatRepository.getConversation(
          event.conversationId!,
        );
        if (existingConversation == null) {
          emit(const ChatError(message: 'Conversación no encontrada'));
          return;
        }
        conversation = existingConversation;
      } else {
        // Obtener o crear conversación
        conversation = await _chatRepository.getOrCreateConversation(
          propertyId: event.propertyId,
          bookingId: event.bookingId,
          guestUserId: event.userId,
          guestName: event.userName,
        );
      }

      // Cargar mensajes
      final messages = await _chatRepository.getMessages(
        conversationId: conversation.id,
      );

      // Suscribirse a nuevos mensajes en tiempo real
      // El tracking ahora se maneja internamente en watchMessages
      _messagesSubscription?.cancel();
      _messagesSubscription = _chatRepository
          .watchMessages(conversation.id)
          .listen((change) {
        switch (change) {
          case MessageAdded(:final message):
            add(ChatMessageReceived(message: message));
          case MessageDeleted(:final messageId):
            add(ChatMessageDeleted(messageId: messageId));
        }
      });

      emit(ChatLoaded(
        conversation: conversation,
        messages: messages,
        currentUserId: event.userId,
      ));
    } catch (e) {
      emit(ChatError(message: _getErrorMessage(e)));
    }
  }

  /// Maneja la carga de más mensajes
  Future<void> _onLoadMessages(
    ChatLoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    if (currentState.isLoadingMore || !currentState.hasMoreMessages) return;

    try {
      emit(ChatLoaded(
        conversation: currentState.conversation,
        messages: currentState.messages,
        currentUserId: currentState.currentUserId,
        isLoadingMore: true,
        hasMoreMessages: currentState.hasMoreMessages,
      ));

      final oldestMessage = currentState.messages.firstOrNull;
      final newMessages = await _chatRepository.getMessages(
        conversationId: currentState.conversation.id,
        before: oldestMessage?.createdAt,
      );

      final allMessages = [...newMessages, ...currentState.messages];

      emit(ChatLoaded(
        conversation: currentState.conversation,
        messages: allMessages,
        currentUserId: currentState.currentUserId,
        isLoadingMore: false,
        hasMoreMessages: newMessages.length >= 50,
      ));
    } catch (e) {
      emit(ChatLoaded(
        conversation: currentState.conversation,
        messages: currentState.messages,
        currentUserId: currentState.currentUserId,
        isLoadingMore: false,
        hasMoreMessages: currentState.hasMoreMessages,
      ));
    }
  }

  /// Maneja el envío de mensaje
  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    final content = event.content.trim();
    if (content.isEmpty) return;

    try {
      emit(ChatSending(
        conversation: currentState.conversation,
        messages: currentState.messages,
        currentUserId: currentState.currentUserId,
      ));

      // Enviar mensaje
      final message = await _chatRepository.sendTextMessage(
        conversationId: currentState.conversation.id,
        senderUserId: currentState.currentUserId,
        content: content,
      );

      // Añadir mensaje a la lista
      final updatedMessages = [...currentState.messages, message];

      emit(ChatLoaded(
        conversation: currentState.conversation,
        messages: updatedMessages,
        currentUserId: currentState.currentUserId,
      ));

      debugPrint('✅ [ChatBloc] Mensaje enviado (la BD se encarga de las notificaciones)');
    } catch (e) {
      debugPrint('❌ [ChatBloc] Error enviando mensaje: $e');
      // Volver al estado anterior con error
      emit(ChatLoaded(
        conversation: currentState.conversation,
        messages: currentState.messages,
        currentUserId: currentState.currentUserId,
      ));
      // Emitir error temporal
      emit(ChatError(message: _getErrorMessage(e)));
      // Recuperar estado
      emit(ChatLoaded(
        conversation: currentState.conversation,
        messages: currentState.messages,
        currentUserId: currentState.currentUserId,
      ));
    }
  }

  /// Maneja el envío de adjuntos: sube cada archivo al bucket y crea su mensaje.
  ///
  /// Los archivos se procesan en orden para que el usuario los vea aparecer en
  /// la conversación en el mismo orden en que los eligió. Si uno falla se
  /// detiene el lote: los ya enviados se conservan y los restantes no se suben.
  ///
  /// Si la subida funciona pero la inserción falla, se borra el archivo recién
  /// subido para no dejarlo huérfano en el bucket.
  Future<void> _onSendAttachment(
    ChatSendAttachment event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;
    if (event.drafts.isEmpty) return;

    final conversation = currentState.conversation;
    final userId = currentState.currentUserId;
    final messages = [...currentState.messages];
    final total = event.drafts.length;

    for (var i = 0; i < total; i++) {
      final draft = event.drafts[i];
      String? uploadedPath;

      emit(ChatUploadingAttachment(
        conversation: conversation,
        messages: messages,
        currentUserId: userId,
        fileName: draft.fileName,
        currentIndex: i + 1,
        total: total,
      ));

      try {
        final upload = await _mediaService.upload(
          conversationId: conversation.id,
          draft: draft,
        );
        uploadedPath = upload.storagePath;

        final message = upload.isImage
            ? await _chatRepository.sendImageMessage(
                conversationId: conversation.id,
                senderUserId: userId,
                imagePath: upload.storagePath,
                mimeType: upload.mimeType,
                fileSize: upload.size,
              )
            : await _chatRepository.sendFileMessage(
                conversationId: conversation.id,
                senderUserId: userId,
                filePath: upload.storagePath,
                fileName: upload.fileName,
                fileSize: upload.size,
                mimeType: upload.mimeType,
              );

        messages.add(message);
        debugPrint('✅ [ChatBloc] Adjunto enviado: ${upload.storagePath}');
      } catch (e) {
        debugPrint('❌ [ChatBloc] Error enviando adjunto: $e');

        // El archivo llegó al bucket pero el mensaje no: revertir la subida.
        if (uploadedPath != null) {
          await _mediaService.deleteAttachment(uploadedPath);
        }

        final error = e is ChatMediaException ? e.message : _getErrorMessage(e);

        // Se conservan los adjuntos ya enviados; se descarta el resto del lote.
        emit(ChatError(message: error));
        emit(ChatLoaded(
          conversation: conversation,
          messages: messages,
          currentUserId: userId,
        ));
        return;
      }
    }

    emit(ChatLoaded(
      conversation: conversation,
      messages: messages,
      currentUserId: userId,
    ));
  }

  /// Maneja mensaje recibido por realtime
  Future<void> _onMessageReceived(
    ChatMessageReceived event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    // Evitar duplicados
    if (currentState.messages.any((m) => m.id == event.message.id)) {
      return;
    }

    // Añadir mensaje a la lista
    final updatedMessages = [...currentState.messages, event.message];

    emit(ChatLoaded(
      conversation: currentState.conversation,
      messages: updatedMessages,
      currentUserId: currentState.currentUserId,
    ));
  }

  /// Maneja la eliminación de un mensaje propio (acción del usuario).
  /// Optimista: quita el mensaje de la lista y, si falla el borrado, lo restaura.
  Future<void> _onDeleteMessage(
    ChatDeleteMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    final previousMessages = currentState.messages;
    final deletedMessage = previousMessages
        .where((m) => m.id == event.messageId)
        .firstOrNull;

    // Si el mensaje ya no está en la lista, no hay nada que hacer
    if (deletedMessage == null) return;

    // Quitar optimísticamente
    final updatedMessages = previousMessages
        .where((m) => m.id != event.messageId)
        .toList();

    emit(ChatLoaded(
      conversation: currentState.conversation,
      messages: updatedMessages,
      currentUserId: currentState.currentUserId,
    ));

    try {
      await _chatRepository.deleteMessage(
        messageId: event.messageId,
        attachmentPath: deletedMessage.attachmentPath,
      );
      debugPrint('✅ [ChatBloc] Mensaje eliminado');
    } catch (e) {
      debugPrint('❌ [ChatBloc] Error eliminando mensaje: $e');
      // Restaurar la lista previa
      emit(ChatLoaded(
        conversation: currentState.conversation,
        messages: previousMessages,
        currentUserId: currentState.currentUserId,
      ));
      // Emitir error temporal y volver al estado restaurado
      emit(ChatError(message: _getErrorMessage(e)));
      emit(ChatLoaded(
        conversation: currentState.conversation,
        messages: previousMessages,
        currentUserId: currentState.currentUserId,
      ));
    }
  }

  /// Maneja un mensaje eliminado detectado por realtime (por cualquier lado).
  Future<void> _onMessageDeleted(
    ChatMessageDeleted event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    // Solo emitir si el mensaje realmente está en la lista
    if (!currentState.messages.any((m) => m.id == event.messageId)) return;

    final updatedMessages = currentState.messages
        .where((m) => m.id != event.messageId)
        .toList();

    emit(ChatLoaded(
      conversation: currentState.conversation,
      messages: updatedMessages,
      currentUserId: currentState.currentUserId,
    ));
  }

  /// Maneja marcar como leído
  Future<void> _onMarkAsRead(
    ChatMarkAsRead event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    await _chatRepository.markAsRead(
      conversationId: currentState.conversation.id,
      userId: currentState.currentUserId,
    );
  }

  /// Maneja dispose del chat
  Future<void> _onDisposed(
    ChatDisposed event,
    Emitter<ChatState> emit,
  ) async {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _chatRepository.dispose();
  }

  /// Obtiene un mensaje de error amigable
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'Error de conexión. Por favor, verifica tu conexión a internet.';
    }

    if (errorString.contains('timeout')) {
      return 'La solicitud ha tardado demasiado. Por favor, intenta de nuevo.';
    }

    if (errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return 'No tienes permisos para realizar esta acción.';
    }

    return 'Ha ocurrido un error. Por favor, intenta de nuevo.';
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _chatRepository.dispose();
    return super.close();
  }
}
