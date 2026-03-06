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

  /// Asegura que hay una sesión activa de Supabase
  /// Si no hay sesión, crea una sesión anónima
  Future<void> _ensureSession() async {
    final currentSession = _client.auth.currentSession;
    if (currentSession == null) {
      _log('No hay sesión activa, creando sesión anónima...');
      try {
        await _client.auth.signInAnonymously();
        _log('Sesión anónima creada correctamente');
      } catch (e) {
        _logError('Error creando sesión anónima', e);
        rethrow;
      }
    } else {
      _log('Sesión activa encontrada: ${currentSession.user.id}');
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
      // Asegurar que hay una sesión activa antes de hacer el insert
      await _ensureSession();

      // IMPORTANTE: Usar el ID de la sesión ACTUAL de Supabase
      // para que coincida con auth.uid() en las políticas RLS
      final currentAuthUserId = _client.auth.currentUser?.id;
      if (currentAuthUserId == null) {
        throw Exception('No se pudo obtener el ID de usuario de la sesión actual');
      }

      _log('_createConversation - Usando auth.uid(): $currentAuthUserId (guestUserId pasado: $guestUserId)');

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

      // Añadir al huésped como participante usando el ID de la sesión actual
      // Nota: El trigger de BD añade automáticamente los staff/admin de la propiedad
      _log('_createConversation - insertando huésped como participante...');
      await _client.from(SupabaseTables.conversationParticipants).insert({
        'conversation_id': conversationId,
        'user_id': currentAuthUserId, // Usar el ID de la sesión actual
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

    // Obtener IDs de participantes para buscar sus nombres
    final participantUserIds = (participantsResponse as List)
        .map((p) => p['user_id'] as String)
        .toList();

    // Obtener información de todos los participantes en batch
    final participantsInfo = await _getSendersInfo(participantUserIds);

    // Mapear participantes incluyendo sus nombres
    final participants = participantsResponse.map((p) {
      final userId = p['user_id'] as String;
      final info = participantsInfo[userId];

      final flattenedMap = Map<String, dynamic>.from(p);
      flattenedMap['user_name'] = info?['full_name'];
      // Usar el email de auth.users si está disponible
      flattenedMap['user_email'] = null;

      return ParticipantEntity.fromJson(flattenedMap);
    }).toList();

    // Obtener último mensaje (sin joins, la relación es con auth.users)
    final lastMessageResponse = await _client
        .from(SupabaseTables.messages)
        .select('''
          id,
          conversation_id,
          sender_user_id,
          msg_type,
          content,
          created_at,
          read_at
        ''')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    MessageEntity? lastMessage;
    if (lastMessageResponse != null) {
      // Obtener info del remitente
      final senderUserId = lastMessageResponse['sender_user_id'] as String;
      final senderInfo = await _getSenderInfo(senderUserId);

      final flattenedMap = Map<String, dynamic>.from(lastMessageResponse);
      flattenedMap['sender_name'] = senderInfo['full_name'];
      flattenedMap['sender_role'] = senderInfo['role'];

      lastMessage = MessageEntity.fromJson(flattenedMap);
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

    // Query básica sin joins (la relación es con auth.users, no con profiles)
    final selectQuery = '''
      id,
      conversation_id,
      sender_user_id,
      msg_type,
      content,
      created_at,
      read_at
    ''';

    if (before != null) {
      response = await _client
          .from(SupabaseTables.messages)
          .select(selectQuery)
          .eq('conversation_id', conversationId)
          .lt('created_at', before.toIso8601String())
          .order('created_at', ascending: true)
          .limit(limit);
    } else {
      response = await _client
          .from(SupabaseTables.messages)
          .select(selectQuery)
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .limit(limit);
    }

    // Obtener IDs únicos de remitentes para consulta batch
    final senderIds = response
        .map((m) => m['sender_user_id'] as String)
        .toSet()
        .toList();

    // Obtener información de todos los remitentes en batch
    final sendersInfo = await _getSendersInfo(senderIds);

    // Mapear la respuesta incluyendo los datos del remitente
    return response.map((m) {
      final senderUserId = m['sender_user_id'] as String;
      final senderInfo = sendersInfo[senderUserId];

      final flattenedMap = Map<String, dynamic>.from(m);
      flattenedMap['sender_name'] = senderInfo?['full_name'];
      flattenedMap['sender_role'] = senderInfo?['role'];

      return MessageEntity.fromJson(flattenedMap);
    }).toList();
  }

  /// Obtiene información de múltiples remitentes en batch usando RPC
  Future<Map<String, Map<String, String?>>> _getSendersInfo(List<String> userIds) async {
    if (userIds.isEmpty) return {};

    try {
      // Usar función RPC con SECURITY DEFINER para evitar problemas de RLS
      final response = await _client.rpc(
        'get_senders_info',
        params: {'user_ids': userIds},
      );

      if (response == null || response is! List) return {};

      // Crear mapa de resultados
      final result = <String, Map<String, String?>>{};
      for (final data in response) {
        final userId = data['user_id'] as String;
        result[userId] = {
          'full_name': data['full_name'] as String?,
          'role': data['role'] as String?,
        };
      }

      return result;
    } catch (e) {
      _logError('Error obteniendo info de remitentes', e);
      return {};
    }
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
  /// Emite SOLO cuando llega un mensaje nuevo (no re-emite mensajes existentes)
  /// Cada suscripción mantiene su propio estado de tracking local
  Stream<MessageEntity> watchMessages(String conversationId) {
    _log('watchMessages - Iniciando stream para conversación: $conversationId');

    // Estado local para esta suscripción específica
    // Cada listener tiene su propio timestamp tracking
    DateTime? lastSeenCreatedAt;
    bool isFirstEmission = true;

    return _client
        .from(SupabaseTables.messages)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .asyncMap((data) async {
          if (data.isEmpty) return null;

          // Primera emisión: inicializar timestamp SIN emitir nada
          // Los mensajes iniciales ya se cargaron con getMessages()
          if (isFirstEmission) {
            isFirstEmission = false;
            if (data.isNotEmpty) {
              lastSeenCreatedAt = DateTime.parse(
                data.last['created_at'] as String,
              );
              _log('watchMessages - Timestamp inicial: $lastSeenCreatedAt');
            }
            return null;
          }

          // Si no hay timestamp previo (edge case), no emitir
          if (lastSeenCreatedAt == null) {
            return null;
          }

          // Buscar mensajes nuevos comparando con el último timestamp visto
          final newMessages = data.where((record) {
            final createdAt = DateTime.parse(record['created_at'] as String);
            return createdAt.isAfter(lastSeenCreatedAt!);
          }).toList();

          if (newMessages.isEmpty) return null;

          // Actualizar el último timestamp visto al más reciente de los nuevos
          final newestMessage = newMessages.last;
          lastSeenCreatedAt = DateTime.parse(
            newestMessage['created_at'] as String,
          );

          // Obtener IDs únicos de remitentes de los mensajes nuevos
          final senderIds = newMessages
              .map((m) => m['sender_user_id'] as String)
              .toSet()
              .toList();

          // Obtener info de remitentes en batch
          final sendersInfo = await _getSendersInfo(senderIds);

          // Devolver el mensaje más reciente (el stream emite uno a uno)
          final record = newestMessage;
          final senderUserId = record['sender_user_id'] as String;
          final senderInfo = sendersInfo[senderUserId];

          final flattenedMap = Map<String, dynamic>.from(record);
          flattenedMap['sender_name'] = senderInfo?['full_name'];
          flattenedMap['sender_role'] = senderInfo?['role'];

          _log('watchMessages - Nuevo mensaje detectado: ${record['id']}');
          return MessageEntity.fromJson(flattenedMap);
        })
        .where((message) => message != null)
        .cast<MessageEntity>();
  }

  /// Obtiene información del remitente (nombre y rol) usando RPC
  Future<Map<String, String?>> _getSenderInfo(String userId) async {
    try {
      // Usar función RPC con SECURITY DEFINER para evitar problemas de RLS
      final response = await _client.rpc(
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
      _logError('Error obteniendo info del remitente', e);
      return {'full_name': null, 'role': null};
    }
  }

  /// Suscribe a cambios en las conversaciones de un usuario en tiempo real
  /// Incluye actualización de unread_count y último mensaje
  Stream<List<ConversationEntity>> watchUserConversations({
    required String userId,
    String? propertyId,
  }) {
    _log('watchUserConversations - userId: $userId, propertyId: $propertyId');

    // Obtener conversation_ids del usuario
    return _client
        .from(SupabaseTables.conversationParticipants)
        .stream(primaryKey: ['conversation_id', 'user_id'])
        .eq('user_id', userId)
        .asyncMap((participantData) async {
          if (participantData.isEmpty) return <ConversationEntity>[];

          final conversationIds = (participantData as List)
              .map((p) => p['conversation_id'] as String)
              .toList();

          _log('watchUserConversations - ${conversationIds.length} conversaciones');

          // Cargar conversaciones completas
          final conversations = <ConversationEntity>[];
          for (final convId in conversationIds) {
            final conv = await getConversation(convId);
            if (conv != null) {
              // Filtrar por propertyId si se especifica
              if (propertyId == null || conv.propertyId == propertyId) {
                conversations.add(conv);
              }
            }
          }

          // Ordenar por último mensaje
          conversations.sort((a, b) {
            if (a.lastMessage != null && b.lastMessage != null) {
              return b.lastMessage!.createdAt.compareTo(a.lastMessage!.createdAt);
            }
            if (a.lastMessage != null) return -1;
            if (b.lastMessage != null) return 1;
            return b.createdAt.compareTo(a.createdAt);
          });

          return conversations;
        });
  }

  /// Marca mensajes como leídos
  /// Actualiza unread_count a 0 y marca los mensajes como leídos
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  }) async {
    _log('markAsRead - conversationId: $conversationId, userId: $userId');

    try {
      // 1. Actualizar unread_count a 0 y last_read_at en conversation_participants
      await _client
          .from(SupabaseTables.conversationParticipants)
          .update({
            'unread_count': 0,
            'last_read_at': DateTime.now().toIso8601String(),
          })
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);

      // 2. Marcar mensajes como leídos (los que no son del usuario y no están leídos)
      await _client
          .from(SupabaseTables.messages)
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', conversationId)
          .neq('sender_user_id', userId)
          .filter('read_at', 'is', null);

      _log('markAsRead - mensajes marcados como leídos');
    } catch (e) {
      _logError('Error en markAsRead', e);
      rethrow;
    }
  }

  /// Obtiene el conteo de mensajes no leídos para un usuario en una conversación
  Future<int> getUnreadCount({
    required String conversationId,
    required String userId,
  }) async {
    try {
      final response = await _client
          .from(SupabaseTables.conversationParticipants)
          .select('unread_count')
          .eq('conversation_id', conversationId)
          .eq('user_id', userId)
          .maybeSingle();

      final count = response?['unread_count'] as int? ?? 0;
      _log('getUnreadCount - count: $count');
      return count;
    } catch (e) {
      _logError('Error en getUnreadCount', e);
      return 0;
    }
  }

  /// Cancela suscripciones (no-op con stream nativo de Supabase)
  void dispose() {
    // Los streams de Supabase se cancelan automáticamente cuando no hay listeners
  }
}
