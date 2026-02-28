import 'package:equatable/equatable.dart';

/// Tipo de huésped
enum GuestType {
  adult,
  child,
}

/// Tipo de documento de identidad
/// Nota: DNI tiene dos lados (front y back), NIE se trata como DNI
enum DocumentType {
  dniFront,
  dniBack,
  passport,
  other,
}

/// Extensión para obtener el valor de la base de datos
extension DocumentTypeExtension on DocumentType {
  String get dbValue {
    switch (this) {
      case DocumentType.dniFront:
        return 'dni_front';
      case DocumentType.dniBack:
        return 'dni_back';
      case DocumentType.passport:
        return 'passport';
      case DocumentType.other:
        return 'other';
    }
  }

  /// Etiqueta para mostrar en la UI
  String get label {
    switch (this) {
      case DocumentType.dniFront:
        return 'DNI (anverso)';
      case DocumentType.dniBack:
        return 'DNI (reverso)';
      case DocumentType.passport:
        return 'Pasaporte';
      case DocumentType.other:
        return 'Otro';
    }
  }

  static DocumentType fromDbValue(String value) {
    switch (value.toLowerCase()) {
      case 'dni_front':
      case 'dni':
        return DocumentType.dniFront;
      case 'dni_back':
        return DocumentType.dniBack;
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
    this.hasDocumentImage = false,
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

  /// Si tiene la foto del documento subida
  final bool hasDocumentImage;

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
    bool? hasDocumentImage,
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
      hasDocumentImage: hasDocumentImage ?? this.hasDocumentImage,
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
      hasDocumentImage: json['has_document_image'] as bool? ?? false,
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
      'has_document_image': hasDocumentImage,
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
        hasDocumentImage,
      ];
}
