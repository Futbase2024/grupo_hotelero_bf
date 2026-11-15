import 'package:equatable/equatable.dart';

/// Motivo por el que se borran (o se borraron) las imágenes de una reserva.
///
/// Refleja `guest_documents.deleted_reason` y el `scheduled_reason` de
/// `get_booking_documents_status`.
enum DocumentDeletionReason {
  validated24h('validated_24h'),
  bookingCancelled('booking_cancelled'),
  checkoutNotValidated('checkout_not_validated'),
  manual('manual');

  const DocumentDeletionReason(this.value);

  final String value;

  static DocumentDeletionReason? fromValue(String? value) {
    for (final reason in values) {
      if (reason.value == value) return reason;
    }
    return null;
  }
}

/// Estado de privacidad de los documentos de identidad de una reserva:
/// cuántos quedan, cuándo se borrarán y si el staff los ha retenido.
class BookingDocumentsStatusEntity extends Equatable {
  const BookingDocumentsStatusEntity({
    required this.bookingId,
    required this.activeCount,
    required this.deletedCount,
    this.lastDeletedAt,
    this.scheduledAt,
    this.scheduledReason,
    this.isRetained = false,
    this.retainedReason,
    this.retainedAt,
    this.retainedByName,
  });

  final String bookingId;

  /// Documentos cuya imagen sigue en el bucket
  final int activeCount;

  /// Documentos cuya imagen ya se borró (la fila queda como constancia)
  final int deletedCount;
  final DateTime? lastDeletedAt;

  /// Cuándo se borrarán automáticamente (`null` si están retenidos)
  final DateTime? scheduledAt;
  final DocumentDeletionReason? scheduledReason;

  final bool isRetained;
  final String? retainedReason;
  final DateTime? retainedAt;

  /// Nombre de quien activó la retención, en mayúsculas
  final String? retainedByName;

  bool get hasActiveDocuments => activeCount > 0;

  factory BookingDocumentsStatusEntity.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String key) {
      final value = json[key] as String?;
      return value != null ? DateTime.parse(value).toLocal() : null;
    }

    return BookingDocumentsStatusEntity(
      bookingId: json['booking_id'] as String? ?? '',
      activeCount: (json['active_count'] as num?)?.toInt() ?? 0,
      deletedCount: (json['deleted_count'] as num?)?.toInt() ?? 0,
      lastDeletedAt: parseDate('last_deleted_at'),
      scheduledAt: parseDate('scheduled_at'),
      scheduledReason: DocumentDeletionReason.fromValue(json['scheduled_reason'] as String?),
      isRetained: json['is_retained'] as bool? ?? false,
      retainedReason: json['retained_reason'] as String?,
      retainedAt: parseDate('retained_at'),
      retainedByName: json['retained_by_name'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        activeCount,
        deletedCount,
        lastDeletedAt,
        scheduledAt,
        scheduledReason,
        isRetained,
        retainedReason,
        retainedAt,
        retainedByName,
      ];
}
