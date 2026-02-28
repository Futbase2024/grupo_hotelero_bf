import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../../core/config/supabase_config.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';

/// DataSource para operaciones de chat con Supabase
class ChatDatasource {
  ChatDatasource();

  final _client = SupabaseConfig.client;

  void _log(String message) {
    debugPrint('🔵 [ChatDatasource] $message');
  }

  void _logError(String message, [Object? error]) {
    debugPrint('🔴 [ChatDatasource] $message');
    if (error != null) {
      debugPrint('🔴 Error: $error');
    }
  }

  /// Obtiene o crea una conversación para un booking
  Future<ConversationEntity> getOrCreateConversation({
    required String propertyId,
    String? bookingId,
    required String guestUserId,
    required String guestName,
  }) async {
    _log('getOrCreateConversation - propertyId: $propertyId, bookingId: $bookingId, guestUserId: $guestUserId');

    // Buscar conversación existente para este booking
    if (bookingId != null) {
      _log('Buscando conversación por bookingId...');
      final existingConversation = await _getConversationByBooking(bookingId);
      if (existingConversation != null) {
        _log('Conversación existente encontrada por bookingId');
        return existingConversation;
      }
    }

    // Buscar conversación existente para este usuario en esta propiedad
    _log('Buscando conversación existente para usuario...');
    final existingForUser = await _getConversationForUser(
      userId: guestUserId,
      propertyId: propertyId,
    );
    if (existingForUser != null) {
      _log('Conversación existente encontrada para usuario');
      return existingForUser;
    }

    // Crear nueva conversación
    _log('Creando nueva conversación...');
    return await _createConversation(
      propertyId: propertyId,
      bookingId: bookingId,
      guestUserId: guestUserId,
      guestName: guestName,
    );
  }

  Future<ConversationEntity?> _getConversationByBooking(String bookingId) async {
    try {
      final response = await _client
          .from(SupabaseTables.conversations)
          .select('''
            id,
            property_id,
            booking_id,
            created_at
          ''')
          .eq('booking_id', bookingId)
          .maybeSingle();

      if (response == null) return null;

      return await _enrichConversation(response);
    } catch (e) {
      _logError('Error en _getConversationByBooking', e);
      rethrow;
    }
  }

  Future<ConversationEntity?> _getConversationForUser({
    required String userId,
    required String propertyId,
  }) async {
    try {
      // Buscar conversaciones donde el usuario es participante
      _log('_getConversationForUser - consultando conversation_participants...');
      final participantResponse = await _client
          .from(SupabaseTables.conversationParticipants)
          .select('conversation_id')
          .eq('user_id', userId);

      if (participantResponse.isEmpty) {
        _log('_getConversationForUser - sin participantes');
        return null;
      }

      final conversationIds = (participantResponse as List)
          .map((p) => p['conversation_id'] as String)
          .toList();

      _log('_getConversationForUser - conversationIds: $conversationIds');

      // Buscar conversación en la propiedad
      final response = await _client
          .from(SupabaseTables.conversations)
          .select('''
            id,
            property_id,
            booking_id,
            created_at
          ''')
          .eq('property_id', propertyId)
          .inFilter('id', conversationIds)
          .maybeSingle();

      if (response == null) return null;

      return await _enrichConversation(response);
    } catch (e) {
      _logError('Error en _getConversationForUser', e);
      rethrow;
    }
  }

  Future<ConversationEntity> _createConversation({
    required String propertyId,
    String? bookingId,
    required String guestUserId,
    required String guestName,
  }) async {
    try {
      // Crear la conversación
      _log('_createConversation - insertando en conversations...');
      final conversationResponse = await _client
          .from(SupabaseTables.conversations)
          .insert({
            'property_id': propertyId,
            'booking_id': bookingId,
          })
          .select()
          .single();

      final conversationId = conversationResponse['id'] as String;
      _log('_createConversation - conversación creada: $conversationId');

      // Añadir al huésped como participante
      // Nota: El trigger de BD añade automáticamente los staff/admin de la propiedad
      _log('_createConversation - insertando huésped como participante...');
      await _client.from(SupabaseTables.conversationParticipants).insert({
        'conversation_id': conversationId,
        'user_id': guestUserId,
        'role': 'guest',
      });
      _log('_createConversation - participante insertado');

      return await _enrichConversation(conversationResponse);
    } catch (e) {
      _logError('Error en _createConversation', e);
      rethrow;
    }
  }

  Future<ConversationEntity> _enrichConversation(Map<String, dynamic> data) async {
    final conversationId = data['id'] as String;

    // Obtener participantes
    final participantsResponse = await _client
        .from(SupabaseTables.conversationParticipants)
        .select('''
          conversation_id,
          user_id,
          role,
          created_at
        ''')
        .eq('conversation_id', conversationId);

    final participants = (participantsResponse as List).map((p) {
      return ParticipantEntity.fromJson(p);
    }).toList();

    // Obtener último mensaje
    final lastMessageResponse = await _client
        .from(SupabaseTables.messages)
        .select('''
          id,
          conversation_id,
          sender_user_id,
          msg_type,
          content,
          created_at
        ''')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    MessageEntity? lastMessage;
    if (lastMessageResponse != null) {
      lastMessage = MessageEntity.fromJson(lastMessageResponse);
    }

    return ConversationEntity(
      id: conversationId,
      propertyId: data['property_id'] as String,
      bookingId: data['booking_id'] as String?,
      createdAt: DateTime.parse(data['created_at'] as String),
      participants: participants,
      lastMessage: lastMessage,
    );
  }

