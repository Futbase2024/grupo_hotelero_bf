import 'package:bf_stay/features/admin/domain/entities/invoice_entity.dart';

/// Factura mínima para tests con importes coherentes (IVA 10 %)
InvoiceEntity buildInvoice({
  required String number,
  required DateTime issueDate,
  InvoiceStatus status = InvoiceStatus.issued,
  double base = 100,
  String clientName = 'Juan Pérez',
  String? clientNif = '12345678Z',
}) {
  final tax = base * 0.10;
  return InvoiceEntity(
    id: 'id-$number',
    invoiceNumber: number,
    propertyId: 'prop-1',
    issuerName: 'BANFERRA JEREZ 2020 S.L.',
    issuerNif: 'B02919355',
    clientName: clientName,
    clientNif: clientNif,
    issueDate: issueDate,
    concept: 'Alojamiento',
    lineItems: [
      InvoiceLineItem(description: 'Noche', quantity: 1, unitPrice: base),
    ],
    subtotalExcludingTax: base,
    taxBase: base,
    taxRate: 10,
    taxAmount: tax,
    totalIncludingTax: base + tax,
    status: status,
    createdAt: issueDate,
  );
}
