import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/bloc/auth_bloc.dart';

/// Modal bottom sheet para login de administradores y staff
///
/// Se abre con el trigger oculto de 5 taps en el logo.
/// Usa email + contraseña (no código BF).
/// Tras login exitoso, navega al AdminDashboard.
class AdminLoginBottomSheet extends StatefulWidget {
  const AdminLoginBottomSheet({super.key});

  /// Muestra el bottom sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const AdminLoginBottomSheet(),
    );
  }

  @override
  State<AdminLoginBottomSheet> createState() => _AdminLoginBottomSheetState();
}

class _AdminLoginBottomSheetState extends State<AdminLoginBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _hasSubmittedOnce = false;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  bool get _isEmailValid {
    final email = _emailController.text.trim();
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool get _isPasswordValid => _passwordController.text.length >= 6;

  bool get _isFormValid => _isEmailValid && _isPasswordValid;

  void _handleSubmit() {
    if (!_isFormValid) {
      setState(() => _hasSubmittedOnce = true);
      return;
    }

    setState(() {
      _hasSubmittedOnce = true;
      _errorMessage = null;
    });

    context.read<AuthBloc>().add(
          AuthLoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  void _handleAuthStateChange(AuthState state) {
    if (state is AuthLoading) {
      // Loading state
    } else if (state is AuthAuthenticated) {
      // Evitar reentrada si ya se procesó el login exitoso
      if (_isSuccess) return;

      // Verificar que es admin o staff
      final role = state.user.role.name;
      if (role == 'admin' || role == 'staff') {
        setState(() => _isSuccess = true);
        HapticFeedback.mediumImpact();

        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            // Primero navegar, luego cerrar el bottom sheet
            context.go(AppRoutes.staffDashboard);
            Navigator.of(context).pop();
          }
        });
      } else {
        // Usuario no autorizado para el panel admin
        setState(() {
          _errorMessage = S.of(context).auth_admin_error_unauthorized;
        });
        HapticFeedback.vibrate();
      }
    } else if (state is AuthError) {
      setState(() {
        _errorMessage = state.message;
      });
      HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isDark = AppColors.isDarkMode(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _handleAuthStateChange(state),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 8,
              bottom: bottomPadding + 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  _buildDragHandle(),
                  const SizedBox(height: 24),

                  // Header
                  _buildHeader(isDark),
                  const SizedBox(height: 28),

                  // Campos del formulario
                  _buildEmailField(isDark),
                  const SizedBox(height: 16),
                  _buildPasswordField(isDark),
                  const SizedBox(height: 8),

                  // Mensaje de error
                  _buildErrorMessage(),
                  const SizedBox(height: 24),

                  // Botón de acceso
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.goldDark.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        // Título
        Text(
          S.of(context).auth_admin_sheet_title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: isDark ? AppColors.white : AppColors.black,
            fontFamily: 'Playfair Display',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),

        // Subtítulo
        Text(
          S.of(context).auth_admin_sheet_subtitle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            color: isDark ? AppColors.darkTextSecondary : AppColors.gray500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField(bool isDark) {
    final hasError = _hasSubmittedOnce && !_isEmailValid && _emailController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          S.of(context).auth_admin_label_email,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.gray500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),

        // Input
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.gray50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError
                  ? AppColors.error
                  : _emailFocusNode.hasFocus
                      ? AppColors.gold
                      : isDark
                          ? AppColors.goldDark.withValues(alpha: 0.3)
                          : AppColors.gray200,
              width: 1,
            ),
          ),
          child: Focus(
            onFocusChange: (hasFocus) => setState(() {}),
            child: TextFormField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              autofillHints: const [AutofillHints.email],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.white : AppColors.black,
              ),
              decoration: InputDecoration(
                hintText: S.of(context).auth_admin_hint_email,
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  color: AppColors.gray400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(bool isDark) {
    final hasError = _hasSubmittedOnce && !_isPasswordValid && _passwordController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          S.of(context).auth_admin_label_password,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.gray500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),

        // Input
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.gray50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError
                  ? AppColors.error
                  : _passwordFocusNode.hasFocus
                      ? AppColors.gold
                      : isDark
                          ? AppColors.goldDark.withValues(alpha: 0.3)
                          : AppColors.gray200,
              width: 1,
            ),
          ),
          child: Focus(
            onFocusChange: (hasFocus) => setState(() {}),
            child: TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: _obscurePassword,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              autofillHints: const [AutofillHints.password],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.white : AppColors.black,
              ),
              decoration: InputDecoration(
                hintText: S.of(context).auth_admin_hint_password,
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  color: AppColors.gray400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.gray500,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              onFieldSubmitted: (_) => _handleSubmit(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 14,
              color: AppColors.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return SizedBox(
          width: double.infinity,
          height: 52,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              // El botón siempre es gold, solo cambia a verde en éxito
              color: _isSuccess ? AppColors.success : AppColors.gold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: isLoading || _isSuccess ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.black,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: Colors.transparent,
                disabledForegroundColor: AppColors.black,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isSuccess
                    ? const Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: AppColors.black,
                      )
                    : isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.black,
                              ),
                            ),
                          )
                        : Text(
                            S.of(context).auth_admin_submit_button,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.black,
                            ),
                          ),
              ),
            ),
          ),
        );
      },
    );
  }
}
