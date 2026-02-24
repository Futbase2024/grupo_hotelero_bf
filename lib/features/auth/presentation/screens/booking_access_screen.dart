import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/responsive.dart';
import '../../domain/bloc/auth_bloc.dart';

/// Pantalla de acceso para huéspedes mediante código de reserva
class BookingAccessScreen extends StatefulWidget {
  const BookingAccessScreen({super.key});

  @override
  State<BookingAccessScreen> createState() => _BookingAccessScreenState();
}

class _BookingAccessScreenState extends State<BookingAccessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookingCodeController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void dispose() {
    _bookingCodeController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _handleAccess() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(AuthLoginWithBookingRequested(
          bookingCode: _bookingCodeController.text,
          lastName: _lastNameController.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
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
                colors: [
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
                      'Acceso de Huésped',
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.headlineMedium(context),
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    _buildBenefitItem(context, Icons.confirmation_number_outlined, 'Código de reserva'),
                    const SizedBox(height: AppTheme.spacing16),
                    _buildBenefitItem(context, Icons.person_outline, 'Tu apellido'),
                    const SizedBox(height: AppTheme.spacing16),
                    _buildBenefitItem(context, Icons.phone_android_outlined, 'Acceso instantáneo'),
                    const SizedBox(height: AppTheme.spacing32),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Text(
                        'El código de reserva lo recibiste en el email de confirmación.',
                        style: TextStyle(
                          fontSize: ResponsiveFontSize.bodySmall(context),
                          color: AppColors.textSecondary,
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
                colors: [
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
                      'Acceso de Huésped',
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.headlineLarge(context),
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    Text(
                      'Disfruta de tu estancia con acceso digital',
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.titleMedium(context),
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacing48),
                    _buildBenefitItem(context, Icons.confirmation_number_outlined, 'Código de reserva'),
                    const SizedBox(height: AppTheme.spacing20),
                    _buildBenefitItem(context, Icons.person_outline, 'Tu apellido'),
                    const SizedBox(height: AppTheme.spacing20),
                    _buildBenefitItem(context, Icons.phone_android_outlined, 'Acceso instantáneo'),
                    const SizedBox(height: AppTheme.spacing20),
                    _buildBenefitItem(context, Icons.lock_outline, 'Check-in seguro'),
                    const SizedBox(height: AppTheme.spacing40),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing20),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        boxShadow: [
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
                            'El código de reserva lo recibiste en el email de confirmación de tu reserva.',
                            style: TextStyle(
                              fontSize: ResponsiveFontSize.bodyMedium(context),
                              color: AppColors.textSecondary,
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
          child: Icon(icon, color: AppColors.goldDark, size: 24),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Text(
          text,
          style: TextStyle(
            fontSize: ResponsiveFontSize.bodyLarge(context),
            color: AppColors.textPrimary,
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
                onPressed: () => context.go('/login'),
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
            'Acceso de Huésped',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: ResponsiveFontSize.headlineMedium(context),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Ingresa tu código de reserva y apellido para acceder',
            style: TextStyle(
              fontSize: ResponsiveFontSize.bodyMedium(context),
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.responsive(mobile: AppTheme.spacing32, tablet: AppTheme.spacing40)),

          // Booking code field
          TextFormField(
            controller: _bookingCodeController,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Código de Reserva',
              prefixIcon: Icon(Icons.confirmation_number_outlined),
              hintText: 'BF-XXXXX',
            ),
            style: TextStyle(fontSize: ResponsiveFontSize.bodyMedium(context)),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu código de reserva';
              }
              if (value.length < 4) {
                return 'El código debe tener al menos 4 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Last name field
          TextFormField(
            controller: _lastNameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
            onFieldSubmitted: (_) => _handleAccess(),
            decoration: const InputDecoration(
              labelText: 'Apellido',
              prefixIcon: Icon(Icons.person_outlined),
              hintText: 'Tu apellido tal como aparece en la reserva',
            ),
            style: TextStyle(fontSize: ResponsiveFontSize.bodyMedium(context)),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu apellido';
              }
              return null;
            },
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
                      'Acceder',
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
                color: AppColors.goldWithAlpha10,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
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
                        '¿Dónde encuentro mi código?',
                        style: TextStyle(
                          fontSize: ResponsiveFontSize.titleSmall(context),
                          color: AppColors.goldDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    'El código de reserva lo recibiste en el email de confirmación de tu reserva. '
                    'Tiene el formato BF-XXXXX.',
                    style: TextStyle(
                      fontSize: ResponsiveFontSize.bodySmall(context),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing32),
          ],

          // Footer
          Text(
            'BF Stay © 2024',
            style: TextStyle(
              fontSize: ResponsiveFontSize.bodySmall(context),
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
