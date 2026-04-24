import 'package:bf_stay/core/utils/timestamp_parser.dart';
import 'package:equatable/equatable.dart';

import 'message_entity.dart';

/// Rol del participante en la conversación
enum ParticipantRole {
  guest,
  staff,
  admin;

  static ParticipantRole fromString(String value) {
    return ParticipantRole.values.firstWhere(
      (role) => role.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ParticipantRole.guest,
    );
  }
}

/// Participante de una conversación
class ParticipantEntity extends Equatable {
  const ParticipantEntity({
    required this.conversationId,
    required this.userId,
    required this.role,
    required this.createdAt,
    // Campos joined desde auth.users
    this.userName,
    this.userEmail,
  });

  final String conversationId;
  final String userId;
  final ParticipantRole role;
  final DateTime createdAt;

  // Campos de relaciones
  final String? userName;
  final String? userEmail;

  // ============================================
  // GETTERS
  // ============================================

  /// Indica si el participante es staff
  bool get isStaff => role == ParticipantRole.staff || role == ParticipantRole.admin;

  /// Devuelve el nombre para mostrar
  String get displayName => userName ?? userEmail ?? 'Usuario';

  /// Devuelve las iniciales para el avatar
  String get initials {
    if (userName != null && userName!.isNotEmpty) {
      final parts = userName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    if (userEmail != null && userEmail!.isNotEmpty) {
      return userEmail![0].toUpperCase();
    }
    return '?';
  }

  // ============================================
  // FACTORY METHODS
  // ============================================

  factory ParticipantEntity.fromJson(Map<String, dynamic> json) {
    return ParticipantEntity(
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      role: ParticipantRole.fromString(json['role'] as String? ?? 'guest'),
      createdAt: parseUtcTimestamp(json['created_at'] as String),
      userName: json['user_name'] as String?,
      userEmail: json['user_email'] as String?,
    );
  }

  // ============================================
  // METHODS
  // ============================================

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'user_id': userId,
      'role': role.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        conversationId,
        userId,
        role,
        createdAt,
        userName,
        userEmail,
      ];
}

/// Entidad que representa una conversación de chat
class ConversationEntity extends Equatable {
  const ConversationEntity({
    required this.id,
    required this.propertyId,
    this.bookingId,
    required this.createdAt,
    this.participants = const [],
    this.lastMessage,
    this.unreadCount = 0,
    // Campos joined desde otras tablas
    this.propertyName,
    this.bookingCode,
    this.guestName,
  });

  final String id;
  final String propertyId;
  final String? bookingId;
  final DateTime createdAt;
  final List<ParticipantEntity> participants;
  final MessageEntity? lastMessage;
  final int unreadCount;

  // Campos de relaciones
  final String? propertyName;
  final String? bookingCode;
  final String? guestName;

  // ============================================
  // GETTERS
  // ============================================

  /// Indica si la conversación tiene mensajes
  bool get hasMessages => lastMessage != null;

  /// Indica si hay mensajes sin leer
  bool get hasUnread => unreadCount > 0;

  /// Devuelve el tiempo transcurrido desde el último mensaje
  String get lastMessageTimeAgo {
    if (lastMessage == null) return '';
    return lastMessage!.timeAgo;
  }

  /// Devuelve un preview del último mensaje
  String get lastMessagePreview {
    if (lastMessage == null) return 'Sin mensajes';
    if (lastMessage!.isImage) return '📷 Imagen';
    final text = lastMessage!.content;
    if (text.length <= 50) return text;
    return '${text.substring(0, 50)}...';
  }

  /// Obtiene el participante staff (para mostrar en el header del chat)
  ParticipantEntity? get staffParticipant {
    try {
      return participants.firstWhere((p) => p.isStaff);
    } catch (_) {
      return null;
    }
  }

  /// Obtiene el participante guest
  ParticipantEntity? get guestParticipant {
    try {
      return participants.firstWhere((p) => !p.isStaff);
    } catch (_) {
      return null;
    }
  }

  /// Devuelve el nombre del otro participante según el contexto
  /// - Si el usuario actual es guest → mostrar "Grupo H. BF"
  /// - Si el usuario actual es staff → mostrar el nombre del huésped
  String getOtherParticipantName(String currentUserId) {
    // Encontrar al otro participante (que no sea el usuario actual)
    try {
      final otherParticipant = participants.firstWhere(
        (p) => p.userId != currentUserId,
      );

      // Si el otro participante es staff, mostrar "Grupo H. BF"
      if (otherParticipant.isStaff) {
        return 'Grupo H. BF';
      }

      // Si es guest, mostrar su nombre
      return otherParticipant.displayName;
    } catch (_) {
      // Si no hay otro participante, mostrar un valor por defecto
      return 'Chat';
    }
  }

  /// Devuelve el nombre del otro participante (staff para guests, guest para staff)
  /// @deprecated Usar getOtherParticipantName(currentUserId) en su lugar
  String get otherParticipantName {
    // Para guests, mostrar "Recepción"
    // Para staff, mostrar el nombre del huésped
    final staffParticipant = this.staffParticipant;
    if (staffParticipant != null) {
      return 'Recepción';
    }
    return 'Chat';
  }

  /// Devuelve el nombre para mostrar en la lista de conversaciones del admin
  /// Formato: "Nombre Huésped - #CODIGO" o "Huésped" si no hay datos
  String get displayNameForAdmin {
    // Priorizar el nombre del booking (guestName), luego el del participante
    final name = guestName ?? guestParticipant?.displayName ?? 'Huésped';

    if (bookingCode != null && bookingCode!.isNotEmpty) {
      return '$name - #$bookingCode';
    }
    return name;
  }

  // ============================================
  // FACTORY METHODS
  // ============================================

  factory ConversationEntity.fromJson(Map<String, dynamic> json) {
    return ConversationEntity(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      bookingId: json['booking_id'] as String?,
      createdAt: parseUtcTimestamp(json['created_at'] as String),
      participants: json['participants'] != null
          ? (json['participants'] as List)
              .map((p) => ParticipantEntity.fromJson(p as Map<String, dynamic>))
              .toList()
          : [],
      lastMessage: json['last_message'] != null
          ? MessageEntity.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      propertyName: json['property_name'] as String?,
      bookingCode: json['booking_code'] as String?,
      guestName: json['guest_name'] as String?,
    );
  }

  // ============================================
  // METHODS
  // ============================================

  ConversationEntity copyWith({
    String? id,
    String? propertyId,
    String? bookingId,
    DateTime? createdAt,
    List<ParticipantEntity>? participants,
    MessageEntity? lastMessage,
    int? unreadCount,
    String? propertyName,
    String? bookingCode,
    String? guestName,
  }) {
    return ConversationEntity(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      bookingId: bookingId ?? this.bookingId,
      createdAt: createdAt ?? this.createdAt,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      propertyName: propertyName ?? this.propertyName,
      bookingCode: bookingCode ?? this.bookingCode,
      guestName: guestName ?? this.guestName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'booking_id': bookingId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'property_id': propertyId,
      'booking_id': bookingId,
    };
  }

  @override
  List<Object?> get props => [
        id,
        propertyId,
        bookingId,
        createdAt,
        participants,
        lastMessage,
        unreadCount,
        propertyName,
        bookingCode,
        guestName,
      ];
}
