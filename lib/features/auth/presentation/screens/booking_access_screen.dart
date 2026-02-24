import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppTheme.spacing32),

                      // Back button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => context.go('/login'),
                          icon: const Icon(Icons.arrow_back),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing16),

                      // Logo
                      _buildLogo(),
                      const SizedBox(height: AppTheme.spacing32),

                      // Título
                      Text(
                        'Acceso de Huésped',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Text(
                        'Ingresa tu código de reserva y apellido para acceder',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacing40),

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
                              : const Text('Acceder'),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing32),

                      // Help section
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
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing48),

                      // Footer
                      Text(
                        'BF Stay © 2024',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'BF',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
