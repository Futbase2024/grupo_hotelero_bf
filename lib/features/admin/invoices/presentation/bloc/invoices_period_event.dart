import 'package:equatable/equatable.dart';
import '../../../domain/entities/invoice_entity.dart';
import 'invoices_period_state.dart';

abstract class InvoicesPeriodEvent extends Equatable {
  const InvoicesPeriodEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar las facturas del periodo con los filtros actuales
class InvoicesPeriodLoadRequested extends InvoicesPeriodEvent {
  const InvoicesPeriodLoadRequested();
}

/// Cambiar el rango de fechas (recarga automáticamente)
class InvoicesPeriodRangeChanged extends InvoicesPeriodEvent {
  const InvoicesPeriodRangeChanged({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  List<Object?> get props => [start, end];
}

/// Incluir/excluir un estado (recarga automáticamente)
class InvoicesPeriodStatusToggled extends InvoicesPeriodEvent {
  const InvoicesPeriodStatusToggled(this.status);

  final InvoiceStatus status;

  @override
  List<Object?> get props => [status];
}

/// Filtrar por alojamiento; null = todos (recarga automáticamente)
class InvoicesPeriodPropertyChanged extends InvoicesPeriodEvent {
  const InvoicesPeriodPropertyChanged({this.propertyId, this.propertyName});

  final String? propertyId;
  final String? propertyName;

  @override
  List<Object?> get props => [propertyId, propertyName];
}

/// Activar/desactivar la portada de resumen del PDF por lotes
class InvoicesPeriodSummaryToggled extends InvoicesPeriodEvent {
  const InvoicesPeriodSummaryToggled(this.includeSummary);

  final bool includeSummary;

  @override
  List<Object?> get props => [includeSummary];
}

/// Generar un archivo del periodo (PDF de facturas, PDF de listado o CSV)
class InvoicesPeriodExportRequested extends InvoicesPeriodEvent {
  const InvoicesPeriodExportRequested({
    required this.format,
    required this.action,
  });

  final PeriodExportFormat format;
  final PeriodExportAction action;

  @override
  List<Object?> get props => [format, action];
}

/// La UI ya ha impreso/compartido el archivo generado
class InvoicesPeriodExportConsumed extends InvoicesPeriodEvent {
  const InvoicesPeriodExportConsumed();
}
