import 'package:equatable/equatable.dart';

import '../validators/traveller_validators.dart';

/// Versión del texto del parte de entrada que se firma.
/// Si cambia el texto legal del parte, se sube la versión (rd933-v2…).
const String kTravellerEntryFormVersion = 'rd933-v1';

/// Tipo de documento de identidad del registro de viajeros
enum TravellerDocumentType {
  dni('dni'),
  nie('nie'),
  passport('passport'),
  other('other');

  const TravellerDocumentType(this.dbValue);

  final String dbValue;

  /// DNI y NIE/TIE llevan número de soporte (IDESP / IXESP); el resto no
  bool get hasSupportNumber =>
      this == TravellerDocumentType.dni || this == TravellerDocumentType.nie;

  /// DNI y NIE tienen letra de control española
  bool get isSpanishId => hasSupportNumber;

  static TravellerDocumentType? fromDb(String? value) {
    switch (value?.toLowerCase()) {
      // Valores heredados del flujo de fotos
      case 'dni':
      case 'dni_front':
      case 'dni_back':
        return TravellerDocumentType.dni;
      case 'nie':
        return TravellerDocumentType.nie;
      case 'passport':
        return TravellerDocumentType.passport;
      case 'other':
        return TravellerDocumentType.other;
      default:
        return null;
    }
  }
}

/// Sexo tal como lo guarda `guests.sex`
enum TravellerSex {
  male('M'),
  female('F'),
  other('other');

  const TravellerSex(this.dbValue);

  final String dbValue;

  static TravellerSex? fromDb(String? value) {
    for (final sex in TravellerSex.values) {
      if (sex.dbValue == value) return sex;
    }
    return null;
  }
}

/// Parentesco del menor con su adulto responsable (códigos internos; el
/// mapeo a los códigos oficiales de SES se hará cuando haya XSD)
enum TravellerRelationship {
  parent('parent'),
  grandparent('grandparent'),
  sibling('sibling'),
  uncleAunt('uncle_aunt'),
  cousin('cousin'),
  legalGuardian('legal_guardian'),
  other('other');

  const TravellerRelationship(this.dbValue);

  final String dbValue;

  static TravellerRelationship? fromDb(String? value) {
    for (final relationship in TravellerRelationship.values) {
      if (relationship.dbValue == value) return relationship;
    }
    return null;
  }
}

/// Huésped del registro de viajeros (RD 933/2021).
///
/// Es independiente de `GuestEntity` (flujo de fotos) para no tocar el
/// check-in actual; ambos leen la misma fila de `guests`.
class TravellerEntity extends Equatable {
  const TravellerEntity({
    this.id,
    this.firstName = '',
    this.lastName1 = '',
    this.lastName2 = '',
    this.sex,
    this.birthDate,
    this.nationality,
    this.documentType,
    this.documentNumber = '',
    this.supportNumber = '',
    this.residenceAddress = '',
    this.residenceCity = '',
    this.residencePostalCode = '',
    this.residenceCountry,
    this.mobile = '',
    this.landline = '',
    this.email = '',
    this.isPrimary = false,
    this.responsibleGuestId,
    this.relationship,
    this.isLegacy = false,
  });

  /// `guests.id` (null hasta que se guarda por primera vez)
  final String? id;
  final String firstName;
  final String lastName1;
  final String lastName2;
  final TravellerSex? sex;
  final DateTime? birthDate;

  /// ISO 3166-1 alfa-3
  final String? nationality;
  final TravellerDocumentType? documentType;
  final String documentNumber;
  final String supportNumber;
  final String residenceAddress;
  final String residenceCity;
  final String residencePostalCode;

  /// ISO 3166-1 alfa-3
  final String? residenceCountry;
  final String mobile;
  final String landline;
  final String email;
  final bool isPrimary;

  /// Adulto de la misma reserva responsable del menor
  final String? responsibleGuestId;
  final TravellerRelationship? relationship;

  /// Registro creado con el flujo de fotos (`register_format = 'legacy'`):
  /// los apellidos no están separados y faltan datos legales.
  final bool isLegacy;

  String get fullName => [firstName, lastName1, lastName2]
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .join(' ');

  /// Edad el día de entrada (la que determina las obligaciones legales)
  int? ageOn(DateTime checkinDate) =>
      TravellerValidators.ageOn(birthDate, checkinDate);

  bool isMinorOn(DateTime checkinDate) {
    final age = ageOn(checkinDate);
    return age != null && age < 18;
  }

  /// Los mayores de 14 firman su propio parte; los menores de 14 van en el
  /// parte de su adulto responsable
  bool needsOwnSignatureOn(DateTime checkinDate) {
    final age = ageOn(checkinDate);
    return age != null && age >= 14;
  }

