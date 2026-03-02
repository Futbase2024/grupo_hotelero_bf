// Configuración para web - usa hash URLs
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void configureUrlStrategy() {
  // Usar hash URLs (#/ruta) para compatibilidad con cualquier servidor
  // Esto hace que las URLs sean: tudominio.com/#/guest/alojamientos
  // en lugar de: tudominio.com/guest/alojamientos (requiere config del servidor)
  setUrlStrategy(const HashUrlStrategy());
}
