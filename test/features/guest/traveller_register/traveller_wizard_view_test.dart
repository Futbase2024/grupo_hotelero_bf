// Montaje del wizard completo en móvil y escritorio: detecta errores de
// layout (desbordamientos, constraints) que el análisis estático no ve.

import 'package:bf_stay/core/di/injection.dart';
import 'package:bf_stay/features/guest/checkin/domain/repositories/checkin_repository.dart';
import 'package:bf_stay/features/guest/traveller_register/domain/entities/traveller_entity.dart';
import 'package:bf_stay/features/guest/traveller_register/domain/entities/traveller_register_status.dart';
import 'package:bf_stay/features/guest/traveller_register/domain/repositories/traveller_register_repository.dart';
import 'package:bf_stay/features/guest/traveller_register/presentation/screens/traveller_wizard_view.dart';
import 'package:bf_stay/features/guest/traveller_register/presentation/widgets/signature_pad.dart';
import 'package:bf_stay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRegisterRepository implements TravellerRegisterRepository {
  _FakeRegisterRepository(this.stored);

  final List<TravellerEntity> stored;

  @override
  Future<List<TravellerEntity>> getTravellers(String bookingId) async => stored;

  @override
  Future<String> saveTraveller({
    required String bookingId,
    required TravellerEntity traveller,
  }) async =>
      traveller.id ?? 'g-new';

  @override
  Future<TravellerRegisterStatus> getStatus(String bookingId) async =>
      TravellerRegisterStatus(
        bookingId: bookingId,
        isComplete: false,
        guests: [
          for (final t in stored)
            if (t.id != null)
              TravellerGuestStatus(
                guestId: t.id!,
                isPrimary: t.isPrimary,
                ageOnCheckin: t.ageOn(DateTime(2027, 7, 1)),
                needsOwnSignature: t.needsOwnSignatureOn(DateTime(2027, 7, 1)),
                signed: false,
                coveredByResponsible: false,
                issues: const [],
              ),
        ],
      );

  @override
  Future<String> signEntryForm({
    required String bookingId,
    required String guestId,
    required String signatureSvg,
  }) async =>
      'form';

  @override
  Future<void> submit(String bookingId) async {}
}

class _FakeCheckinRepository implements CheckinRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _booking = CheckinBookingData(
  bookingId: 'b1',
  bookingCode: 'BF-1',
  unitName: 'Ático',
  propertyName: 'BF Jerez',
  propertyId: 'p1',
  checkInDate: DateTime(2027, 7, 1),
  checkOutDate: DateTime(2027, 7, 4),
  numAdults: 1,
  numChildren: 1,
  childrenAges: const [10],
  guestFirstName: 'Juan',
  guestLastName: 'Pérez',
  guestEmail: 'juan@example.com',
  travellerFormEnabled: true,
);

final _adult = TravellerEntity(
  id: 'g0',
  firstName: 'JUAN',
  lastName1: 'PÉREZ',
  sex: TravellerSex.male,
  birthDate: DateTime(1985, 5, 10),
  nationality: 'ESP',
  documentType: TravellerDocumentType.dni,
  documentNumber: '12345678Z',
  supportNumber: 'ABC123456',
  residenceAddress: 'CALLE LARGA 1',
  residenceCity: 'JEREZ',
  residenceCountry: 'ESP',
  mobile: '+34600000000',
  isPrimary: true,
);

final _child = TravellerEntity(
  id: 'g1',
  firstName: 'LUIS',
  lastName1: 'PÉREZ',
  sex: TravellerSex.male,
  birthDate: DateTime(2017, 2, 1),
  nationality: 'ESP',
  responsibleGuestId: 'g0',
  relationship: TravellerRelationship.parent,
);

void main() {
  setUp(() async {
    await getIt.reset();
    getIt
      ..registerSingleton<TravellerRegisterRepository>(
        _FakeRegisterRepository([_adult, _child]),
      )
      ..registerSingleton<CheckinRepository>(_FakeCheckinRepository());
  });

  tearDown(() => getIt.reset());

  Future<void> pumpWizard(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: TravellerWizardView(booking: _booking, onSubmitted: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final entry in {
    'móvil': const Size(390, 844),
    'escritorio': const Size(1280, 900),
  }.entries) {
    testWidgets('recorre las 3 pantallas sin errores de layout (${entry.key})',
        (tester) async {
      await pumpWizard(tester, entry.value);

      // Pantalla 1: identificación con los datos guardados
      expect(find.text('Identificación'), findsOneWidget);
      expect(find.text('Paso 1 de 3'), findsOneWidget);
      expect(find.text('JUAN'), findsOneWidget);
      expect(find.text('Número de soporte'), findsOneWidget);

      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Pantalla 2: residencia y contacto
      expect(find.text('Residencia y contacto'), findsOneWidget);
      expect(find.text('CALLE LARGA 1'), findsOneWidget);

      // El menor muestra su responsable y parentesco
      await tester.tap(find.textContaining('LUIS PÉREZ'));
      await tester.pumpAndSettle();
      expect(find.text('Adulto responsable'), findsOneWidget);
      expect(find.text('Padre / madre'), findsOneWidget);

      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Pantalla 3: revisión, firma del adulto y aviso de privacidad
      expect(find.text('Revisión y firma'), findsOneWidget);
      expect(find.byType(SignaturePad), findsOneWidget);
      expect(find.text('Lo firmará su adulto responsable'), findsOneWidget);
      expect(find.text('Protección de datos'), findsOneWidget);
      expect(find.text('Faltan datos o firmas para poder enviar'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('sin datos completos marca los errores y no avanza', (tester) async {
    await getIt.reset();
    getIt
      ..registerSingleton<TravellerRegisterRepository>(_FakeRegisterRepository([]))
      ..registerSingleton<CheckinRepository>(_FakeCheckinRepository());

    await pumpWizard(tester, const Size(390, 844));

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    expect(find.text('Identificación'), findsOneWidget);
    expect(find.text('Obligatorio'), findsWidgets);
  });
}