  /// Datos para la RPC `save_traveller_guest`. El servidor normaliza
  /// (mayúsculas, sin espacios en el documento…) y vuelve a validar.
  Map<String, dynamic> toRpcData() {
    String? nonEmpty(String value) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    final birth = birthDate;
    return {
      'first_name': nonEmpty(firstName),
      'last_name_1': nonEmpty(lastName1),
      'last_name_2': nonEmpty(lastName2),
      'sex': sex?.dbValue,
      'birth_date': birth == null
          ? null
          : '${birth.year.toString().padLeft(4, '0')}-'
              '${birth.month.toString().padLeft(2, '0')}-'
              '${birth.day.toString().padLeft(2, '0')}',
      'nationality': nationality,
      'document_type': documentType?.dbValue,
      'document_number': nonEmpty(documentNumber),
      'document_support_number': (documentType?.hasSupportNumber ?? false)
          ? nonEmpty(supportNumber)
          : null,
      'residence_address': nonEmpty(residenceAddress),
      'residence_city': nonEmpty(residenceCity),
      'residence_postal_code': nonEmpty(residencePostalCode),
      'residence_country': residenceCountry,
      'mobile': nonEmpty(mobile),
      'landline_phone': nonEmpty(landline),
      'email': nonEmpty(email),
      'is_primary': isPrimary,
      'responsible_guest_id': responsibleGuestId,
      'relationship': relationship?.dbValue,
    };
  }

  /// Fila de `booking_guests` con el huésped embebido en `guests`
  factory TravellerEntity.fromBookingGuestJson(Map<String, dynamic> json) {
    final guest = (json['guests'] as Map<String, dynamic>?) ?? const {};
    final isLegacy = (guest['register_format'] as String? ?? 'legacy') == 'legacy';
    final birth = guest['birth_date'] as String?;

    // En los registros antiguos el nombre completo va en un solo campo: se
    // propone en "Nombre" y el huésped separa él mismo los apellidos.
    final firstName = isLegacy
        ? (guest['full_name'] as String? ?? '')
        : (guest['first_name'] as String? ?? '');

    return TravellerEntity(
      id: (guest['id'] ?? json['guest_id']) as String?,
      firstName: firstName,
      lastName1: isLegacy ? '' : guest['last_name_1'] as String? ?? '',
      lastName2: isLegacy ? '' : guest['last_name_2'] as String? ?? '',
      sex: TravellerSex.fromDb(guest['sex'] as String?),
      birthDate: birth == null ? null : DateTime.tryParse(birth),
      nationality: guest['nationality'] as String?,
      documentType: TravellerDocumentType.fromDb(guest['document_type'] as String?),
      documentNumber: guest['document_number'] as String? ?? '',
      supportNumber: guest['document_support_number'] as String? ?? '',
      residenceAddress: guest['residence_address'] as String? ?? '',
      residenceCity: guest['residence_city'] as String? ?? '',
      residencePostalCode: guest['residence_postal_code'] as String? ?? '',
      residenceCountry: guest['residence_country'] as String?,
      mobile: guest['phone'] as String? ?? '',
      landline: guest['landline_phone'] as String? ?? '',
      email: guest['email'] as String? ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
      responsibleGuestId: json['responsible_guest_id'] as String?,
      relationship: TravellerRelationship.fromDb(json['relationship'] as String?),
      isLegacy: isLegacy,
    );
  }

  TravellerEntity copyWith({
    String? id,
    String? firstName,
    String? lastName1,
    String? lastName2,
    TravellerSex? sex,
    DateTime? birthDate,
    String? nationality,
    TravellerDocumentType? documentType,
    String? documentNumber,
    String? supportNumber,
    String? residenceAddress,
    String? residenceCity,
    String? residencePostalCode,
    String? residenceCountry,
    String? mobile,
    String? landline,
    String? email,
    bool? isPrimary,
    String? responsibleGuestId,
    TravellerRelationship? relationship,
    bool clearResponsible = false,
    bool? isLegacy,
  }) {
    return TravellerEntity(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName1: lastName1 ?? this.lastName1,
      lastName2: lastName2 ?? this.lastName2,
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      nationality: nationality ?? this.nationality,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      supportNumber: supportNumber ?? this.supportNumber,
      residenceAddress: residenceAddress ?? this.residenceAddress,
      residenceCity: residenceCity ?? this.residenceCity,
      residencePostalCode: residencePostalCode ?? this.residencePostalCode,
      residenceCountry: residenceCountry ?? this.residenceCountry,
      mobile: mobile ?? this.mobile,
      landline: landline ?? this.landline,
      email: email ?? this.email,
      isPrimary: isPrimary ?? this.isPrimary,
      responsibleGuestId:
          clearResponsible ? null : responsibleGuestId ?? this.responsibleGuestId,
      relationship: clearResponsible ? null : relationship ?? this.relationship,
      isLegacy: isLegacy ?? this.isLegacy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName1,
        lastName2,
        sex,
        birthDate,
        nationality,
        documentType,
        documentNumber,
        supportNumber,
        residenceAddress,
        residenceCity,
        residencePostalCode,
        residenceCountry,
        mobile,
        landline,
        email,
        isPrimary,
        responsibleGuestId,
        relationship,
        isLegacy,
      ];
}
