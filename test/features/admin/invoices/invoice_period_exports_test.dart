// Tests de los atajos de periodo, el CSV y el PDF por lotes de facturas.

import 'dart:convert';

import 'package:bf_stay/features/admin/domain/entities/invoice_entity.dart';
import 'package:bf_stay/features/admin/invoices/data/services/invoice_pdf_service.dart';
import 'package:bf_stay/features/admin/invoices/data/services/invoices_csv_service.dart';
import 'package:bf_stay/features/admin/invoices/presentation/bloc/invoice_period_presets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'invoice_fixtures.dart';

/// Nº de páginas de un PDF contando los objetos `/Type /Page`
int _pageCount(List<int> bytes) {
  final text = latin1.decode(bytes);
  return RegExp(r'/Type\s*/Page(?![s\w])').allMatches(text).length;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InvoicePeriodPreset', () {
    final now = DateTime(2026, 2, 14);

    test('trimestres con el último día correcto', () {
      expect(InvoicePeriodPreset.q1.range(now), (DateTime(2026), DateTime(2026, 3, 31)));
      expect(InvoicePeriodPreset.q2.range(now), (DateTime(2026, 4), DateTime(2026, 6, 30)));
      expect(InvoicePeriodPreset.q3.range(now), (DateTime(2026, 7), DateTime(2026, 9, 30)));
      expect(InvoicePeriodPreset.q4.range(now), (DateTime(2026, 10), DateTime(2026, 12, 31)));
    });

    test('este mes respeta febrero', () {
      expect(InvoicePeriodPreset.thisMonth.range(now), (DateTime(2026, 2), DateTime(2026, 2, 28)));
    });

    test('mes anterior en enero salta a diciembre del año anterior', () {
      expect(
        InvoicePeriodPreset.lastMonth.range(DateTime(2026, 1, 10)),
        (DateTime(2025, 12), DateTime(2025, 12, 31)),
      );
    });

    test('año actual y anterior', () {
      expect(InvoicePeriodPreset.thisYear.range(now), (DateTime(2026), DateTime(2026, 12, 31)));
      expect(InvoicePeriodPreset.lastYear.range(now), (DateTime(2025), DateTime(2025, 12, 31)));
    });
  });

  group('InvoicesCsvService', () {
    test('BOM, separador ; y coma decimal', () {
      final bytes = const InvoicesCsvService().generate([
        buildInvoice(number: 'F-2026/0001', issueDate: DateTime(2026, 3, 5), base: 100),
      ]);

      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
      final lines = utf8.decode(bytes.sublist(3)).trim().split('\n');
      expect(lines, hasLength(2));
      expect(lines.first, startsWith('Nº factura;Fecha emisión;Cliente'));
      expect(lines[1], contains('F-2026/0001;05/03/2026;JUAN PÉREZ;12345678Z'));
      expect(lines[1], endsWith('100,00;10,00;10,00;110,00'));
    });

    test('entrecomilla los campos con ; o comillas', () {
      final bytes = const InvoicesCsvService().generate([
        buildInvoice(
          number: 'F-1',
          issueDate: DateTime(2026, 3, 5),
          clientName: 'Acme; "Hoteles"',
        ),
      ]);
      final text = utf8.decode(bytes.sublist(3));
      expect(text, contains('"ACME; ""HOTELES"""'));
    });
  });

  group('InvoicePdfService por lotes', () {
    final invoices = [
      buildInvoice(number: 'F-1', issueDate: DateTime(2026, 3, 5)),
      buildInvoice(number: 'F-2', issueDate: DateTime(2026, 3, 6), status: InvoiceStatus.paid),
      buildInvoice(number: 'F-3', issueDate: DateTime(2026, 4, 1), status: InvoiceStatus.cancelled),
    ];

    test('1 factura por página + portada', () async {
      final bytes = await InvoicePdfService().generateInvoicesBatchPdf(
        invoices,
        start: DateTime(2026, 3),
        end: DateTime(2026, 4, 30),
      );
      expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
      expect(_pageCount(bytes), 4);
    });

    test('sin portada: tantas páginas como facturas', () async {
      final bytes = await InvoicePdfService().generateInvoicesBatchPdf(
        invoices,
        start: DateTime(2026, 3),
        end: DateTime(2026, 4, 30),
        includeSummary: false,
      );
      expect(_pageCount(bytes), 3);
    });

    test('lista vacía lanza ArgumentError', () {
      expect(
        () => InvoicePdfService().generateInvoicesBatchPdf(
          const [],
          start: DateTime(2026, 3),
          end: DateTime(2026, 4, 30),
        ),
        throwsArgumentError,
      );
    });

    test('el listado PDF se genera', () async {
      final bytes = await InvoicePdfService().generateInvoicesListPdf(
        invoices,
        start: DateTime(2026, 3),
        end: DateTime(2026, 4, 30),
      );
      expect(_pageCount(bytes), greaterThanOrEqualTo(1));
    });
  });
}
