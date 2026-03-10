import 'package:equatable/equatable.dart';

/// Tipo de campaña de marketing
enum CampaignType {
  email,
  push,
  sms,
  whatsapp;

  static CampaignType fromString(String value) {
    return CampaignType.values.firstWhere(
      (type) => type.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CampaignType.email,
    );
  }

  String get displayName {
    switch (this) {
      case CampaignType.email:
        return 'Email';
      case CampaignType.push:
        return 'Push';
      case CampaignType.sms:
        return 'SMS';
      case CampaignType.whatsapp:
        return 'WhatsApp';
    }
  }
}

/// Estado de una campaña
enum CampaignStatus {
  draft,
  scheduled,
  active,
  paused,
  completed;

  static CampaignStatus fromString(String value) {
    return CampaignStatus.values.firstWhere(
      (status) => status.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CampaignStatus.draft,
    );
  }

  String get displayName {
    switch (this) {
      case CampaignStatus.draft:
        return 'Borrador';
      case CampaignStatus.scheduled:
        return 'Programada';
      case CampaignStatus.active:
        return 'Activa';
      case CampaignStatus.paused:
        return 'Pausada';
      case CampaignStatus.completed:
        return 'Completada';
    }
  }
}

/// Entidad que representa una campaña de marketing
class CampaignEntity extends Equatable {
  const CampaignEntity({
    required this.id,
    required this.propertyId,
    required this.name,
    required this.type,
    required this.status,
    required this.content,
    required this.createdAt,
    this.subject,
    this.targetAudience,
    this.scheduledAt,
    this.sentAt,
    this.sentCount,
    this.openRate,
    this.createdBy,
    this.updatedAt,
  });

  final String id;
  final String propertyId;
  final String name;
  final CampaignType type;
  final CampaignStatus status;
  final String content;
  final DateTime createdAt;

  final String? subject;
  final Map<String, dynamic>? targetAudience;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final int? sentCount;
  final double? openRate;
  final String? createdBy;
  final DateTime? updatedAt;

  // ============================================
  // GETTERS
  // ============================================

  /// Indica si la campaña es de email
  bool get isEmail => type == CampaignType.email;

  /// Indica si la campaña está programada
  bool get isScheduled => status == CampaignStatus.scheduled && scheduledAt != null;

  /// Indica si la campaña ha sido enviada
  bool get isSent => sentAt != null;

  /// Devuelve el tiempo restante hasta el envío programado
  String get scheduledIn {
    if (scheduledAt == null) return '';
    final diff = scheduledAt!.difference(DateTime.now());
    if (diff.isNegative) return 'Próximamente';
    if (diff.inDays > 0) return 'En ${diff.inDays}d';
    if (diff.inHours > 0) return 'En ${diff.inHours}h';
    return 'Próximamente';
  }

  /// Devuelve la tasa de apertura formateada
  String get openRateFormatted {
    if (openRate == null) return '0%';
    return '${openRate!.toInt()}%';
  }

  // ============================================
  // FACTORY METHODS
  // ============================================

  factory CampaignEntity.fromJson(Map<String, dynamic> json) {
    return CampaignEntity(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      name: json['name'] as String,
      type: CampaignType.fromString(json['type'] as String? ?? 'email'),
      status: CampaignStatus.fromString(json['status'] as String? ?? 'draft'),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      subject: json['subject'] as String?,
      targetAudience: json['target_audience'] as Map<String, dynamic>?,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : null,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
      sentCount: json['sent_count'] as int?,
      openRate: (json['open_rate'] as num?)?.toDouble(),
      createdBy: json['created_by'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // ============================================
  // METHODS
  // ============================================

  CampaignEntity copyWith({
    String? id,
    String? propertyId,
    String? name,
    CampaignType? type,
    CampaignStatus? status,
    String? content,
    DateTime? createdAt,
    String? subject,
    Map<String, dynamic>? targetAudience,
    DateTime? scheduledAt,
    DateTime? sentAt,
    int? sentCount,
    double? openRate,
    String? createdBy,
    DateTime? updatedAt,
  }) {
    return CampaignEntity(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      subject: subject ?? this.subject,
      targetAudience: targetAudience ?? this.targetAudience,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      sentCount: sentCount ?? this.sentCount,
      openRate: openRate ?? this.openRate,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'name': name,
      'type': type.name,
      'status': status.name,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'subject': subject,
      'target_audience': targetAudience,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'sent_count': sentCount,
      'open_rate': openRate,
      'created_by': createdBy,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'property_id': propertyId,
      'name': name,
      'type': type.name,
      'status': status.name,
      'content': content,
      'subject': subject,
      'target_audience': targetAudience ?? {},
      'scheduled_at': scheduledAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }

  @override
  List<Object?> get props => [
        id,
        propertyId,
        name,
        type,
        status,
        content,
        createdAt,
        subject,
        targetAudience,
        scheduledAt,
        sentAt,
        sentCount,
        openRate,
        createdBy,
        updatedAt,
      ];
}
