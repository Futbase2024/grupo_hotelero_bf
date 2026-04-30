import 'package:equatable/equatable.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../../domain/entities/client_entity.dart';

abstract class InvoicesEvent extends Equatable {
  const InvoicesEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar todas las facturas
class InvoicesLoadRequested extends InvoicesEvent {
  const InvoicesLoadRequested();
}

/// Refrescar lista de facturas
class InvoicesRefreshRequested extends InvoicesEvent {
  const InvoicesRefreshRequested();
}

/// Cambiar filtro de estado
class InvoicesFilterChanged extends InvoicesEvent {
  const InvoicesFilterChanged(this.status);

  final InvoiceStatus? status;

  @override
  List<Object?> get props => [status];
}

/// Cambiar búsqueda
class InvoicesSearchChanged extends InvoicesEvent {
  const InvoicesSearchChanged(this.query);

  final String? query;

  @override
  List<Object?> get props => [query];
}

/// Crear nueva factura
class InvoiceCreateRequested extends InvoicesEvent {
  const InvoiceCreateRequested(this.invoice);

  final InvoiceEntity invoice;

  @override
  List<Object?> get props => [invoice];
}

/// Actualizar factura existente
class InvoiceUpdateRequested extends InvoicesEvent {
  const InvoiceUpdateRequested(this.invoice);

  final InvoiceEntity invoice;

  @override
  List<Object?> get props => [invoice];
}

/// Emitir factura (cambiar de draft a issued)
class InvoiceIssueRequested extends InvoicesEvent {
  const InvoiceIssueRequested(this.invoiceId);

  final String invoiceId;

  @override
  List<Object?> get props => [invoiceId];
}

/// Marcar factura como pagada
class InvoiceMarkPaidRequested extends InvoicesEvent {
  const InvoiceMarkPaidRequested(this.invoiceId);

  final String invoiceId;

  @override
  List<Object?> get props => [invoiceId];
}

/// Cancelar factura
class InvoiceCancelRequested extends InvoicesEvent {
  const InvoiceCancelRequested(this.invoiceId, this.reason);

  final String invoiceId;
  final String reason;

  @override
  List<Object?> get props => [invoiceId, reason];
}

/// Eliminar factura (solo borradores)
class InvoiceDeleteRequested extends InvoicesEvent {
  const InvoiceDeleteRequested(this.invoiceId);

  final String invoiceId;

  @override
  List<Object?> get props => [invoiceId];
}

/// Seleccionar factura para ver detalle
class InvoiceSelected extends InvoicesEvent {
  const InvoiceSelected(this.invoice);

  final InvoiceEntity invoice;

  @override
  List<Object?> get props => [invoice];
}

/// Limpiar selección de factura
class InvoiceSelectionCleared extends InvoicesEvent {
  const InvoiceSelectionCleared();
}

/// Cargar reservas disponibles para crear factura
class InvoicesLoadBookingsRequested extends InvoicesEvent {
  const InvoicesLoadBookingsRequested();
}

/// Cargar propiedades disponibles para crear factura manual
class InvoicesLoadPropertiesRequested extends InvoicesEvent {
  const InvoicesLoadPropertiesRequested();
}

/// Cargar clientes guardados
class InvoicesLoadClientsRequested extends InvoicesEvent {
  const InvoicesLoadClientsRequested();
}

/// Buscar clientes por texto
class InvoicesSearchClients extends InvoicesEvent {
  const InvoicesSearchClients(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Guardar cliente desde datos de factura
class InvoicesSaveClient extends InvoicesEvent {
  const InvoicesSaveClient(this.client);

  final ClientEntity client;

  @override
  List<Object?> get props => [client];
}
