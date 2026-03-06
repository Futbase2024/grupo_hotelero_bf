import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/app_update_service.dart';
import 'update_dialog.dart';

/// Widget que envuelve la app y verifica actualizaciones después de que el Navigator está listo
/// Se coloca DENTRO del MaterialApp, no fuera
class AppUpdateWrapper extends StatefulWidget {
  const AppUpdateWrapper({super.key});

  @override
  State<AppUpdateWrapper> createState() => _AppUpdateWrapperState();
}

class _AppUpdateWrapperState extends State<AppUpdateWrapper> {
  bool _hasChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Escuchar changes de ruta para verificar actualizaciones en cada nueva pantalla
    GoRouter.of(context).routeInformationProvider.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    GoRouter.of(context).routeInformationProvider.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    // Verificar actualización cuando cambia la ruta
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    if (_hasChecked) return;

    debugPrint('🔍 [AppUpdateWrapper] Verificando actualizaciones...');

    final updateService = AppUpdateService.instance;
    final status = await updateService.checkForUpdate();

    debugPrint('🔍 [AppUpdateWrapper] Status: $status');

    if (!mounted) return;

    if (status == UpdateStatus.available || status == UpdateStatus.forceRequired) {
      debugPrint('🔍 [AppUpdateWrapper] Mostrando diálogo');
      await UpdateDialog.show(
        context,
        updateStatus: status,
        versionInfo: updateService.versionInfo,
      );
    }

    _hasChecked = true;
  }

  @override
  Widget build(BuildContext context) {
    // Este widget es invisible, solo ejecuta lógica
    return const SizedBox.shrink();
  }
}
