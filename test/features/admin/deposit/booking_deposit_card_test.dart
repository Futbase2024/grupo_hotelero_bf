// Tests de la tarjeta de fianza del panel de administración.
//
// Como el resto de tests del proyecto, sin mocktail: fake manual del
// AdminPanelRepository vía noSuchMethod.

import 'package:bf_stay/features/admin/bookings/presentation/widgets/deposit/booking_deposit_card.dart';
import 'package:bf_stay/features/admin/domain/entities/admin_entities.dart';
import 'package:bf_stay/features/admin/domain/repositories/admin_panel_repository.dart';
import 'package:bf_stay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminPanelRepository implements AdminPanelRepository {
  final List<String?> confirmedReferences = [];
  final List<String> waivedBookings = [];
  bool validateOnConfirm = true;

  @override
  Future<bool> confirmDepositAndValidate({
    required String bookingId,
    String? reference,
  }) async {
    confirmedReferences.add(reference);
    return validateOnConfirm;
  }

  @override
  Future<void> waiveBookingDeposit(String bookingId) async {
    waivedBookings.add(bookingId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

BookingDepositEntity _deposit({
  String status = 'pending',
  String checkinStatus = 'submitted',
}) {
  return BookingDepositEntity.fromJson({
    'id': 'booking-1',
    'booking_code': 'BF-123',
    'property_id': 'property-1',
    'guest_first_name': 'Ana',
    'last_name': 'García',
    'deposit_status': status,
    'deposit_amount_cents': status == 'none' ? null : 15000,
    'deposit_payment_link': 'https://pasarela.test/pago',
    'deposit_sent_via': ['whatsapp'],
    'deposit_requested_at': '2026-10-19T10:00:00Z',
    'properties': {'name': 'Casa BF', 'default_deposit_cents': 15000},
    'checkins': {'status': checkinStatus},
  });
}

Future<void> _pumpDialogTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  late _FakeAdminPanelRepository repository;
  late int changedCount;
  late int validatedCount;

  setUp(() {
    repository = _FakeAdminPanelRepository();
    changedCount = 0;
    validatedCount = 0;
  });

  Future<void> pumpCard(WidgetTester tester, BookingDepositEntity deposit) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: BookingDepositCard(
              deposit: deposit,
              repository: repository,
              onChanged: () async => changedCount++,
              onValidated: () async => validatedCount++,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('sin fianza y con check-in validado no muestra nada',
      (tester) async {
    await pumpCard(
      tester,
      _deposit(status: 'none', checkinStatus: 'validated'),
    );

    expect(find.text('FIANZA'), findsNothing);
  });

  testWidgets('sin fianza y check-in abierto ofrece pedirla', (tester) async {
    await pumpCard(tester, _deposit(status: 'none'));

    expect(find.text('FIANZA'), findsOneWidget);
    expect(find.text('Pedir fianza'), findsOneWidget);
  });

  testWidgets('pendiente: confirmar el pago valida y avisa', (tester) async {
    await pumpCard(tester, _deposit());

    expect(find.text('PENDIENTE DE PAGO'), findsOneWidget);
    expect(find.textContaining('150,00'), findsOneWidget);

    await tester.tap(find.text('Marcar pagada y validar'));
    await tester.pumpAndSettle();

    // Diálogo de confirmación con la referencia opcional
    expect(find.text('Confirmar pago de la fianza'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'OP-123');
    await tester.tap(find.text('Confirmar pago'));
    // Mientras se muestra el aviso la tarjeta sigue con el indicador de carga
    // animándose, así que pumpAndSettle no terminaría nunca
    await _pumpDialogTransition(tester);

    expect(repository.confirmedReferences, ['OP-123']);
    expect(validatedCount, 1);
    expect(
      find.text('Fianza pagada y check-in validado. El huésped ya tiene acceso.'),
      findsOneWidget,
    );

    // La recarga se hace después de cerrar el aviso
    expect(changedCount, 0);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(changedCount, 1);
  });

  testWidgets('pendiente sin check-in enviado: solo marca como pagada',
      (tester) async {
    repository.validateOnConfirm = false;
    await pumpCard(tester, _deposit(checkinStatus: 'in_progress'));

    await tester.tap(find.text('Marcar como pagada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar pago'));
    // Mientras se muestra el aviso la tarjeta sigue con el indicador de carga
    // animándose, así que pumpAndSettle no terminaría nunca
    await _pumpDialogTransition(tester);

    expect(repository.confirmedReferences, [null]);
    expect(validatedCount, 0);
  });

  testWidgets('cancelar el diálogo no hace nada', (tester) async {
    await pumpCard(tester, _deposit());

    await tester.tap(find.text('Marcar pagada y validar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(repository.confirmedReferences, isEmpty);
    expect(changedCount, 0);
  });
}
