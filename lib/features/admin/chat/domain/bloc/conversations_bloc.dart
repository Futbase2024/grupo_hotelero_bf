import 'dart:async';

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

/// Evento para eliminar una conversación (solo admin/staff)
class ConversationsDeleteRequested extends ConversationsEvent {
  const ConversationsDeleteRequested({required this.conversationId});

  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

/// Evento interno cuando el realtime actualiza las conversaciones
class _ConversationsUpdated extends ConversationsEvent {
  const _ConversationsUpdated(this.conversations);

  final List<ConversationEntity> conversations;

  @override
  List<Object?> get props => [conversations];
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
  ConversationsLoaded({
    required this.conversations,
    required this.propertyId,
    this.userId,
    this.isRefreshing = false,
    this.selectedConversation,
  }) : sortedConversations = _sort(conversations);

  final List<ConversationEntity> conversations;
  /// Conversaciones ya ordenadas por último mensaje — calculadas una sola vez al crear el estado
  final List<ConversationEntity> sortedConversations;
  final String propertyId;
  final String? userId;
  final bool isRefreshing;
  final ConversationEntity? selectedConversation;

  static List<ConversationEntity> _sort(List<ConversationEntity> list) {
    final sorted = List<ConversationEntity>.from(list);
    sorted.sort((a, b) {
      if (a.lastMessage != null && b.lastMessage != null) {
        return b.lastMessage!.createdAt.compareTo(a.lastMessage!.createdAt);
      }
      if (a.lastMessage != null) return -1;
      if (b.lastMessage != null) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }

  bool get hasConversations => conversations.isNotEmpty;
  int get totalConversations => conversations.length;
  int get totalUnread => conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
  List<ConversationEntity> get unreadConversations => conversations.where((c) => c.hasUnread).toList();

  @override
  List<Object?> get props => [
        conversations,
        propertyId,
        userId,
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
    on<ConversationsDeleteRequested>(_onDeleteRequested);
    on<_ConversationsUpdated>(_onConversationsUpdated);
  }

  final ChatRepository _chatRepository;

  StreamSubscription<List<ConversationEntity>>? _conversationsSubscription;

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
        userId: currentState.userId,
        isRefreshing: true,
        selectedConversation: currentState.selectedConversation,
      ));

      // Si hay propertyId válido, refrescar por propiedad
      // Si no hay propertyId pero sí userId, refrescar por usuario
      if (currentState.propertyId.isNotEmpty) {
        await _loadConversationsByProperty(
          emit,
          currentState.propertyId,
          userId: currentState.userId,
        );
      } else if (currentState.userId != null && currentState.userId!.isNotEmpty) {
        await _loadConversationsForUser(
          emit,
          userId: currentState.userId!,
          propertyId: null,
        );
      } else {
        // No podemos refrescar sin propertyId ni userId, mostrar estado actual
        emit(ConversationsLoaded(
          conversations: currentState.conversations,
          propertyId: currentState.propertyId,
          userId: currentState.userId,
          isRefreshing: false,
          selectedConversation: currentState.selectedConversation,
        ));
      }
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
        userId: currentState.userId,
        selectedConversation: event.conversation,
      ));
    }
  }

  /// Maneja actualizaciones del realtime
  void _onConversationsUpdated(
    _ConversationsUpdated event,
    Emitter<ConversationsState> emit,
  ) {
    final currentState = state;
    if (currentState is ConversationsLoaded) {
      _Debug.log('Realtime: actualizando ${event.conversations.length} conversaciones');
      emit(ConversationsLoaded(
        conversations: event.conversations,
        propertyId: currentState.propertyId,
        userId: currentState.userId,
        selectedConversation: currentState.selectedConversation,
      ));
    }
  }

  /// Carga conversaciones por propiedad
  Future<void> _loadConversationsByProperty(
    Emitter<ConversationsState> emit,
    String propertyId, {
    String? userId,
  }) async {
    try {
      _Debug.log('Cargando conversaciones por propiedad: $propertyId');
      final conversations = await _chatRepository.getConversationsByProperty(
        propertyId: propertyId,
      );
      _Debug.log('Conversaciones cargadas: ${conversations.length}');

      // Iniciar suscripción realtime si hay userId
      if (userId != null && userId.isNotEmpty) {
        _startRealtimeSubscription(userId: userId, propertyId: propertyId);
      }

      emit(ConversationsLoaded(
        conversations: conversations,
        propertyId: propertyId,
        userId: userId,
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

      // Iniciar suscripción realtime
      _startRealtimeSubscription(userId: userId, propertyId: propertyId);

      emit(ConversationsLoaded(
        conversations: conversations,
        propertyId: propertyId ?? '',
        userId: userId,
      ));
    } catch (e) {
      _Debug.error('Error en _loadConversationsForUser', e);
      emit(ConversationsError(message: _getErrorMessage(e)));
    }
  }

  /// Inicia la suscripción realtime para actualizaciones de conversaciones
  void _startRealtimeSubscription({
    required String userId,
    String? propertyId,
  }) {
    // Cancelar suscripción anterior si existe
    _conversationsSubscription?.cancel();

    _Debug.log('Iniciando suscripción realtime para userId: $userId');

    _conversationsSubscription = _chatRepository
        .watchUserConversations(userId: userId, propertyId: propertyId)
        .listen(
          (conversations) {
            _Debug.log('Realtime: recibidas ${conversations.length} conversaciones');
            add(_ConversationsUpdated(conversations));
          },
          onError: (error) {
            _Debug.error('Error en suscripción realtime', error);
          },
        );
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

  /// Maneja la solicitud de eliminar una conversación
  Future<void> _onDeleteRequested(
    ConversationsDeleteRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;

    try {
      _Debug.log('Eliminando conversación: ${event.conversationId}');

      // Eliminar la conversación
      await _chatRepository.deleteConversation(
        conversationId: event.conversationId,
      );

      _Debug.log('Conversación eliminada correctamente');

      // Actualizar la lista localmente removiendo la conversación eliminada
      final updatedConversations = currentState.conversations
          .where((c) => c.id != event.conversationId)
          .toList();

      emit(ConversationsLoaded(
        conversations: updatedConversations,
        propertyId: currentState.propertyId,
        userId: currentState.userId,
        selectedConversation: currentState.selectedConversation?.id == event.conversationId
            ? null
            : currentState.selectedConversation,
      ));
    } catch (e) {
      _Debug.error('Error en _onDeleteRequested', e);
      // Re-emitir el estado actual con error
      emit(ConversationsError(message: 'Error al eliminar la conversación: ${e.toString()}'));
      // Restaurar el estado anterior después del error
      await Future.delayed(const Duration(milliseconds: 100));
      emit(currentState);
    }
  }

  @override
  Future<void> close() {
    _conversationsSubscription?.cancel();
    return super.close();
  }
}
