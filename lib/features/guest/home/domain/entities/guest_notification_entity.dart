import 'package:equatable/equatable.dart';

/// Entity para notificaciones del huésped
class GuestNotificationEntity extends Equatable {
  const GuestNotificationEntity({
    required this.id,
    required this.userId,
    this.bookingId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? bookingId;
  final String type; // checkin_validated, checkin_rejected, etc.
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  /// Si es una notificación de check-in validado
  bool get isCheckinValidated => type == 'checkin_validated';

  /// Si es una notificación de check-in rechazado
  bool get isCheckinRejected => type == 'checkin_rejected';

  /// Si es una notificación de reserva cancelada
  bool get isBookingCancelled => type == 'booking_cancelled';

  /// Convierte desde un mapa JSON
  factory GuestNotificationEntity.fromJson(Map<String, dynamic> json) {
    return GuestNotificationEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookingId: json['booking_id'] as String?,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convierte a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'booking_id': bookingId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Crea una copia con el estado de lectura actualizado
  GuestNotificationEntity copyWith({bool? isRead}) {
    return GuestNotificationEntity(
      id: id,
      userId: userId,
      bookingId: bookingId,
      type: type,
      title: title,
      body: body,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        bookingId,
        type,
        title,
        body,
        data,
        isRead,
        createdAt,
      ];
}
