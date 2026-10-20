import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/invoices_repository.dart';
import '../../data/services/invoice_pdf_service.dart';
import '../../data/services/invoices_csv_service.dart';
import 'invoices_period_event.dart';
import 'invoices_period_state.dart';

/// Facturas de un periodo: listado con totales y exportación
/// (PDF con todas las facturas, PDF del listado o CSV).
class InvoicesPeriodBloc extends Bloc<InvoicesPeriodEvent, InvoicesPeriodState> {
  InvoicesPeriodBloc({
    required InvoicesRepository repository,
    required DateTime start,
    required DateTime end,
    InvoicePdfService? pdfService,
    InvoicesCsvService? csvService,
  })  : _repository = repository,
        _pdfService = pdfService ?? InvoicePdfService(),
        _csvService = csvService ?? const InvoicesCsvService(),
        super(InvoicesPeriodState(start: start, end: end)) {
    on<InvoicesPeriodLoadRequested>(_onLoadRequested);
    on<InvoicesPeriodRangeChanged>(_onRangeChanged);
    on<InvoicesPeriodStatusToggled>(_onStatusToggled);
    on<InvoicesPeriodPropertyChanged>(_onPropertyChanged);
    on<InvoicesPeriodSummaryToggled>(_onSummaryToggled);
    on<InvoicesPeriodExportRequested>(_onExportRequested);
    on<InvoicesPeriodExportConsumed>(_onExportConsumed);
  }

  final InvoicesRepository _repository;
  final InvoicePdfService _pdfService;
  final InvoicesCsvService _csvService;

  /// Evita que una respuesta lenta de un filtro anterior pise a la última
  int _requestId = 0;

  Future<void> _onLoadRequested(
    InvoicesPeriodLoadRequested event,
    Emitter<InvoicesPeriodState> emit,
  ) =>
      _load(emit);

  Future<void> _onRangeChanged(
    InvoicesPeriodRangeChanged event,
    Emitter<InvoicesPeriodState> emit,
  ) async {
    // Si el usuario invierte las fechas se corrige el orden
    final swap = event.end.isBefore(event.start);
    emit(state.copyWith(
      start: swap ? event.end : event.start,
      end: swap ? event.start : event.end,
    ));
    await _load(emit);
  }

  Future<void> _onStatusToggled(
    InvoicesPeriodStatusToggled event,
    Emitter<InvoicesPeriodState> emit,
  ) async {
    final statuses = {...state.statuses};
    if (!statuses.remove(event.status)) statuses.add(event.status);
    // Al menos un estado: si se desmarcan todos no tendría sentido la consulta
    if (statuses.isEmpty) return;
    emit(state.copyWith(statuses: statuses));
    await _load(emit);
  }

  Future<void> _onPropertyChanged(
    InvoicesPeriodPropertyChanged event,
    Emitter<InvoicesPeriodState> emit,
  ) async {
    emit(event.propertyId == null
        ? state.copyWith(clearProperty: true)
        : state.copyWith(
            propertyId: event.propertyId,
            propertyName: event.propertyName,
          ));
    await _load(emit);
  }

  void _onSummaryToggled(
    InvoicesPeriodSummaryToggled event,
    Emitter<InvoicesPeriodState> emit,
  ) {
    emit(state.copyWith(includeSummary: event.includeSummary));
  }

  Future<void> _load(Emitter<InvoicesPeriodState> emit) async {
    final requestId = ++_requestId;
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final invoices = await _repository.getByIssueDateRange(
        start: state.start,
        end: state.end,
        statuses: state.statuses,
        propertyId: state.propertyId,
      );
      if (requestId != _requestId) return;
      emit(state.copyWith(invoices: invoices, isLoading: false, hasLoaded: true));
    } catch (e) {
      if (requestId != _requestId) return;
      debugPrint('🔴 [InvoicesPeriodBloc] Error cargando periodo: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'No se pudieron cargar las facturas del periodo: $e',
      ));
    }
  }

  Future<void> _onExportRequested(
    InvoicesPeriodExportRequested event,
    Emitter<InvoicesPeriodState> emit,
  ) async {
    if (state.isExporting || state.invoices.isEmpty) return;
    emit(state.copyWith(exportingFormat: event.format, clearError: true));

    try {
      final file = await _buildFile(event.format, event.action);
      emit(state.copyWith(pendingExport: file, clearExporting: true));
    } catch (e) {
      debugPrint('🔴 [InvoicesPeriodBloc] Error exportando: $e');
      emit(state.copyWith(
        clearExporting: true,
        error: 'No se pudo generar el archivo: $e',
      ));
    }
  }

  Future<PeriodExportFile> _buildFile(
    PeriodExportFormat format,
    PeriodExportAction action,
  ) async {
    final suffix = state.fileSuffix;
    switch (format) {
      case PeriodExportFormat.invoicesPdf:
        return PeriodExportFile(
          bytes: await _pdfService.generateInvoicesBatchPdf(
            state.invoices,
            start: state.start,
            end: state.end,
            includeSummary: state.includeSummary,
            propertyName: state.propertyName,
          ),
          fileName: 'Facturas_$suffix.pdf',
          mimeType: 'application/pdf',
          action: action,
        );
      case PeriodExportFormat.listPdf:
        return PeriodExportFile(
          bytes: await _pdfService.generateInvoicesListPdf(
            state.invoices,
            start: state.start,
            end: state.end,
            propertyName: state.propertyName,
          ),
          fileName: 'Listado_facturas_$suffix.pdf',
          mimeType: 'application/pdf',
          action: action,
        );
      case PeriodExportFormat.csv:
        // El CSV no se imprime: siempre se comparte/descarga
        return PeriodExportFile(
          bytes: _csvService.generate(state.invoices),
          fileName: 'Listado_facturas_$suffix.csv',
          mimeType: 'text/csv',
          action: PeriodExportAction.share,
        );
    }
  }

  void _onExportConsumed(
    InvoicesPeriodExportConsumed event,
    Emitter<InvoicesPeriodState> emit,
  ) {
    emit(state.copyWith(clearPendingExport: true, clearError: true));
  }
}
