import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Recuadro de firma. Devuelve la firma como SVG completo con `viewBox`
/// 400×150 (el mismo que usa el panel para pintarla), independiente del
/// tamaño de pantalla en que se firmó.
class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    required this.onChanged,
    required this.hint,
    required this.clearLabel,
    this.enabled = true,
  });

  /// SVG de la firma, o null si está vacía
  final ValueChanged<String?> onChanged;
  final String hint;
  final String clearLabel;
  final bool enabled;

  static const double viewBoxWidth = 400;
  static const double viewBoxHeight = 150;

  /// Convierte los trazos (en coordenadas del viewBox) a SVG
  static String? toSvg(List<List<Offset>> strokes) {
    final drawn = strokes.where((s) => s.isNotEmpty).toList();
    if (drawn.isEmpty) return null;

    String n(double v) => v.toStringAsFixed(1);
    final d = StringBuffer();
    for (final stroke in drawn) {
      d.write('M ${n(stroke.first.dx)} ${n(stroke.first.dy)} ');
      // Un toque sin arrastre se dibuja como un punto
      final rest = stroke.length == 1 ? [stroke.first] : stroke.skip(1);
      for (final p in rest) {
        d.write('L ${n(p.dx)} ${n(p.dy)} ');
      }
    }
    return '<svg xmlns="http://www.w3.org/2000/svg" '
        'viewBox="0 0 ${viewBoxWidth.toInt()} ${viewBoxHeight.toInt()}">'
        '<path d="${d.toString().trim()}" stroke="#D4AF37" stroke-width="3" '
        'stroke-linecap="round" stroke-linejoin="round" fill="none"/></svg>';
  }

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _strokes = [];

  Offset _toViewBox(Offset local, Size size) => Offset(
        (local.dx / size.width * SignaturePad.viewBoxWidth)
            .clamp(0, SignaturePad.viewBoxWidth),
        (local.dy / size.height * SignaturePad.viewBoxHeight)
            .clamp(0, SignaturePad.viewBoxHeight),
      );

  void _clear() {
    setState(_strokes.clear);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final hasStrokes = _strokes.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: SignaturePad.viewBoxWidth / SignaturePad.viewBoxHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.getInputBackgroundColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasStrokes ? AppColors.gold : AppColors.getBorderColor(context),
                    width: hasStrokes ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: GestureDetector(
                    onPanStart: widget.enabled
                        ? (details) => setState(() => _strokes.add(
                              [_toViewBox(details.localPosition, size)],
                            ))
                        : null,
                    onPanUpdate: widget.enabled
                        ? (details) => setState(() => _strokes.last.add(
                              _toViewBox(details.localPosition, size),
                            ))
                        : null,
                    onPanEnd: widget.enabled
                        ? (_) => widget.onChanged(SignaturePad.toSvg(_strokes))
                        : null,
                    child: CustomPaint(
                      size: size,
                      painter: _SignaturePainter(strokes: _strokes, size: size),
                      child: hasStrokes
                          ? const SizedBox.expand()
                          : Center(
                              child: Text(
                                widget.hint,
                                style: TextStyle(
                                  color: AppColors.getTextTertiaryColor(context),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (hasStrokes && widget.enabled)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.clear, size: 18),
              label: Text(widget.clearLabel),
            ),
          ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({required this.strokes, required this.size})
      : _version = strokes.fold<int>(0, (sum, s) => sum + s.length);

  final List<List<Offset>> strokes;
  final Size size;
  final int _version;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final scaleX = size.width / SignaturePad.viewBoxWidth;
    final scaleY = size.height / SignaturePad.viewBoxHeight;
    final paint = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final path = Path()
        ..moveTo(stroke.first.dx * scaleX, stroke.first.dy * scaleY);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx * scaleX, p.dy * scaleY);
      }
      if (stroke.length == 1) {
        canvas.drawCircle(
          Offset(stroke.first.dx * scaleX, stroke.first.dy * scaleY),
          1.5,
          paint..style = PaintingStyle.fill,
        );
        paint.style = PaintingStyle.stroke;
      } else {
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) =>
      oldDelegate._version != _version || oldDelegate.size != size;
}
