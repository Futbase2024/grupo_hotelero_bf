import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';

/// Prepara la foto de un documento de identidad antes de subirla.
///
/// 1. Corrige la orientación EXIF y la reduce a [maxDimension].
/// 2. Graba encima una marca «COPIA» grande en diagonal y una franja inferior
///    con la finalidad y la fecha.
/// 3. La re-codifica a JPEG por debajo de [maxFileSizeBytes].
///
/// Se hace en el móvil para que la imagen original sin marca nunca llegue al
/// servidor: lo que se guarda en el bucket (y lo que ve el staff) es esto.
class DocumentWatermarkService {
  const DocumentWatermarkService._();

  static const int maxDimension = 1600;
  static const int maxFileSizeBytes = 500 * 1024;

  static const String _watermarkText = 'COPIA';
  static const String _footerPrefix = 'Solo para registro de viajeros · BF Stay';

  /// Devuelve la imagen marcada en JPEG.
  static Future<Uint8List> prepare(Uint8List originalBytes) async {
    final normalized = await FlutterImageCompress.compressWithList(
      originalBytes,
      minWidth: maxDimension,
      minHeight: maxDimension,
      quality: 95,
      format: CompressFormat.jpeg,
    );

    final watermarkedPng = await _drawWatermark(normalized);
    final result = await _encodeJpeg(watermarkedPng);

    debugPrint(
      '🔏 [DocumentWatermark] ${originalBytes.length} B → ${result.length} B con marca',
    );
    return result;
  }

  static Future<Uint8List> _drawWatermark(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    codec.dispose();

    final width = image.width.toDouble();
    final height = image.height.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImage(image, ui.Offset.zero, ui.Paint());

    _drawDiagonalMark(canvas, width, height);
    _drawFooter(canvas, width, height);

    final picture = recorder.endRecording();
    final marked = await picture.toImage(image.width, image.height);
    picture.dispose();
    image.dispose();

    final byteData = await marked.toByteData(format: ui.ImageByteFormat.png);
    marked.dispose();
    if (byteData == null) {
      throw StateError('No se pudo generar la imagen con marca de agua');
    }
    return byteData.buffer.asUint8List();
  }

  /// «COPIA» centrada, siguiendo la diagonal de la imagen y ocupando ~70 %.
  static void _drawDiagonalMark(ui.Canvas canvas, double width, double height) {
    final diagonal = math.sqrt(width * width + height * height);
    final angle = -math.atan2(height, width);

    // Se mide con un tamaño base y se escala hasta el 70 % de la diagonal
    const baseFontSize = 100.0;
    final baseWidth = _buildParagraph(
      fontSize: baseFontSize,
      foreground: ui.Paint(),
    ).maxIntrinsicWidth;
    final fontSize = baseFontSize * (diagonal * 0.7) / baseWidth;

    final outline = _buildParagraph(
      fontSize: fontSize,
      foreground: ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = math.max(2.0, fontSize * 0.03)
        ..color = AppColors.white.withValues(alpha: 0.55),
    );
    final fill = _buildParagraph(
      fontSize: fontSize,
      foreground: ui.Paint()..color = AppColors.error.withValues(alpha: 0.38),
    );

    final offset = ui.Offset(-fill.maxIntrinsicWidth / 2, -fill.height / 2);

    canvas
      ..save()
      ..translate(width / 2, height / 2)
      ..rotate(angle)
      ..drawParagraph(fill, offset)
      ..drawParagraph(outline, offset)
      ..restore();
  }

  /// Franja inferior: finalidad + fecha, para saber para qué se hizo la copia.
  static void _drawFooter(ui.Canvas canvas, double width, double height) {
    final bandHeight = math.max(28.0, height * 0.06);
    final top = height - bandHeight;

    canvas.drawRect(
      ui.Rect.fromLTWH(0, top, width, bandHeight),
      ui.Paint()..color = AppColors.black.withValues(alpha: 0.6),
    );

    final date = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final footer = _buildParagraph(
      text: '$_footerPrefix · $date',
      fontSize: bandHeight * 0.42,
      fontWeight: ui.FontWeight.w500,
      foreground: ui.Paint()..color = AppColors.white,
      maxWidth: width * 0.95,
    );

    canvas.drawParagraph(
      footer,
      ui.Offset((width - footer.width) / 2, top + (bandHeight - footer.height) / 2),
    );
  }

  static ui.Paragraph _buildParagraph({
    String text = _watermarkText,
    required double fontSize,
    required ui.Paint foreground,
    ui.FontWeight fontWeight = ui.FontWeight.w900,
    double maxWidth = double.infinity,
  }) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: ui.TextAlign.center,
        maxLines: 1,
        ellipsis: '…',
      ),
    )
      ..pushStyle(
        ui.TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: text == _watermarkText ? fontSize * 0.12 : 0,
          foreground: foreground,
        ),
      )
      ..addText(text);

    final paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: maxWidth));
    if (maxWidth.isInfinite) {
      // Re-maquetar al ancho real para que el centrado sea exacto
      paragraph.layout(ui.ParagraphConstraints(width: paragraph.maxIntrinsicWidth + 1));
    }
    return paragraph;
  }

  /// JPEG bajando la calidad por pasos hasta quedar por debajo del límite.
  static Future<Uint8List> _encodeJpeg(Uint8List pngBytes) async {
    var result = pngBytes;
    for (final quality in const [85, 70, 55, 40]) {
      result = await FlutterImageCompress.compressWithList(
        pngBytes,
        minWidth: maxDimension,
        minHeight: maxDimension,
        quality: quality,
        format: CompressFormat.jpeg,
        autoCorrectionAngle: false,
      );
      if (result.length <= maxFileSizeBytes) break;
    }
    return result;
  }
}
