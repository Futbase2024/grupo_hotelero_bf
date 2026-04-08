import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/bloc/auth_bloc.dart';
import '../formatters/bf_code_formatter.dart';

/// Pantalla de acceso para huéspedes mediante código de reserva
class BookingAccessScreen extends StatefulWidget {
  const BookingAccessScreen({super.key});

  @override
  State<BookingAccessScreen> createState() => _BookingAccessScreenState();
}

class _BookingAccessScreenState extends State<BookingAccessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookingCodeController = TextEditingController(text: BfCodeFormatter.initialValue);

  @override
  void dispose() {
    _bookingCodeController.dispose();
    super.dispose();
  }

  void _handleAccess() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(AuthLoginWithBookingRequested(
          bookingCode: _bookingCodeController.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              _showErrorDialog(context, state.message);
            }

            if (state is AuthAuthenticated) {
              // El router manejará la redirección
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return ResponsiveLayout(
              mobile: (context) => _buildMobileLayout(context, isLoading),
              tablet: (context) => _buildTabletLayout(context, isLoading),
              desktop: (context) => _buildDesktopLayout(context, isLoading),
            );
          },
        ),
      ),
    );
  }

  /// Layout para móvil: formulario centrado con scroll
  Widget _buildMobileLayout(BuildContext context, bool isLoading) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.contentPaddingHorizontal),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _buildForm(context, isLoading, showBackButton: true),
        ),
      ),
    );
  }

  /// Layout para tablet: dos columnas con panel informativo
  Widget _buildTabletLayout(BuildContext context, bool isLoading) {
    final isDark = AppColors.isDarkMode(context);

    return Row(
      children: [
        // Panel izquierdo - Informativo
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.gold.withValues(alpha: 0.15),
                        AppColors.gold.withValues(alpha: 0.08),
                      ]
                    : [
                        AppColors.gold.withValues(alpha: 0.1),
                        AppColors.gold.withValues(alpha: 0.05),
                      ],
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLogo(context, size: 120),
                    const SizedBox(height: AppTheme.spacing32),
                    Text(
                      S.of(context).auth_booking_access_title,
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.headlineMedium(context),
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    _buildBenefitItem(context, Icons.confirmation_number_outlined, S.of(context).auth_booking_benefit_code),
                    const SizedBox(height: AppTheme.spacing16),
                    _buildBenefitItem(context, Icons.person_outline, S.of(context).auth_booking_benefit_personal),
                    const SizedBox(height: AppTheme.spacing16),
                    _buildBenefitItem(context, Icons.phone_android_outlined, S.of(context).auth_booking_benefit_instant),
                    const SizedBox(height: AppTheme.spacing32),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      decoration: BoxDecoration(
                        color: AppColors.getCardColor(context).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Text(
                        S.of(context).auth_booking_code_info_short,
                        style: TextStyle(
                          fontSize: ResponsiveFontSize.bodySmall(context),
                          color: AppColors.getTextSecondaryColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Panel derecho - Formulario
        Expanded(
          flex: 5,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: _buildForm(context, isLoading, showBackButton: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Layout para desktop: similar a tablet
  Widget _buildDesktopLayout(BuildContext context, bool isLoading) {
    final isDark = AppColors.isDarkMode(context);

    return Row(
      children: [
        // Panel izquierdo - Informativo más grande
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.gold.withValues(alpha: 0.2),
                        AppColors.gold.withValues(alpha: 0.1),
                      ]
                    : [
                        AppColors.gold.withValues(alpha: 0.15),
                        AppColors.gold.withValues(alpha: 0.05),
                      ],
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing64),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLogo(context, size: 140),
                    const SizedBox(height: AppTheme.spacing40),
                    Text(
                      S.of(context).auth_booking_access_title,
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.headlineLarge(context),
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    Text(
                      S.of(context).auth_booking_desktop_subtitle,
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.titleMedium(context),
                        color: AppColors.getTextSecondaryColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacing48),
                    _buildBenefitItem(context, Icons.confirmation_number_outlined, S.of(context).auth_booking_benefit_code),
                    const SizedBox(height: AppTheme.spacing20),
                    _buildBenefitItem(context, Icons.person_outline, S.of(context).auth_booking_benefit_personal),
                    const SizedBox(height: AppTheme.spacing20),
                    _buildBenefitItem(context, Icons.phone_android_outlined, S.of(context).auth_booking_benefit_instant),
                    const SizedBox(height: AppTheme.spacing20),
                    _buildBenefitItem(context, Icons.lock_outline, S.of(context).auth_booking_benefit_secure_checkin),
                    const SizedBox(height: AppTheme.spacing40),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing20),
                      decoration: BoxDecoration(
                        color: AppColors.getCardColor(context).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.email_outlined, color: AppColors.gold, size: 32),
                          const SizedBox(height: AppTheme.spacing12),
                          Text(
                            S.of(context).auth_booking_code_info_full,
                            style: TextStyle(
                              fontSize: ResponsiveFontSize.bodyMedium(context),
                              color: AppColors.getTextSecondaryColor(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Panel derecho - Formulario
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing64),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: _buildForm(context, isLoading, showBackButton: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing8),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, color: AppColors.gold, size: 24),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Text(
          text,
          style: TextStyle(
            fontSize: ResponsiveFontSize.bodyLarge(context),
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, bool isLoading, {required bool showBackButton}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button solo en móvil
          if (showBackButton) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () {
                  // Verificar si hay historial para hacer pop
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    // Si no hay historial, ir a la home pública
                    context.go('/');
                  }
                },
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
          ],

          // Logo solo en móvil
          if (context.isMobile) ...[
            _buildLogo(context),
            const SizedBox(height: AppTheme.spacing32),
          ],

          // Título
          Text(
            S.of(context).auth_booking_access_title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: ResponsiveFontSize.headlineMedium(context),
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimaryColor(context),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            S.of(context).auth_booking_form_subtitle,
            style: TextStyle(
              fontSize: ResponsiveFontSize.bodyMedium(context),
              color: AppColors.getTextSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.responsive(mobile: AppTheme.spacing32, tablet: AppTheme.spacing40)),

          // Booking code field with real-time validation
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _bookingCodeController,
                  inputFormatters: [BfCodeFormatter()],
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => _handleAccess(),
                  decoration: InputDecoration(
                    labelText: S.of(context).auth_booking_field_code,
                    prefixIcon: const Icon(Icons.confirmation_number_outlined),
                    hintText: S.of(context).auth_booking_code_hint,
                  ),
                  style: TextStyle(
                    fontSize: ResponsiveFontSize.bodyMedium(context),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context).auth_booking_validation_code_required;
                    }
                    if (!BfCodeFormatter.isValid(value)) {
                      return S.of(context).auth_booking_validation_code_invalid;
                    }
                    return null;
                  },
                ),
              ),
              // Real-time validation indicator
              if (_bookingCodeController.text.isNotEmpty) ...[
                const SizedBox(width: AppTheme.spacing12),
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacing16),
                  child: _buildValidationIndicator(),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spacing32),

          // Access button
          SizedBox(
            height: AppTheme.buttonHeightLarge,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleAccess,
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      S.of(context).auth_booking_access_button,
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.labelLarge(context),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing32),

          // Help section (solo en móvil)
          if (context.isMobile) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: AppColors.getGoldWithAlpha(context, alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: AppColors.gold,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Text(
                        S.of(context).auth_booking_help_title,
                        style: TextStyle(
                          fontSize: ResponsiveFontSize.titleSmall(context),
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    S.of(context).auth_booking_help_body,
                    style: TextStyle(
                      fontSize: ResponsiveFontSize.bodySmall(context),
                      color: AppColors.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing32),
          ],

          // Footer
          Text(
            S.of(context).auth_booking_footer,
            style: TextStyle(
              fontSize: ResponsiveFontSize.bodySmall(context),
              color: AppColors.getTextTertiaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de error profesional
  void _showErrorDialog(BuildContext context, String message) {
    final isDark = AppColors.isDarkMode(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            color: isDark ? AppColors.darkSurface : AppColors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppTheme.spacing20),
              Text(
                S.of(context).auth_booking_error_title,
                style: TextStyle(
                  fontSize: ResponsiveFontSize.titleLarge(dialogContext),
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.gray900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                _getErrorMessage(message),
                style: TextStyle(
                  fontSize: ResponsiveFontSize.bodyMedium(dialogContext),
                  color: isDark ? AppColors.gray400 : AppColors.gray700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  child: Text(
                    S.of(context).auth_booking_error_dismiss,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Traduce los mensajes de error tecnicos a mensajes amigables
  String _getErrorMessage(String technicalMessage) {
    if (technicalMessage.contains('booking not found') ||
        technicalMessage.contains('code_not_found')) {
      return S.of(context).auth_booking_error_code_not_found;
    }
    if (technicalMessage.contains('code_expired')) {
      return S.of(context).auth_booking_error_code_expired;
    }
    if (technicalMessage.contains('email_mismatch')) {
      return S.of(context).auth_booking_error_email_mismatch;
    }
    // Mensaje generico para otros errores
    return S.of(context).auth_booking_error_generic;
  }

  /// Indicador de validación en tiempo real
  Widget _buildValidationIndicator() {
    final code = _bookingCodeController.text;
    final isValid = BfCodeFormatter.isValid(code);
    final isComplete = BfCodeFormatter.isComplete(code);

    if (!isComplete) {
      // Código incompleto - mostrar progreso
      final cleanCode = code.replaceAll('-', '');
      final progress = cleanCode.length / BfCodeFormatter.rawLength;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              color: AppColors.gold.withValues(alpha: 0.6),
              backgroundColor: AppColors.gray200,
            ),
          ),
        ],
      );
    }

    if (isValid) {
      // Código válido
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 24,
        ),
      );
    }

    // Código completo pero inválido
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.cancel,
        color: AppColors.error,
        size: 24,
      ),
    );
  }

  Widget _buildLogo(BuildContext context, {double? size}) {
    final logoSize = size ?? context.responsive<double>(mobile: 80.0, tablet: 100.0, desktop: 120.0);

    return Center(
      child: SizedBox(
        width: logoSize,
        height: logoSize,
        child: Image.asset(
          'assets/icons/logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
