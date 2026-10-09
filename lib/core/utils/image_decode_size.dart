import 'package:flutter/widgets.dart';

/// Utilidades para dimensionar la **decodificación** de imágenes.
///
/// Por defecto Flutter decodifica cada imagen a su resolución original y la mantiene así en el
/// caché de memoria, aunque se pinte en una tarjeta de 160 px. Una foto de 4000×3000 ocupa
/// ~48 MB de RAM decodificada; reducida a 480×360 ocupa ~0,7 MB.
///
/// Pasar `memCacheWidth` / `memCacheHeight` (`CachedNetworkImage`) o `cacheWidth` / `cacheHeight`
/// (`Image`) hace que se decodifique al tamaño realmente necesario. Es la corrección que pide
/// Google Play en la acción recomendada "reducción de resolución de mapas de bits".
///
/// Basta con indicar **una** de las dos dimensiones: la otra se deriva manteniendo la relación
/// de aspecto original.
class ImageDecodeSize {
  const ImageDecodeSize._();

  /// Densidad máxima que se tiene en cuenta.
  ///
  /// Por encima de 3x el detalle añadido no es perceptible pero el coste en memoria crece
  /// con el cuadrado del factor.
  static const double _maxDevicePixelRatio = 3;

  /// Píxeles físicos necesarios para pintar [logicalSize] píxeles lógicos en [context].
  static int forLogical(BuildContext context, double logicalSize) {
    final ratio = MediaQuery.devicePixelRatioOf(
      context,
    ).clamp(1.0, _maxDevicePixelRatio);
    return (logicalSize * ratio).round();
  }

  /// Ancho de la pantalla en píxeles físicos.
  ///
  /// Cota superior segura para imágenes que ocupan todo el ancho (heros, carruseles): nunca
  /// hace falta decodificar más ancho que la propia pantalla.
  static int screenWidth(BuildContext context) =>
      forLogical(context, MediaQuery.sizeOf(context).width);
}
