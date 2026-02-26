import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/bloc/auth_bloc.dart';
import '../formatters/bf_code_formatter.dart';

/// Modal bottom sheet elegante para login de huéspedes
///
/// Se abre con una animación desde abajo y contiene:
/// - Campo de email
/// - Campo de código de reserva (BF-XXXX-XXXX)
/// - Validación en tiempo real
/// - Animaciones de éxito/error
class LoginBottomSheet extends StatefulWidget {
  const LoginBottomSheet({super.key});

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
      builder: (context) => const LoginBottomSheet(),
    );
  }

  @override
  State<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<LoginBottomSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _codeFocusNode = FocusNode();

  bool _isEmailValid = false;
  bool _isCodeValid = false;
  bool _hasSubmittedOnce = false;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _codeController.addListener(_validateCode);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    _codeController.removeListener(_validateCode);
    _emailController.dispose();
    _codeController.dispose();
    _emailFocusNode.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final email = _emailController.text;
    final isValid = _isValidEmail(email);
    if (_isEmailValid != isValid) {
      setState(() => _isEmailValid = isValid);
    }
  }

  void _validateCode() {
    final code = _codeController.text;
    final isValid = BfCodeFormatter.isValidFormat(code);
    if (_isCodeValid != isValid) {
      setState(() => _isCodeValid = isValid);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim());
  }

  bool get _isFormValid => _isEmailValid && _isCodeValid;

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
          AuthLoginWithBookingAndEmailRequested(
            email: _emailController.text.trim(),
            bookingCode: _codeController.text.trim(),
          ),
        );
  }

  void _handleAuthStateChange(AuthState state) {
    if (state is AuthLoading) {
      // Loading state - no hacer nada especial
    } else if (state is AuthAuthenticated) {
      // Éxito - mostrar animación y cerrar
      setState(() => _isSuccess = true);
      HapticFeedback.mediumImpact();

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.of(context).pop();
          // Navegar según el rol del usuario
          if (state.user.role.name == 'staff' ||
              state.user.role.name == 'admin') {
            context.go(AppRoutes.staffDashboard);
          } else {
            context.go(AppRoutes.guestHome);
          }
        }
      });
    } else if (state is AuthError) {
      // Error - mostrar mensaje
      setState(() {
        _errorMessage = state.message;
      });
      HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = AppColors.isDarkMode(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _handleAuthStateChange(state),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
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

                // Header con logo
                _buildHeader(isDark),
                const SizedBox(height: 32),

                // Campos del formulario
                _buildEmailField(isDark),
                const SizedBox(height: 16),
                _buildCodeField(isDark),
                const SizedBox(height: 8),

                // Mensaje de error
                _buildErrorMessage(),
                const SizedBox(height: 24),

                // Botón de acceso
                _buildSubmitButton(isDark),
                const SizedBox(height: 16),

                // Texto de ayuda
                _buildHelpText(isDark),
              ],
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
        // Logo pequeño en dorado
        SizedBox(
          width: 80,
          height: 26,
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              AppColors.gold,
              BlendMode.srcIn,
            ),
            child: Image.asset(
              'assets/icons/logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Título
        Text(
          'Acceso a tu reserva',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: isDark ? AppColors.white : AppColors.black,
            fontFamily: 'Playfair Display',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Subtítulo
        Text(
          'Introduce tu correo y el código que recibiste',
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
          'CORREO ELECTRÓNICO',
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
                hintText: 'tu@correo.com',
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  color: isDark ? AppColors.gray400 : AppColors.gray400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onFieldSubmitted: (_) => _codeFocusNode.requestFocus(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeField(bool isDark) {
    final hasError = _hasSubmittedOnce && !_isCodeValid && _codeController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'CÓDIGO DE RESERVA',
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
                  : _codeFocusNode.hasFocus
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
              controller: _codeController,
              focusNode: _codeFocusNode,
              inputFormatters: [
                BfCodeFormatter(),
                LengthLimitingTextInputFormatter(12),
              ],
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.white : AppColors.black,
                letterSpacing: 2.0,
                fontFamily: 'JetBrains Mono',
              ),
              decoration: InputDecoration(
                hintText: 'BF-XXXX-XXXX',
                hintStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: isDark ? AppColors.gray400 : AppColors.gray400,
                  letterSpacing: 2.0,
                  fontFamily: 'JetBrains Mono',
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                suffixIcon: _codeController.text.isEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.content_paste_rounded,
                          size: 18,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.gray500,
                        ),
                        onPressed: _pasteFromClipboard,
                      )
                    : null,
              ),
              onFieldSubmitted: (_) => _handleSubmit(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _codeController.text = data!.text!.toUpperCase();
    }
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

  Widget _buildSubmitButton(bool isDark) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final isDisabled = !_isFormValid && !_hasSubmittedOnce;

        return SizedBox(
          width: double.infinity,
          height: 52,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _isSuccess
                  ? AppColors.success
                  : isDisabled
                      ? isDark
                          ? AppColors.darkSurface
                          : AppColors.gray100
                      : AppColors.gold,
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
                disabledForegroundColor: isDark
                    ? AppColors.gray400
                    : AppColors.gray400,
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
                            'Acceder a mi reserva',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDisabled
                                  ? isDark
                                      ? AppColors.gray400
                                      : AppColors.gray400
                                  : AppColors.black,
                            ),
                          ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelpText(bool isDark) {
    return Text(
      '¿No tienes tu código? Contacta con tu alojamiento',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w300,
        color: isDark ? AppColors.gray400 : AppColors.gray400,
      ),
      textAlign: TextAlign.center,
    );
  }
}
