import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

/// Datos de contacto devueltos por [EditGuestContactDialog]
class GuestContactInput {
  const GuestContactInput({required this.email, this.phone});

  final String email;
  final String? phone;
}

/// Diálogo para corregir el email y el teléfono del huésped de una reserva
class EditGuestContactDialog extends StatefulWidget {
  const EditGuestContactDialog({
    super.key,
    required this.initialEmail,
    this.initialPhone,
  });

  final String initialEmail;
  final String? initialPhone;

  /// Muestra el diálogo y devuelve los datos introducidos, o `null` si se cancela
  static Future<GuestContactInput?> show(
    BuildContext context, {
    required String initialEmail,
    String? initialPhone,
  }) {
    return showDialog<GuestContactInput>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditGuestContactDialog(
        initialEmail: initialEmail,
        initialPhone: initialPhone,
      ),
    );
  }

  @override
  State<EditGuestContactDialog> createState() => _EditGuestContactDialogState();
}

class _EditGuestContactDialogState extends State<EditGuestContactDialog> {
  static final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final phone = _phoneController.text.trim();
    Navigator.of(context).pop(
      GuestContactInput(
        email: _emailController.text.trim(),
        phone: phone.isEmpty ? null : phone,
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return S.of(context).admin_booking_guest_edit_email_required;
    }
    if (!_emailRegExp.hasMatch(email)) {
      return S.of(context).admin_booking_guest_edit_email_invalid;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(24),
      backgroundColor: AppColors.darkSurface,
      content: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.goldWithAlpha10,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.contact_mail_outlined,
                  size: 48,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                S.of(context).admin_booking_guest_edit_title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                S.of(context).admin_booking_guest_edit_desc,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.gray300,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _ContactField(
                controller: _emailController,
                label: S.of(context).admin_booking_guest_edit_email_label,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              _ContactField(
                controller: _phoneController,
                label: S.of(context).admin_booking_guest_edit_phone_label,
                hint: S.of(context).admin_booking_send_whatsapp_phone_hint,
                keyboardType: TextInputType.phone,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gray300,
                        side: const BorderSide(color: AppColors.darkBorder),
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
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(S.of(context).common_save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo de texto del diálogo, con el estilo dark del panel de administración
class _ContactField extends StatelessWidget {
  const _ContactField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.validator,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      autofocus: autofocus,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(color: AppColors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.gray500),
        floatingLabelStyle: const TextStyle(color: AppColors.gold),
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.gray500),
        filled: true,
        fillColor: AppColors.darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
