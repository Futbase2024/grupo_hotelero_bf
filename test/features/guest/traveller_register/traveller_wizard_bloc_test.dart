// BLoC del wizard de registro de viajeros, con repositorios falsos.
//
// Como el resto de tests del proyecto, sin bloc_test ni mocktail.

import 'dart:typed_data';

import 'package:bf_stay/features/guest/checkin/domain/repositories/checkin_repository.dart';
import 'package:bf_stay/features/guest/traveller_register/domain/entities/traveller_entity.dart';
import 'package:bf_stay/features/guest/traveller_register/domain/entities/traveller_register_status.dart';
import 'package:bf_stay/features/guest/traveller_register/domain/repositories/traveller_register_repository.dart';
import 'package:bf_stay/features/guest/traveller_register/presentation/bloc/traveller_wizard_bloc.dart';
import 'package:bf_stay/features/guest/traveller_register/presentation/bloc/traveller_wizard_event.dart';
import 'package:bf_stay/features/guest/traveller_register/presentation/bloc/traveller_wizard_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRegisterRepository implements TravellerRegisterRepository {
  List<TravellerEntity> stored = [];
  final List<TravellerEntity> saved = [];
  final List<String> signedGuests = [];
  int submitCalls = 0;
  TravellerRegisterException? submitError;
  bool complete = false;
  int _nextId = 1;

  @override
  Future<List<TravellerEntity>> getTravellers(String bookingId) async =>
      List.of(stored);

  @override
  Future<String> saveTraveller({
    required String bookingId,
    required TravellerEntity traveller,
  }) async {
    saved.add(traveller);
    final id = traveller.id ?? 'g${_nextId++}';
    final withId = traveller.copyWith(id: id);
    final i = stored.indexWhere((t) => t.id == id);
    if (i >= 0) {
      stored[i] = withId;
    } else {
      stored.add(withId);
    }
    return id;
  }

  @override
  Future<TravellerRegisterStatus> getStatus(String bookingId) async {
    return TravellerRegisterStatus(
      bookingId: bookingId,
      isComplete: complete,
      guests: [
        for (final t in stored)
          TravellerGuestStatus(
            guestId: t.id!,
            isPrimary: t.isPrimary,
            ageOnCheckin: 40,
            needsOwnSignature: true,
            signed: signedGuests.contains(t.id),
            coveredByResponsible: false,
            issues: const [],
          ),
      ],
    );
  }

  @override
  Future<String> signEntryForm({
    required String bookingId,
    required String guestId,
    required String signatureSvg,
  }) async {
    signedGuests.add(guestId);
    complete = true;
    return 'form-$guestId';
  }

  @override
  Future<void> submit(String bookingId) async {
    submitCalls++;
    if (submitError != null) throw submitError!;
  }
}

class _FakeCheckinRepository implements CheckinRepository {
  final List<String> uploadedKinds = [];
  List<String>? keptKinds;

  @override
  Future<String> uploadDocument({
    required String bookingId,
    required String guestId,
    required String docKind,
    required List<int> bytes,
    required String mimeType,
  }) async {
    uploadedKinds.add(docKind);
    return 'path/$docKind';
  }

