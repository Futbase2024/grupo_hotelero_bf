import 'package:equatable/equatable.dart';

/// Entity para reservas con datos completos para el panel de administración
class AdminBookingEntity extends Equatable {
  const AdminBookingEntity({
    required this.id,
    required this.bookingCode,
    required this.unitId,
    required this.unitName,
    required this.propertyId,
    required this.propertyName,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numGuests,
    required this.status,
    required this.guestEmail,
    this.guestFirstName,
    this.guestLastName,
    this.guestPhone,
    this.staffNotes,
    this.codeFirstUsedAt,
    this.codeSentAt,
    this.checkinId,
    this.checkinStatus,
    this.docsPending,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String bookingCode;
  final String unitId;
  final String unitName;
  final String propertyId;
  final String propertyName;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int numGuests;
  final String status; // confirmed, checked_in, checked_out, cancelled
  final String guestEmail;
  final String? guestFirstName;
  final String? guestLastName;
  final String? guestPhone;
  final String? staffNotes;
  final DateTime? codeFirstUsedAt;
  final DateTime? codeSentAt;
  final String? checkinId;
  final String? checkinStatus; // draft, submitted, validated, rejected
  final int? docsPending;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Nombre completo del huésped
  String get guestFullName {
    if (guestFirstName == null && guestLastName == null) return '';
    return '${guestFirstName ?? ''} ${guestLastName ?? ''}'.trim();
  }

  /// Si el código ha sido usado
  bool get isCodeUsed => codeFirstUsedAt != null;

  /// Si el código ha sido enviado por email
  bool get isCodeSent => codeSentAt != null;

  /// Si tiene check-in iniciado
  bool get hasCheckin => checkinId != null;

  /// Si el check-in está pendiente de revisión
  bool get isCheckinPending => checkinStatus == 'submitted';

  /// Si hay documentos pendientes
  bool get hasDocsPending => (docsPending ?? 0) > 0;

  /// Convierte desde un mapa JSON (respuesta de Supabase/Edge Function)
  factory AdminBookingEntity.fromJson(Map<String, dynamic> json) {
    return AdminBookingEntity(
      id: json['id'] as String,
      bookingCode: json['booking_code'] as String,
      unitId: json['unit_id'] as String,
      unitName: json['unit_name'] as String? ?? '',
      propertyId: json['property_id'] as String,
      propertyName: json['property_name'] as String? ?? '',
      checkInDate: DateTime.parse(json['check_in_date'] as String),
      checkOutDate: DateTime.parse(json['check_out_date'] as String),
      numGuests: json['num_guests'] as int? ?? 1,
      status: json['status'] as String? ?? 'confirmed',
      guestEmail: json['guest_email'] as String? ?? '',
      guestFirstName: json['guest_first_name'] as String?,
      guestLastName: json['guest_last_name'] as String?,
      guestPhone: json['guest_phone'] as String?,
      staffNotes: json['staff_notes'] as String?,
      codeFirstUsedAt: json['code_first_used_at'] != null
          ? DateTime.parse(json['code_first_used_at'] as String)
          : null,
      codeSentAt: json['code_sent_at'] != null
          ? DateTime.parse(json['code_sent_at'] as String)
          : null,
      checkinId: json['checkin_id'] as String?,
      checkinStatus: json['checkin_status'] as String?,
      docsPending: json['docs_pending'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convierte a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_code': bookingCode,
      'unit_id': unitId,
      'unit_name': unitName,
      'property_id': propertyId,
      'property_name': propertyName,
      'check_in_date': checkInDate.toIso8601String(),
      'check_out_date': checkOutDate.toIso8601String(),
      'num_guests': numGuests,
      'status': status,
      'guest_email': guestEmail,
      'guest_first_name': guestFirstName,
      'guest_last_name': guestLastName,
      'guest_phone': guestPhone,
      'staff_notes': staffNotes,
      'code_first_used_at': codeFirstUsedAt?.toIso8601String(),
      'code_sent_at': codeSentAt?.toIso8601String(),
      'checkin_id': checkinId,
      'checkin_status': checkinStatus,
      'docs_pending': docsPending,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        bookingCode,
        unitId,
        unitName,
        propertyId,
        propertyName,
        checkInDate,
        checkOutDate,
        numGuests,
        status,
        guestEmail,
        guestFirstName,
        guestLastName,
        guestPhone,
        staffNotes,
        codeFirstUsedAt,
        codeSentAt,
        checkinId,
        checkinStatus,
        docsPending,
        createdAt,
        updatedAt,
      ];
}
