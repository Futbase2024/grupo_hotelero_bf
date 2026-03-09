import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../domain/entities/invoice_entity.dart';

/// Servicio para generar PDFs de facturas con soporte Unicode completo
class InvoicePdfService {
  // Colores del diseño
  static const _colorBlack = PdfColor(0.067, 0.067, 0.067);
  static const _colorDark = PdfColor(0.110, 0.110, 0.110);
  static const _colorGold = PdfColor(0.69, 0.553, 0.341);
  static const _colorGoldSoft = PdfColor(0.839, 0.757, 0.627);
  static const _colorSilver = PdfColor(0.749, 0.769, 0.788);
  static const _colorBorder = PdfColor(0.851, 0.851, 0.851);
  static const _colorLight = PdfColor(0.969, 0.969, 0.969);
  static const _colorTextSoft = PdfColor(0.4, 0.4, 0.4);
  static const _colorRowDivider = PdfColor(0.94, 0.94, 0.94);
  static const _colorGoldBg = PdfColor(0.95, 0.93, 0.90);

  // Fuentes cargadas para soporte Unicode - inicializadas con helvetica como fallback
  pw.Font _regularFont = pw.Font.helvetica();
  pw.Font _boldFont = pw.Font.helvetica();

  // Logo cargado para el PDF
  pw.MemoryImage? _logoImage;

  /// Carga las fuentes TTF locales que soportan Unicode (acentos, n, etc.)
  Future<void> _loadFonts() async {
    bool fontsLoaded = false;

    // Intentar cargar fuentes locales primero (no requieren internet)
    try {
      final regularFontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final boldFontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');

      _regularFont = pw.Font.ttf(regularFontData);
      _boldFont = pw.Font.ttf(boldFontData);
      fontsLoaded = true;
      debugPrint('✅ Fuentes Roboto cargadas desde assets locales');
    } catch (e) {
      debugPrint('⚠️ Error cargando fuentes locales: $e');
    }

    // Fallback: intentar con fuentes de Google (requiere internet)
    if (!fontsLoaded) {
      try {
        _regularFont = await PdfGoogleFonts.robotoRegular();
        _boldFont = await PdfGoogleFonts.robotoBold();
        fontsLoaded = true;
        debugPrint('✅ Fuentes cargadas desde Google Fonts');
      } catch (e) {
        debugPrint('⚠️ Error cargando fuentes Google: $e');
      }
    }

    // Si no se pudieron cargar fuentes, helvetica ya está asignado por defecto
    if (!fontsLoaded) {
      debugPrint('⚠️ Usando Helvetica como fallback (no soporta acentos)');
    }
  }

  /// Carga el logo desde los assets
  Future<void> _loadLogo() async {
    if (_logoImage != null) return;

    try {
      final ByteData byteData = await rootBundle.load('assets/images/logo_factura.png');
      final Uint8List logoBytes = byteData.buffer.asUint8List();
      _logoImage = pw.MemoryImage(logoBytes);
      debugPrint('Logo cargado correctamente para el PDF');
    } catch (e) {
      debugPrint('Error cargando logo: $e');
      _logoImage = null;
    }
  }

  /// Obtiene el estilo de texto regular
  pw.TextStyle _regularStyle({double? fontSize, PdfColor? color, double? letterSpacing}) {
    return pw.TextStyle(
      font: _regularFont,
      fontSize: fontSize ?? 8,
      color: color ?? _colorBlack,
      letterSpacing: letterSpacing,
    );
  }

  /// Obtiene el estilo de texto en negrita
  pw.TextStyle _boldStyle({double? fontSize, PdfColor? color, double? letterSpacing}) {
    return pw.TextStyle(
      font: _boldFont,
      fontSize: fontSize ?? 8,
      fontWeight: pw.FontWeight.bold,
      color: color ?? _colorBlack,
      letterSpacing: letterSpacing,
    );
  }

