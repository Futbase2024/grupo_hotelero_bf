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

/// Evento al escribir en el buscador de la lista.
///
/// El filtrado es local: las conversaciones ya están en memoria y se mantienen
/// al día por realtime, así que no hace falta ir al servidor.
class ConversationsSearchChanged extends ConversationsEvent {
  const ConversationsSearchChanged({required this.query});

  final String query;

  @override
  List<Object?> get props => [query];
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
  factory ConversationsLoaded({
    required List<ConversationEntity> conversations,
    required String propertyId,
    String? userId,
    bool isRefreshing = false,
    ConversationEntity? selectedConversation,
    String searchQuery = '',
  }) {
    final sorted = _sort(conversations);
    return ConversationsLoaded._(
      conversations: conversations,
      sortedConversations: sorted,
      visibleConversations: _filter(sorted, searchQuery),
      propertyId: propertyId,
      userId: userId,
      isRefreshing: isRefreshing,
      selectedConversation: selectedConversation,
      searchQuery: searchQuery,
    );
  }

  const ConversationsLoaded._({
    required this.conversations,
    required this.sortedConversations,
    required this.visibleConversations,
    required this.propertyId,
    required this.userId,
    required this.isRefreshing,
    required this.selectedConversation,
    required this.searchQuery,
  });

  final List<ConversationEntity> conversations;
  /// Conversaciones ya ordenadas por último mensaje — calculadas una sola vez al crear el estado
  final List<ConversationEntity> sortedConversations;

  /// Conversaciones que se pintan: las ordenadas, filtradas por [searchQuery].
  final List<ConversationEntity> visibleConversations;

  final String propertyId;
  final String? userId;
  final bool isRefreshing;
  final ConversationEntity? selectedConversation;

  /// Texto del buscador. Vacío = sin filtro.
  final String searchQuery;

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

  static List<ConversationEntity> _filter(
    List<ConversationEntity> list,
    String query,
  ) {
    final needle = _normalize(query);
    if (needle.isEmpty) return list;
    return list.where((c) => _haystackOf(c).contains(needle)).toList();
  }

  /// Texto sobre el que se busca: nombre del huésped y código de reserva.
  ///
  /// El código se indexa también sin guiones para que «9KGF9NYN» encuentre
  /// «#BF-9KGF-9NYN». El contenido del último mensaje solo entra si es texto:
  /// en imágenes y documentos guarda un storage path, y buscar por UUID no
  /// tiene ningún sentido para quien usa la pantalla.
  static String _haystackOf(ConversationEntity c) {
    final code = c.bookingCode ?? '';
    final lastMessage = c.lastMessage;

    return _normalize([
      c.guestName ?? '',
      c.guestParticipant?.displayName ?? '',
      code,
      code.replaceAll('-', ''),
      if (lastMessage != null && lastMessage.isText) lastMessage.content,
    ].join(' '));
  }

  static const String _accented = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  static const String _plain = 'aaaaaeeeeiiiiooooouuuunc';

  /// Minúsculas y sin acentos, para que «jesus» encuentre «Jesús».
  static String _normalize(String value) {
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final index = _accented.indexOf(char);
      buffer.write(index == -1 ? char : _plain[index]);
    }
    return buffer.toString().trim();
  }

  bool get hasConversations => conversations.isNotEmpty;

  /// Hay búsqueda activa pero ninguna conversación la cumple.
  bool get hasNoSearchResults =>
      searchQuery.trim().isNotEmpty && visibleConversations.isEmpty;

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
        searchQuery,
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
    on<ConversationsSearchChanged>(_onSearchChanged);
    on<ConversationsDeleteRequested>(_onDeleteRequested);
    on<_ConversationsUpdated>(_onConversationsUpdated);
  }

  final ChatRepository _chatRepository;

  StreamSubscription<List<ConversationEntity>>? _conversationsSubscription;

  /// Búsqueda activa, para no perderla al recargar o al llegar realtime.
  String get _searchQuery {
    final current = state;
    return current is ConversationsLoaded ? current.searchQuery : '';
  }

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
        searchQuery: currentState.searchQuery,
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
          searchQuery: currentState.searchQuery,
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
        searchQuery: currentState.searchQuery,
      ));
    }
  }

  /// Maneja el cambio del texto de búsqueda (filtrado local).
  void _onSearchChanged(
    ConversationsSearchChanged event,
    Emitter<ConversationsState> emit,
  ) {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;
    if (currentState.searchQuery == event.query) return;

    emit(ConversationsLoaded(
      conversations: currentState.conversations,
      propertyId: currentState.propertyId,
      userId: currentState.userId,
      isRefreshing: currentState.isRefreshing,
      selectedConversation: currentState.selectedConversation,
      searchQuery: event.query,
    ));
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
        searchQuery: currentState.searchQuery,
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
        searchQuery: _searchQuery,
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
        searchQuery: _searchQuery,
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
        searchQuery: currentState.searchQuery,
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
