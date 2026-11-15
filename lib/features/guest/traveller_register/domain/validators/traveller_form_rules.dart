import '../entities/traveller_entity.dart';
import 'traveller_validators.dart';

/// Motivo por el que un campo no es válido
enum TravellerFieldError { required, invalid, responsibleNotAdult }

/// Campos del formulario (mismos nombres que usa el servidor en las incidencias)
abstract final class TravellerField {
  static const firstName = 'first_name';
  static const lastName1 = 'last_name_1';
  static const sex = 'sex';
  static const birthDate = 'birth_date';
  static const nationality = 'nationality';
  static const documentType = 'document_type';
  static const documentNumber = 'document_number';
  static const supportNumber = 'document_support_number';
  static const residenceAddress = 'residence_address';
  static const residenceCity = 'residence_city';
  static const residenceCountry = 'residence_country';
  static const contact = 'contact';
  static const mobile = 'mobile';
  static const landline = 'landline_phone';
  static const email = 'email';
  static const responsible = 'responsible_guest_id';
  static const relationship = 'relationship';
}

/// Reglas de cada pantalla del formulario.
///
/// Reflejan las obligatoriedades de `_traveller_guest_issues` en el servidor
/// (Anexo I del RD 933/2021, pendientes de validar con asesoría): el
/// servidor es quien decide, esto solo evita que el huésped avance con
/// errores evidentes.
abstract final class TravellerFormRules {
  static const int adultAge = 18;
  static const int ownSignatureAge = 14;

  /// Pantalla 1: identificación
  static Map<String, TravellerFieldError> identification(
    TravellerEntity t,
    DateTime checkinDate,
  ) {
    final errors = <String, TravellerFieldError>{};
    final age = t.ageOn(checkinDate);
    final isAdult = age != null && age >= adultAge;

    if (t.firstName.trim().isEmpty) {
      errors[TravellerField.firstName] = TravellerFieldError.required;
    }
    if (t.lastName1.trim().isEmpty) {
      errors[TravellerField.lastName1] = TravellerFieldError.required;
    }
    if (t.sex == null) errors[TravellerField.sex] = TravellerFieldError.required;
    if (t.nationality == null) {
      errors[TravellerField.nationality] = TravellerFieldError.required;
    }

    final birth = t.birthDate;
    if (birth == null) {
      errors[TravellerField.birthDate] = TravellerFieldError.required;
    } else if (birth.isAfter(checkinDate) || (age ?? 0) > 120) {
      errors[TravellerField.birthDate] = TravellerFieldError.invalid;
    }

    final type = t.documentType;
    final number = t.documentNumber.trim();
    if (type == null) {
      if (isAdult) {
        errors[TravellerField.documentType] = TravellerFieldError.required;
      }
    }
    if (number.isEmpty) {
      if (isAdult) {
        errors[TravellerField.documentNumber] = TravellerFieldError.required;
      }
    } else if (!_isValidNumber(type, number)) {
      errors[TravellerField.documentNumber] = TravellerFieldError.invalid;
    }

    if (type != null && type.hasSupportNumber) {
      final support = t.supportNumber.trim();
      if (support.isEmpty) {
        if (isAdult && number.isNotEmpty) {
          errors[TravellerField.supportNumber] = TravellerFieldError.required;
        }
      } else if (!TravellerValidators.isValidSupportNumber(support)) {
        errors[TravellerField.supportNumber] = TravellerFieldError.invalid;
      }
    }

    return errors;
  }

  /// Pantalla 2: residencia y contacto. [all] es la lista de huéspedes de la
  /// reserva (para comprobar el adulto responsable de un menor).
  static Map<String, TravellerFieldError> residenceAndContact(
    TravellerEntity t,
    DateTime checkinDate,
    List<TravellerEntity> all,
  ) {
    final errors = <String, TravellerFieldError>{};
    final age = t.ageOn(checkinDate);

    final email = t.email.trim();
    if (email.isNotEmpty && !TravellerValidators.isValidEmail(email)) {
      errors[TravellerField.email] = TravellerFieldError.invalid;
    }
    if (t.mobile.trim().isNotEmpty && !TravellerValidators.isValidPhone(t.mobile)) {
      errors[TravellerField.mobile] = TravellerFieldError.invalid;
    }
    if (t.landline.trim().isNotEmpty &&
        !TravellerValidators.isValidPhone(t.landline)) {
      errors[TravellerField.landline] = TravellerFieldError.invalid;
    }

    if (age == null) return errors;

    if (age >= adultAge) {
      if (t.residenceAddress.trim().isEmpty) {
        errors[TravellerField.residenceAddress] = TravellerFieldError.required;
      }
      if (t.residenceCity.trim().isEmpty) {
        errors[TravellerField.residenceCity] = TravellerFieldError.required;
      }
      if (t.residenceCountry == null) {
        errors[TravellerField.residenceCountry] = TravellerFieldError.required;
      }
      if (t.mobile.trim().isEmpty && t.landline.trim().isEmpty && email.isEmpty) {
        errors[TravellerField.contact] = TravellerFieldError.required;
      }
      return errors;
    }

    // Menor: adulto responsable de la reserva y parentesco. El domicilio se
    // hereda del responsable si no se indica.
    final responsible = _findById(all, t.responsibleGuestId);
    if (responsible == null) {
      errors[TravellerField.responsible] = TravellerFieldError.required;
      if (t.residenceCountry == null) {
        errors[TravellerField.residenceCountry] = TravellerFieldError.required;
      }
    } else {
      final responsibleAge = responsible.ageOn(checkinDate);
      if (responsibleAge == null || responsibleAge < adultAge) {
        errors[TravellerField.responsible] = TravellerFieldError.responsibleNotAdult;
      }
    }
    if (t.relationship == null) {
      errors[TravellerField.relationship] = TravellerFieldError.required;
    }
    return errors;
  }

  /// Adultos guardados que pueden ser responsables de un menor
  static List<TravellerEntity> possibleResponsibles(
    List<TravellerEntity> all,
    DateTime checkinDate,
  ) {
    return all.where((t) {
      final age = t.ageOn(checkinDate);
      return t.id != null && age != null && age >= adultAge;
    }).toList();
  }

  static bool _isValidNumber(TravellerDocumentType? type, String number) {
    switch (type) {
      case TravellerDocumentType.dni:
        return TravellerValidators.isValidDni(number);
      case TravellerDocumentType.nie:
        return TravellerValidators.isValidNie(number);
      case TravellerDocumentType.passport:
      case TravellerDocumentType.other:
      case null:
        return TravellerValidators.isValidForeignDocument(number);
    }
  }

  static TravellerEntity? _findById(List<TravellerEntity> all, String? id) {
    if (id == null) return null;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }
}
