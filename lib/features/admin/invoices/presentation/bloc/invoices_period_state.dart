import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/invoice_entity.dart';

/// Qué se genera a partir de las facturas del periodo
enum PeriodExportFormat {
  /// Un PDF con todas las facturas (1 por página)
  invoicesPdf,

  /// Un PDF con la tabla del listado
  listPdf,

  /// CSV del listado para Excel/gestoría
  csv,
}

/// Qué se hace con el archivo generado
enum PeriodExportAction { print, share }

/// Archivo generado pendiente de que la UI lo imprima o comparta
class PeriodExportFile extends Equatable {
  const PeriodExportFile({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    required this.action,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  final PeriodExportAction action;

  bool get isPdf => mimeType == 'application/pdf';

  @override
  List<Object?> get props => [fileName, mimeType, action, bytes.length];
}

class InvoicesPeriodState extends Equatable {
  const InvoicesPeriodState({
    required this.start,
    required this.end,
    this.statuses = defaultStatuses,
    this.propertyId,
    this.propertyName,
    this.includeSummary = true,
    this.invoices = const [],
    this.isLoading = false,
    this.hasLoaded = false,
    this.exportingFormat,
    this.pendingExport,
    this.error,
  });

  /// Por defecto solo las facturas fiscalmente válidas
  static const defaultStatuses = {InvoiceStatus.issued, InvoiceStatus.paid};

  /// A partir de este número se avisa de que el PDF puede tardar
  static const largeBatchThreshold = 150;

  final DateTime start;
  final DateTime end;
  final Set<InvoiceStatus> statuses;
  final String? propertyId;
  final String? propertyName;
  final bool includeSummary;
  final List<InvoiceEntity> invoices;
  final bool isLoading;
  final bool hasLoaded;
  final PeriodExportFormat? exportingFormat;
  final PeriodExportFile? pendingExport;
  final String? error;

  bool get isExporting => exportingFormat != null;
  bool get isEmpty => hasLoaded && invoices.isEmpty;
  bool get isLargeBatch => invoices.length > largeBatchThreshold;

  int get count => invoices.length;

  double get totalBase => invoices.fold(0.0, (sum, i) => sum + i.taxBase);
  double get totalTax => invoices.fold(0.0, (sum, i) => sum + i.taxAmount);
  double get totalAmount => invoices.fold(0.0, (sum, i) => sum + i.totalIncludingTax);

  int countByStatus(InvoiceStatus status) =>
      invoices.where((i) => i.status == status).length;

  /// Importe emitido pendiente de cobro
  double get totalPending => invoices
      .where((i) => i.status == InvoiceStatus.issued)
      .fold(0.0, (sum, i) => sum + i.totalIncludingTax);

  /// Facturas agrupadas por mes de emisión (meses en orden cronológico,
  /// facturas en el orden de numeración que devuelve el repositorio)
  Map<DateTime, List<InvoiceEntity>> get invoicesByMonth {
    final map = <DateTime, List<InvoiceEntity>>{};
    for (final invoice in invoices) {
      final month = DateTime(invoice.issueDate.year, invoice.issueDate.month);
      map.putIfAbsent(month, () => []).add(invoice);
    }
    final months = map.keys.toList()..sort();
    return {for (final m in months) m: map[m]!};
  }

  /// Sufijo de los nombres de archivo: 2026-03-01_a_2026-07-31
  String get fileSuffix => '${_isoDate(start)}_a_${_isoDate(end)}';

  static String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  InvoicesPeriodState copyWith({
    DateTime? start,
    DateTime? end,
    Set<InvoiceStatus>? statuses,
    String? propertyId,
    String? propertyName,
    bool? includeSummary,
    List<InvoiceEntity>? invoices,
    bool? isLoading,
    bool? hasLoaded,
    PeriodExportFormat? exportingFormat,
    PeriodExportFile? pendingExport,
    String? error,
    bool clearProperty = false,
    bool clearExporting = false,
    bool clearPendingExport = false,
    bool clearError = false,
  }) {
    return InvoicesPeriodState(
      start: start ?? this.start,
      end: end ?? this.end,
      statuses: statuses ?? this.statuses,
      propertyId: clearProperty ? null : (propertyId ?? this.propertyId),
      propertyName: clearProperty ? null : (propertyName ?? this.propertyName),
      includeSummary: includeSummary ?? this.includeSummary,
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      exportingFormat: clearExporting ? null : (exportingFormat ?? this.exportingFormat),
      pendingExport: clearPendingExport ? null : (pendingExport ?? this.pendingExport),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        start,
        end,
        statuses,
        propertyId,
        propertyName,
        includeSummary,
        invoices,
        isLoading,
        hasLoaded,
        exportingFormat,
        pendingExport,
        error,
      ];
}
