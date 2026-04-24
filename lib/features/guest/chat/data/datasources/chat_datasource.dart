import 'dart:async';

import 'package:bf_stay/core/utils/timestamp_parser.dart';
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

    // Validar que propertyId no esté vacío
    if (propertyId.isEmpty) {
      throw ArgumentError('propertyId no puede estar vacío');
    }

    // Validar que guestUserId no esté vacío
    if (guestUserId.isEmpty) {
      throw ArgumentError('guestUserId no puede estar vacío');
    }

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
      _log('_getConversationByBooking - buscando bookingId: $bookingId');

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

      _log('_getConversationByBooking - respuesta: $response');

      if (response == null) {
        _log('_getConversationByBooking - no se encontró conversación');
        return null;
      }

      _log('_getConversationByBooking - conversación encontrada: ${response['id']}');
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
      await _ensureSession();

      _log('_createConversation - guestUserId: $guestUserId, guestName: $guestName');

      // RPC con SECURITY DEFINER: crea conversación + añade guest como participante
      // en una sola llamada atómica. No depende de las políticas RLS.
      _log('_createConversation - llamando RPC create_guest_conversation...');
      final conversationId = await _client.rpc(
        'create_guest_conversation',
        params: {
          'p_property_id': propertyId,
          'p_booking_id': bookingId,
          'p_guest_user_id': guestUserId,
          'p_guest_name': guestName,
        },
      ) as String;

      _log('_createConversation - conversación creada via RPC: $conversationId');

      // Ya somos participante, SELECT pasa la política RLS
      final conversationResponse = await _client
          .from(SupabaseTables.conversations)
          .select('''
            id,
            property_id,
            booking_id,
            created_at
          ''')
          .eq('id', conversationId)
          .single();

      return await _enrichConversation(conversationResponse);
    } catch (e) {
      _logError('Error en _createConversation', e);
      rethrow;
    }
  }

  Future<ConversationEntity> _enrichConversation(Map<String, dynamic> data) async {
    final conversationId = data['id'] as String;
    final bookingId = data['booking_id'] as String?;

    // Obtener participantes y último mensaje en paralelo
    final results = await Future.wait([
      _client
          .from(SupabaseTables.conversationParticipants)
          .select('conversation_id, user_id, role, created_at')
          .eq('conversation_id', conversationId),
      _client
          .from(SupabaseTables.messages)
          .select('id, conversation_id, sender_user_id, msg_type, content, created_at, read_at')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(1),
    ]);

    final participantsResponse = results[0] as List;
    final messagesResponse = results[1] as List;
    final lastMessageRaw = messagesResponse.isNotEmpty ? messagesResponse.first as Map<String, dynamic> : null;

    // Recopilar todos los user IDs en una sola llamada batch (participantes + remitente del mensaje)
    final allUserIds = participantsResponse
        .map((p) => p['user_id'] as String)
        .toSet();
    if (lastMessageRaw != null) {
      allUserIds.add(lastMessageRaw['sender_user_id'] as String);
    }

    final allUsersInfo = await _getSendersInfo(allUserIds.toList());

    // Mapear participantes incluyendo sus nombres
    final participants = participantsResponse.map((p) {
      final userId = p['user_id'] as String;
      final info = allUsersInfo[userId];
      final flattenedMap = Map<String, dynamic>.from(p);
      flattenedMap['user_name'] = info?['full_name'];
      flattenedMap['user_email'] = null;
      return ParticipantEntity.fromJson(flattenedMap);
    }).toList();

    // Construir último mensaje con info del remitente (ya en allUsersInfo, sin query extra)
    MessageEntity? lastMessage;
    if (lastMessageRaw != null) {
      final senderUserId = lastMessageRaw['sender_user_id'] as String;
      final senderInfo = allUsersInfo[senderUserId];
      final flattenedMap = Map<String, dynamic>.from(lastMessageRaw);
      flattenedMap['sender_name'] = senderInfo?['full_name'];
      flattenedMap['sender_role'] = senderInfo?['role'];
      lastMessage = MessageEntity.fromJson(flattenedMap);
    }

    // Obtener información del booking si existe
    String? bookingCode;
    String? guestName;
    if (bookingId != null) {
      try {
        final bookingResponse = await _client
            .from(SupabaseTables.bookings)
            .select('booking_code, guest_first_name, last_name')
            .eq('id', bookingId)
            .maybeSingle();

        if (bookingResponse != null) {
          bookingCode = bookingResponse['booking_code'] as String?;
          final firstName = bookingResponse['guest_first_name'] as String?;
          final lastName = bookingResponse['last_name'] as String?;
          if (firstName != null || lastName != null) {
            guestName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
          }
        }
      } catch (e) {
        _logError('Error obteniendo info del booking', e);
      }
    }

    return ConversationEntity(
      id: conversationId,
      propertyId: data['property_id'] as String,
      bookingId: bookingId,
      createdAt: parseUtcTimestamp(data['created_at'] as String),
      participants: participants,
      lastMessage: lastMessage,
      bookingCode: bookingCode,
      guestName: guestName,
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
  /// ✅ OPTIMIZADO: batch queries en lugar de N+1
  Future<List<ConversationEntity>> getConversationsByProperty({
    required String propertyId,
  }) async {
    final response = await _client
        .from(SupabaseTables.conversations)
        .select('id')
        .eq('property_id', propertyId);

    final conversationIds = (response as List)
        .map((c) => c['id'] as String)
        .toList();

    return _getConversationsBatch(conversationIds, propertyId);
  }

  /// Obtiene todas las conversaciones donde el usuario es participante
  /// ✅ OPTIMIZADO: batch queries en lugar de N+1
  Future<List<ConversationEntity>> getConversationsForUser({
    required String userId,
    String? propertyId,
  }) async {
    final participantResponse = await _client
        .from(SupabaseTables.conversationParticipants)
        .select('conversation_id')
        .eq('user_id', userId);

    if (participantResponse.isEmpty) return [];

    final conversationIds = (participantResponse as List)
        .map((p) => p['conversation_id'] as String)
        .toList();

    return _getConversationsBatch(conversationIds, propertyId);
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
  /// Usa el stream nativo de Supabase con filtro por conversation_id
  /// Emite SOLO cuando llega un mensaje nuevo (no re-emite mensajes existentes)
  Stream<MessageEntity> watchMessages(String conversationId) {
    _log('watchMessages - Iniciando stream para conversación: $conversationId');

    // Trackear IDs de mensajes ya emitidos para evitar duplicados
    final emittedMessageIds = <String>{};

    return _client
        .from(SupabaseTables.messages)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .asyncMap((messages) async {
          if (messages.isEmpty) return <MessageEntity>[];

          // Obtener IDs únicos de remitentes para consulta batch
          final senderIds = messages
              .map((m) => m['sender_user_id'] as String)
              .toSet()
              .toList();

          // Obtener información de todos los remitentes en batch
          final sendersInfo = await _getSendersInfo(senderIds);

          // Filtrar solo mensajes NUEVOS (no emitidos previamente)
          final newMessages = <MessageEntity>[];

          for (final m in messages) {
            final messageId = m['id'] as String;

            // Si ya emitimos este mensaje, lo saltamos
            if (emittedMessageIds.contains(messageId)) {
              continue;
            }

            // Marcar como emitido
            emittedMessageIds.add(messageId);

            // Construir el mensaje con info del remitente
            final senderUserId = m['sender_user_id'] as String;
            final senderInfo = sendersInfo[senderUserId];

            final flattenedMap = Map<String, dynamic>.from(m);
            flattenedMap['sender_name'] = senderInfo?['full_name'];
            flattenedMap['sender_role'] = senderInfo?['role'];

            newMessages.add(MessageEntity.fromJson(flattenedMap));
            _log('watchMessages - Nuevo mensaje emitido: $messageId');
          }

          return newMessages;
        })
        // Expandir la lista de mensajes nuevos en mensajes individuales
        .expand((messages) => messages);
  }

  /// Suscribe a cambios en las conversaciones de un usuario en tiempo real
  /// Incluye actualización de unread_count y último mensaje
  /// ✅ OPTIMIZADO: Batch queries + throttle para evitar N+1 y disparos continuos
  Stream<List<ConversationEntity>> watchUserConversations({
    required String userId,
    String? propertyId,
  }) {
    _log('watchUserConversations - userId: $userId, propertyId: $propertyId');

    DateTime? lastEmit;

    return _client
        .from(SupabaseTables.conversationParticipants)
        .stream(primaryKey: ['conversation_id', 'user_id'])
        .eq('user_id', userId)
        .asyncMap((participantData) async {
          // Throttle: ignorar si el último emit fue hace menos de 800ms
          final now = DateTime.now();
          if (lastEmit != null &&
              now.difference(lastEmit!) < const Duration(milliseconds: 800)) {
            return null;
          }
          lastEmit = now;

          if (participantData.isEmpty) return <ConversationEntity>[];

          final conversationIds = (participantData as List)
              .map((p) => p['conversation_id'] as String)
              .toList();

          _log('watchUserConversations - ${conversationIds.length} conversaciones');

          return await _getConversationsBatch(conversationIds, propertyId);
        })
        .where((result) => result != null)
        .cast<List<ConversationEntity>>();
  }

  /// ✅ OPTIMIZACIÓN: Obtiene múltiples conversaciones en batch (4 queries en lugar de N*3)
  Future<List<ConversationEntity>> _getConversationsBatch(
    List<String> conversationIds,
    String? propertyId,
  ) async {
    if (conversationIds.isEmpty) return [];

    try {
      // 1. Obtener todas las conversaciones en un solo query
      var conversationsQuery = _client
          .from(SupabaseTables.conversations)
          .select('''
            id,
            property_id,
            booking_id,
            created_at
          ''')
          .inFilter('id', conversationIds);

      // Filtrar por propertyId si se especifica
      if (propertyId != null) {
        conversationsQuery = conversationsQuery.eq('property_id', propertyId);
      }

      final conversationsResponse = await conversationsQuery;

      if (conversationsResponse.isEmpty) return [];

      final filteredConversationIds = (conversationsResponse as List)
          .map((c) => c['id'] as String)
          .toList();

      // 2. Obtener todos los participantes de todas las conversaciones en un solo query
      final participantsResponse = await _client
          .from(SupabaseTables.conversationParticipants)
          .select('''
            conversation_id,
            user_id,
            role,
            created_at
          ''')
          .inFilter('conversation_id', filteredConversationIds);

      // 3. Obtener todos los user_ids únicos para buscar sus nombres
      final userIds = (participantsResponse as List)
          .map((p) => p['user_id'] as String)
          .toSet()
          .toList();

      // 4. Obtener info de todos los usuarios en batch
      final usersInfo = await _getSendersInfo(userIds);

      // 5. Agrupar participantes por conversation_id
      final participantsByConversation = <String, List<Map<String, dynamic>>>{};
      for (final p in participantsResponse) {
        final convId = p['conversation_id'] as String;
        participantsByConversation.putIfAbsent(convId, () => []).add(p);
      }

      // 6. Obtener últimos mensajes de todas las conversaciones en un solo query
      // Usamos una subquery para obtener el mensaje más reciente de cada conversación
      final lastMessagesResponse = await _client
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
          .inFilter('conversation_id', filteredConversationIds)
          .order('created_at', ascending: false);

      // Filtrar para mantener solo el último mensaje de cada conversación
      final lastMessagesByConversation = <String, Map<String, dynamic>>{};
      final seenConversationIds = <String>{};
      for (final msg in lastMessagesResponse) {
        final convId = msg['conversation_id'] as String;
        if (!seenConversationIds.contains(convId)) {
          seenConversationIds.add(convId);
          lastMessagesByConversation[convId] = msg;
        }
      }

      // 7. Obtener información de bookings en batch
      final bookingIds = (conversationsResponse as List)
          .map((c) => c['booking_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      final bookingsInfo = <String, Map<String, dynamic>>{};
      if (bookingIds.isNotEmpty) {
        try {
          final bookingsResponse = await _client
              .from(SupabaseTables.bookings)
              .select('id, booking_code, guest_first_name, last_name')
              .inFilter('id', bookingIds);

          for (final b in bookingsResponse) {
            bookingsInfo[b['id'] as String] = b;
          }
        } catch (e) {
          _logError('Error obteniendo info de bookings', e);
        }
      }

      // 8. Construir las entidades de conversación
      final conversations = <ConversationEntity>[];
      for (final convData in conversationsResponse) {
        final convId = convData['id'] as String;
        final bookingId = convData['booking_id'] as String?;

        // Construir participantes con nombres
        final participantsRaw = participantsByConversation[convId] ?? [];
        final participants = participantsRaw.map((p) {
          final userId = p['user_id'] as String;
          final info = usersInfo[userId];

          return ParticipantEntity.fromJson({
            'conversation_id': p['conversation_id'],
            'user_id': userId,
            'role': p['role'],
            'created_at': p['created_at'],
            'user_name': info?['full_name'],
            'user_email': null,
          });
        }).toList();

        // Construir último mensaje si existe
        MessageEntity? lastMessage;
        final lastMsgData = lastMessagesByConversation[convId];
        if (lastMsgData != null) {
          final senderUserId = lastMsgData['sender_user_id'] as String;
          final senderInfo = usersInfo[senderUserId];

          lastMessage = MessageEntity.fromJson({
            'id': lastMsgData['id'],
            'conversation_id': lastMsgData['conversation_id'],
            'sender_user_id': senderUserId,
            'msg_type': lastMsgData['msg_type'],
            'content': lastMsgData['content'],
            'created_at': lastMsgData['created_at'],
            'read_at': lastMsgData['read_at'],
            'sender_name': senderInfo?['full_name'],
            'sender_role': senderInfo?['role'],
          });
        }

        // Obtener info del booking si existe
        String? bookingCode;
        String? guestName;
        if (bookingId != null) {
          final bookingInfo = bookingsInfo[bookingId];
          if (bookingInfo != null) {
            bookingCode = bookingInfo['booking_code'] as String?;
            final firstName = bookingInfo['guest_first_name'] as String?;
            final lastName = bookingInfo['last_name'] as String?;
            if (firstName != null || lastName != null) {
              guestName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
            }
          }
        }

        conversations.add(ConversationEntity(
          id: convId,
          propertyId: convData['property_id'] as String,
          bookingId: bookingId,
          createdAt: parseUtcTimestamp(convData['created_at'] as String),
          participants: participants,
          lastMessage: lastMessage,
          bookingCode: bookingCode,
          guestName: guestName,
        ));
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
    } catch (e) {
      _logError('Error en _getConversationsBatch', e);
      rethrow;
    }
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

  /// Elimina una conversación completa (mensajes, participantes y conversación)
  /// Solo disponible para admin/staff
  Future<void> deleteConversation({
    required String conversationId,
  }) async {
    _log('deleteConversation - conversationId: $conversationId');

    try {
      // 1. Eliminar mensajes de la conversación
      await _client
          .from(SupabaseTables.messages)
          .delete()
          .eq('conversation_id', conversationId);
      _log('deleteConversation - mensajes eliminados');

      // 2. Eliminar participantes de la conversación
      await _client
          .from(SupabaseTables.conversationParticipants)
          .delete()
          .eq('conversation_id', conversationId);
      _log('deleteConversation - participantes eliminados');

      // 3. Eliminar la conversación
      await _client
          .from(SupabaseTables.conversations)
          .delete()
          .eq('id', conversationId);
      _log('deleteConversation - conversación eliminada');
    } catch (e) {
      _logError('Error en deleteConversation', e);
      rethrow;
    }
  }

  /// Cancela suscripciones (no-op con stream nativo de Supabase)
  void dispose() {
    // Los streams de Supabase se cancelan automáticamente cuando no hay listeners
  }
}
