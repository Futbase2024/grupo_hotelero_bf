import 'package:equatable/equatable.dart';

/// Tipo de huésped
enum GuestType {
  adult,
  child,
}

/// Tipo de documento de identidad del huésped.
///
/// Es el tipo REAL del documento, no la cara fotografiada: las caras
/// (`dni_front`, `dni_back`, `passport`) son el `doc_kind` de `guest_documents`
/// y se obtienen con [frontDocKind] / [backDocKind].
enum DocumentType {
  dni,
  nie,
  passport,
  other,
}

/// Extensión para obtener el valor de la base de datos
extension DocumentTypeExtension on DocumentType {
  String get dbValue {
    switch (this) {
      case DocumentType.dni:
        return 'dni';
      case DocumentType.nie:
        return 'nie';
      case DocumentType.passport:
        return 'passport';
      case DocumentType.other:
        return 'other';
    }
  }

  /// Etiqueta para mostrar en la UI
  String get label {
    switch (this) {
      case DocumentType.dni:
        return 'DNI';
      case DocumentType.nie:
        return 'NIE';
      case DocumentType.passport:
        return 'Pasaporte';
      case DocumentType.other:
        return 'Otro';
    }
  }

  /// Si el documento necesita foto del reverso.
  /// El pasaporte se acredita con una sola foto (página de datos).
  bool get requiresBackSide {
    switch (this) {
      case DocumentType.dni:
      case DocumentType.nie:
      case DocumentType.other:
        return true;
      case DocumentType.passport:
        return false;
    }
  }

  /// `doc_kind` con el que se guarda la cara frontal en `guest_documents`
  String get frontDocKind {
    switch (this) {
      case DocumentType.dni:
      case DocumentType.nie:
        return 'dni_front';
      case DocumentType.passport:
        return 'passport';
      case DocumentType.other:
        return 'other';
    }
  }

  /// `doc_kind` con el que se guarda el reverso, o null si no lleva
  String? get backDocKind => requiresBackSide ? 'dni_back' : null;

  static DocumentType fromDbValue(String value) {
    switch (value.toLowerCase()) {
      // 'dni_front' y 'dni_back' son valores heredados de cuando el tipo y la
      // cara del documento se guardaban en el mismo campo.
      case 'dni':
      case 'dni_front':
      case 'dni_back':
        return DocumentType.dni;
      case 'nie':
        return DocumentType.nie;
      case 'passport':
        return DocumentType.passport;
      default:
        return DocumentType.other;
    }
  }
}

/// Entidad que representa un huésped en el check-in
class GuestEntity extends Equatable {
  const GuestEntity({
    this.id,
    required this.fullName,
    this.email,
    this.phone,
    required this.type,
    this.age,
    this.documentType,
    this.documentNumber,
    this.nationality,
    this.birthDate,
    this.isPrimary = false,
    this.isReadOnly = false,
    this.hasDocumentFront = false,
    this.hasDocumentBack = false,
  });

  /// ID del huésped en la base de datos (null si aún no se ha guardado)
  final String? id;

  /// Nombre completo del huésped
  final String fullName;

  /// Email (opcional, normalmente solo el titular lo tiene)
  final String? email;

  /// Teléfono (opcional)
  final String? phone;

  /// Tipo de huésped (adulto o niño)
  final GuestType type;

  /// Edad (solo para niños)
  final int? age;

  /// Tipo de documento de identidad
  final DocumentType? documentType;

  /// Número de documento
  final String? documentNumber;

  /// Nacionalidad
  final String? nationality;

  /// Fecha de nacimiento
  final DateTime? birthDate;

  /// Si es el huésped titular de la reserva
  final bool isPrimary;

  /// Si es de solo lectura (niños menores de 14 años)
  final bool isReadOnly;

  /// Si tiene subida la foto de la cara frontal del documento
  /// (anverso del DNI/NIE o página de datos del pasaporte)
  final bool hasDocumentFront;

  /// Si tiene subida la foto del reverso del documento
  final bool hasDocumentBack;

  /// Si tiene alguna foto del documento subida
  bool get hasDocumentImage => hasDocumentFront || hasDocumentBack;

  /// Si están subidas todas las caras que exige su tipo de documento
  bool get hasAllRequiredDocuments {
    if (!hasDocumentFront) return false;
    final requiresBack = documentType?.requiresBackSide ?? true;
    return !requiresBack || hasDocumentBack;
  }

  /// Niños menores de 14 años NO necesitan documento
  /// Los adultos y niños de 14+ años sí necesitan
  bool get needsDocument {
    if (type == GuestType.child && age != null && age! < 14) return false;
    return true;
  }

  /// Si es un niño menor de 14 años (no requiere datos)
  bool get isChildUnder14 => type == GuestType.child && age != null && age! < 14;

  /// Si es un niño de 14 o más años (requiere documento como adulto)
  bool get isChildOver14 => type == GuestType.child && age != null && age! >= 14;

  /// Si es adulto
  bool get isAdult => type == GuestType.adult;

  /// Si es niño
  bool get isChild => type == GuestType.child;

  /// Etiqueta descriptiva del tipo
  String get typeLabel {
    if (isChildUnder14) return 'Niño';
    if (isChildOver14) return 'Joven';
    return 'Adulto';
  }

  /// Copia con nuevos valores
  GuestEntity copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    GuestType? type,
    int? age,
    DocumentType? documentType,
    String? documentNumber,
    String? nationality,
    DateTime? birthDate,
    bool? isPrimary,
    bool? isReadOnly,
    bool? hasDocumentFront,
    bool? hasDocumentBack,
  }) {
    return GuestEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      age: age ?? this.age,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      nationality: nationality ?? this.nationality,
      birthDate: birthDate ?? this.birthDate,
      isPrimary: isPrimary ?? this.isPrimary,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      hasDocumentFront: hasDocumentFront ?? this.hasDocumentFront,
      hasDocumentBack: hasDocumentBack ?? this.hasDocumentBack,
    );
  }

  /// Crea desde JSON (respuesta de Supabase)
  factory GuestEntity.fromJson(Map<String, dynamic> json) {
    return GuestEntity(
      id: json['id'] as String?,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      type: json['type'] == 'child' ? GuestType.child : GuestType.adult,
      age: json['age'] as int?,
      documentType: json['document_type'] != null
          ? DocumentTypeExtension.fromDbValue(json['document_type'] as String)
          : null,
      documentNumber: json['document_number'] as String?,
      nationality: json['nationality'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      isPrimary: json['is_primary'] as bool? ?? false,
      isReadOnly: json['is_read_only'] as bool? ?? false,
      hasDocumentFront: json['has_document_front'] as bool? ?? false,
      hasDocumentBack: json['has_document_back'] as bool? ?? false,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'full_name': fullName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'type': type == GuestType.child ? 'child' : 'adult',
      if (age != null) 'age': age,
      if (documentType != null) 'document_type': documentType!.dbValue,
      if (documentNumber != null) 'document_number': documentNumber,
      if (nationality != null) 'nationality': nationality,
      if (birthDate != null) 'birth_date': birthDate!.toIso8601String().split('T').first,
      'is_primary': isPrimary,
      'is_read_only': isReadOnly,
      'has_document_front': hasDocumentFront,
      'has_document_back': hasDocumentBack,
    };
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        phone,
        type,
        age,
        documentType,
        documentNumber,
        nationality,
        birthDate,
        isPrimary,
        isReadOnly,
        hasDocumentFront,
        hasDocumentBack,
      ];
}
