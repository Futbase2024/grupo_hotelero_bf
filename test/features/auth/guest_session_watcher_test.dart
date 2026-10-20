// Tests de GuestSessionWatcher: revalidación de la sesión del huésped con la
// app abierta (al volver a primer plano, ante pushes de cierre y periódicamente).
//
// El proyecto no usa mocktail/bloc_test, así que se emplea un fake manual del
// AuthRepository y solo `flutter_test`.

import 'dart:async';

import 'package:bf_stay/core/services/notification_refresh_bus.dart';
import 'package:bf_stay/features/auth/domain/bloc/auth_bloc.dart';
import 'package:bf_stay/features/auth/domain/entities/user_entity.dart';
import 'package:bf_stay/features/auth/domain/repositories/auth_repository.dart';
import 'package:bf_stay/features/auth/presentation/widgets/guest_session_watcher.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const guest = UserEntity(
    id: 'guest-1',
    email: '',
    role: UserRole.guest,
    bookingId: 'booking-1',
  );
  const staff = UserEntity(
    id: 'staff-1',
    email: 'staff@bfstay.test',
    role: UserRole.staff,
  );

  late _FakeAuthRepository repository;
  late AuthBloc bloc;

  /// Monta el watcher con [user] ya autenticado y pone a cero el contador de
  /// verificaciones, para medir solo las que dispara el watcher.
  ///
  /// El bloc se crea aquí (dentro de `testWidgets`) y no en `setUp`: así su
  /// trabajo asíncrono corre en la zona de tiempo simulado y `pump` lo procesa.
  Future<void> pumpWatcherAuthenticatedAs(
    WidgetTester tester,
    UserEntity user,
  ) async {
    repository = _FakeAuthRepository()..currentUser = user;
    bloc = AuthBloc(authRepository: repository);
    addTearDown(() async {
      await bloc.close();
      await repository.dispose();
    });

    bloc.add(const AuthCheckRequested());
    await tester.pump();
    expect(bloc.state, isA<AuthAuthenticated>());

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const GuestSessionWatcher(child: SizedBox()),
      ),
    );
    repository.getCurrentUserCalls = 0;
  }

  /// Desmonta el watcher para cancelar su temporizador periódico.
  Future<void> unmountWatcher(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  void simulateAppResume(WidgetTester tester) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  testWidgets('al volver la app a primer plano revalida la sesión del huésped',
      (tester) async {
    await pumpWatcherAuthenticatedAs(tester, guest);

    simulateAppResume(tester);
    await tester.pump();

    expect(repository.getCurrentUserCalls, 1);
    await unmountWatcher(tester);
  });

  testWidgets('si la estancia terminó, la revalidación cierra la sesión',
      (tester) async {
    await pumpWatcherAuthenticatedAs(tester, guest);

    // El servidor ya no devuelve la reserva: getCurrentUser da null
    repository.currentUser = null;
    simulateAppResume(tester);
    await tester.pump();

    expect(bloc.state, isA<AuthUnauthenticated>());
    await unmountWatcher(tester);
  });

  testWidgets('un push de cierre de reserva revalida la sesión',
      (tester) async {
    await pumpWatcherAuthenticatedAs(tester, guest);

    NotificationRefreshBus.instance.emit('booking_status');
    await tester.pump();
    NotificationRefreshBus.instance.emit('checkout_status');
    await tester.pump();

    expect(repository.getCurrentUserCalls, 2);
    await unmountWatcher(tester);
  });

  testWidgets('otros pushes (p. ej. chat) no revalidan la sesión',
      (tester) async {
    await pumpWatcherAuthenticatedAs(tester, guest);

    NotificationRefreshBus.instance.emit('chat_message');
    await tester.pump();

    expect(repository.getCurrentUserCalls, 0);
    await unmountWatcher(tester);
  });

  testWidgets('revalida periódicamente con la app abierta', (tester) async {
    await pumpWatcherAuthenticatedAs(tester, guest);

    await tester.pump(GuestSessionWatcher.periodicCheckInterval);

    expect(repository.getCurrentUserCalls, 1);
    await unmountWatcher(tester);
  });

  testWidgets('no revalida al staff', (tester) async {
    await pumpWatcherAuthenticatedAs(tester, staff);

    simulateAppResume(tester);
    await tester.pump();
    NotificationRefreshBus.instance.emit('booking_status');
    await tester.pump();
    await tester.pump(GuestSessionWatcher.periodicCheckInterval);

    expect(repository.getCurrentUserCalls, 0);
    await unmountWatcher(tester);
  });
}

class _FakeAuthRepository implements AuthRepository {
  UserEntity? currentUser;
  int getCurrentUserCalls = 0;

  final StreamController<void> _sessionChanges =
      StreamController<void>.broadcast();

  @override
  Future<UserEntity?> getCurrentUser() async {
    getCurrentUserCalls++;
    return currentUser;
  }

  @override
  Stream<void> get sessionChanges => _sessionChanges.stream;

  Future<void> dispose() => _sessionChanges.close();

  // El resto del contrato (login, logout...) no se usa en estos tests.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
