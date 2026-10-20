import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../domain/entities/admin_entities.dart';
import '../../../domain/bloc/admin_dashboard_state.dart';

/// Servicio para generar PDFs de reservas filtradas (fondo blanco para impresión)
class BookingsPdfService {
  // Colores corporativos BF Stay (tema claro para impresión)
  static const _colorGold = PdfColor(0.831, 0.686, 0.216); // #D4AF37
  static const _colorGoldLight = PdfColor(0.898, 0.788, 0.384); // #E5C962
  static const _colorBlack = PdfColor(0.11, 0.11, 0.11); // #1C1C1C
  static const _colorWhite = PdfColors.white;
  static const _colorTextSoft = PdfColor(0.4, 0.4, 0.4);
  static const _colorBorder = PdfColor(0.88, 0.88, 0.88); // #E0E0E0
  static const _colorRowAlt = PdfColor(0.97, 0.97, 0.97); // #F7F7F7
  static const _colorGreen = PdfColor(0.2, 0.6, 0.2);
  static const _colorRed = PdfColor(0.75, 0.2, 0.2);

  pw.Font _regularFont = pw.Font.helvetica();
  pw.Font _boldFont = pw.Font.helvetica();
  pw.MemoryImage? _logoImage;

  Future<void> _loadFonts() async {
    try {
      final regularFontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final boldFontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      _regularFont = pw.Font.ttf(regularFontData);
      _boldFont = pw.Font.ttf(boldFontData);
    } catch (e) {
      debugPrint('Error cargando fuentes locales: $e');
      try {
        _regularFont = await PdfGoogleFonts.robotoRegular();
        _boldFont = await PdfGoogleFonts.robotoBold();
      } catch (_) {
        debugPrint('Usando Helvetica como fallback');
      }
    }
  }

