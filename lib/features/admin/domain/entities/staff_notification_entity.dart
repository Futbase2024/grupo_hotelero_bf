import 'package:equatable/equatable.dart';

/// Entity para notificaciones del staff en tiempo real
class StaffNotificationEntity extends Equatable {
  const StaffNotificationEntity({
    required this.id,
    required this.propertyId,
    required this.type,
    required this.title,
    required this.body,
    required this.bookingId,
    this.data,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String propertyId;
  final String type; // checkin_completed, checkin_rejected, etc.
  final String title;
  final String body;
  final String bookingId;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime createdAt;

  /// Si es una notificación de check-in completado
  bool get isCheckinCompleted => type == 'checkin_completed';

  /// Si es una notificación de check-in rechazado
  bool get isCheckinRejected => type == 'checkin_rejected';

  /// Convierte desde un mapa JSON
  factory StaffNotificationEntity.fromJson(Map<String, dynamic> json) {
    return StaffNotificationEntity(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      bookingId: json['booking_id'] as String,
      data: json['data'] as Map<String, dynamic>?,
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convierte a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'type': type,
      'title': title,
      'body': body,
      'booking_id': bookingId,
      'data': data,
      'read': read,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Crea una copia con el estado de lectura actualizado
  StaffNotificationEntity copyWith({bool? read}) {
    return StaffNotificationEntity(
      id: id,
      propertyId: propertyId,
      type: type,
      title: title,
      body: body,
      bookingId: bookingId,
      data: data,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        propertyId,
        type,
        title,
        body,
        bookingId,
        data,
        read,
        createdAt,
      ];
}
