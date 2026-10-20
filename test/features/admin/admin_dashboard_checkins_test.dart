// Tests del refresco del tab de check-ins del panel de administración.
//
// El proyecto no usa mocktail/bloc_test, así que se emplea un fake manual del
// AdminPanelRepository (vía noSuchMethod) y solo `flutter_test`.

import 'package:bf_stay/features/admin/domain/bloc/bloc.dart';
import 'package:bf_stay/features/admin/domain/entities/admin_entities.dart';
import 'package:bf_stay/features/admin/domain/repositories/admin_panel_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminPanelRepository implements AdminPanelRepository {
  /// Filtro de estado de check-in recibido en cada llamada a `listBookings`.
  final List<String?> checkinStatusFilters = [];

  /// `fromDate` recibido en cada llamada (null = sin ventana deslizante).
  final List<DateTime?> fromDates = [];

  /// Ids pedidos en cada llamada (los usa el refresco incremental por Realtime).
  final List<List<String>?> requestedBookingIds = [];

  /// `limit` recibido en cada llamada (la primera carga pide un bloque corto).
  final List<int?> limits = [];

  List<AdminBookingEntity> result = [];

  int get callCount => checkinStatusFilters.length;

  @override
  Future<List<AdminBookingEntity>> listBookings({
    String? propertyId,
    String? statusFilter,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
    String? checkinStatusFilter,
    List<String>? bookingIds,
    int? limit,
    bool lightweight = false,
  }) async {
    checkinStatusFilters.add(checkinStatusFilter);
    fromDates.add(fromDate);
    requestedBookingIds.add(bookingIds);
    limits.add(limit);
    if (bookingIds != null) {
      return result.where((b) => bookingIds.contains(b.id)).toList();
    }
    return limit == null ? result : result.take(limit).toList();
  }

  int summaryCalls = 0;
  int notificationsCalls = 0;

  @override
  Future<DashboardSummaryEntity> getDashboardSummary({String? propertyId}) async {
    summaryCalls++;
    return const DashboardSummaryEntity(
      pendingCheckins: 1,
      upcomingCheckins: 2,
      unreadNotifications: 0,
      totalUnits: 14,
      occupiedToday: 7,
    );
  }

  @override
  Future<List<StaffNotificationEntity>> getNotifications({
    String? propertyId,
    bool? unreadOnly,
  }) async {
    notificationsCalls++;
    return const [];
  }

  @override
  Stream<StaffNotificationEntity> watchNotifications({String? propertyId}) =>
      const Stream<StaffNotificationEntity>.empty();

  @override
  Stream<Set<String>> watchCheckins({String? propertyId}) =>
      const Stream<Set<String>>.empty();

  // Los métodos no usados por estos tests lanzan si se invocan.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

AdminBookingEntity _booking({
  required String id,
  required String checkinStatus,
}) {
  return AdminBookingEntity(
    id: id,
    bookingCode: 'BF-$id',
    unitId: 'unit-1',
    unitName: 'Apto 1',
    propertyId: 'prop-1',
    propertyName: 'BF Stay',
    checkInDate: DateTime(2026, 7, 27),
    checkOutDate: DateTime(2026, 7, 30),
    numGuests: 2,
    status: 'confirmed',
    guestEmail: 'guest@example.com',
    guestFirstName: 'Ana',
    guestLastName: 'García',
    checkinId: 'checkin-$id',
    checkinStatus: checkinStatus,
  );
}

