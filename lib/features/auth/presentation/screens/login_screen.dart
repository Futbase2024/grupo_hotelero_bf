import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/responsive.dart';
import '../../domain/bloc/auth_bloc.dart';

/// Pantalla de login para personal (staff/admin)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(AuthLoginRequested(
          email: _emailController.text,
          password: _passwordController.text,
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
          child: _buildForm(context, isLoading),
        ),
      ),
    );
  }

  /// Layout para tablet: dos columnas con imagen/promo a la izquierda
  Widget _buildTabletLayout(BuildContext context, bool isLoading) {
    return Row(
      children: [
        // Panel izquierdo - Branding
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.black,
                  AppColors.black.withValues(alpha: 0.9),
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
                      'BF Stay',
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.headlineLarge(context),
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    Text(
                      'Sistema de Gestión de Huéspedes',
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.titleMedium(context),
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
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
                child: _buildForm(context, isLoading),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Layout para desktop: similar a tablet pero con más espacio
  Widget _buildDesktopLayout(BuildContext context, bool isLoading) {
    return Row(
      children: [
        // Panel izquierdo - Branding más grande
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.black,
                  AppColors.black.withValues(alpha: 0.95),
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
                      'BF Stay',
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.headlineLarge(context),
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    Text(
                      'Sistema de Gestión de Huéspedes',
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.titleLarge(context),
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacing48),
                    // Features list
                    _buildFeatureItem(context, Icons.hotel_outlined, 'Gestión de reservas'),
                    const SizedBox(height: AppTheme.spacing16),
                    _buildFeatureItem(context, Icons.people_outline, 'Check-in digital'),
                    const SizedBox(height: AppTheme.spacing16),
                    _buildFeatureItem(context, Icons.chat_outlined, 'Chat con huéspedes'),
                    const SizedBox(height: AppTheme.spacing16),
                    _buildFeatureItem(context, Icons.key_outlined, 'Acceso sin llaves'),
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
                child: _buildForm(context, isLoading),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.gold, size: 24),
        const SizedBox(width: AppTheme.spacing12),
        Text(
          text,
          style: TextStyle(
            fontSize: ResponsiveFontSize.bodyMedium(context),
            color: AppColors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo solo en móvil
          if (context.isMobile) ...[
            const SizedBox(height: AppTheme.spacing32),
            _buildLogo(context),
            const SizedBox(height: AppTheme.spacing32),
          ] else ...[
            const SizedBox(height: AppTheme.spacing24),
          ],

          // Título
          Text(
            'Bienvenido',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: ResponsiveFontSize.headlineMedium(context),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Inicia sesión para continuar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: ResponsiveFontSize.bodyMedium(context),
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.responsive(mobile: AppTheme.spacing32, tablet: AppTheme.spacing40)),

          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            style: TextStyle(fontSize: ResponsiveFontSize.bodyMedium(context)),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu email';
              }
              if (!value.contains('@')) {
                return 'Por favor ingresa un email válido';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
            onFieldSubmitted: (_) => _handleLogin(),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            style: TextStyle(fontSize: ResponsiveFontSize.bodyMedium(context)),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu contraseña';
              }
              if (value.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacing8),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading
                  ? null
                  : () => _showForgotPasswordDialog(context),
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(fontSize: ResponsiveFontSize.bodySmall(context)),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),

          // Login button
          SizedBox(
            height: AppTheme.buttonHeightLarge,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleLogin,
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
                      'Iniciar Sesión',
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.labelLarge(context),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing32),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                ),
                child: Text(
                  'o',
                  style: TextStyle(fontSize: ResponsiveFontSize.bodySmall(context)),
                ),
              ),
              Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: AppTheme.spacing32),

          // Guest access button
          SizedBox(
            height: AppTheme.buttonHeightLarge,
            child: OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => context.go('/booking-access'),
              icon: const Icon(Icons.key_outlined),
              label: Text(
                'Acceso con código de reserva',
                style: TextStyle(
                  fontSize: ResponsiveFontSize.labelLarge(context),
                ),
              ),
            ),
          ),
          SizedBox(height: context.responsive(mobile: AppTheme.spacing32, tablet: AppTheme.spacing48)),

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

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Recuperar Contraseña',
          style: TextStyle(fontSize: ResponsiveFontSize.titleLarge(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingresa tu email y te enviaremos instrucciones para restablecer tu contraseña.',
              style: TextStyle(fontSize: ResponsiveFontSize.bodyMedium(context)),
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              style: TextStyle(fontSize: ResponsiveFontSize.bodyMedium(context)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancelar',
              style: TextStyle(fontSize: ResponsiveFontSize.labelLarge(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                context.read<AuthBloc>().add(
                      AuthPasswordResetRequested(email: emailController.text),
                    );
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email de recuperación enviado'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: Text(
              'Enviar',
              style: TextStyle(fontSize: ResponsiveFontSize.labelLarge(context)),
            ),
          ),
        ],
      ),
    );
  }
}
