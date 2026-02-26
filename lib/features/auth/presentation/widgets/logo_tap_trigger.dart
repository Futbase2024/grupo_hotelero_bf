import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget que detecta 5 taps consecutivos rápidos sobre su child.
///
/// El trigger es completamente OCULTO:
/// - No hay feedback visual en los primeros 4 taps
/// - No tiene InkWell ni splash
/// - Usa GestureDetector puro para ser invisible
///
/// En el 5º tap:
/// - Vibración háptica suave (HapticFeedback.lightImpact)
/// - Ejecuta el callback [onTriggered]
///
/// El contador se reinicia si pasan más de 500ms entre taps.
class LogoTapTrigger extends StatefulWidget {
  const LogoTapTrigger({
    super.key,
    required this.child,
    required this.onTriggered,
    this.tapCount = 5,
    this.tapWindow = const Duration(milliseconds: 500),
  });

  /// Widget hijo que será envuelto por el detector
  final Widget child;

  /// Callback ejecutado cuando se completa la secuencia de taps
  final VoidCallback onTriggered;

  /// Número de taps requeridos (por defecto 5)
  final int tapCount;

  /// Ventana de tiempo máxima entre taps (por defecto 500ms)
  final Duration tapWindow;

  @override
  State<LogoTapTrigger> createState() => _LogoTapTriggerState();
}

class _LogoTapTriggerState extends State<LogoTapTrigger> {
  int _tapCount = 0;
  DateTime? _lastTap;

  void _handleTap() {
    final now = DateTime.now();

    // Reiniciar contador si pasó demasiado tiempo entre taps
    if (_lastTap != null && now.difference(_lastTap!) > widget.tapWindow) {
      _tapCount = 0;
    }

    _tapCount++;
    _lastTap = now;

    // Cuando se alcanza el número de taps requerido
    if (_tapCount >= widget.tapCount) {
      _tapCount = 0;
      _lastTap = null;

      // Vibración háptica suave
      HapticFeedback.lightImpact();

      // Ejecutar callback
      widget.onTriggered();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usar GestureDetector puro - NO InkWell para no mostrar feedback visual
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );
  }
}
