import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Diálogo profesional de confirmación para cerrar sesión.
/// Sigue el patrón de diseño de BF Stay con colores gold y soporte dark mode.
class LogoutConfirmationDialog extends StatelessWidget {
  const LogoutConfirmationDialog({super.key});

  /// Muestra el diálogo de confirmación de logout.
  /// Retorna true si el usuario confirma, false si cancela.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.blackWithAlpha80,
      builder: (context) => const LogoutConfirmationDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Dialog(
      backgroundColor: AppColors.getCardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.gold,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.goldWithAlpha30,
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de logout con fondo gold
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.goldWithAlpha20,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.goldWithAlpha30,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.logout_rounded,
                size: 40,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 24),

            // Título
            Text(
              'Cerrar sesión',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextPrimaryColor(context),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Descripción
            Text(
              '¿Estás seguro de que deseas cerrar sesión?\n\n'
              'Podrás volver a acceder con tu código de reserva cuando lo necesites.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.getTextSecondaryColor(context),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Botones
            Column(
              children: [
                // Botón de cancelar (secundario)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: isDark
                            ? AppColors.whiteWithAlpha30
                            : AppColors.blackWithAlpha20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Botón de cerrar sesión (principal con gold)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
