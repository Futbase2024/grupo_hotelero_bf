import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/core/theme/app_theme.dart';
import 'package:bf_stay/core/theme/responsive.dart';
import 'package:bf_stay/features/auth/domain/bloc/auth_bloc.dart';
import 'package:bf_stay/features/guest/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:bf_stay/features/guest/checkout/presentation/bloc/checkout_event.dart';
import 'package:bf_stay/features/guest/checkout/presentation/bloc/checkout_state.dart';

/// Pantalla de Check-out para huéspedes
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CheckoutBloc>().add(CheckoutStarted(widget.bookingId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: BlocConsumer<CheckoutBloc, CheckoutState>(
          listener: _handleStateChange,
          builder: (context, state) {
            if (state is CheckoutLoading) {
              return const _LoadingView();
            }
            if (state is CheckoutLoaded) {
              return _CheckoutSummaryView(state: state);
            }
            if (state is CheckoutSubmitting) {
              return const _SubmittingView();
            }
            if (state is CheckoutSuccess) {
              return const _SuccessView();
            }
            if (state is CheckoutError) {
              return _ErrorView(message: state.message, bookingId: widget.bookingId);
            }
            return const _LoadingView();
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/guest'),
      ),
      title: const Text('Check-out'),
    );
  }

  void _handleStateChange(BuildContext context, CheckoutState state) {
    if (state is CheckoutSuccess) {
      // Refrescar el estado del usuario
      context.read<AuthBloc>().add(const AuthCheckRequested());

      // Redirigir automáticamente a la pantalla inicial
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          context.go('/guest');
        }
      });
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// LOADING / SUBMITTING / ERROR VIEWS
// ═══════════════════════════════════════════════════════════════

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.gold),
          SizedBox(height: 16),
          Text(
            'Cargando datos de la estancia...',
            style: TextStyle(color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}

class _SubmittingView extends StatelessWidget {
  const _SubmittingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.gold),
          SizedBox(height: 16),
          Text(
            'Procesando check-out...',
            style: TextStyle(color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.bookingId});

  final String message;
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: AppColors.gray500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<CheckoutBloc>().add(CheckoutStarted(bookingId));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.black,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SUCCESS VIEW
// ═══════════════════════════════════════════════════════════════

class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 80,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Check-out Completado!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Gracias por tu estancia. ¡Esperamos verte pronto!',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/guest'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: const Text(
                  'Volver al inicio',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CHECKOUT SUMMARY VIEW
// ═══════════════════════════════════════════════════════════════

class _CheckoutSummaryView extends StatefulWidget {
  const _CheckoutSummaryView({required this.state});

  final CheckoutLoaded state;

  @override
  State<_CheckoutSummaryView> createState() => _CheckoutSummaryViewState();
}

class _CheckoutSummaryViewState extends State<_CheckoutSummaryView> {
  final _feedbackController = TextEditingController();
  int _rating = 0;
  bool _showConfirmationDialog = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.isAlreadyCheckedOut) {
      return _buildAlreadyCheckedOutView(context);
    }

    if (_showConfirmationDialog) {
      return _buildConfirmationDialog(context);
    }

    return _buildSummaryForm(context);
  }

  Widget _buildAlreadyCheckedOutView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline,
                size: 80,
                color: AppColors.info,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Check-out ya realizado',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Ya has completado el check-out de esta reserva.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/guest'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: const Text(
                  'Volver al inicio',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryForm(BuildContext context) {
    final booking = widget.state.bookingData;
    final dateFormat = DateFormat('d MMMM yyyy');

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.contentPaddingHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),
          const SizedBox(height: AppTheme.spacing24),

          // Resumen de la estancia
          _buildStaySummaryCard(context, booking, dateFormat),
          const SizedBox(height: AppTheme.spacing24),

          // Rating opcional
          _buildRatingSection(context),
          const SizedBox(height: AppTheme.spacing24),

          // Feedback opcional
          _buildFeedbackSection(context),
          const SizedBox(height: AppTheme.spacing32),

          // Botón de confirmar
          _buildConfirmButton(context),
          const SizedBox(height: AppTheme.spacing24),

          // Info
          _buildInfoCard(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen de tu estancia',
          style: TextStyle(
            fontSize: ResponsiveFontSize.headlineSmall(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Revisa los datos y confirma tu check-out cuando estés listo para salir.',
          style: TextStyle(
            fontSize: ResponsiveFontSize.bodyMedium(context),
            color: AppColors.getTextSecondaryColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildStaySummaryCard(
    BuildContext context,
    dynamic booking,
    DateFormat dateFormat,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Column(
        children: [
          // Alojamiento
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home_outlined,
                  color: AppColors.black,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.unitName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      booking.propertyName,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: AppTheme.spacing24, color: AppColors.getBorderColor(context)),

          // Fechas
          Row(
            children: [
              Expanded(
                child: _buildDateItem(
                  context,
                  Icons.login,
                  'Check-in',
                  dateFormat.format(booking.checkInDate),
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: _buildDateItem(
                  context,
                  Icons.logout,
                  'Check-out',
                  dateFormat.format(booking.checkOutDate),
                  isHighlighted: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Huéspedes y noches
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  context,
                  Icons.people_outline,
                  '${booking.numGuests} huéspedes',
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: _buildInfoItem(
                  context,
                  Icons.bed_outlined,
                  '${booking.stayNights} ${booking.stayNights == 1 ? 'noche' : 'noches'}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateItem(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.gold.withValues(alpha: 0.1)
            : AppColors.getSurfaceSecondaryColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: isHighlighted
            ? Border.all(color: AppColors.gold)
            : null,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isHighlighted ? AppColors.gold : AppColors.getTextSecondaryColor(context),
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isHighlighted ? AppColors.gold : AppColors.getTextPrimaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: AppColors.getTextSecondaryColor(context),
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cómo fue tu estancia? (opcional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            return IconButton(
              onPressed: () {
                setState(() {
                  _rating = starValue;
                });
              },
              icon: Icon(
                starValue <= _rating ? Icons.star : Icons.star_border,
                color: AppColors.gold,
                size: 36,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comentarios adicionales (opcional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        TextField(
          controller: _feedbackController,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Cuéntanos sobre tu experiencia...',
            hintStyle: TextStyle(color: AppColors.getTextSecondaryColor(context)),
            filled: true,
            fillColor: AppColors.getInputBackgroundColor(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppColors.getBorderColor(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppColors.getBorderColor(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: const BorderSide(color: AppColors.gold, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _showConfirmationDialog = true;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: const Text(
          'Confirmar Check-out',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.info),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Al confirmar el check-out, indicas que has recogido todas tus pertenencias y dejado el alojamiento.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getTextSecondaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationDialog(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.help_outline,
                  size: 48,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '¿Confirmar check-out?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '¿Estás seguro de que deseas finalizar tu estancia?',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.getTextSecondaryColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showConfirmationDialog = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.getTextPrimaryColor(context),
                        side: BorderSide(color: AppColors.getBorderColor(context)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<CheckoutBloc>().add(CheckoutConfirmed(
                          feedback: _feedbackController.text.trim().isEmpty
                              ? null
                              : _feedbackController.text.trim(),
                          rating: _rating > 0 ? _rating : null,
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
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
