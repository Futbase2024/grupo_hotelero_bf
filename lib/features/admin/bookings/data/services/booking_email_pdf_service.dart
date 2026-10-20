import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../../core/constants/checkin_policy.dart';
import '../../../domain/entities/admin_booking_entity.dart';

/// Genera un PDF con la misma informacion que la plantilla del email de check-in
/// para compartir por WhatsApp.
class BookingEmailPdfService {
  static const _gold = PdfColor(0.831, 0.686, 0.216);
  static const _goldLight = PdfColor(0.898, 0.788, 0.384);
  static const _dark = PdfColor(0.051, 0.051, 0.051);
  static const _soft = PdfColor(0.45, 0.45, 0.45);

  /// Colores del aviso destacado de hora limite de check-in
  static const _noticeBackground = PdfColor(0.992, 0.965, 0.890);
  static const _noticeText = PdfColor(0.541, 0.427, 0.122);

  pw.Font? _regularFont;
  pw.Font? _boldFont;
  pw.MemoryImage? _logoImage;

  Future<void> _loadFonts() async {
    if (_regularFont != null) return;
    try {
      final regularData =
          await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      _regularFont = pw.Font.ttf(regularData);
      _boldFont = pw.Font.ttf(boldData);
    } catch (e) {
      debugPrint('⚠️ Error fuentes: $e');
    }
  }

  Future<void> _loadLogo() async {
    if (_logoImage != null) return;
    try {
      final data = await rootBundle.load('assets/icons/logoBF.png');
      _logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      debugPrint('⚠️ Error logo: $e');
    }
  }

  Future<Uint8List> generateEmailPdf(
    AdminBookingEntity booking, {
    Uint8List? heroImage,
  }) async {
    await _loadFonts();
    await _loadLogo();

    pw.MemoryImage? heroMemoryImage;
    if (heroImage != null && heroImage.isNotEmpty) {
      try {
        heroMemoryImage = pw.MemoryImage(heroImage);
      } catch (e) {
        debugPrint('⚠️ Error imagen cabecera: $e');
      }
    }

    final checkIn = DateFormat('dd/MM/yyyy').format(booking.checkInDate);
    final checkOut = DateFormat('dd/MM/yyyy').format(booking.checkOutDate);

    final regular = pw.TextStyle(
      font: _regularFont ?? pw.Font.helvetica(),
      fontSize: 10,
      color: _dark,
    );
    final bold = pw.TextStyle(
      font: _boldFont ?? pw.Font.helvetica(),
      fontWeight: pw.FontWeight.bold,
      fontSize: 10,
      color: _dark,
    );

    final pdf = pw.Document(
      title: 'Reserva ${booking.bookingCode} - BF Stay',
      author: 'Grupo Hotelero BF',
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            // Imagen de cabecera (igual que el correo)
            if (heroMemoryImage != null)
              pw.Image(heroMemoryImage, fit: pw.BoxFit.cover, height: 190),
            pw.Padding(
              padding: const pw.EdgeInsets.all(30),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  // Logo + Titulo
                  pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  if (_logoImage != null)
                    pw.Container(
                      width: 36,
                      height: 36,
                      margin: const pw.EdgeInsets.only(right: 10),
                      child: pw.Image(_logoImage!, fit: pw.BoxFit.contain),
                    ),
                  pw.Text('BF STAY', style: bold.copyWith(fontSize: 22, color: _gold)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text('Grupo Hotelero BF',
                  style: regular.copyWith(fontSize: 10, color: _goldLight)),
              pw.Divider(color: _gold, thickness: 0.5, height: 20),

              // Saludo
              pw.Text(
                'Hola, ${booking.guestFirstName ?? booking.guestFullName}',
                style: bold.copyWith(fontSize: 18),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Tu estancia esta reservada',
                  style: regular.copyWith(fontSize: 12, color: _soft)),
              pw.SizedBox(height: 20),

              // Tarjeta propiedad
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _gold, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(booking.propertyName,
                        style: bold.copyWith(fontSize: 16, color: _gold)),
                    if (booking.unitName.isNotEmpty)
                      pw.Text(booking.unitName,
                          style: regular.copyWith(fontSize: 11, color: _soft)),
                    pw.Divider(color: _gold, thickness: 0.5, height: 20),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      children: [
                        pw.Column(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text('CHECK-IN',
                                style: bold.copyWith(fontSize: 8, color: _soft)),
                            pw.SizedBox(height: 4),
                            pw.Text(checkIn,
                                style: bold.copyWith(fontSize: 14)),
                          ],
                        ),
                        pw.Container(
                            width: 0.5, height: 30, color: _gold),
                        pw.Column(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text('CHECK-OUT',
                                style: bold.copyWith(fontSize: 8, color: _soft)),
                            pw.SizedBox(height: 4),
                            pw.Text(checkOut,
                                style: bold.copyWith(fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Aviso destacado: hora limite de check-in
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: pw.BoxDecoration(
                  color: _noticeBackground,
                  border: pw.Border(
                    left: pw.BorderSide(color: _gold, width: 3),
                  ),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      CheckinPolicy.maxCheckinNotice,
                      style: bold.copyWith(fontSize: 12, color: _noticeText),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Codigo de acceso
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: pw.BoxDecoration(
                  color: _dark,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text('CODIGO DE ACCESO',
                        style: bold.copyWith(fontSize: 9, color: _goldLight)),
                    pw.SizedBox(height: 6),
                    pw.Text(booking.bookingCode,
                        style: bold.copyWith(fontSize: 26, color: _gold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Links app (clicables)
              pw.Text('Descarga o abre BF Stay',
                  style: bold.copyWith(fontSize: 12)),
              pw.SizedBox(height: 8),
              pw.UrlLink(
                destination:
                    'https://apps.apple.com/es/app/bf-stay/id6759832221',
                child: pw.Text('Descargar en App Store',
                    style: regular.copyWith(
                      fontSize: 10,
                      color: PdfColors.blue,
                      decoration: pw.TextDecoration.underline,
                    )),
              ),
              pw.SizedBox(height: 5),
              pw.UrlLink(
                destination:
                    'https://play.google.com/store/apps/details?id=com.bfstay.app',
                child: pw.Text('Descargar en Google Play',
                    style: regular.copyWith(
                      fontSize: 10,
                      color: PdfColors.blue,
                      decoration: pw.TextDecoration.underline,
                    )),
              ),
              pw.SizedBox(height: 20),

              // Telefonos
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor(0.88, 0.88, 0.88)),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text('Telefono de soporte',
                        style: bold.copyWith(fontSize: 9, color: _soft)),
                    pw.SizedBox(height: 4),
                    pw.Text('+34 656 61 80 65  |  +34 674 27 70 16',
                        style: bold.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

                  // Footer
                  pw.Divider(color: PdfColor(0.88, 0.88, 0.88), height: 10),
                  pw.Text(
                    '${DateTime.now().year} BF Stay - Grupo Hotelero BF',
                    style: regular.copyWith(fontSize: 7, color: _soft),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }
}