  /// Genera el PDF de la factura
  Future<Uint8List> generateInvoicePdf(InvoiceEntity invoice) async {
    debugPrint('📄 [PDF] Iniciando generación de factura: ${invoice.invoiceNumber}');

    try {
      // Cargar fuentes y logo antes de generar el PDF
      debugPrint('📄 [PDF] Cargando fuentes...');
      await _loadFonts();
      debugPrint('📄 [PDF] Cargando logo...');
      await _loadLogo();
      debugPrint('📄 [PDF] Fuentes y logo cargados');

      final pdf = pw.Document(
        title: 'Factura ${invoice.invoiceNumber}',
        author: 'Grupo Hotelero BF',
        creator: 'BF Stay',
      );

      debugPrint('📄 [PDF] Construyendo contenido...');
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(12 * PdfPageFormat.mm),
          build: (context) => _buildPageContent(invoice),
        ),
      );

      debugPrint('📄 [PDF] Guardando PDF en bytes...');
      final bytes = await pdf.save();
      debugPrint('✅ [PDF] PDF generado correctamente - ${bytes.length} bytes');
      return bytes;
    } catch (e, stackTrace) {
      debugPrint('❌ [PDF] Error generando PDF: $e');
      debugPrint('❌ [PDF] StackTrace: $stackTrace');
      rethrow;
    }
  }

  pw.Widget _buildPageContent(InvoiceEntity invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildTopAccent(),
        pw.SizedBox(height: 10),
        _buildHeader(invoice),
        pw.SizedBox(height: 12),
        _buildSectionGrid(invoice),
        pw.SizedBox(height: 10),
        _buildStayTable(invoice),
        pw.SizedBox(height: 10),
        _buildLineItemsTable(invoice),
        pw.SizedBox(height: 10),
        _buildSummaryArea(invoice),
        pw.SizedBox(height: 12),
        _buildFooter(),
      ],
    );
  }

  pw.Widget _buildTopAccent() {
    return pw.Container(
      height: 4,
      decoration: const pw.BoxDecoration(
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(flex: 1, child: pw.Container(color: _colorBlack)),
          pw.Expanded(flex: 1, child: pw.Container(color: _colorGold)),
          pw.Expanded(flex: 1, child: pw.Container(color: _colorSilver)),
        ],
      ),
    );
  }

  pw.Widget _buildHeader(InvoiceEntity invoice) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo
        pw.Expanded(
          flex: 40,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 120,
                height: 55,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _colorBorder),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: _logoImage != null
                    ? pw.ClipRRect(
                        horizontalRadius: 6,
                        verticalRadius: 6,
                        child: pw.Image(
                          _logoImage!,
                          fit: pw.BoxFit.contain,
                        ),
                      )
                    : pw.Center(
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text('BF', style: _boldStyle(fontSize: 24, color: _colorGold)),
                            pw.Text(
                              'BOUTIQUE JEREZ',
                              style: _regularStyle(fontSize: 6, color: _colorTextSoft, letterSpacing: 1.5),
                            ),
                          ],
                        ),
                      ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'GRUPO HOTELERO BF',
                style: _regularStyle(fontSize: 8, color: _colorTextSoft, letterSpacing: 1),
              ),
            ],
          ),
        ),
        pw.Expanded(
          flex: 60,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'FACTURA',
                style: _boldStyle(fontSize: 26, color: _colorDark, letterSpacing: 1.5),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'BANFERRA JEREZ 2020 S.L.',
                style: _boldStyle(fontSize: 10, color: _colorBlack),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'C/ Ermita del Mimbral 4',
                style: _regularStyle(fontSize: 8, color: _colorTextSoft),
              ),
              pw.Text(
                '11408 Jerez de la Frontera, Cádiz, España',
                style: _regularStyle(fontSize: 8, color: _colorTextSoft),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'CIF: B02919355',
                style: _regularStyle(fontSize: 8, color: _colorTextSoft),
              ),
              pw.Text(
                'Tel: +34 674 27 70 16 | info@boutiquejerez.es',
                style: _regularStyle(fontSize: 8, color: _colorTextSoft),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSectionGrid(InvoiceEntity invoice) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _buildSectionBox(
            title: 'CLIENTE',
            content: _buildClientContent(invoice),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _buildSectionBox(
            title: 'DATOS DE FACTURA',
            content: _buildInvoiceDataContent(invoice),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSectionBox({required String title, required pw.Widget content}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _colorBorder),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const pw.BoxDecoration(
              color: _colorLight,
              border: pw.Border(
                bottom: pw.BorderSide(color: _colorGoldSoft, width: 1.5),
              ),
            ),
            child: pw.Text(
              title,
              style: _boldStyle(fontSize: 8, color: _colorDark, letterSpacing: 0.8),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: content,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildClientContent(InvoiceEntity invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          invoice.clientName.toUpperCase(),
          style: _boldStyle(fontSize: 10, color: _colorBlack),
        ),
        if (invoice.clientAddress != null && invoice.clientAddress!.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            invoice.clientAddress!,
            style: _regularStyle(fontSize: 8, color: _colorTextSoft),
          ),
        ],
        if (invoice.clientCity != null && invoice.clientCity!.isNotEmpty)
          pw.Text(
            '${invoice.clientPostalCode ?? ''} ${invoice.clientCity}',
            style: _regularStyle(fontSize: 8, color: _colorTextSoft),
          ),
        pw.SizedBox(height: 4),
        if (invoice.clientNif != null && invoice.clientNif!.isNotEmpty)
          _buildClientRow('CIF/NIF:', invoice.clientNif!),
        if (invoice.clientEmail != null && invoice.clientEmail!.isNotEmpty)
          _buildClientRow('Email:', invoice.clientEmail!),
        if (invoice.clientPhone != null && invoice.clientPhone!.isNotEmpty)
          _buildClientRow('Tel:', invoice.clientPhone!),
      ],
    );
  }

  pw.Widget _buildClientRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1),
      child: pw.Row(
        children: [
          pw.Text(
            '$label ',
            style: _boldStyle(fontSize: 8, color: _colorTextSoft),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: _regularStyle(fontSize: 8, color: _colorBlack),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInvoiceDataContent(InvoiceEntity invoice) {
    return pw.Column(
      children: [
        _buildMetaRow('Nº Factura', invoice.invoiceNumber),
        _buildMetaRow('Fecha emisión', _formatDate(invoice.issueDate)),
        if (invoice.dueDate != null)
          _buildMetaRow('Fecha vencimiento', _formatDate(invoice.dueDate!)),
        _buildMetaRow('Forma de pago', 'Tarjeta de crédito'),
        if (invoice.bookingCode != null && invoice.bookingCode!.isNotEmpty)
          _buildMetaRow('Referencia', invoice.bookingCode!),
      ],
    );
  }

  pw.Widget _buildMetaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 45,
            child: pw.Text(
              label,
              style: _boldStyle(fontSize: 8, color: _colorTextSoft),
            ),
          ),
          pw.Expanded(
            flex: 55,
            child: pw.Text(
              value,
              style: _regularStyle(fontSize: 8, color: _colorBlack),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStayTable(InvoiceEntity invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DATOS DE ESTANCIA',
          style: _boldStyle(fontSize: 8, color: _colorDark, letterSpacing: 0.8),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _colorBorder),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Table(
            border: pw.TableBorder(
              horizontalInside: const pw.BorderSide(color: _colorRowDivider),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(1.5),
              2: pw.FlexColumnWidth(1.5),
              3: pw.FlexColumnWidth(1.5),
              4: pw.FlexColumnWidth(1),
              5: pw.FlexColumnWidth(1),
              6: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: _colorLight,
                  border: pw.Border(
                    bottom: pw.BorderSide(color: _colorGoldSoft, width: 1.5),
                  ),
                ),
                children: [
                  _buildTableHeader('Alojamiento'),
                  _buildTableHeader('Reserva', center: true),
                  _buildTableHeader('Check-in', center: true),
                  _buildTableHeader('Check-out', center: true),
                  _buildTableHeader('Noc.', center: true),
                  _buildTableHeader('Ad.', center: true),
                  _buildTableHeader('Niñ.', center: true),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildTableCell(invoice.unitName ?? 'N/A'),
                  _buildTableCell(_formatDate(invoice.issueDate), center: true),
                  _buildTableCell(
                    invoice.periodStart != null ? _formatDate(invoice.periodStart!) : '-',
                    center: true,
                  ),
                  _buildTableCell(
                    invoice.periodEnd != null ? _formatDate(invoice.periodEnd!) : '-',
                    center: true,
                  ),
                  _buildTableCell('1', center: true),
                  _buildTableCell('1', center: true),
                  _buildTableCell('0', center: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text, {bool center = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        style: _boldStyle(fontSize: 7, color: _colorDark, letterSpacing: 0.3),
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool center = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        style: _regularStyle(fontSize: 7, color: _colorBlack),
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildLineItemsTable(InvoiceEntity invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CONCEPTOS FACTURADOS',
          style: _boldStyle(fontSize: 8, color: _colorDark, letterSpacing: 0.8),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _colorBorder),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Table(
            border: pw.TableBorder(
              horizontalInside: const pw.BorderSide(color: _colorRowDivider),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(5),
              1: pw.FlexColumnWidth(1.5),
              2: pw.FlexColumnWidth(1.5),
              3: pw.FlexColumnWidth(1),
              4: pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: _colorLight,
                  border: pw.Border(
                    bottom: pw.BorderSide(color: _colorGoldSoft, width: 1.5),
                  ),
                ),
                children: [
                  _buildTableHeader('Descripción'),
                  _buildTableHeader('Cant.', center: true),
                  _buildTableHeader('Precio', center: true),
                  _buildTableHeader('IVA', center: true),
                  _buildTableHeader('Importe', center: true),
                ],
              ),
              ...invoice.lineItems.map(
                (item) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            item.description,
                            style: _regularStyle(fontSize: 7, color: _colorBlack),
                          ),
                          if (invoice.periodStart != null && invoice.periodEnd != null)
                            pw.Text(
                              'Estancia ${_formatDate(invoice.periodStart!)} - ${_formatDate(invoice.periodEnd!)}',
                              style: _regularStyle(fontSize: 6, color: _colorTextSoft),
                            ),
                        ],
                      ),
                    ),
                    _buildTableCell('${item.quantity} noc.', center: true),
                    _buildTableCell(_formatCurrency(item.unitPrice), center: true),
                    _buildTableCell('${item.taxRate.toStringAsFixed(0)}%', center: true),
                    _buildTableCell(_formatCurrency(item.subtotal), center: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryArea(InvoiceEntity invoice) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(flex: 58, child: _buildNotesBox(invoice)),
        pw.SizedBox(width: 10),
        pw.Expanded(flex: 42, child: _buildTotalsCard(invoice)),
      ],
    );
  }

  pw.Widget _buildNotesBox(InvoiceEntity invoice) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _colorBorder),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const pw.BoxDecoration(
              color: _colorLight,
              border: pw.Border(
                bottom: pw.BorderSide(color: _colorGoldSoft, width: 1.5),
              ),
            ),
            child: pw.Text(
              'OBSERVACIONES',
              style: _boldStyle(fontSize: 8, color: _colorDark, letterSpacing: 0.8),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Text(
              invoice.notes ??
                  'Gracias por su estancia en Boutique Jerez.\n'
                  'Factura emitida electrónicamente.\n'
                  'IVA incluido conforme a normativa vigente.',
              style: _regularStyle(fontSize: 7, color: _colorTextSoft),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTotalsCard(InvoiceEntity invoice) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _colorBorder),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const pw.BoxDecoration(
              color: _colorLight,
              border: pw.Border(
                bottom: pw.BorderSide(color: _colorGoldSoft, width: 1.5),
              ),
            ),
            child: pw.Text(
              'RESUMEN ECONÓMICO',
              style: _boldStyle(fontSize: 8, color: _colorDark, letterSpacing: 0.8),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              children: [
                _buildTotalRow('Base imponible', invoice.taxBase),
                pw.SizedBox(height: 4),
                _buildTotalRow(
                  'IVA (${invoice.taxRate.toStringAsFixed(0)}%)',
                  invoice.taxAmount,
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: _colorGoldBg,
                    border: pw.Border(
                      top: const pw.BorderSide(color: _colorGold, width: 1.5),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTAL FACTURA',
                        style: _boldStyle(fontSize: 10, color: _colorBlack),
                      ),
                      pw.Text(
                        _formatCurrency(invoice.totalIncludingTax),
                        style: _boldStyle(fontSize: 14, color: _colorBlack),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, double amount) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: _boldStyle(fontSize: 8, color: _colorTextSoft)),
        pw.Text(
          _formatCurrency(amount),
          style: _boldStyle(fontSize: 9, color: _colorBlack),
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _colorBorder)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Grupo Hotelero BF',
            style: _boldStyle(fontSize: 8, color: _colorBlack),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'BANFERRA JEREZ 2020 S.L. - CIF B02919355 - Jerez de la Frontera, España',
            style: _regularStyle(fontSize: 7, color: _colorTextSoft),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Este documento sirve como justificante de facturación emitido por medios electrónicos.',
            style: _regularStyle(fontSize: 7, color: _colorTextSoft),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2).replaceAll('.', ',')} EUR';
  }

  /// Abre el diálogo de impresión
  Future<void> printInvoice(InvoiceEntity invoice) async {
    final pdfBytes = await generateInvoicePdf(invoice);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Factura_${invoice.invoiceNumber}',
    );
  }

  /// Descarga el PDF a un archivo
  Future<File> saveInvoiceToFile(InvoiceEntity invoice) async {
    debugPrint('🔵 [PDF] Iniciando guardado de factura: ${invoice.invoiceNumber}');

    try {
      debugPrint('🔵 [PDF] Generando bytes del PDF...');
      final pdfBytes = await generateInvoicePdf(invoice);
      debugPrint('✅ [PDF] PDF generado: ${pdfBytes.length} bytes');

      debugPrint('🔵 [PDF] Obteniendo directorio de documentos...');
      final directory = await getApplicationDocumentsDirectory();
      debugPrint('✅ [PDF] Directorio: ${directory.path}');

      final sanitizedNumber = invoice.invoiceNumber.replaceAll('/', '-');
      final filePath = '${directory.path}/Factura_$sanitizedNumber.pdf';
      debugPrint('🔵 [PDF] Ruta del archivo: $filePath');

      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      debugPrint('✅ [PDF] Archivo guardado correctamente');

      return file;
    } catch (e, stackTrace) {
      debugPrint('❌ [PDF] Error guardando archivo: $e');
      debugPrint('❌ [PDF] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Comparte el PDF
  /// [rect] es necesario para iPad - es la posición del widget que invoca compartir
  Future<void> shareInvoice(InvoiceEntity invoice, Rect shareRect) async {
    debugPrint('🔵 [SHARE] Iniciando compartir factura: ${invoice.invoiceNumber}');
    debugPrint('🔵 [SHARE] shareRect: $shareRect');

    try {
      debugPrint('🔵 [SHARE] Paso 1: Guardando archivo...');
      final file = await saveInvoiceToFile(invoice);
      debugPrint('✅ [SHARE] Archivo listo: ${file.path}');
      debugPrint('🔵 [SHARE] ¿Archivo existe?: ${await file.exists()}');
      debugPrint('🔵 [SHARE] Tamaño archivo: ${await file.length()} bytes');

      final sanitizedNumber = invoice.invoiceNumber.replaceAll('/', '-');

      debugPrint('🔵 [SHARE] Paso 2: Llamando a Share.shareXFiles...');
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Factura $sanitizedNumber - Grupo Hotelero BF',
        text: 'Adjunto encontrará la factura $sanitizedNumber.',
        sharePositionOrigin: shareRect,
      );
      debugPrint('✅ [SHARE] Compartido correctamente');
    } catch (e, stackTrace) {
      debugPrint('❌ [SHARE] Error al compartir: $e');
      debugPrint('❌ [SHARE] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Obtiene los bytes del PDF para previsualización
  Future<Uint8List> getPdfBytes(InvoiceEntity invoice) async {
    return generateInvoicePdf(invoice);
  }
}