  /// Obtiene una conversación por ID
  Future<ConversationEntity?> getConversation(String conversationId) async {
    final response = await _client
        .from(SupabaseTables.conversations)
        .select('''
          id,
          property_id,
          booking_id,
          created_at
        ''')
        .eq('id', conversationId)
        .maybeSingle();

    if (response == null) return null;

    return await _enrichConversation(response);
  }

  /// Obtiene todas las conversaciones de una propiedad (para admin/staff)
  Future<List<ConversationEntity>> getConversationsByProperty({
    required String propertyId,
  }) async {
    final response = await _client
        .from(SupabaseTables.conversations)
        .select('''
          id,
          property_id,
          booking_id,
          created_at
        ''')
        .eq('property_id', propertyId)
        .order('created_at', ascending: false);

    final conversations = <ConversationEntity>[];
    for (final data in response) {
      final conversation = await _enrichConversation(data);
      conversations.add(conversation);
    }

    return conversations;
  }

  /// Obtiene todas las conversaciones donde el usuario es participante
  Future<List<ConversationEntity>> getConversationsForUser({
    required String userId,
    String? propertyId,
  }) async {
    // Obtener conversaciones donde el usuario es participante
    final participantResponse = await _client
        .from(SupabaseTables.conversationParticipants)
        .select('conversation_id')
        .eq('user_id', userId);

    if (participantResponse.isEmpty) return [];

    final conversationIds = (participantResponse as List)
        .map((p) => p['conversation_id'] as String)
        .toList();

    // Construir query con filtro opcional de propiedad
    List<dynamic> response;
    if (propertyId != null) {
      response = await _client
          .from(SupabaseTables.conversations)
          .select('''
            id,
            property_id,
            booking_id,
            created_at
          ''')
          .inFilter('id', conversationIds)
          .eq('property_id', propertyId)
          .order('created_at', ascending: false);
    } else {
      response = await _client
          .from(SupabaseTables.conversations)
          .select('''
            id,
            property_id,
            booking_id,
            created_at
          ''')
          .inFilter('id', conversationIds)
          .order('created_at', ascending: false);
    }

    final conversations = <ConversationEntity>[];
    for (final data in response) {
      final conversation = await _enrichConversation(data);
      conversations.add(conversation);
    }

    return conversations;
  }

  /// Obtiene los mensajes de una conversación
  Future<List<MessageEntity>> getMessages({
    required String conversationId,
    int limit = 50,
    DateTime? before,
  }) async {
    List<dynamic> response;

    if (before != null) {
      response = await _client
          .from(SupabaseTables.messages)
          .select('''
            id,
            conversation_id,
            sender_user_id,
            msg_type,
            content,
            created_at
          ''')
          .eq('conversation_id', conversationId)
          .lt('created_at', before.toIso8601String())
          .order('created_at', ascending: true)
          .limit(limit);
    } else {
      response = await _client
          .from(SupabaseTables.messages)
          .select('''
            id,
            conversation_id,
            sender_user_id,
            msg_type,
            content,
            created_at
          ''')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .limit(limit);
    }

    return response.map((m) => MessageEntity.fromJson(m)).toList();
  }

  /// Envía un mensaje de texto
  Future<MessageEntity> sendTextMessage({
    required String conversationId,
    required String senderUserId,
    required String content,
  }) async {
    final response = await _client
        .from(SupabaseTables.messages)
        .insert({
          'conversation_id': conversationId,
          'sender_user_id': senderUserId,
          'msg_type': 'text',
          'content': content,
        })
        .select()
        .single();

    return MessageEntity.fromJson(response);
  }

  /// Envía un mensaje con imagen
  Future<MessageEntity> sendImageMessage({
    required String conversationId,
    required String senderUserId,
    required String imagePath,
  }) async {
    final response = await _client
        .from(SupabaseTables.messages)
        .insert({
          'conversation_id': conversationId,
          'sender_user_id': senderUserId,
          'msg_type': 'image',
          'content': imagePath,
        })
        .select()
        .single();

    return MessageEntity.fromJson(response);
  }

  /// Suscribe a nuevos mensajes en tiempo real usando Supabase Realtime
  Stream<MessageEntity> watchMessages(String conversationId) {
    // Usar el stream nativo de Supabase para la tabla messages
    return _client
        .from(SupabaseTables.messages)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .asyncMap((data) async {
          // Obtener solo el último mensaje nuevo
          if (data.isNotEmpty) {
            final lastRecord = data.last;
            return MessageEntity.fromJson(lastRecord);
          }
          // Retornar null si no hay datos, pero el stream necesita un valor
          // Usamos un mensaje vacío que será filtrado en el BLoC
          return MessageEntity(
            id: '',
            conversationId: conversationId,
            senderUserId: '',
            msgType: MessageType.text,
            content: '',
            createdAt: DateTime.now(),
          );
        })
        .where((message) => message.id.isNotEmpty); // Filtrar mensajes vacíos
  }

  /// Marca mensajes como leídos (implementación futura con tabla de read_status)
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  }) async {
    // Por ahora no implementamos tracking de lectura
    // Se podría añadir una tabla message_read_status
  }

  /// Obtiene el conteo de mensajes no leídos
  Future<int> getUnreadCount({
    required String conversationId,
    required String userId,
  }) async {
    // Por ahora retorna 0, implementar con tabla de read_status
    return 0;
  }

  /// Cancela suscripciones (no-op con stream nativo de Supabase)
  void dispose() {
    // Los streams de Supabase se cancelan automáticamente cuando no hay listeners
  }
}
