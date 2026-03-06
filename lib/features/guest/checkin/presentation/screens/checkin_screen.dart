import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/core/theme/app_theme.dart';
import 'package:bf_stay/core/theme/responsive.dart';
import 'package:bf_stay/features/auth/domain/bloc/auth_bloc.dart';
import 'package:bf_stay/features/guest/checkin/presentation/bloc/checkin_bloc.dart';
import 'package:bf_stay/features/guest/checkin/presentation/bloc/checkin_event.dart';
import 'package:bf_stay/features/guest/checkin/presentation/bloc/checkin_state.dart';
import 'package:bf_stay/features/guest/checkin/presentation/widgets/guest_form_card.dart';
import 'package:bf_stay/features/guest/checkin/presentation/widgets/document_upload_sheet.dart';
import 'package:bf_stay/features/guest/checkin/domain/entities/guest_entity.dart';

/// Pantalla de Check-in para huéspedes con gestión de múltiples huéspedes
class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CheckinBloc>().add(CheckinStarted(widget.bookingId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<CheckinBloc>().add(
              CheckinRefreshRequested(widget.bookingId),
            );
          },
          child: BlocConsumer<CheckinBloc, CheckinState>(
            listener: _handleStateChange,
            builder: (context, state) {
              if (state is CheckinLoading) {
                return const _LoadingView();
              }
              if (state is CheckinLoaded) {
                return _buildLoadedView(context, state);
              }
              if (state is CheckinSubmitting) {
                return const _SubmittingView();
              }
              if (state is CheckinAlreadyCompleted) {
                return _CheckinCompletedView(
                  state: state,
                  bookingId: widget.bookingId,
                );
              }
              if (state is CheckinError) {
                return _ErrorView(message: state.message);
              }
              return const _LoadingView();
            },
          ),
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
      title: const Text('Check-in Online'),
    );
  }

  void _handleStateChange(BuildContext context, CheckinState state) {
    if (state is CheckinSuccess) {
      // Refrescar el estado del usuario para actualizar checkInCompleted
      context.read<AuthBloc>().add(const AuthCheckRequested());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in completado exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/guest');
    }
  }

  Widget _buildLoadedView(BuildContext context, CheckinLoaded state) {
    return ResponsiveLayout(
      mobile: (context) => _MobileLayout(state: state),
      tablet: (context) => _TabletLayout(state: state),
      desktop: (context) => _DesktopLayout(state: state),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LOADING / ERROR / SUBMITTING VIEWS
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
            'Cargando datos de la reserva...',
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
            'Enviando check-in...',
            style: TextStyle(color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}

class _CheckinCompletedView extends StatelessWidget {
  const _CheckinCompletedView({
    required this.state,
    required this.bookingId,
  });

  final CheckinAlreadyCompleted state;
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: state.isValidated
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                state.isValidated ? Icons.check_circle : Icons.pending_actions,
                size: 80,
                color: state.isValidated ? AppColors.success : AppColors.gold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              state.isValidated ? 'Check-in Validado' : 'Check-in Completado',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              state.statusMessage,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
            // Indicador de espera si está pendiente de validación
            if (!state.isValidated) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.gold.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Esperando validación...',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.home, color: AppColors.gold, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.bookingData.unitName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.gold, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${_formatDate(state.bookingData.checkInDate)} - ${_formatDate(state.bookingData.checkOutDate)}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people, color: AppColors.gold, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${state.guests.length} huésped${state.guests.length != 1 ? 'es' : ''} registrado${state.guests.length != 1 ? 's' : ''}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

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
                final currentState = context.read<CheckinBloc>().state;
                if (currentState is CheckinLoaded) {
                  context.read<CheckinBloc>().add(CheckinStarted(
                    currentState.bookingData.bookingId,
                  ));
                }
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
// STEP INFO
// ═══════════════════════════════════════════════════════════════

class _StepInfo {
  final IconData icon;
  final String title;

  const _StepInfo({required this.icon, required this.title});
}

const List<_StepInfo> _steps = [
  _StepInfo(icon: Icons.people_outline, title: 'Huéspedes'),
  _StepInfo(icon: Icons.badge_outlined, title: 'Documentos'),
  _StepInfo(icon: Icons.draw_outlined, title: 'Firma'),
  _StepInfo(icon: Icons.check_circle_outline, title: 'Confirmar'),
];

// ═══════════════════════════════════════════════════════════════
// MOBILE LAYOUT
// ═══════════════════════════════════════════════════════════════

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.state});

  final CheckinLoaded state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildLinearProgressIndicator(context, state.currentStep),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(context.contentPaddingHorizontal),
            child: _buildCurrentStep(context),
          ),
        ),
        _buildNavigationButtons(context),
      ],
    );
  }

  Widget _buildLinearProgressIndicator(BuildContext context, int currentStep) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? AppColors.gold
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 3) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (state.currentStep) {
      case 0:
        return _GuestsStep(state: state);
      case 1:
        return _DocumentsStep(state: state);
      case 2:
        return _SignatureStep(state: state);
      case 3:
        return _ConfirmationStep(state: state);
      default:
        return _GuestsStep(state: state);
    }
  }

  Widget _buildNavigationButtons(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (state.currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _onPrevious(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppColors.gold : AppColors.black,
                    side: BorderSide(
                      color: isDark ? AppColors.gold : AppColors.blackWithAlpha30,
                    ),
                  ),
                  child: const Text('Atrás'),
                ),
              ),
            if (state.currentStep > 0) const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: ElevatedButton(
                onPressed: state.isCurrentStepComplete
                    ? () => _onNext(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.black,
                  disabledBackgroundColor: AppColors.gray600,
                ),
                child: Text(
                  state.currentStep == 3 ? 'Completar' : 'Continuar',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPrevious(BuildContext context) {
    context.read<CheckinBloc>().add(CheckinStepChanged(state.currentStep - 1));
  }

  void _onNext(BuildContext context) {
    if (state.currentStep == 3) {
      context.read<CheckinBloc>().add(const CheckinSubmitted());
    } else {
      context.read<CheckinBloc>().add(CheckinStepChanged(state.currentStep + 1));
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// TABLET LAYOUT
// ═══════════════════════════════════════════════════════════════

class _TabletLayout extends StatelessWidget {
  const _TabletLayout({required this.state});

  final CheckinLoaded state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HorizontalStepper(currentStep: state.currentStep),
        Expanded(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacing32),
                child: _buildCurrentStep(context),
              ),
            ),
          ),
        ),
        _NavigationButtons(state: state),
      ],
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (state.currentStep) {
      case 0:
        return _GuestsStep(state: state);
      case 1:
        return _DocumentsStep(state: state);
      case 2:
        return _SignatureStep(state: state);
      case 3:
        return _ConfirmationStep(state: state);
      default:
        return _GuestsStep(state: state);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// DESKTOP LAYOUT
// ═══════════════════════════════════════════════════════════════

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.state});

  final CheckinLoaded state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left panel - Stepper
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: AppColors.isDarkMode(context)
                ? AppColors.darkSurface
                : AppColors.backgroundCard,
            border: Border(
              right: BorderSide(color: AppColors.getBorderColor(context)),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing24),
                  child: Text(
                    'Progreso del Check-in',
                    style: TextStyle(
                      fontSize: ResponsiveFontSize.titleMedium(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: _VerticalStepper(currentStep: state.currentStep),
                ),
              ],
            ),
          ),
        ),
        // Right panel - Content
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spacing48),
                      child: _buildCurrentStep(context),
                    ),
                  ),
                ),
              ),
              _NavigationButtons(state: state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (state.currentStep) {
      case 0:
        return _GuestsStep(state: state);
      case 1:
        return _DocumentsStep(state: state);
      case 2:
        return _SignatureStep(state: state);
      case 3:
        return _ConfirmationStep(state: state);
      default:
        return _GuestsStep(state: state);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// HORIZONTAL STEPPER
// ═══════════════════════════════════════════════════════════════

class _HorizontalStepper extends StatelessWidget {
  const _HorizontalStepper({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing24,
        vertical: AppTheme.spacing16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_steps.length, (index) {
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;
          final step = _steps[index];

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepCircle(
                index: index,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                step: step,
              ),
              if (index < _steps.length - 1)
                Container(
                  width: 40,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: isCompleted ? AppColors.gold : AppColors.border,
                ),
            ],
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// VERTICAL STEPPER
// ═══════════════════════════════════════════════════════════════

class _VerticalStepper extends StatelessWidget {
  const _VerticalStepper({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      itemCount: _steps.length,
      itemBuilder: (context, index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;
        final step = _steps[index];
        final isLast = index == _steps.length - 1;

        Color bgColor;
        Color iconColor;

        if (isCompleted) {
          bgColor = AppColors.success;
          iconColor = Colors.white;
        } else if (isCurrent) {
          bgColor = AppColors.gold;
          iconColor = Colors.white;
        } else {
          bgColor = AppColors.border;
          iconColor = AppColors.textSecondary;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : step.icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 48,
                    color: isCompleted ? AppColors.gold : AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  step.title,
                  style: TextStyle(
                    fontSize: ResponsiveFontSize.bodyMedium(context),
                    color: isCurrent ? AppColors.gold : AppColors.textSecondary,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STEP CIRCLE
// ═══════════════════════════════════════════════════════════════

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.index,
    required this.isCompleted,
    required this.isCurrent,
    required this.step,
  });

  final int index;
  final bool isCompleted;
  final bool isCurrent;
  final _StepInfo step;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color iconColor;
    Color textColor;

    if (isCompleted) {
      bgColor = AppColors.success;
      iconColor = Colors.white;
      textColor = AppColors.textPrimary;
    } else if (isCurrent) {
      bgColor = AppColors.gold;
      iconColor = Colors.white;
      textColor = AppColors.gold;
    } else {
      bgColor = AppColors.border;
      iconColor = AppColors.textSecondary;
      textColor = AppColors.textSecondary;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : step.icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          step.title,
          style: TextStyle(
            fontSize: ResponsiveFontSize.bodySmall(context),
            color: textColor,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// NAVIGATION BUTTONS
// ═══════════════════════════════════════════════════════════════

class _NavigationButtons extends StatelessWidget {
  const _NavigationButtons({required this.state});

  final CheckinLoaded state;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Row(
              children: [
                if (state.currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _onPrevious(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppColors.gold : AppColors.black,
                        side: BorderSide(
                          color: isDark ? AppColors.gold : AppColors.blackWithAlpha30,
                        ),
                      ),
                      child: const Text('Atrás'),
                    ),
                  ),
                if (state.currentStep > 0) const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.isCurrentStepComplete
                        ? () => _onNext(context)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.black,
                      disabledBackgroundColor: AppColors.gray600,
                    ),
                    child: Text(
                      state.currentStep == 3 ? 'Completar' : 'Continuar',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onPrevious(BuildContext context) {
    context.read<CheckinBloc>().add(CheckinStepChanged(state.currentStep - 1));
  }

  void _onNext(BuildContext context) {
    if (state.currentStep == 3) {
      context.read<CheckinBloc>().add(const CheckinSubmitted());
    } else {
      context.read<CheckinBloc>().add(CheckinStepChanged(state.currentStep + 1));
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// GUESTS STEP
// ═══════════════════════════════════════════════════════════════

class _GuestsStep extends StatelessWidget {
  const _GuestsStep({required this.state});

  final CheckinLoaded state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Datos de los Huéspedes',
          style: TextStyle(
            fontSize: ResponsiveFontSize.headlineSmall(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Completa los datos de todos los huéspedes. Los niños menores de 14 años no requieren documentación.',
          style: TextStyle(
            fontSize: ResponsiveFontSize.bodyMedium(context),
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),

        // Resumen de huéspedes
        _buildGuestsSummary(context),
        const SizedBox(height: AppTheme.spacing24),

        // Lista de huéspedes
        ...state.guests.asMap().entries.map((entry) {
          final index = entry.key;
          final guest = entry.value;

          return GuestFormCard(
            guest: guest,
            index: index,
            onChanged: (updatedGuest) {
              context.read<CheckinBloc>().add(CheckinGuestUpdated(
                index,
                updatedGuest,
              ));
            },
            onDocumentUpload: guest.needsDocument
                ? () => _handleDocumentUpload(context, index)
                : null,
          );
        }),
      ],
    );
  }

  Widget _buildGuestsSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.goldWithAlpha10,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.goldWithAlpha30),
      ),
      child: Row(
        children: [
          Icon(Icons.people, color: AppColors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${state.totalGuests} huéspedes: ${state.bookingData.numAdults} adultos, ${state.bookingData.numChildren} niños',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!state.allGuestsHaveName)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Pendiente',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleDocumentUpload(BuildContext context, int guestIndex) {
    final currentState = context.read<CheckinBloc>().state;
    if (currentState is! CheckinLoaded) return;

    final guest = currentState.guests[guestIndex];

    DocumentUploadSheet.show(
      context: context,
      guest: guest,
      onConfirm: (type, number, imageBytes) {
        context.read<CheckinBloc>().add(CheckinGuestDocumentUpdated(
          guestIndex: guestIndex,
          documentType: type,
          documentNumber: number,
          imageBytes: imageBytes,
        ));
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DOCUMENTS STEP
// ═══════════════════════════════════════════════════════════════

class _DocumentsStep extends StatelessWidget {
  const _DocumentsStep({required this.state});

  final CheckinLoaded state;

  @override
  Widget build(BuildContext context) {
    final guestsRequiringDocs = state.guestsRequiringDocument;
    final guestsWithDocs = state.guestsWithDocument;
    final guestsPendingDocs = state.guestsPendingDocument;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documentos de Identidad',
          style: TextStyle(
            fontSize: ResponsiveFontSize.headlineSmall(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Sube el documento de identidad de cada huésped mayor de 14 años.',
          style: TextStyle(
            fontSize: ResponsiveFontSize.bodyMedium(context),
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),

        // Progress
        _buildDocumentsProgress(context, guestsWithDocs, guestsRequiringDocs),
        const SizedBox(height: AppTheme.spacing24),

        // Lista de documentos pendientes
        if (guestsPendingDocs.isNotEmpty) ...[
          Text(
            'Documentos pendientes',
            style: TextStyle(
              fontSize: ResponsiveFontSize.titleMedium(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          ...guestsPendingDocs.map((guest) => _buildPendingDocumentCard(context, guest)),
        ],

        // Lista de documentos completados
        if (guestsWithDocs.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'Documentos subidos',
            style: TextStyle(
              fontSize: ResponsiveFontSize.titleMedium(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          ...guestsWithDocs.map((guest) => _buildCompletedDocumentCard(context, guest)),
        ],
      ],
    );
  }

  Widget _buildDocumentsProgress(
    BuildContext context,
    List<GuestEntity> guestsWithDocs,
    List<GuestEntity> guestsRequiringDocs,
  ) {
    final completed = guestsWithDocs.length;
    final total = guestsRequiringDocs.length;
    final progress = total > 0 ? completed / total : 1.0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: state.allDocumentsComplete
            ? AppColors.successLight
            : AppColors.goldWithAlpha10,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                state.allDocumentsComplete ? Icons.check_circle : Icons.upload_file,
                color: state.allDocumentsComplete ? AppColors.success : AppColors.gold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$completed de $total documentos subidos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: state.allDocumentsComplete
                        ? AppColors.success
                        : AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                state.allDocumentsComplete ? AppColors.success : AppColors.gold,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingDocumentCard(BuildContext context, GuestEntity guest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.badge_outlined,
              color: AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guest.fullName.isEmpty ? 'Huésped sin nombre' : guest.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  guest.isChildOver14
                      ? 'Joven (${guest.age} años) - Documento requerido'
                      : 'Documento requerido',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement document upload
            },
            icon: const Icon(Icons.upload, size: 18),
            label: const Text('Subir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedDocumentCard(BuildContext context, GuestEntity guest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guest.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${guest.documentType?.name.toUpperCase() ?? "Documento"}: ${guest.documentNumber}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.gray500, size: 20),
            onPressed: () {
              // TODO: Implement edit document
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SIGNATURE STEP
// ═══════════════════════════════════════════════════════════════

class _SignatureStep extends StatefulWidget {
  const _SignatureStep({required this.state});

  final CheckinLoaded state;

  @override
  State<_SignatureStep> createState() => _SignatureStepState();
}

class _SignatureStepState extends State<_SignatureStep> {
  final List<Offset?> _points = [];
  bool _hasSignature = false;

  @override
  void initState() {
    super.initState();
    _hasSignature = widget.state.signatureSvg != null &&
        widget.state.signatureSvg!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Firma del Titular',
          style: TextStyle(
            fontSize: ResponsiveFontSize.headlineSmall(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Firma con tu dedo en el área de abajo para confirmar los datos.',
          style: TextStyle(
            fontSize: ResponsiveFontSize.bodyMedium(context),
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),

        // Signature area
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: _hasSignature ? AppColors.success : AppColors.border,
              width: _hasSignature ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) {
                setState(() {
                  _points.add(details.localPosition);
                  _hasSignature = true;
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _points.add(details.localPosition);
                });
              },
              onPanEnd: (details) {
                setState(() {
                  _points.add(null); // Separation between strokes
                });
                _saveSignature();
              },
              child: SizedBox.expand(
                child: CustomPaint(
                  painter: SignaturePainter(points: List.from(_points)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Clear button
        if (_points.isNotEmpty)
          Center(
            child: TextButton.icon(
              onPressed: _clearSignature,
              icon: const Icon(Icons.clear, color: AppColors.gray500),
              label: const Text(
                'Borrar firma',
                style: TextStyle(color: AppColors.gray500),
              ),
            ),
          ),

        // Status
        const SizedBox(height: AppTheme.spacing16),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: _hasSignature
                ? AppColors.successLight
                : AppColors.warningLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Row(
            children: [
              Icon(
                _hasSignature ? Icons.check_circle : Icons.edit,
                color: _hasSignature ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 12),
              Text(
                _hasSignature
                    ? 'Firma capturada correctamente'
                    : 'Pendiente de firma',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _hasSignature ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _clearSignature() {
    setState(() {
      _points.clear();
      _hasSignature = false;
    });
    context.read<CheckinBloc>().add(const CheckinSignatureSaved(null));
  }

  void _saveSignature() {
    // Convert points to SVG path
    final svgPath = _pointsToSvgPath();
    if (svgPath.isNotEmpty) {
      context.read<CheckinBloc>().add(CheckinSignatureSaved(svgPath));
    }
  }

  String _pointsToSvgPath() {
    if (_points.isEmpty) return '';

    final buffer = StringBuffer();
    bool isFirst = true;

    for (final point in _points) {
      if (point == null) {
        isFirst = true;
        continue;
      }

      if (isFirst) {
        buffer.write('M ${point.dx} ${point.dy} ');
        isFirst = false;
      } else {
        buffer.write('L ${point.dx} ${point.dy} ');
      }
    }

    // Devolver SVG completo con color gold
    return '<path d="$buffer" stroke="#D4AF37" stroke-width="3" stroke-linecap="round" fill="none"/>';
  }
}

class SignaturePainter extends CustomPainter {
  SignaturePainter({required this.points});

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.gold
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Crear un path para cada trazo continuo
    Path? currentPath;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      if (point == null) {
        // Fin del trazo actual, dibujarlo si existe
        if (currentPath != null) {
          canvas.drawPath(currentPath, paint);
          currentPath = null;
        }
      } else {
        if (currentPath == null) {
          // Iniciar nuevo trazo
          currentPath = Path();
          currentPath.moveTo(point.dx, point.dy);
        } else {
          // Continuar el trazo con línea suave
          currentPath.lineTo(point.dx, point.dy);
        }
      }
    }

    // Dibujar el último path si existe
    if (currentPath != null) {
      canvas.drawPath(currentPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SignaturePainter oldDelegate) {
    // Siempre repintar cuando los puntos son diferentes
    if (points.length != oldDelegate.points.length) return true;

    // Comparar el último punto para detectar cambios durante el dibujo
    if (points.isNotEmpty && oldDelegate.points.isNotEmpty) {
      final currentLast = points.last;
      final oldLast = oldDelegate.points.last;
      // Comparar valores de Offset, no referencias
      if (currentLast == null && oldLast == null) return false;
      if (currentLast == null || oldLast == null) return true;
      if (currentLast.dx != oldLast.dx || currentLast.dy != oldLast.dy) return true;
    }

    return false;
  }
}

// ═══════════════════════════════════════════════════════════════
// CONFIRMATION STEP
// ═══════════════════════════════════════════════════════════════

class _ConfirmationStep extends StatelessWidget {
  const _ConfirmationStep({required this.state});

  final CheckinLoaded state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirmación',
          style: TextStyle(
            fontSize: ResponsiveFontSize.headlineSmall(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Revisa que todos los datos sean correctos antes de enviar.',
          style: TextStyle(
            fontSize: ResponsiveFontSize.bodyMedium(context),
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),

        // Resumen de la reserva
        _buildBookingSummary(context),
        const SizedBox(height: AppTheme.spacing24),

        // Resumen de huéspedes
        _buildGuestsSummary(context),
        const SizedBox(height: AppTheme.spacing24),

        // Estado de documentos
        _buildDocumentsStatus(context),
        const SizedBox(height: AppTheme.spacing24),

        // Estado de firma
        _buildSignatureStatus(context),

        // Aviso legal
        const SizedBox(height: AppTheme.spacing24),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: AppColors.infoLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Al completar el check-in, confirmas que los datos proporcionados son correctos y aceptas las normas de la casa.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.getTextSecondaryColor(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingSummary(BuildContext context) {
    final booking = state.bookingData;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hotel, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(
                'Reserva',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            context,
            'Código',
            booking.bookingCode,
            Icons.confirmation_number_outlined,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            context,
            'Check-in',
            '${booking.checkInDate.day}/${booking.checkInDate.month}/${booking.checkInDate.year}',
            Icons.login,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            context,
            'Check-out',
            '${booking.checkOutDate.day}/${booking.checkOutDate.month}/${booking.checkOutDate.year}',
            Icons.logout,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            context,
            'Huéspedes',
            '${booking.numAdults} adultos, ${booking.numChildren} niños',
            Icons.people,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.gray500),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.getTextSecondaryColor(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildGuestsSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(
                'Huéspedes (${state.guests.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...state.guests.map((guest) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  guest.isChildUnder14
                      ? Icons.child_care
                      : guest.isPrimary
                          ? Icons.star
                          : Icons.person,
                  size: 20,
                  color: guest.isChildUnder14
                      ? AppColors.success
                      : guest.isPrimary
                          ? AppColors.gold
                          : AppColors.gray500,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    guest.fullName.isEmpty ? 'Sin nombre' : guest.fullName,
                    style: TextStyle(
                      fontSize: 14,
                      color: guest.isReadOnly
                          ? AppColors.gray500
                          : AppColors.getTextPrimaryColor(context),
                    ),
                  ),
                ),
                if (guest.isPrimary)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.goldWithAlpha20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'TITULAR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                if (guest.isChildUnder14)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'MENOR 14',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDocumentsStatus(BuildContext context) {
    final isComplete = state.allDocumentsComplete;
    final completed = state.guestsWithDocument.length;
    final total = state.guestsRequiringDocument.length;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: isComplete ? AppColors.successLight : AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.warning,
            color: isComplete ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isComplete
                  ? 'Todos los documentos subidos'
                  : '$completed de $total documentos subidos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isComplete ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureStatus(BuildContext context) {
    final hasSignature = state.signatureSvg != null && state.signatureSvg!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: hasSignature ? AppColors.successLight : AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(
            hasSignature ? Icons.draw : Icons.edit_off,
            color: hasSignature ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 12),
          Text(
            hasSignature ? 'Firma capturada' : 'Pendiente de firma',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: hasSignature ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
