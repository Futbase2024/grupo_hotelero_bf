import 'package:equatable/equatable.dart';

/// Entidad para un huésped dentro del detalle del check-in
class CheckinGuestEntity extends Equatable {
  const CheckinGuestEntity({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.documentType,
    this.documentNumber,
    this.nationality,
    this.birthDate,
    this.type,
    this.age,
    required this.isPrimary,
  });

  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? documentType;
  final String? documentNumber;
  final String? nationality;
  final DateTime? birthDate;
  final String? type;
  final int? age;
  final bool isPrimary;

  factory CheckinGuestEntity.fromJson(Map<String, dynamic> json) {
    return CheckinGuestEntity(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      documentType: json['document_type'] as String?,
      documentNumber: json['document_number'] as String?,
      nationality: json['nationality'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      type: json['type'] as String?,
      age: json['age'] as int?,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'document_type': documentType,
      'document_number': documentNumber,
      'nationality': nationality,
      'birth_date': birthDate?.toIso8601String(),
      'type': type,
      'age': age,
      'is_primary': isPrimary,
    };
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        phone,
        documentType,
        documentNumber,
        nationality,
        birthDate,
        type,
        age,
        isPrimary,
      ];
}

/// Entidad para un documento dentro del detalle del check-in
class CheckinDocumentEntity extends Equatable {
  const CheckinDocumentEntity({
    required this.id,
    this.guestId,
    required this.docKind,
    required this.storagePath,
    this.mimeType,
    this.createdAt,
  });

  final String id;
  final String? guestId;
  final String docKind;
  final String storagePath;
  final String? mimeType;
  final DateTime? createdAt;

  factory CheckinDocumentEntity.fromJson(Map<String, dynamic> json) {
    return CheckinDocumentEntity(
      id: json['id'] as String? ?? '',
      guestId: json['guest_id'] as String?,
      docKind: json['doc_kind'] as String? ?? '',
      storagePath: json['storage_path'] as String? ?? '',
      mimeType: json['mime_type'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guest_id': guestId,
      'doc_kind': docKind,
      'storage_path': storagePath,
      'mime_type': mimeType,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Nombre legible del tipo de documento
  String get docKindLabel {
    switch (docKind) {
      case 'dni_front':
        return 'DNI (anverso)';
      case 'dni_back':
        return 'DNI (reverso)';
      case 'passport':
        return 'Pasaporte';
      case 'other':
        return 'Otro';
      default:
        return docKind;
    }
  }

  @override
  List<Object?> get props => [
        id,
        guestId,
        docKind,
        storagePath,
        mimeType,
        createdAt,
      ];
}

/// Entidad para el detalle completo de un check-in
class CheckinDetailEntity extends Equatable {
  const CheckinDetailEntity({
    required this.checkinId,
    required this.checkinStatus,
    this.signatureSvg,
    this.submittedAt,
    this.validatedAt,
    this.rejectedAt,
    this.rejectionReason,
    required this.bookingId,
    required this.bookingCode,
    required this.unitName,
    required this.propertyName,
    required this.checkinDate,
    required this.checkoutDate,
    required this.guests,
    required this.documents,
  });

  final String checkinId;
  final String checkinStatus;
  final String? signatureSvg;
  final DateTime? submittedAt;
  final DateTime? validatedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final String bookingId;
  final String bookingCode;
  final String unitName;
  final String propertyName;
  final DateTime checkinDate;
  final DateTime checkoutDate;
  final List<CheckinGuestEntity> guests;
  final List<CheckinDocumentEntity> documents;

  /// Si el check-in está pendiente de validación
  bool get isPending => checkinStatus == 'submitted';

  /// Si el check-in está validado
  bool get isValidated => checkinStatus == 'validated';

  /// Si el check-in está rechazado
  bool get isRejected => checkinStatus == 'rejected';

  /// Huésped titular
  CheckinGuestEntity? get primaryGuest {
    try {
      return guests.firstWhere((g) => g.isPrimary);
    } catch (_) {
      return null;
    }
  }

  /// Documentos de un huésped específico
  List<CheckinDocumentEntity> documentsForGuest(String guestId) {
    return documents.where((d) => d.guestId == guestId).toList();
  }

  factory CheckinDetailEntity.fromJson(Map<String, dynamic> json) {
    // Parsear huéspedes
    final guestData = json['guest_data'] as List<dynamic>? ?? [];
    final guests = guestData
        .map((g) => CheckinGuestEntity.fromJson(g as Map<String, dynamic>))
        .toList();

    // Parsear documentos
    final documentsData = json['documents_data'] as List<dynamic>? ?? [];
    final documents = documentsData
        .map((d) => CheckinDocumentEntity.fromJson(d as Map<String, dynamic>))
        .toList();

    return CheckinDetailEntity(
      checkinId: json['checkin_id'] as String? ?? '',
      checkinStatus: json['checkin_status'] as String? ?? '',
      signatureSvg: json['signature_svg'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      validatedAt: json['validated_at'] != null
          ? DateTime.parse(json['validated_at'] as String)
          : null,
      rejectedAt: json['rejected_at'] != null
          ? DateTime.parse(json['rejected_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      bookingId: json['booking_id'] as String? ?? '',
      bookingCode: json['booking_code'] as String? ?? '',
      unitName: json['unit_name'] as String? ?? '',
      propertyName: json['property_name'] as String? ?? '',
      checkinDate: json['checkin_date'] != null
          ? DateTime.parse(json['checkin_date'] as String)
          : DateTime.now(),
      checkoutDate: json['checkout_date'] != null
          ? DateTime.parse(json['checkout_date'] as String)
          : DateTime.now(),
      guests: guests,
      documents: documents,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'checkin_id': checkinId,
      'checkin_status': checkinStatus,
      'signature_svg': signatureSvg,
      'submitted_at': submittedAt?.toIso8601String(),
      'validated_at': validatedAt?.toIso8601String(),
      'rejected_at': rejectedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'booking_id': bookingId,
      'booking_code': bookingCode,
      'unit_name': unitName,
      'property_name': propertyName,
      'checkin_date': checkinDate.toIso8601String(),
      'checkout_date': checkoutDate.toIso8601String(),
      'guest_data': guests.map((g) => g.toJson()).toList(),
      'documents_data': documents.map((d) => d.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        checkinId,
        checkinStatus,
        signatureSvg,
        submittedAt,
        validatedAt,
        rejectedAt,
        rejectionReason,
        bookingId,
        bookingCode,
        unitName,
        propertyName,
        checkinDate,
        checkoutDate,
        guests,
        documents,
      ];
}
