import 'package:equatable/equatable.dart';

/// Tipo de mensaje
enum MessageType {
  text,
  image;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MessageType.text,
    );
  }
}

/// Entidad que representa un mensaje de chat
class MessageEntity extends Equatable {
  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.msgType,
    required this.content,
    required this.createdAt,
    // Campos joined desde auth.users
    this.senderName,
    this.senderRole,
  });

  final String id;
  final String conversationId;
  final String senderUserId;
  final MessageType msgType;
  final String content;
  final DateTime createdAt;

  // Campos de relaciones (populados desde joins)
  final String? senderName;
  final String? senderRole;

  // ============================================
  // GETTERS
  // ============================================

  /// Indica si el mensaje es de texto
  bool get isText => msgType == MessageType.text;

  /// Indica si el mensaje es una imagen
  bool get isImage => msgType == MessageType.image;

  /// Indica si el mensaje fue enviado por el usuario actual
  bool isFromMe(String currentUserId) => senderUserId == currentUserId;

  /// Indica si el mensaje fue enviado por staff
  bool get isFromStaff => senderRole == 'staff' || senderRole == 'admin';

  /// Devuelve el tiempo transcurrido en formato legible
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Devuelve la hora formateada (HH:MM)
  String get formattedTime {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Devuelve el nombre del remitente o un valor por defecto
  String get displaySenderName => senderName ?? 'Usuario';

  /// Devuelve las iniciales del remitente para el avatar
  String get senderInitials {
    if (senderName == null || senderName!.isEmpty) return '?';
    final parts = senderName!.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  // ============================================
  // FACTORY METHODS
  // ============================================

  /// Crea una entidad desde un mapa JSON
  factory MessageEntity.fromJson(Map<String, dynamic> json) {
    return MessageEntity(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderUserId: json['sender_user_id'] as String,
      msgType: MessageType.fromString(json['msg_type'] as String? ?? 'text'),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      // Campos joined
      senderName: json['sender_name'] as String?,
      senderRole: json['sender_role'] as String?,
    );
  }

  // ============================================
  // METHODS
  // ============================================

  /// Crea una copia con valores modificados
  MessageEntity copyWith({
    String? id,
    String? conversationId,
    String? senderUserId,
    MessageType? msgType,
    String? content,
    DateTime? createdAt,
    String? senderName,
    String? senderRole,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderUserId: senderUserId ?? this.senderUserId,
      msgType: msgType ?? this.msgType,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
    );
  }

  /// Convierte la entidad a un mapa JSON para inserción
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_user_id': senderUserId,
      'msg_type': msgType.name,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convierte a JSON para crear (sin id ni timestamps)
  Map<String, dynamic> toJsonForCreate() {
    return {
      'conversation_id': conversationId,
      'sender_user_id': senderUserId,
      'msg_type': msgType.name,
      'content': content,
    };
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderUserId,
        msgType,
        content,
        createdAt,
        senderName,
        senderRole,
      ];
}

/// Extensión para ordenar mensajes por fecha
extension MessageListSort on List<MessageEntity> {
  /// Ordena mensajes por fecha (más antiguos primero para chat)
  List<MessageEntity> sortedByDate({bool ascending = true}) {
    final sorted = List<MessageEntity>.from(this);
    sorted.sort((a, b) {
      final comparison = a.createdAt.compareTo(b.createdAt);
      return ascending ? comparison : -comparison;
    });
    return sorted;
  }

  /// Agrupa mensajes por fecha
  Map<DateTime, List<MessageEntity>> groupedByDate() {
    final map = <DateTime, List<MessageEntity>>{};
    for (final message in this) {
      final date = DateTime(
        message.createdAt.year,
        message.createdAt.month,
        message.createdAt.day,
      );
      map.putIfAbsent(date, () => []).add(message);
    }
    return map;
  }
}
