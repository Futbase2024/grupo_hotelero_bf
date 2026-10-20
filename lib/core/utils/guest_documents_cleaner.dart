import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';

/// Elimina del bucket `guest-documents` los archivos devueltos por las RPC de
/// borrado (`delete_checkin`, `delete_booking`).
///
/// El borrado en base de datos ya ha hecho commit cuando se llama a esta
/// función, así que un fallo al eliminar un archivo solo se registra y no
/// interrumpe el resto: como mucho quedan archivos huérfanos en el bucket.
Future<void> removeGuestDocuments(
  List<String> storagePaths, {
  String logTag = 'removeGuestDocuments',
}) async {
  if (storagePaths.isEmpty) return;

  debugPrint('🗑️ [$logTag] Eliminando ${storagePaths.length} archivos del storage...');

  for (final path in storagePaths) {
    try {
      await SupabaseConfig.client.storage.from('guest-documents').remove([path]);
      debugPrint('🗑️ [$logTag] Archivo eliminado: $path');
    } catch (e) {
      debugPrint('⚠️ [$logTag] Error eliminando archivo $path: $e');
    }
  }
}
