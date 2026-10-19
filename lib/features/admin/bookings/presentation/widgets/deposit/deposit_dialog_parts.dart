import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../l10n/app_localizations.dart';

/// Contenedor común de los diálogos de fianza: icono grande, título, contenido
/// desplazable y botones Cancelar / acción principal.
class DepositDialogScaffold extends StatelessWidget {
  const DepositDialogScaffold({
    super.key,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.title,
    required this.actionText,
    required this.onAction,
    required this.children,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final String title;
  final String actionText;
  final VoidCallback onAction;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.getCardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 48, color: color),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 20),
                ...children,
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              AppColors.getTextSecondaryColor(context),
                          side: BorderSide(
                            color: AppColors.getBorderColor(context),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(S.of(context).common_cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: AppColors.getTextColorForBackground(
                            color,
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          actionText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
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
        ),
      ),
    );
  }
}

/// Texto explicativo de los diálogos de fianza
class DepositDialogMessage extends StatelessWidget {
  const DepositDialogMessage(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 15,
        height: 1.4,
        color: AppColors.getTextSecondaryColor(context),
      ),
    );
  }
}

/// Campo de texto con el estilo de los diálogos de fianza
class DepositTextField extends StatelessWidget {
  const DepositTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color),
        );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      autofocus: autofocus,
      // El teclado numérico de iOS no tiene tecla "Listo": se cierra al tocar fuera
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      style: TextStyle(color: AppColors.getTextPrimaryColor(context)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: AppColors.getTextSecondaryColor(context)),
        hintStyle: TextStyle(color: AppColors.getTextTertiaryColor(context)),
        filled: true,
        fillColor: AppColors.getInputBackgroundColor(context),
        border: border(AppColors.getBorderColor(context)),
        enabledBorder: border(AppColors.getBorderColor(context)),
        focusedBorder: border(AppColors.gold),
        errorBorder: border(AppColors.error),
        focusedErrorBorder: border(AppColors.error),
      ),
    );
  }
}
