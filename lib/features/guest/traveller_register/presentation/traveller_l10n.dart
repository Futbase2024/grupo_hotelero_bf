import '../../../../l10n/app_localizations.dart';
import '../domain/entities/traveller_entity.dart';
import '../domain/validators/traveller_form_rules.dart';

/// Textos traducidos de los valores del registro de viajeros
extension TravellerL10n on S {
  String documentTypeLabel(TravellerDocumentType type) {
    switch (type) {
      case TravellerDocumentType.dni:
        return guest_traveller_doc_dni;
      case TravellerDocumentType.nie:
        return guest_traveller_doc_nie;
      case TravellerDocumentType.passport:
        return guest_traveller_doc_passport;
      case TravellerDocumentType.other:
        return guest_traveller_doc_other;
    }
  }

  String sexLabel(TravellerSex sex) {
    switch (sex) {
      case TravellerSex.male:
        return guest_traveller_sex_male;
      case TravellerSex.female:
        return guest_traveller_sex_female;
      case TravellerSex.other:
        return guest_traveller_sex_other;
    }
  }

  String relationshipLabel(TravellerRelationship relationship) {
    switch (relationship) {
      case TravellerRelationship.parent:
        return guest_traveller_rel_parent;
      case TravellerRelationship.grandparent:
        return guest_traveller_rel_grandparent;
      case TravellerRelationship.sibling:
        return guest_traveller_rel_sibling;
      case TravellerRelationship.uncleAunt:
        return guest_traveller_rel_uncle_aunt;
      case TravellerRelationship.cousin:
        return guest_traveller_rel_cousin;
      case TravellerRelationship.legalGuardian:
        return guest_traveller_rel_legal_guardian;
      case TravellerRelationship.other:
        return guest_traveller_rel_other;
    }
  }

  String? fieldErrorText(TravellerFieldError? error) {
    switch (error) {
      case TravellerFieldError.required:
        return guest_traveller_error_required;
      case TravellerFieldError.invalid:
        return guest_traveller_error_invalid;
      case TravellerFieldError.responsibleNotAdult:
        return guest_traveller_error_responsible_not_adult;
      case null:
        return null;
    }
  }

  /// Nombre del campo de una incidencia del servidor
  String fieldLabel(String field) {
    switch (field) {
      case TravellerField.firstName:
        return guest_traveller_first_name;
      case TravellerField.lastName1:
        return guest_traveller_last_name_1;
      case 'last_name_2':
        return guest_traveller_last_name_2;
      case TravellerField.sex:
        return guest_traveller_sex;
      case TravellerField.birthDate:
        return guest_traveller_birth_date;
      case TravellerField.nationality:
        return guest_traveller_nationality;
      case TravellerField.documentType:
        return guest_traveller_document_type;
      case TravellerField.documentNumber:
        return guest_traveller_document_number;
      case TravellerField.supportNumber:
        return guest_traveller_support_number;
      case TravellerField.residenceAddress:
        return guest_traveller_address;
      case TravellerField.residenceCity:
        return guest_traveller_city;
      case TravellerField.residenceCountry:
        return guest_traveller_country;
      case TravellerField.contact:
        return guest_traveller_contact_section;
      case TravellerField.email:
        return guest_traveller_email;
      case TravellerField.responsible:
        return guest_traveller_responsible;
      case TravellerField.relationship:
        return guest_traveller_relationship;
      case 'register_format':
        return guest_traveller_legacy_notice;
      default:
        return field;
    }
  }

  /// Mensaje para un código de error del servidor
  String travellerErrorMessage(String code) {
    switch (code) {
      case 'checkin_locked':
        return guest_traveller_error_locked;
      case 'register_incomplete':
        return guest_traveller_error_incomplete;
      case 'not_allowed':
        return guest_traveller_error_not_allowed;
      default:
        if (code.startsWith('invalid_') ||
            code == 'value_too_long' ||
            code == 'first_name_required') {
          return guest_traveller_error_invalid_data;
        }
        return guest_traveller_error_generic;
    }
  }
}
