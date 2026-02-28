import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../guest/chat/domain/entities/conversation_entity.dart';
import '../../../../guest/chat/domain/repositories/chat_repository.dart';

// ignore: avoid_classes_with_only_static_members
class _Debug {
  static void log(String message) {
    debugPrint('🔵 [ConversationsBloc] $message');
  }

  static void error(String message, [Object? error]) {
    debugPrint('🔴 [ConversationsBloc] $message');
    if (error != null) {
      debugPrint('🔴 Error: $error');
    }
  }
}

// ============== EVENTS ==============

/// Eventos base del ConversationsBloc
abstract class ConversationsEvent extends Equatable {
  const ConversationsEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar conversaciones de una propiedad
class ConversationsStarted extends ConversationsEvent {
  const ConversationsStarted({required this.propertyId});

  final String propertyId;

  @override
  List<Object?> get props => [propertyId];
}

/// Evento para cargar conversaciones del usuario actual
class ConversationsLoadForUser extends ConversationsEvent {
  const ConversationsLoadForUser({
    required this.userId,
    this.propertyId,
  });

  final String userId;
  final String? propertyId;

  @override
  List<Object?> get props => [userId, propertyId];
}

/// Evento para refrescar la lista
class ConversationsRefreshRequested extends ConversationsEvent {
  const ConversationsRefreshRequested();
}

/// Evento cuando se selecciona una conversación
class ConversationsSelected extends ConversationsEvent {
  const ConversationsSelected({required this.conversation});

  final ConversationEntity conversation;

  @override
  List<Object?> get props => [conversation];
}

// ============== STATES ==============

/// Estados base del ConversationsBloc
abstract class ConversationsState extends Equatable {
  const ConversationsState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ConversationsInitial extends ConversationsState {
  const ConversationsInitial();
}

/// Estado de carga
class ConversationsLoading extends ConversationsState {
  const ConversationsLoading();
}

/// Estado con conversaciones cargadas
class ConversationsLoaded extends ConversationsState {
  const ConversationsLoaded({
    required this.conversations,
    required this.propertyId,
    this.isRefreshing = false,
    this.selectedConversation,
  });

  final List<ConversationEntity> conversations;
  final String propertyId;
  final bool isRefreshing;
  final ConversationEntity? selectedConversation;

  /// Indica si hay conversaciones
  bool get hasConversations => conversations.isNotEmpty;

  /// Total de conversaciones
  int get totalConversations => conversations.length;

  /// Conversaciones ordenadas por último mensaje (más recientes primero)
  List<ConversationEntity> get sortedConversations {
    final sorted = List<ConversationEntity>.from(conversations);
    sorted.sort((a, b) {
      // Si ambas tienen último mensaje, comparar por fecha
      if (a.lastMessage != null && b.lastMessage != null) {
        return b.lastMessage!.createdAt.compareTo(a.lastMessage!.createdAt);
      }
      // Si solo una tiene mensaje, ponerla primero
      if (a.lastMessage != null) return -1;
      if (b.lastMessage != null) return 1;
      // Si ninguna tiene mensaje, comparar por fecha de creación
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }

  /// Total de mensajes no leídos
  int get totalUnread {
    return conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
  }

  /// Conversaciones con mensajes no leídos
  List<ConversationEntity> get unreadConversations {
    return conversations.where((c) => c.hasUnread).toList();
  }

  @override
  List<Object?> get props => [
        conversations,
        propertyId,
        isRefreshing,
        selectedConversation,
      ];
}

/// Estado de error
class ConversationsError extends ConversationsState {
  const ConversationsError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// ============== BLOC ==============

/// BLoC para gestionar la lista de conversaciones
class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  ConversationsBloc({
    required ChatRepository chatRepository,
  })  : _chatRepository = chatRepository,
        super(const ConversationsInitial()) {
    on<ConversationsStarted>(_onStarted);
    on<ConversationsLoadForUser>(_onLoadForUser);
    on<ConversationsRefreshRequested>(_onRefreshRequested);
    on<ConversationsSelected>(_onSelected);
  }

  final ChatRepository _chatRepository;

  /// Maneja el evento de inicio
  Future<void> _onStarted(
    ConversationsStarted event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(const ConversationsLoading());
    await _loadConversationsByProperty(emit, event.propertyId);
  }

  /// Maneja la carga de conversaciones para un usuario
  Future<void> _onLoadForUser(
    ConversationsLoadForUser event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(const ConversationsLoading());
    await _loadConversationsForUser(
      emit,
      userId: event.userId,
      propertyId: event.propertyId,
    );
  }

  /// Maneja la solicitud de refresco
  Future<void> _onRefreshRequested(
    ConversationsRefreshRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is ConversationsLoaded) {
      emit(ConversationsLoaded(
        conversations: currentState.conversations,
        propertyId: currentState.propertyId,
        isRefreshing: true,
        selectedConversation: currentState.selectedConversation,
      ));

      await _loadConversationsByProperty(emit, currentState.propertyId);
    }
  }

  /// Maneja la selección de una conversación
  Future<void> _onSelected(
    ConversationsSelected event,
    Emitter<ConversationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is ConversationsLoaded) {
      emit(ConversationsLoaded(
        conversations: currentState.conversations,
        propertyId: currentState.propertyId,
        selectedConversation: event.conversation,
      ));
    }
  }

  /// Carga conversaciones por propiedad
  Future<void> _loadConversationsByProperty(
    Emitter<ConversationsState> emit,
    String propertyId,
  ) async {
    try {
      _Debug.log('Cargando conversaciones por propiedad: $propertyId');
      final conversations = await _chatRepository.getConversationsByProperty(
        propertyId: propertyId,
      );
      _Debug.log('Conversaciones cargadas: ${conversations.length}');

      emit(ConversationsLoaded(
        conversations: conversations,
        propertyId: propertyId,
      ));
    } catch (e) {
      _Debug.error('Error en _loadConversationsByProperty', e);
      emit(ConversationsError(message: _getErrorMessage(e)));
    }
  }

  /// Carga conversaciones para un usuario
  Future<void> _loadConversationsForUser(
    Emitter<ConversationsState> emit, {
    required String userId,
    String? propertyId,
  }) async {
    try {
      _Debug.log('Cargando conversaciones para usuario: $userId');
      final conversations = await _chatRepository.getConversationsForUser(
        userId: userId,
        propertyId: propertyId,
      );
      _Debug.log('Conversaciones cargadas: ${conversations.length}');

      emit(ConversationsLoaded(
        conversations: conversations,
        propertyId: propertyId ?? '',
      ));
    } catch (e) {
      _Debug.error('Error en _loadConversationsForUser', e);
      emit(ConversationsError(message: _getErrorMessage(e)));
    }
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

    return 'Ha ocurrido un error al cargar las conversaciones.';
  }
}
