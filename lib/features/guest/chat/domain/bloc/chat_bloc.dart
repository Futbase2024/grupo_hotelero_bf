import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../../core/services/notification_service.dart';
import '../entities/conversation_entity.dart';
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

/// Evento cuando llega un nuevo mensaje por realtime
class ChatMessageReceived extends ChatEvent {
  const ChatMessageReceived({required this.message});

  final MessageEntity message;

  @override
  List<Object?> get props => [message];
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
  const ChatLoaded({
    required this.conversation,
    required this.messages,
    required this.currentUserId,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
  });

  final ConversationEntity conversation;
  final List<MessageEntity> messages;
  final String currentUserId;
  final bool isLoadingMore;
  final bool hasMoreMessages;

  /// Indica si hay mensajes
  bool get hasMessages => messages.isNotEmpty;

  /// Último mensaje (para mostrar preview)
  MessageEntity? get lastMessage =>
      messages.isNotEmpty ? messages.last : null;

  /// Mensajes ordenados por fecha (más antiguos primero)
  List<MessageEntity> get sortedMessages =>
      messages.sortedByDate(ascending: true);

  /// Cantidad de mensajes
  int get messageCount => messages.length;

  /// Nombre del otro participante (según el usuario actual)
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

/// Estado de error
class ChatError extends ChatState {
  const ChatError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// ============== BLOC ==============

/// BLoC para gestionar el estado del chat
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required ChatRepository chatRepository,
  })  : _chatRepository = chatRepository,
        super(const ChatInitial()) {
    on<ChatStarted>(_onStarted);
    on<ChatLoadMessages>(_onLoadMessages);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatMessageReceived>(_onMessageReceived);
    on<ChatMarkAsRead>(_onMarkAsRead);
    on<ChatDisposed>(_onDisposed);
  }

  final ChatRepository _chatRepository;

  StreamSubscription<MessageEntity>? _messagesSubscription;

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
          .listen((message) {
        add(ChatMessageReceived(message: message));
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

      // ========== NUEVO: Encolar notificación push para el destinatario ==========
      final currentUserId = currentState.currentUserId;
      final recipient = currentState.conversation.participants
          .where((p) => p.userId != currentUserId)
          .firstOrNull;

      if (recipient == null) {
        debugPrint('⚠️ [ChatBloc] No se encontró destinatario');
        return;
      }

      // Obtener info del remitente para mostrar en la notificación
      final senderInfo = await _getSenderInfo(currentUserId);
      final senderName = senderInfo['full_name'] ?? 'Usuario';

      // Truncar el contenido si es muy largo
      final body = content.length > 50
          ? '📷 Imagen'
          : content;

      // ========== NUEVO: Encolar notificación push usando NotificationService
      await NotificationService().queuePushNotification(
        userId: recipient.userId,
        title: 'Nuevo mensaje de $senderName',
        body: body,
        data: {
          'conversation_id': currentState.conversation.id,
          'sender_user_id': currentState.currentUserId,
          'type': 'new_chat_message',
        },
      );

      debugPrint('✅ [ChatBloc] Push notification queued for recipient: ${recipient.userName}');
    } catch (e) {
      debugPrint('❌ [ChatBloc] Error enviando push notification: $e');
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

  /// Obtiene información del remitente para mostrar en la notificación
  Future<Map<String, String?>> _getSenderInfo(String userId) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_senders_info',
        params: {'user_ids': [userId]},
      );

      if (response != null && response is List && response.isNotEmpty) {
        final data = response.first;
        return {
          'full_name': data['full_name'] as String?,
          'role': data['role'] as String?,
        };
      }

      return {'full_name': null, 'role': null};
    } catch (e) {
      debugPrint('❌ [ChatBloc] Error obteniendo info del remitente: $e');
      return {'full_name': null, 'role': null};
    }
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
