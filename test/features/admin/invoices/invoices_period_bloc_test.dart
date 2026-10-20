// Tests del BLoC de facturas por periodo.
//
// El proyecto no usa mocktail/bloc_test: se usan fakes manuales y flutter_test.

import 'dart:typed_data';

import 'package:bf_stay/features/admin/domain/entities/invoice_entity.dart';
import 'package:bf_stay/features/admin/domain/repositories/invoices_repository.dart';
import 'package:bf_stay/features/admin/invoices/data/services/invoice_pdf_service.dart';
import 'package:bf_stay/features/admin/invoices/presentation/bloc/invoices_period_bloc.dart';
import 'package:bf_stay/features/admin/invoices/presentation/bloc/invoices_period_event.dart';
import 'package:bf_stay/features/admin/invoices/presentation/bloc/invoices_period_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'invoice_fixtures.dart';

class _RangeCall {
  _RangeCall(this.start, this.end, this.statuses, this.propertyId);

  final DateTime start;
  final DateTime end;
  final Set<InvoiceStatus>? statuses;
  final String? propertyId;
}

class _FakeInvoicesRepository implements InvoicesRepository {
  final List<_RangeCall> calls = [];
  List<InvoiceEntity> result = [];
  Object? error;

  @override
  Future<List<InvoiceEntity>> getByIssueDateRange({
    required DateTime start,
    required DateTime end,
    Set<InvoiceStatus>? statuses,
    String? propertyId,
  }) async {
    calls.add(_RangeCall(start, end, statuses, propertyId));
    if (error != null) throw error!;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePdfService extends InvoicePdfService {
  int batchCalls = 0;
  bool? lastIncludeSummary;
  String? lastPropertyName;

  @override
  Future<Uint8List> generateInvoicesBatchPdf(
    List<InvoiceEntity> invoices, {
    required DateTime start,
    required DateTime end,
    bool includeSummary = true,
    String? propertyName,
  }) async {
    batchCalls++;
    lastIncludeSummary = includeSummary;
    lastPropertyName = propertyName;
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<Uint8List> generateInvoicesListPdf(
    List<InvoiceEntity> invoices, {
    required DateTime start,
    required DateTime end,
    String? propertyName,
  }) async =>
      Uint8List.fromList([4, 5]);
}

/// Espera a que el BLoC procese los eventos pendientes
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeInvoicesRepository repository;
  late _FakePdfService pdfService;
  late InvoicesPeriodBloc bloc;

  final start = DateTime(2026, 3);
  final end = DateTime(2026, 7, 31);

  final invoices = [
    buildInvoice(number: 'F-2026/0001', issueDate: DateTime(2026, 3, 5), base: 100),
    buildInvoice(
      number: 'F-2026/0002',
      issueDate: DateTime(2026, 3, 20),
      base: 200,
      status: InvoiceStatus.paid,
    ),
    buildInvoice(
      number: 'F-2026/0003',
      issueDate: DateTime(2026, 5, 2),
      base: 50,
      status: InvoiceStatus.paid,
    ),
  ];

  setUp(() {
    repository = _FakeInvoicesRepository()..result = invoices;
    pdfService = _FakePdfService();
    bloc = InvoicesPeriodBloc(
      repository: repository,
      start: start,
      end: end,
      pdfService: pdfService,
    );
  });

  tearDown(() => bloc.close());

  group('carga', () {
    test('estado inicial: emitidas + pagadas, con portada, sin cargar', () {
      expect(bloc.state.statuses, InvoicesPeriodState.defaultStatuses);
      expect(bloc.state.includeSummary, isTrue);
      expect(bloc.state.hasLoaded, isFalse);
    });

    test('carga las facturas con el rango y los estados por defecto', () async {
      bloc.add(const InvoicesPeriodLoadRequested());
      await _settle();

      expect(repository.calls.single.start, start);
      expect(repository.calls.single.end, end);
      expect(repository.calls.single.statuses, InvoicesPeriodState.defaultStatuses);
      expect(bloc.state.invoices, invoices);
      expect(bloc.state.hasLoaded, isTrue);
      expect(bloc.state.isLoading, isFalse);
    });

    test('un error de carga deja el mensaje en el estado', () async {
      repository.error = Exception('sin conexión');
      bloc.add(const InvoicesPeriodLoadRequested());
      await _settle();

      expect(bloc.state.error, contains('sin conexión'));
      expect(bloc.state.isLoading, isFalse);
    });
  });

  group('filtros', () {
    test('cambiar el rango recarga y corrige fechas invertidas', () async {
      bloc.add(InvoicesPeriodRangeChanged(start: DateTime(2026, 6, 30), end: DateTime(2026, 4)));
      await _settle();

      expect(bloc.state.start, DateTime(2026, 4));
      expect(bloc.state.end, DateTime(2026, 6, 30));
      expect(repository.calls.last.start, DateTime(2026, 4));
    });

    test('marcar/desmarcar estados recarga con el nuevo conjunto', () async {
      bloc.add(const InvoicesPeriodStatusToggled(InvoiceStatus.cancelled));
      await _settle();
      expect(repository.calls.last.statuses, {
        InvoiceStatus.issued,
        InvoiceStatus.paid,
        InvoiceStatus.cancelled,
      });

      bloc.add(const InvoicesPeriodStatusToggled(InvoiceStatus.issued));
      await _settle();
      expect(repository.calls.last.statuses, {InvoiceStatus.paid, InvoiceStatus.cancelled});
    });

    test('no permite quedarse sin ningún estado', () async {
      bloc.add(const InvoicesPeriodStatusToggled(InvoiceStatus.issued));
      await _settle();
      final callsBefore = repository.calls.length;

      bloc.add(const InvoicesPeriodStatusToggled(InvoiceStatus.paid));
      await _settle();

      expect(bloc.state.statuses, {InvoiceStatus.paid});
      expect(repository.calls.length, callsBefore);
    });

    test('filtrar por alojamiento y volver a "todos"', () async {
      bloc.add(const InvoicesPeriodPropertyChanged(propertyId: 'p1', propertyName: 'Casa A'));
      await _settle();
      expect(repository.calls.last.propertyId, 'p1');
      expect(bloc.state.propertyName, 'Casa A');

      bloc.add(const InvoicesPeriodPropertyChanged());
      await _settle();
      expect(repository.calls.last.propertyId, isNull);
      expect(bloc.state.propertyName, isNull);
    });
  });

  group('totales', () {
    test('suma base, IVA y total y separa pendientes de cobro', () async {
      bloc.add(const InvoicesPeriodLoadRequested());
      await _settle();

      expect(bloc.state.count, 3);
      expect(bloc.state.totalBase, closeTo(350, 0.001));
      expect(bloc.state.totalTax, closeTo(35, 0.001));
      expect(bloc.state.totalAmount, closeTo(385, 0.001));
      expect(bloc.state.totalPending, closeTo(110, 0.001));
      expect(bloc.state.countByStatus(InvoiceStatus.paid), 2);
    });

    test('agrupa por mes en orden cronológico', () async {
      bloc.add(const InvoicesPeriodLoadRequested());
      await _settle();

      final byMonth = bloc.state.invoicesByMonth;
      expect(byMonth.keys, [DateTime(2026, 3), DateTime(2026, 5)]);
      expect(byMonth[DateTime(2026, 3)]!.length, 2);
    });

    test('nombre de archivo con el rango ISO', () {
      expect(bloc.state.fileSuffix, '2026-03-01_a_2026-07-31');
    });
  });

  group('exportación', () {
    test('PDF de facturas: pasa la portada y deja el archivo pendiente', () async {
      bloc
        ..add(const InvoicesPeriodLoadRequested())
        ..add(const InvoicesPeriodSummaryToggled(false));
      await _settle();

      bloc.add(const InvoicesPeriodExportRequested(
        format: PeriodExportFormat.invoicesPdf,
        action: PeriodExportAction.print,
      ));
      await _settle();

      expect(pdfService.batchCalls, 1);
      expect(pdfService.lastIncludeSummary, isFalse);
      final file = bloc.state.pendingExport!;
      expect(file.fileName, 'Facturas_2026-03-01_a_2026-07-31.pdf');
      expect(file.action, PeriodExportAction.print);
      expect(file.isPdf, isTrue);
      expect(bloc.state.isExporting, isFalse);

      bloc.add(const InvoicesPeriodExportConsumed());
      await _settle();
      expect(bloc.state.pendingExport, isNull);
    });

    test('el CSV siempre se comparte aunque se pida imprimir', () async {
      bloc.add(const InvoicesPeriodLoadRequested());
      await _settle();

      bloc.add(const InvoicesPeriodExportRequested(
        format: PeriodExportFormat.csv,
        action: PeriodExportAction.print,
      ));
      await _settle();

      final file = bloc.state.pendingExport!;
      expect(file.mimeType, 'text/csv');
      expect(file.action, PeriodExportAction.share);
      expect(file.fileName, endsWith('.csv'));
    });

    test('sin facturas no genera nada', () async {
      repository.result = [];
      bloc.add(const InvoicesPeriodLoadRequested());
      await _settle();

      bloc.add(const InvoicesPeriodExportRequested(
        format: PeriodExportFormat.invoicesPdf,
        action: PeriodExportAction.share,
      ));
      await _settle();

      expect(pdfService.batchCalls, 0);
      expect(bloc.state.pendingExport, isNull);
    });
  });
}
