// Entidad del registro de viajeros y lectura de la respuesta del servidor.

import 'package:bf_stay/features/guest/traveller_register/domain/entities/traveller_entity.dart';
import 'package:bf_stay/features/guest/traveller_register/domain/entities/traveller_register_status.dart';
import 'package:bf_stay/features/guest/traveller_register/domain/repositories/traveller_register_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final checkin = DateTime(2027, 7, 1);

  group('TravellerEntity', () {
    test('firma propia desde los 14 años, menor hasta los 18', () {
      final child = TravellerEntity(birthDate: DateTime(2017, 2, 1));
      final teen = TravellerEntity(birthDate: DateTime(2012, 3, 1));
      final adult = TravellerEntity(birthDate: DateTime(1985, 5, 10));

      expect(child.needsOwnSignatureOn(checkin), isFalse);
      expect(child.isMinorOn(checkin), isTrue);
      expect(teen.needsOwnSignatureOn(checkin), isTrue);
      expect(teen.isMinorOn(checkin), isTrue);
      expect(adult.needsOwnSignatureOn(checkin), isTrue);
      expect(adult.isMinorOn(checkin), isFalse);
      expect(const TravellerEntity().needsOwnSignatureOn(checkin), isFalse);
    });

    test('toRpcData usa las claves de save_traveller_guest', () {
      final data = TravellerEntity(
        firstName: ' Juan ',
        lastName1: 'Pérez',
        sex: TravellerSex.male,
        birthDate: DateTime(1985, 5, 10),
        nationality: 'ESP',
        documentType: TravellerDocumentType.dni,
        documentNumber: '12345678Z',
        supportNumber: 'ABC123456',
        mobile: '+34600000000',
        isPrimary: true,
      ).toRpcData();

      expect(data['first_name'], 'Juan');
      expect(data['last_name_1'], 'Pérez');
      expect(data['last_name_2'], isNull);
      expect(data['sex'], 'M');
      expect(data['birth_date'], '1985-05-10');
      expect(data['document_type'], 'dni');
      expect(data['document_support_number'], 'ABC123456');
      expect(data['mobile'], '+34600000000');
      expect(data['landline_phone'], isNull);
      expect(data['is_primary'], isTrue);
    });

    test('el pasaporte no envía número de soporte', () {
      final data = const TravellerEntity(
        firstName: 'John',
        documentType: TravellerDocumentType.passport,
        documentNumber: 'X1234',
        supportNumber: 'ABC123456',
      ).toRpcData();

      expect(data['document_support_number'], isNull);
    });

    test('lee un huésped nuevo de booking_guests + guests', () {
      final traveller = TravellerEntity.fromBookingGuestJson({
        'guest_id': 'g1',
        'is_primary': false,
        'responsible_guest_id': 'g0',
        'relationship': 'parent',
        'guests': {
          'id': 'g1',
          'full_name': 'LUIS PÉREZ',
          'first_name': 'LUIS',
          'last_name_1': 'PÉREZ',
          'sex': 'M',
          'birth_date': '2017-02-01',
          'nationality': 'ESP',
          'register_format': 'rd933_v1',
        },
      });

      expect(traveller.id, 'g1');
      expect(traveller.firstName, 'LUIS');
      expect(traveller.lastName1, 'PÉREZ');
      expect(traveller.isLegacy, isFalse);
      expect(traveller.responsibleGuestId, 'g0');
      expect(traveller.relationship, TravellerRelationship.parent);
      expect(traveller.ageOn(checkin), 10);
    });

    test('un registro antiguo propone su nombre completo en "Nombre"', () {
      final traveller = TravellerEntity.fromBookingGuestJson({
        'guest_id': 'g2',
        'is_primary': true,
        'guests': {
          'id': 'g2',
          'full_name': 'JUAN PÉREZ GARCÍA',
          'document_type': 'dni_front',
          'document_number': '12345678Z',
          'register_format': 'legacy',
        },
      });

      expect(traveller.isLegacy, isTrue);
      expect(traveller.firstName, 'JUAN PÉREZ GARCÍA');
      expect(traveller.lastName1, isEmpty);
      expect(traveller.documentType, TravellerDocumentType.dni);
      expect(traveller.isPrimary, isTrue);
    });

    test('copyWith puede quitar el responsable', () {
      const minor = TravellerEntity(
        responsibleGuestId: 'g0',
        relationship: TravellerRelationship.parent,
      );
      final cleared = minor.copyWith(clearResponsible: true);

      expect(cleared.responsibleGuestId, isNull);
      expect(cleared.relationship, isNull);
    });
  });

  group('TravellerRegisterStatus', () {
    test('lee la respuesta de traveller_register_issues', () {
      final status = TravellerRegisterStatus.fromJson({
        'booking_id': 'b1',
        'complete': false,
        'guests': [
          {
            'guest_id': 'g0',
            'is_primary': true,
            'age_on_checkin': 42,
            'needs_own_signature': true,
            'signed': false,
            'covered_by_responsible': false,
            'issues': [
              {'field': 'last_name_2', 'code': 'recommended', 'level': 'warning'},
            ],
          },
          {
            'guest_id': 'g1',
            'is_primary': false,
            'age_on_checkin': 10,
            'needs_own_signature': false,
            'signed': false,
            'covered_by_responsible': false,
            'issues': [
              {'field': 'relationship', 'code': 'required', 'level': 'error'},
            ],
          },
        ],
      });

      expect(status.isComplete, isFalse);
      final adult = status.guest('g0')!;
      expect(adult.hasBlockingIssues, isFalse);
      expect(adult.canSign, isTrue);
      expect(adult.isDone, isFalse);

      final child = status.guest('g1')!;
      expect(child.hasBlockingIssues, isTrue);
      expect(child.canSign, isFalse);
      expect(status.guest('nadie'), isNull);
    });
  });

  group('TravellerRegisterException', () {
    test('extrae el código del mensaje de Postgres', () {
      final e = TravellerRegisterException.fromServerMessage(
        'checkin_locked: el check-in ya se ha enviado',
      );
      expect(e.code, 'checkin_locked');
      expect(e.detail, 'el check-in ya se ha enviado');

      expect(
        TravellerRegisterException.fromServerMessage('invalid_document_number').code,
        'invalid_document_number',
      );
    });
  });
}
