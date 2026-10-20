import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/invoice_entity.dart';

/// Genera el listado de facturas en CSV compatible con Excel en español
/// (separador `;`, coma decimal y BOM UTF-8 para que se vean los acentos).
class InvoicesCsvService {
  const InvoicesCsvService();

  static const _separator = ';';
  static const _headers = [
    'Nº factura',
    'Fecha emisión',
    'Cliente',
    'NIF',
    'Concepto',
    'Reserva',
    'Estado',
    'Base imponible',
    'IVA %',
    'IVA',
    'Total',
  ];

  Uint8List generate(List<InvoiceEntity> invoices) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final buffer = StringBuffer()..writeln(_headers.map(_escape).join(_separator));

    for (final invoice in invoices) {
      final row = [
        invoice.invoiceNumber,
        dateFormat.format(invoice.issueDate),
        invoice.clientName.toUpperCase(),
        invoice.clientNif ?? '',
        invoice.concept,
        invoice.bookingCode ?? '',
        invoice.status.label,
        _amount(invoice.taxBase),
        _amount(invoice.taxRate),
        _amount(invoice.taxAmount),
        _amount(invoice.totalIncludingTax),
      ];
      buffer.writeln(row.map(_escape).join(_separator));
    }

    // BOM UTF-8 para que Excel detecte la codificación
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(buffer.toString())]);
  }

  String _amount(double value) => value.toStringAsFixed(2).replaceAll('.', ',');

  String _escape(String value) {
    final needsQuotes = value.contains(_separator) ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}
