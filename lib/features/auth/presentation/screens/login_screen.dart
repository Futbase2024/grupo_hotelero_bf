import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/responsive.dart';
import '../../domain/bloc/auth_bloc.dart';
import '../widgets/logo_tap_trigger.dart';

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
    final isDark = AppColors.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.white,
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

  /// Layout para tablet: dos columnas con branding a la izquierda
  Widget _buildTabletLayout(BuildContext context, bool isLoading) {
    final isDark = AppColors.isDarkMode(context);

    return Row(
      children: [
        // Panel izquierdo - Branding
        Expanded(
          flex: 5,
          child: Container(
            color: isDark ? AppColors.black : AppColors.white,
            child: _buildBrandingPanel(context),
          ),
        ),
        // Panel derecho - Formulario
        Expanded(
          flex: 5,
          child: Container(
            color: isDark ? AppColors.darkSurface : AppColors.gray50,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacing48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buildForm(context, isLoading),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Layout para desktop: similar a tablet pero con más espacio
  Widget _buildDesktopLayout(BuildContext context, bool isLoading) {
    final isDark = AppColors.isDarkMode(context);

    return Row(
      children: [
        // Panel izquierdo - Branding
        Expanded(
          flex: 6,
          child: Container(
            color: isDark ? AppColors.black : AppColors.white,
            child: _buildBrandingPanel(context, showFeatures: true),
          ),
        ),
        // Panel derecho - Formulario
        Expanded(
          flex: 4,
          child: Container(
            color: isDark ? AppColors.darkSurface : AppColors.gray50,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacing64),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buildForm(context, isLoading),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Panel de branding con logo y título
  Widget _buildBrandingPanel(BuildContext context, {bool showFeatures = false}) {
    final isDark = AppColors.isDarkMode(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo circular
            _buildCircularLogo(context, size: 100),
            const SizedBox(height: AppTheme.spacing32),

            // Título
            Text(
              'BF Stay',
              style: TextStyle(
                fontSize: ResponsiveFontSize.headlineLarge(context),
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),

            // Subtítulo
            Text(
              'Panel de Control',
              style: TextStyle(
                fontSize: ResponsiveFontSize.titleMedium(context),
                color: isDark ? AppColors.gray400 : AppColors.gray600,
              ),
            ),

            if (showFeatures) ...[
              const SizedBox(height: AppTheme.spacing48),
              _buildFeatureList(context),
            ],
          ],
        ),
      ),
    );
  }

  /// Logo circular estilo dashboard
  Widget _buildCircularLogo(BuildContext context, {double? size}) {
    final logoSize = size ?? 80.0;

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        color: AppColors.gold,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.goldWithAlpha30,
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          'assets/icons/logo.png',
          width: logoSize * 0.6,
          height: logoSize * 0.6,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Text(
            'BF',
            style: TextStyle(
              fontSize: logoSize * 0.35,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
        ),
      ),
    );
  }

  /// Lista de features minimalista
  Widget _buildFeatureList(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    final features = [
      (Icons.hotel_outlined, 'Gestión de reservas', AppColors.success),
      (Icons.people_outline, 'Check-in digital', AppColors.warning),
      (Icons.chat_outlined, 'Chat con huéspedes', AppColors.info),
      (Icons.key_outlined, 'Acceso sin llaves', AppColors.gold),
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(feature.$1, color: feature.$3, size: 22),
              const SizedBox(width: AppTheme.spacing12),
              Text(
                feature.$2,
                style: TextStyle(
                  fontSize: ResponsiveFontSize.bodyMedium(context),
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildForm(BuildContext context, bool isLoading) {
    final isDark = AppColors.isDarkMode(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo solo en móvil
          if (context.isMobile) ...[
            const SizedBox(height: AppTheme.spacing24),
            LogoTapTrigger(
              onTriggered: () => context.go('/booking-access'),
              child: _buildCircularLogo(context),
            ),
            const SizedBox(height: AppTheme.spacing24),
            Text(
              'BF Stay',
              style: TextStyle(
                fontSize: ResponsiveFontSize.headlineMedium(context),
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Panel de Control',
              style: TextStyle(
                fontSize: ResponsiveFontSize.bodyMedium(context),
                color: isDark ? AppColors.gray400 : AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing40),
          ] else ...[
            const SizedBox(height: AppTheme.spacing24),
          ],

          // Email field - estilo minimalista
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray600),
              prefixIcon: Icon(Icons.email_outlined, color: isDark ? AppColors.gray400 : AppColors.gray600),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: const BorderSide(color: AppColors.gold, width: 2),
              ),
            ),
            style: TextStyle(
              fontSize: ResponsiveFontSize.bodyMedium(context),
              color: isDark ? AppColors.white : AppColors.black,
            ),
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
              labelStyle: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray600),
              prefixIcon: Icon(Icons.lock_outlined, color: isDark ? AppColors.gray400 : AppColors.gray600),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: const BorderSide(color: AppColors.gold, width: 2),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            style: TextStyle(
              fontSize: ResponsiveFontSize.bodyMedium(context),
              color: isDark ? AppColors.white : AppColors.black,
            ),
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
              onPressed: isLoading ? null : () => _showForgotPasswordDialog(context),
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  fontSize: ResponsiveFontSize.bodySmall(context),
                  color: AppColors.gold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),

          // Login button - estilo minimalista
          SizedBox(
            height: AppTheme.buttonHeightLarge,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                      ),
                    )
                  : Text(
                      'Iniciar Sesión',
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.labelLarge(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),

          // Divider minimalista
          Row(
            children: [
              Expanded(child: Divider(color: isDark ? AppColors.darkBorder : AppColors.gray200)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                child: Text(
                  'o',
                  style: TextStyle(
                    fontSize: ResponsiveFontSize.bodySmall(context),
                    color: isDark ? AppColors.gray400 : AppColors.gray600,
                  ),
                ),
              ),
              Expanded(child: Divider(color: isDark ? AppColors.darkBorder : AppColors.gray200)),
            ],
          ),
          const SizedBox(height: AppTheme.spacing24),

          // Guest access button - minimalista
          SizedBox(
            height: AppTheme.buttonHeightLarge,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : () => context.go('/booking-access'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.gray200),
                foregroundColor: isDark ? AppColors.white : AppColors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              icon: Icon(Icons.key_outlined, color: AppColors.gold),
              label: Text(
                'Acceso con código de reserva',
                style: TextStyle(
                  fontSize: ResponsiveFontSize.labelLarge(context),
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing32),

          // Footer minimalista
          Text(
            'BF Stay © 2026',
            style: TextStyle(
              fontSize: ResponsiveFontSize.bodySmall(context),
              color: isDark ? AppColors.gray400 : AppColors.gray600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    final isDark = AppColors.isDarkMode(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Text(
          'Recuperar Contraseña',
          style: TextStyle(
            fontSize: ResponsiveFontSize.titleLarge(dialogContext),
            color: isDark ? AppColors.white : AppColors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingresa tu email y te enviaremos instrucciones para restablecer tu contraseña.',
              style: TextStyle(
                fontSize: ResponsiveFontSize.bodyMedium(dialogContext),
                color: isDark ? AppColors.gray400 : AppColors.gray600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray600),
                prefixIcon: Icon(Icons.email_outlined, color: isDark ? AppColors.gray400 : AppColors.gray600),
                filled: true,
                fillColor: isDark ? AppColors.black : AppColors.gray50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.gray200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: const BorderSide(color: AppColors.gold, width: 2),
                ),
              ),
              style: TextStyle(
                fontSize: ResponsiveFontSize.bodyMedium(dialogContext),
                color: isDark ? AppColors.white : AppColors.black,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontSize: ResponsiveFontSize.labelLarge(dialogContext),
                color: isDark ? AppColors.gray400 : AppColors.gray600,
              ),
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
                  SnackBar(
                    content: const Text('Email de recuperación enviado'),
                    backgroundColor: AppColors.gold,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: Text(
              'Enviar',
              style: TextStyle(fontSize: ResponsiveFontSize.labelLarge(dialogContext)),
            ),
          ),
        ],
      ),
    );
  }
}
