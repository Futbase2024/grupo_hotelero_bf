import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Diálogo profesional de notificación (error, aviso, éxito, información).
/// No se cierra tocando fuera: el usuario debe pulsar "Entendido".
class InfoDialog extends StatelessWidget {
  const InfoDialog({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.buttonText = 'Entendido',
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final String buttonText;

  static Future<void> error(BuildContext context, {required String title, required String message}) =>
      _show(context, InfoDialog(
        title: title,
        message: message,
        icon: Icons.error_outline,
        color: AppColors.error,
        backgroundColor: AppColors.errorLight,
      ));

  static Future<void> warning(BuildContext context, {required String title, required String message}) =>
      _show(context, InfoDialog(
        title: title,
        message: message,
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        backgroundColor: AppColors.warningLight,
      ));

  static Future<void> success(BuildContext context, {required String title, required String message}) =>
      _show(context, InfoDialog(
        title: title,
        message: message,
        icon: Icons.check_circle_outline,
        color: AppColors.success,
        backgroundColor: AppColors.successLight,
      ));

  static Future<void> info(BuildContext context, {required String title, required String message}) =>
      _show(context, InfoDialog(
        title: title,
        message: message,
        icon: Icons.info_outline,
        color: AppColors.info,
        backgroundColor: AppColors.infoLight,
      ));

  static Future<void> _show(BuildContext context, InfoDialog dialog) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.blackWithAlpha80,
      builder: (_) => dialog,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.getCardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
                child: Icon(icon, size: 48, color: color),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextPrimaryColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.getTextSecondaryColor(context),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
