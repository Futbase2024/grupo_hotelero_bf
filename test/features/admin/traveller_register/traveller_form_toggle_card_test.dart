// Tests del interruptor "Formulario de registro de viajeros" del panel.
//
// Como el resto de tests del proyecto, sin mocktail: fake manual.

import 'package:bf_stay/features/admin/traveller_register/domain/repositories/traveller_form_admin_repository.dart';
import 'package:bf_stay/features/admin/traveller_register/presentation/widgets/traveller_form_toggle_card.dart';
import 'package:bf_stay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTravellerFormRepository implements TravellerFormAdminRepository {
  bool enabled = false;
  bool failLoad = false;
  TravellerFormToggleException? rejectWith;
  final List<bool> setCalls = [];

  @override
  Future<bool> isEnabled(String bookingId) async {
    if (failLoad) throw Exception('sin conexión');
    return enabled;
  }

  @override
  Future<bool> setEnabled({
    required String bookingId,
    required bool enabled,
  }) async {
    setCalls.add(enabled);
    if (rejectWith != null) throw rejectWith!;
    this.enabled = enabled;
    return enabled;
  }
}

void main() {
  late _FakeTravellerFormRepository repository;

  setUp(() => repository = _FakeTravellerFormRepository());

  Future<void> pumpCard(WidgetTester tester, {bool isLocked = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: TravellerFormToggleCard(
            bookingId: 'booking-1',
            repository: repository,
            isLocked: isLocked,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Switch switchOf(WidgetTester tester) =>
      tester.widget<Switch>(find.byType(Switch));

  testWidgets('por defecto aparece apagado y se puede cambiar', (tester) async {
    await pumpCard(tester);

    expect(find.text('Formulario de registro de viajeros'), findsOneWidget);
    expect(switchOf(tester).value, isFalse);
    expect(switchOf(tester).onChanged, isNotNull);
  });

  testWidgets('activar pide confirmación y guarda', (tester) async {
    await pumpCard(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('¿Activar el formulario de registro?'), findsOneWidget);

    await tester.tap(find.text('Activar'));
    await tester.pumpAndSettle();

    expect(repository.setCalls, [true]);
    expect(switchOf(tester).value, isTrue);
    expect(find.text('Formulario de registro activado'), findsOneWidget);
  });

  testWidgets('cancelar la confirmación no cambia nada', (tester) async {
    await pumpCard(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(repository.setCalls, isEmpty);
    expect(switchOf(tester).value, isFalse);
  });

  testWidgets('desactivar pide su propia confirmación', (tester) async {
    repository.enabled = true;
    await pumpCard(tester);
    expect(switchOf(tester).value, isTrue);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('¿Desactivar el formulario de registro?'), findsOneWidget);

    await tester.tap(find.text('Desactivar'));
    await tester.pumpAndSettle();

    expect(repository.setCalls, [false]);
    expect(switchOf(tester).value, isFalse);
  });

  testWidgets('con el check-in enviado se muestra bloqueado', (tester) async {
    repository.enabled = true;
    await pumpCard(tester, isLocked: true);

    expect(switchOf(tester).value, isTrue);
    expect(switchOf(tester).onChanged, isNull);
    expect(
      find.text(
        'El check-in ya se ha enviado: no se puede cambiar el método de check-in.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('si el servidor lo rechaza muestra un diálogo de error',
      (tester) async {
    repository.rejectWith = const TravellerFormToggleException(
      'checkin_already_submitted: el check-in ya se ha enviado',
    );
    await pumpCard(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Activar'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo cambiar'), findsOneWidget);
    expect(switchOf(tester).value, isFalse);
  });

  testWidgets('si falla la carga no deja cambiarlo', (tester) async {
    repository.failLoad = true;
    await pumpCard(tester);

    expect(switchOf(tester).onChanged, isNull);
    expect(
      find.text('No se pudo cargar el estado del formulario.'),
      findsOneWidget,
    );
  });
}