/// Deja correr la cola de eventos del BLoC.
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  late _FakeAdminPanelRepository repository;

  setUp(() {
    repository = _FakeAdminPanelRepository()
      ..result = [_booking(id: '1', checkinStatus: 'submitted')];
  });

  group('AdminDashboardBloc · tab de check-ins', () {
    test('recarga al entrar en el tab aunque ya haya check-ins cargados',
        () async {
      final bloc = AdminDashboardBloc(repository: repository);

      bloc.add(const AdminDashboardCheckinsLoadRequested());
      await _settle();
      // Primera carga: bloque corto para pintar ya + carga completa.
      expect(repository.callCount, 2);
      expect(bloc.state.checkins, isNotEmpty);

      // Regresión: antes solo se recargaba si la lista estaba vacía, así que un
      // check-in enviado después de abrir el panel no llegaba a aparecer.
      bloc.add(const AdminDashboardTabChanged(2));
      await _settle();
      // Ya no es la primera carga: una sola consulta, sin bloque corto.
      expect(repository.callCount, 3);
      expect(repository.checkinStatusFilters.last, 'submitted');

      await bloc.close();
    });

    test('el refresco con datos en pantalla no activa isLoadingCheckins',
        () async {
      final bloc = AdminDashboardBloc(repository: repository);

      bloc.add(const AdminDashboardCheckinsLoadRequested());
      await _settle();

      final loadingFlags = <bool>[];
      final sub = bloc.stream.listen((s) => loadingFlags.add(s.isLoadingCheckins));

      bloc.add(const AdminDashboardCheckinsLoadRequested());
      await _settle();

      expect(loadingFlags, isNotEmpty);
      expect(loadingFlags.contains(true), isFalse);
      expect(bloc.state.isLoadingCheckins, isFalse);
      expect(bloc.state.checkins, repository.result);

      await sub.cancel();
      await bloc.close();
    });

    test('cambiar el filtro de estado recarga con el filtro server-side',
        () async {
      final bloc = AdminDashboardBloc(repository: repository);

      bloc.add(const AdminDashboardCheckinsFilterChanged('validated'));
      await _settle();

      // Primera carga: un bloque corto para pintar ya + la carga completa.
      expect(repository.callCount, 2);
      expect(repository.limits.first, isNotNull);
      expect(repository.limits.last, isNull);
      expect(repository.checkinStatusFilters.last, 'validated');

      await bloc.close();
    });

    test('el filtro "all" no restringe el estado en el servidor', () async {
      final bloc = AdminDashboardBloc(repository: repository);

      bloc.add(const AdminDashboardCheckinsFilterChanged('all'));
      await _settle();

      expect(repository.checkinStatusFilters.last, isNull);
      // Sin filtro de estado sí se acota con la ventana deslizante.
      expect(repository.fromDates.last, isNotNull);

      await bloc.close();
    });

    test('la primera carga pinta un bloque corto antes de la lista completa',
        () async {
      repository.result = List.generate(
        150,
        (i) => _booking(id: 'b$i', checkinStatus: 'validated'),
      );

      final bloc = AdminDashboardBloc(repository: repository);
      final counts = <int>[];
      final sub = bloc.stream.listen((s) => counts.add(s.checkins.length));

      bloc.add(const AdminDashboardCheckinsLoadRequested());
      await _settle();

      // Se emite primero el bloque corto y después la lista entera.
      expect(counts, contains(100));
      expect(bloc.state.checkins.length, 150);
      expect(bloc.state.isRefreshingCheckins, isFalse);

      await sub.cancel();
      await bloc.close();
    });

    test('un cambio en Realtime refresca solo las reservas afectadas',
        () async {
      repository.result = [
        _booking(id: 'b1', checkinStatus: 'submitted'),
        _booking(id: 'b2', checkinStatus: 'submitted'),
      ];

      final bloc = AdminDashboardBloc(repository: repository);
      bloc.add(const AdminDashboardCheckinsLoadRequested());
      await _settle();

      repository.requestedBookingIds.clear();
      bloc.add(const AdminDashboardCheckinsChanged(bookingIds: {'b2'}));
      await _settle();

      // Solo se pide la reserva que cambió, no la lista entera.
      expect(repository.requestedBookingIds, [
        ['b2'],
      ]);
      expect(bloc.state.checkins.length, 2);

      await bloc.close();
    });

    test('con filtro de estado no se aplica la ventana deslizante', () async {
      final bloc = AdminDashboardBloc(repository: repository);

      bloc.add(const AdminDashboardCheckinsLoadRequested());
      await _settle();

      // El join interno ya deja la consulta en unas pocas filas; acotar por
      // fecha escondería un check-in pendiente de una reserva antigua.
      expect(repository.checkinStatusFilters.last, 'submitted');
      expect(repository.fromDates.last, isNull);

      await bloc.close();
    });

    test('la carga inicial del dashboard no descarga la lista de reservas',
        () async {
      final bloc = AdminDashboardBloc(repository: repository);

      bloc.add(const AdminDashboardLoadRequested());
      await _settle();

      // El resumen se sirve entero desde el RPC (KPIs, ocupación y últimos
      // check-ins): bajar ~500 reservas en el arranque era trabajo tirado.
      expect(repository.summaryCalls, 1);
      expect(repository.notificationsCalls, 1);
      expect(repository.callCount, 0);
      expect(bloc.state.summary?.occupancyRate, closeTo(50, 0.01));

      await bloc.close();
    });

    test('"mes anterior" consulta el rango en el servidor, no la ventana',
        () async {
      final bloc = AdminDashboardBloc(repository: repository);

      bloc.add(const AdminDashboardBookingsDateFilterChanged(
        dateFilter: DateFilter.lastMonth,
      ));
      await _settle();

      // Regresión: con la ventana de 30 días, resolver "mes anterior" en
      // cliente mostraba solo la parte que hubiera caído dentro.
      final now = DateTime.now();
      expect(repository.fromDates.last, DateTime(now.year, now.month - 1));

      await bloc.close();
    });

    test('"todo el histórico" no acota por fecha', () async {
      final bloc = AdminDashboardBloc(repository: repository);

      bloc.add(const AdminDashboardBookingsDateFilterChanged(
        dateFilter: DateFilter.allHistory,
      ));
      await _settle();

      expect(repository.callCount, 1);
      expect(repository.fromDates.last, isNull);

      await bloc.close();
    });

    test('una recarga solicitada durante otra en curso no se pierde', () async {
      final bloc = AdminDashboardBloc(repository: repository);

      bloc
        ..add(const AdminDashboardCheckinsLoadRequested())
        ..add(const AdminDashboardCheckinsLoadRequested());
      await _settle();

      // La segunda se encola y se relanza al terminar la primera (antes se
      // descartaba y la lista quedaba obsoleta). Son 3 llamadas: bloque corto
      // inicial + carga completa + la recarga encolada.
      expect(repository.callCount, 3);

      await bloc.close();
    });
  });
}
