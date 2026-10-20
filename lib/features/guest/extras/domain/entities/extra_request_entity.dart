import 'package:equatable/equatable.dart';

/// Estado de una solicitud de extra.
enum ExtraRequestStatus {
  /// Solicitado por el huésped, pendiente de gestión por el admin.
  requested,

  /// Gestionado por el admin (contactado / confirmado / preparado).
  managed,

  /// Cancelado.
  cancelled;

  String get dbValue => name;

  static ExtraRequestStatus fromDbValue(String? value) {
    switch (value) {
      case 'managed':
        return ExtraRequestStatus.managed;
      case 'cancelled':
        return ExtraRequestStatus.cancelled;
      case 'requested':
      default:
        return ExtraRequestStatus.requested;
    }
  }
}

/// Solicitud de un extra (p. ej. Pack Romántico) hecha por un huésped.
///
/// NO representa una reserva ni un pago confirmado: el pago se realiza en una
/// web externa y no podemos conocer su resultado. Es un aviso de interés que el
/// admin gestiona manualmente (seguimiento).
class ExtraRequestEntity extends Equatable {
  const ExtraRequestEntity({
    required this.id,
    required this.bookingId,
    this.propertyId,
    this.userId,
    this.guestName,
    this.unitName,
    required this.extraType,
    required this.extraName,
    this.price,
    this.status = ExtraRequestStatus.requested,
    this.notes,
    required this.createdAt,
    this.managedAt,
    this.managedBy,
  });

  final String id;
  final String bookingId;
  final String? propertyId;
  final String? userId;
  final String? guestName;
  final String? unitName;

  /// Tipo de extra, p. ej. `romantic_pack`.
  final String extraType;

  /// Nombre legible del extra, p. ej. `Pack Romántico Básico`.
  final String extraName;

  /// Precio informativo mostrado al huésped (puede ser null).
  final double? price;

  final ExtraRequestStatus status;

  /// Notas internas del admin.
  final String? notes;

  final DateTime createdAt;
  final DateTime? managedAt;
  final String? managedBy;

  bool get isRequested => status == ExtraRequestStatus.requested;
  bool get isManaged => status == ExtraRequestStatus.managed;
  bool get isCancelled => status == ExtraRequestStatus.cancelled;

  factory ExtraRequestEntity.fromJson(Map<String, dynamic> json) {
    return ExtraRequestEntity(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      propertyId: json['property_id'] as String?,
      userId: json['user_id'] as String?,
      guestName: json['guest_name'] as String?,
      unitName: json['unit_name'] as String?,
      extraType: json['extra_type'] as String,
      extraName: json['extra_name'] as String,
      price: (json['price'] as num?)?.toDouble(),
      status: ExtraRequestStatus.fromDbValue(json['status'] as String?),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      managedAt: json['managed_at'] != null
          ? DateTime.parse(json['managed_at'] as String)
          : null,
      managedBy: json['managed_by'] as String?,
    );
  }

  /// Payload para insertar una nueva solicitud (sin campos autogenerados).
  Map<String, dynamic> toInsertJson() {
    return {
      'booking_id': bookingId,
      'property_id': propertyId,
      'user_id': userId,
      'guest_name': guestName,
      'unit_name': unitName,
      'extra_type': extraType,
      'extra_name': extraName,
      'price': price,
      'status': status.dbValue,
    };
  }

  ExtraRequestEntity copyWith({
    ExtraRequestStatus? status,
    String? notes,
    DateTime? managedAt,
    String? managedBy,
  }) {
    return ExtraRequestEntity(
      id: id,
      bookingId: bookingId,
      propertyId: propertyId,
      userId: userId,
      guestName: guestName,
      unitName: unitName,
      extraType: extraType,
      extraName: extraName,
      price: price,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      managedAt: managedAt ?? this.managedAt,
      managedBy: managedBy ?? this.managedBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookingId,
        propertyId,
        userId,
        guestName,
        unitName,
        extraType,
        extraName,
        price,
        status,
        notes,
        createdAt,
        managedAt,
        managedBy,
      ];
}