  Future<void> _loadLogo() async {
    if (_logoImage != null) return;
    try {
      final byteData = await rootBundle.load('assets/icons/logoBF.png');
      _logoImage = pw.MemoryImage(byteData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error cargando logo: $e');
      _logoImage = null;
    }
  }

  pw.TextStyle _regular({double? fontSize, PdfColor? color}) => pw.TextStyle(
        font: _regularFont,
        fontSize: fontSize ?? 8,
        color: color ?? _colorBlack,
      );

  pw.TextStyle _bold({double? fontSize, PdfColor? color}) => pw.TextStyle(
        font: _boldFont,
        fontWeight: pw.FontWeight.bold,
        fontSize: fontSize ?? 8,
        color: color ?? _colorBlack,
      );

  /// Genera el PDF de reservas filtradas
  Future<Uint8List> generateBookingsPdf({
    required List<AdminBookingEntity> bookings,
    required DateFilter dateFilter,
    required DateTime? customDateStart,
    required DateTime? customDateEnd,
    String? statusFilter,
  }) async {
    await _loadFonts();
    await _loadLogo();

    final pdf = pw.Document(
      title: 'Informe de Reservas - BF Stay',
      author: 'Grupo Hotelero BF',
      creator: 'BF Stay',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(12 * PdfPageFormat.mm),
        build: (context) => [
          _buildHeader(dateFilter, customDateStart, customDateEnd, statusFilter),
          pw.SizedBox(height: 16),
          _buildSummary(bookings),
          pw.SizedBox(height: 16),
          ..._buildBookingsTable(bookings),
          pw.SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(
    DateFilter dateFilter,
    DateTime? customDateStart,
    DateTime? customDateEnd,
    String? statusFilter,
  ) {
    final now = DateTime.now();
    final generatedAt = DateFormat('dd/MM/yyyy \'a las\' HH:mm').format(now);

    String filterLabel = _getFilterLabel(dateFilter, customDateStart, customDateEnd);
    if (statusFilter != null && statusFilter != 'all') {
      final statusLabels = {
        'confirmed': 'Confirmadas',
        'active': 'Activas',
        'in_house': 'En casa',
        'checked_out': 'Finalizadas',
        'cancelled': 'Canceladas',
      };
      filterLabel += ' | ${statusLabels[statusFilter] ?? statusFilter}';
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: _colorWhite,
        border: pw.Border.all(color: _colorBorder),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 60,
            height: 60,
            child: _logoImage != null
                ? pw.Image(_logoImage!, fit: pw.BoxFit.contain)
                : pw.Center(
                    child: pw.Text('BF',
                        style: _bold(fontSize: 28, color: _colorGold)),
                  ),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('INFORME DE RESERVAS',
                    style: _bold(fontSize: 22, color: _colorGold)),
                pw.SizedBox(height: 4),
                pw.Text('BF Stay - Grupo Hotelero BF',
                    style: _regular(fontSize: 11, color: _colorTextSoft)),
                pw.SizedBox(height: 12),
                pw.Container(height: 1, color: _colorGold),
                pw.SizedBox(height: 8),
                pw.Text('Filtros aplicados: $filterLabel',
                    style: _regular(fontSize: 9, color: _colorBlack)),
                pw.SizedBox(height: 4),
                pw.Text('Generado: $generatedAt',
                    style: _regular(fontSize: 8, color: _colorTextSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummary(List<AdminBookingEntity> bookings) {
    final total = bookings.length;
    final confirmed = bookings.where((b) => b.bookingStatus.toDbString() == 'confirmed').length;
    final active = bookings.where((b) => b.bookingStatus.toDbString() == 'active').length;
    final inHouse = bookings.where((b) => b.bookingStatus.toDbString() == 'in_house').length;
    final checkedOut = bookings.where((b) => b.bookingStatus.toDbString() == 'checked_out').length;
    final cancelled = bookings.where((b) => b.bookingStatus.toDbString() == 'cancelled').length;

    final withCheckin = bookings.where((b) => b.checkinStatus == 'validated').length;
    final nonCancelled = total - cancelled;
    final checkinPercent = nonCancelled > 0 ? ((withCheckin / nonCancelled) * 100).round() : 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _colorWhite,
        border: pw.Border.all(color: _colorBorder),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('RESUMEN',
              style: _bold(fontSize: 10, color: _colorGold)),
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _buildSummaryItem('Total', '$total', _colorBlack),
              _buildSummaryItem('Confirmadas', '$confirmed', _colorGold),
              _buildSummaryItem('Activas', '$active', _colorGreen),
              _buildSummaryItem('En casa', '$inHouse', _colorGoldLight),
              _buildSummaryItem('Finalizadas', '$checkedOut', _colorTextSoft),
              _buildSummaryItem('Canceladas', '$cancelled', _colorRed),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(height: 1, color: _colorBorder),
          pw.SizedBox(height: 8),
          pw.Text(
            'Check-in completado: $withCheckin/$nonCancelled ($checkinPercent%)',
            style: _bold(fontSize: 9, color: _colorGold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('$label: ', style: _regular(fontSize: 8, color: _colorTextSoft)),
        pw.Text(value, style: _bold(fontSize: 9, color: color)),
      ],
    );
  }

  List<pw.Widget> _buildBookingsTable(List<AdminBookingEntity> bookings) {
    final columnWidths = const {
      0: pw.FlexColumnWidth(0.6),
      1: pw.FlexColumnWidth(2.5),
      2: pw.FlexColumnWidth(1.8),
      3: pw.FlexColumnWidth(1.2),
      4: pw.FlexColumnWidth(1.2),
      5: pw.FlexColumnWidth(1.4),
      6: pw.FlexColumnWidth(1.2),
      7: pw.FlexColumnWidth(0.6),
    };

    final headerRow = pw.TableRow(
      decoration: const pw.BoxDecoration(color: _colorGold),
      children: [
        _buildTh('#'),
        _buildTh('Huesped'),
        _buildTh('Unidad'),
        _buildTh('Entrada', center: true),
        _buildTh('Salida', center: true),
        _buildTh('Codigo', center: true),
        _buildTh('Estado', center: true),
        _buildTh('CK', center: true),
      ],
    );

    final dataRows = bookings.asMap().entries.map((entry) {
      final i = entry.key;
      final b = entry.value;
      final bgColor = i.isEven ? _colorWhite : _colorRowAlt;
      return pw.TableRow(
        decoration: pw.BoxDecoration(color: bgColor),
        children: [
          _buildTd('${i + 1}'),
          _buildTd(b.guestFullName),
          _buildTd(b.unitName),
          _buildTd(DateFormat('dd/MM/yy').format(b.checkInDate), center: true),
          _buildTd(DateFormat('dd/MM/yy').format(b.checkOutDate), center: true),
          _buildTd(b.bookingCode, center: true),
          _buildTd(_statusLabel(b.bookingStatus.toDbString()), center: true),
          _buildCheckinCell(b.checkinStatus == 'validated'),
        ],
      );
    }).toList();

    return [
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _colorBorder),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Table(
          columnWidths: columnWidths,
          border: pw.TableBorder(
            horizontalInside: const pw.BorderSide(color: _colorBorder),
          ),
          children: [headerRow, ...dataRows],
        ),
      ),
    ];
  }

  pw.Widget _buildTh(String text, {bool center = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      child: pw.Text(
        text,
        style: _bold(fontSize: 7, color: _colorWhite),
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildTd(String text, {bool center = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: pw.Text(
        text,
        style: _regular(fontSize: 7, color: _colorBlack),
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildCheckinCell(bool checkinValidated) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: pw.Text(
        checkinValidated ? 'SI' : 'NO',
        style: _bold(
          fontSize: 7,
          color: checkinValidated ? _colorGreen : _colorRed,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildLegend() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _colorBorder),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Text('SI ', style: _bold(fontSize: 7, color: _colorGreen)),
              pw.Text('= Check-in completo',
                  style: _regular(fontSize: 7, color: _colorTextSoft)),
              pw.SizedBox(width: 16),
              pw.Text('NO ', style: _bold(fontSize: 7, color: _colorRed)),
              pw.Text('= Sin check-in',
                  style: _regular(fontSize: 7, color: _colorTextSoft)),
            ],
          ),
          pw.Text(
            '© BF Stay ${DateTime.now().year}',
            style: _regular(fontSize: 7, color: _colorTextSoft),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(
    DateFilter dateFilter,
    DateTime? customDateStart,
    DateTime? customDateEnd,
  ) {
    final now = DateTime.now();
    final fmt = DateFormat('dd/MM/yyyy');
    final fmtMonth = DateFormat('MMMM yyyy', 'es_ES');

    switch (dateFilter) {
      case DateFilter.all:
        return 'Todas las fechas';
      case DateFilter.allHistory:
        return 'Histórico completo';
      case DateFilter.today:
        return 'Hoy (${fmt.format(now)})';
      case DateFilter.yesterday:
        final y = now.subtract(const Duration(days: 1));
        return 'Ayer (${fmt.format(y)})';
      case DateFilter.thisWeek:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return 'Semana ${fmt.format(monday)} - ${fmt.format(sunday)}';
      case DateFilter.thisMonth:
        return 'Mes de ${fmtMonth.format(now)}';
      case DateFilter.lastMonth:
        final last = DateTime(now.year, now.month - 1);
        return 'Mes de ${fmtMonth.format(last)}';
      case DateFilter.customRange:
        if (customDateStart != null && customDateEnd != null) {
          return '${fmt.format(customDateStart)} - ${fmt.format(customDateEnd)}';
        }
        return 'Rango personalizado';
    }
  }

  String _statusLabel(String status) {
    return switch (status) {
      'created' => 'Creada',
      'confirmed' => 'Confirmada',
      'active' => 'Activa',
      'in_house' => 'En casa',
      'checked_out' => 'Finalizada',
      'closed' => 'Cerrada',
      'cancelled' => 'Cancelada',
      _ => status,
    };
  }

  /// Abre el diálogo de impresión/guardado
  Future<void> printBookingsReport({
    required List<AdminBookingEntity> bookings,
    required DateFilter dateFilter,
    required DateTime? customDateStart,
    required DateTime? customDateEnd,
    String? statusFilter,
  }) async {
    final pdfBytes = await generateBookingsPdf(
      bookings: bookings,
      dateFilter: dateFilter,
      customDateStart: customDateStart,
      customDateEnd: customDateEnd,
      statusFilter: statusFilter,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Informe_Reservas_BFStay',
    );
  }
}
