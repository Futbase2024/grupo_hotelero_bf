import '../entities/admin_entities.dart';

/// Contrato del repositorio de facturas
abstract class InvoicesRepository {
  /// Obtiene todas las facturas
  Future<List<InvoiceEntity>> getAll();

  /// Obtiene facturas filtradas por estado
  Future<List<InvoiceEntity>> getByStatus(InvoiceStatus status);

  /// Obtiene facturas filtradas por propiedad
  Future<List<InvoiceEntity>> getByPropertyId(String propertyId);

  /// Obtiene una factura por ID
  Future<InvoiceEntity?> getById(String id);

  /// Obtiene facturas de una reserva
  Future<List<InvoiceEntity>> getByBookingId(String bookingId);

  /// Crea una nueva factura (estado draft)
  Future<InvoiceEntity> create(InvoiceEntity invoice);

  /// Actualiza una factura existente
  Future<InvoiceEntity> update(InvoiceEntity invoice);

  /// Emite una factura (cambia de draft a issued)
  Future<InvoiceEntity> issue(String invoiceId);

  /// Marca una factura como pagada
  Future<InvoiceEntity> markAsPaid(String invoiceId);

  /// Cancela una factura
  Future<InvoiceEntity> cancel(String invoiceId, String reason);

  /// Elimina una factura (solo en estado draft)
  Future<void> delete(String invoiceId);

  /// Busca facturas por número, cliente o concepto
  Future<List<InvoiceEntity>> search(String query);

  /// Genera un nuevo número de factura
  Future<String> generateInvoiceNumber();
}
