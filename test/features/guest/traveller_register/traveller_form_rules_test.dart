// Reglas de cada pantalla del formulario de registro de viajeros.

import 'package:bf_stay/features/guest/traveller_register/domain/entities/traveller_entity.dart';
import 'package:bf_stay/features/guest/traveller_register/domain/validators/traveller_form_rules.dart';
import 'package:bf_stay/features/guest/traveller_register/presentation/widgets/signature_pad.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final checkin = DateTime(2027, 7, 1);

  final adult = TravellerEntity(
    id: 'a',
    firstName: 'Juan',
    lastName1: 'Pérez',
    sex: TravellerSex.male,
    birthDate: DateTime(1985, 5, 10),
    nationality: 'ESP',
    documentType: TravellerDocumentType.dni,
    documentNumber: '12345678Z',
    supportNumber: 'ABC123456',
    residenceAddress: 'Calle Larga 1',
    residenceCity: 'Jerez',
    residenceCountry: 'ESP',
    mobile: '+34600000000',
  );

  final child = TravellerEntity(
    id: 'c',
    firstName: 'Luis',
    lastName1: 'Pérez',
    sex: TravellerSex.male,
    birthDate: DateTime(2017, 2, 1),
    nationality: 'ESP',
    responsibleGuestId: 'a',
    relationship: TravellerRelationship.parent,
  );

  group('identificación', () {
    test('un adulto completo no tiene errores', () {
      expect(TravellerFormRules.identification(adult, checkin), isEmpty);
    });

    test('un adulto sin documento ni soporte da error', () {
      final errors = TravellerFormRules.identification(
        adult.copyWith(documentNumber: '', supportNumber: ''),
        checkin,
      );
      expect(errors[TravellerField.documentNumber], TravellerFieldError.required);
      // Sin número no se exige todavía el soporte
      expect(errors.containsKey(TravellerField.supportNumber), isFalse);
    });

    test('DNI con letra incorrecta y soporte con formato erróneo', () {
      final errors = TravellerFormRules.identification(
        adult.copyWith(documentNumber: '12345678A', supportNumber: '123'),
        checkin,
      );
      expect(errors[TravellerField.documentNumber], TravellerFieldError.invalid);
      expect(errors[TravellerField.supportNumber], TravellerFieldError.invalid);
    });

    test('el pasaporte no exige número de soporte', () {
      final errors = TravellerFormRules.identification(
        adult.copyWith(
          documentType: TravellerDocumentType.passport,
          documentNumber: 'X1234567',
          supportNumber: '',
        ),
        checkin,
      );
      expect(errors, isEmpty);
    });

    test('un menor puede no tener documento', () {
      expect(TravellerFormRules.identification(child, checkin), isEmpty);
    });

    test('fecha de nacimiento posterior a la entrada no es válida', () {
      final errors = TravellerFormRules.identification(
        adult.copyWith(birthDate: DateTime(2028)),
        checkin,
      );
      expect(errors[TravellerField.birthDate], TravellerFieldError.invalid);
    });

    test('campos vacíos obligatorios', () {
      final errors = TravellerFormRules.identification(const TravellerEntity(), checkin);
      expect(errors.keys, containsAll([
        TravellerField.firstName,
        TravellerField.lastName1,
        TravellerField.sex,
        TravellerField.birthDate,
        TravellerField.nationality,
      ]));
    });
  });

  group('residencia y contacto', () {
    test('un adulto completo no tiene errores', () {
      expect(
        TravellerFormRules.residenceAndContact(adult, checkin, [adult]),
        isEmpty,
      );
    });

    test('un adulto necesita domicilio y al menos un contacto', () {
      final errors = TravellerFormRules.residenceAndContact(
        adult.copyWith(residenceAddress: '', mobile: ''),
        checkin,
        [adult],
      );
      expect(errors[TravellerField.residenceAddress], TravellerFieldError.required);
      expect(errors[TravellerField.contact], TravellerFieldError.required);
    });

    test('un menor con responsable adulto no necesita domicilio propio', () {
      expect(
        TravellerFormRules.residenceAndContact(child, checkin, [adult, child]),
        isEmpty,
      );
    });

    test('un menor sin responsable ni parentesco da error', () {
      final errors = TravellerFormRules.residenceAndContact(
        child.copyWith(clearResponsible: true),
        checkin,
        [adult, child],
      );
      expect(errors[TravellerField.responsible], TravellerFieldError.required);
      expect(errors[TravellerField.relationship], TravellerFieldError.required);
      expect(errors[TravellerField.residenceCountry], TravellerFieldError.required);
    });

    test('el responsable tiene que ser mayor de edad', () {
      final teen = child.copyWith(id: 't', birthDate: DateTime(2011));
      final errors = TravellerFormRules.residenceAndContact(
        child.copyWith(responsibleGuestId: 't'),
        checkin,
        [teen, child],
      );
      expect(errors[TravellerField.responsible], TravellerFieldError.responsibleNotAdult);
    });

    test('solo los adultos guardados pueden ser responsables', () {
      final list = [adult, child, TravellerEntity(birthDate: DateTime(1990))];
      expect(
        TravellerFormRules.possibleResponsibles(list, checkin).map((t) => t.id),
        ['a'],
      );
    });

    test('formato de email y teléfonos', () {
      final errors = TravellerFormRules.residenceAndContact(
        adult.copyWith(email: 'mal', mobile: '12', landline: 'abc'),
        checkin,
        [adult],
      );
      expect(errors[TravellerField.email], TravellerFieldError.invalid);
      expect(errors[TravellerField.mobile], TravellerFieldError.invalid);
      expect(errors[TravellerField.landline], TravellerFieldError.invalid);
    });
  });

  group('firma en SVG', () {
    test('sin trazos no hay firma', () {
      expect(SignaturePad.toSvg([]), isNull);
      expect(SignaturePad.toSvg([[]]), isNull);
    });

    test('genera un SVG completo con viewBox 400×150 que acepta el servidor', () {
      final svg = SignaturePad.toSvg([
        [const Offset(10, 20), const Offset(30, 40)],
        [const Offset(50, 60)],
      ])!;

      expect(svg, startsWith('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 150">'));
      expect(svg, contains('d="M 10.0 20.0 L 30.0 40.0 M 50.0 60.0 L 50.0 60.0"'));
      expect(svg, endsWith('</svg>'));
      // Mismas comprobaciones que sign_traveller_entry_form
      expect(svg.length, greaterThanOrEqualTo(20));
      expect(RegExp(r'<script|javascript:|on[a-z]+\s*=', caseSensitive: false).hasMatch(svg), isFalse);
    });
  });
}