  @override
  Future<void> deleteObsoleteDocuments({
    required String bookingId,
    required String guestId,
    required List<String> keepDocKinds,
  }) async {
    keptKinds = keepDocKinds;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CheckinBookingData _booking({int adults = 2}) => CheckinBookingData(
      bookingId: 'b1',
      bookingCode: 'BF-1',
      unitName: 'Ático',
      propertyName: 'BF Jerez',
      propertyId: 'p1',
      checkInDate: DateTime(2027, 7, 1),
      checkOutDate: DateTime(2027, 7, 4),
      numAdults: adults,
      numChildren: 0,
      childrenAges: const [],
      guestFirstName: 'Juan',
      guestLastName: 'Pérez',
      guestEmail: 'juan@example.com',
      guestPhone: '+34600000000',
      travellerFormEnabled: true,
    );

TravellerEntity _completeAdult({String? id, bool isPrimary = true}) => TravellerEntity(
      id: id,
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
      isPrimary: isPrimary,
    );

/// Espera a que el BLoC procese los eventos pendientes
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeRegisterRepository repository;
  late _FakeCheckinRepository checkinRepository;
  late TravellerWizardBloc bloc;

  setUp(() {
    repository = _FakeRegisterRepository();
    checkinRepository = _FakeCheckinRepository();
    bloc = TravellerWizardBloc(
      repository: repository,
      checkinRepository: checkinRepository,
    );
  });

  tearDown(() => bloc.close());

  Future<void> start({int adults = 2}) async {
    bloc.add(TravellerWizardStarted(_booking(adults: adults)));
    await _settle();
    await _settle();
  }

  test('sin huéspedes propone al titular con los datos de la reserva', () async {
    await start();

    expect(bloc.state.status, TravellerWizardStatus.ready);
    expect(bloc.state.travellers, hasLength(1));
    final primary = bloc.state.travellers.first;
    expect(primary.firstName, 'Juan');
    expect(primary.lastName1, 'Pérez');
    expect(primary.email, 'juan@example.com');
    expect(primary.isPrimary, isTrue);
    expect(bloc.state.maxGuests, 2);
  });

  test('no avanza con errores: los marca y no guarda nada', () async {
    await start();

    bloc.add(const TravellerWizardStepRequested(1));
    await _settle();

    expect(bloc.state.step, 0);
    expect(bloc.state.showErrors, isTrue);
    expect(bloc.state.selectedIndex, 0);
    expect(repository.saved, isEmpty);
  });

  test('con los datos completos guarda y pasa a la siguiente pantalla', () async {
    await start();
    bloc.add(TravellerWizardTravellerChanged(0, _completeAdult()));
    await _settle();

    bloc.add(const TravellerWizardStepRequested(1));
    await _settle();
    await _settle();

    expect(bloc.state.step, 1);
    expect(bloc.state.showErrors, isFalse);
    expect(repository.saved, hasLength(1));
    expect(bloc.state.travellers.single.id, 'g1');
    expect(bloc.state.registerStatus, isNotNull);
  });

  test('añadir y quitar huéspedes respeta el máximo y lo ya guardado', () async {
    repository.stored = [_completeAdult(id: 'g0')];
    await start(adults: 2);

    bloc.add(const TravellerWizardTravellerAdded());
    await _settle();
    expect(bloc.state.travellers, hasLength(2));
    expect(bloc.state.selectedIndex, 1);
    expect(bloc.state.canAddTraveller, isFalse);

    // El guardado no se puede quitar desde la app
    bloc.add(const TravellerWizardTravellerRemoved(0));
    await _settle();
    expect(bloc.state.travellers, hasLength(2));

    bloc.add(const TravellerWizardTravellerRemoved(1));
    await _settle();
    expect(bloc.state.travellers, hasLength(1));
  });

  test('las fotos guardan antes al huésped y suben las dos caras', () async {
    await start();

    bloc.add(TravellerWizardDocumentPhotosAdded(
      index: 0,
      documentType: TravellerDocumentType.dni,
      documentNumber: '12345678Z',
      frontBytes: Uint8List.fromList([1, 2, 3]),
      backBytes: Uint8List.fromList([4, 5, 6]),
    ));
    await _settle();
    await _settle();

    expect(repository.saved, hasLength(1));
    expect(checkinRepository.uploadedKinds, ['dni_front', 'dni_back']);
    expect(checkinRepository.keptKinds, ['dni_front', 'dni_back']);
    expect(bloc.state.guestIdsWithPhotos, {'g1'});
    expect(bloc.state.travellers.first.documentNumber, '12345678Z');
  });

  test('el pasaporte sube una sola foto y retira el reverso', () async {
    await start();

    bloc.add(TravellerWizardDocumentPhotosAdded(
      index: 0,
      documentType: TravellerDocumentType.passport,
      documentNumber: 'X1234567',
      frontBytes: Uint8List.fromList([1]),
    ));
    await _settle();
    await _settle();

    expect(checkinRepository.uploadedKinds, ['passport']);
    expect(checkinRepository.keptKinds, ['passport']);
  });

  test('firmar refresca el estado y permite enviar', () async {
    repository.stored = [_completeAdult(id: 'g0')];
    await start();
    expect(bloc.state.registerStatus!.isComplete, isFalse);

    bloc.add(const TravellerWizardSignatureSubmitted(
      guestId: 'g0',
      signatureSvg: '<svg viewBox="0 0 400 150"><path d="M 1 1"/></svg>',
    ));
    await _settle();
    await _settle();

    expect(repository.signedGuests, ['g0']);
    expect(bloc.state.registerStatus!.isComplete, isTrue);
    expect(bloc.state.registerStatus!.guest('g0')!.signed, isTrue);

    bloc.add(const TravellerWizardSubmitRequested());
    await _settle();
    expect(repository.submitCalls, 1);
    expect(bloc.state.status, TravellerWizardStatus.submitted);
  });

  test('si el servidor rechaza el envío se muestra el código y se puede cerrar', () async {
    repository.stored = [_completeAdult(id: 'g0')];
    repository.submitError = const TravellerRegisterException('register_incomplete');
    await start();

    bloc.add(const TravellerWizardSubmitRequested());
    await _settle();
    await _settle();

    expect(bloc.state.status, TravellerWizardStatus.ready);
    expect(bloc.state.errorCode, 'register_incomplete');

    bloc.add(const TravellerWizardErrorDismissed());
    await _settle();
    expect(bloc.state.errorCode, isNull);
  });

  test('volver atrás no valida ni guarda', () async {
    repository.stored = [_completeAdult(id: 'g0')];
    await start();
    bloc.add(const TravellerWizardStepRequested(1));
    await _settle();
    await _settle();
    final savesBefore = repository.saved.length;

    bloc.add(const TravellerWizardStepRequested(0));
    await _settle();

    expect(bloc.state.step, 0);
    expect(repository.saved.length, savesBefore);
  });
}
