import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../core/services/app_update_service.dart';
import '../../core/theme/app_colors.dart';

/// Diálogo de actualización que se muestra cuando hay una nueva versión disponible
/// Soporta actualización opcional o forzada
class UpdateDialog extends StatelessWidget {
  const UpdateDialog({
    super.key,
    required this.updateStatus,
    this.versionInfo,
    this.onUpdate,
    this.onLater,
  });

  final UpdateStatus updateStatus;
  final AppVersionInfo? versionInfo;
  final VoidCallback? onUpdate;
  final VoidCallback? onLater;

  /// Muestra el diálogo de actualización
  /// Retorna true si el usuario eligió actualizar, false si eligió más tarde
  static Future<bool?> show(
    BuildContext context, {
    required UpdateStatus updateStatus,
    AppVersionInfo? versionInfo,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: updateStatus != UpdateStatus.forceRequired,
      useRootNavigator: true,
      builder: (context) => UpdateDialog(
        updateStatus: updateStatus,
        versionInfo: versionInfo,
        onUpdate: () {
          Navigator.of(context).pop(true);
          AppUpdateService.instance.openStore();
        },
        onLater: updateStatus != UpdateStatus.forceRequired
            ? () => Navigator.of(context).pop(false)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isForceUpdate = updateStatus == UpdateStatus.forceRequired;

    return Platform.isIOS
        ? _buildCupertinoDialog(context, isForceUpdate)
        : _buildMaterialDialog(context, isForceUpdate);
  }

  Widget _buildCupertinoDialog(BuildContext context, bool isForceUpdate) {
    return CupertinoAlertDialog(
      title: Text(
        isForceUpdate ? 'Actualización Requerida' : 'Nueva Versión Disponible',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getMessage(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            if (versionInfo?.latestVersion != null) ...[
              const SizedBox(height: 8),
              Text(
                'Versión ${versionInfo!.latestVersion}',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!isForceUpdate)
          CupertinoDialogAction(
            isDefaultAction: false,
            onPressed: onLater,
            child: const Text('Más tarde'),
          ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: onUpdate,
          child: const Text('Actualizar'),
        ),
      ],
    );
  }

  Widget _buildMaterialDialog(BuildContext context, bool isForceUpdate) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            isForceUpdate ? Icons.update_disabled : Icons.system_update,
            color: isForceUpdate ? AppColors.error : AppColors.gold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isForceUpdate ? 'Actualización Requerida' : 'Nueva Versión Disponible',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getMessage(),
            style: const TextStyle(fontSize: 14),
          ),
          if (versionInfo?.latestVersion != null) ...[
            const SizedBox(height: 8),
            Text(
              'Versión ${versionInfo!.latestVersion}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!isForceUpdate)
          TextButton(
            onPressed: onLater,
            child: const Text('Más tarde'),
          ),
        ElevatedButton(
          onPressed: onUpdate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Actualizar'),
        ),
      ],
    );
  }

  String _getMessage() {
    if (versionInfo?.updateMessage != null) {
      return versionInfo!.updateMessage!;
    }

    return updateStatus == UpdateStatus.forceRequired
        ? 'Es necesario actualizar la aplicación para continuar usándola. '
            'Esta versión incluye mejoras importantes y correcciones de seguridad.'
        : 'Hay una nueva versión disponible con mejoras y correcciones. '
            '¿Deseas actualizar ahora?';
  }
}

/// Widget que envuelve la app y verifica actualizaciones al iniciar
class UpdateChecker extends StatefulWidget {
  const UpdateChecker({
    super.key,
    required this.child,
    this.checkOnStart = true,
  });

  final Widget child;
  final bool checkOnStart;

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🔍 [UpdateChecker] initState');
    if (widget.checkOnStart) {
      // Usar addPostFrameCallback para ejecutar después del primer frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Esperar un poco más para asegurar que el Navigator esté listo
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _checkForUpdate();
          }
        });
      });
    }
  }

  Future<void> _checkForUpdate() async {
    if (_hasChecked) {
      debugPrint('🔍 [UpdateChecker] Ya verificado, saltando');
      return;
    }

    debugPrint('🔍 [UpdateChecker] Verificando actualizaciones...');

    final updateService = AppUpdateService.instance;
    debugPrint('🔍 [UpdateChecker] Versión actual: ${updateService.currentVersion}');
    debugPrint('🔍 [UpdateChecker] VersionInfo: ${updateService.versionInfo}');

    final status = await updateService.checkForUpdate();
    debugPrint('🔍 [UpdateChecker] Status: $status');

    if (!mounted) {
      debugPrint('🔍 [UpdateChecker] Widget no montado');
      return;
    }

    if (status == UpdateStatus.available || status == UpdateStatus.forceRequired) {
      debugPrint('🔍 [UpdateChecker] Mostrando diálogo de actualización');
      // Usar addPostFrameCallback para asegurar que el contexto esté listo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final navigatorContext = rootNavigatorKey.currentContext;
        if (navigatorContext != null) {
          UpdateDialog.show(
            navigatorContext,
            updateStatus: status,
            versionInfo: updateService.versionInfo,
          );
        } else {
          debugPrint('❌ [UpdateChecker] NavigatorContext es null');
        }
      });
    } else {
      debugPrint('🔍 [UpdateChecker] No hay actualización pendiente');
    }

    _hasChecked = true;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
