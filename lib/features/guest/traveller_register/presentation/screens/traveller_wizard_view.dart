import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../admin/shared/widgets/info_dialog.dart';
import '../../../checkin/domain/repositories/checkin_repository.dart';
import '../../domain/repositories/traveller_register_repository.dart';
import '../bloc/traveller_wizard_bloc.dart';
import '../bloc/traveller_wizard_event.dart';
import '../bloc/traveller_wizard_state.dart';
import '../traveller_l10n.dart';
import '../widgets/identification_form.dart';
import '../widgets/residence_contact_form.dart';
import '../widgets/review_signature_step.dart';
import '../widgets/traveller_selector.dart';

/// Check-in con el formulario de registro de viajeros (RD 933/2021).
///
/// Solo se muestra si el staff lo ha activado en la reserva
/// (`bookings.traveller_form_enabled`); si no, el check-in sigue siendo el de
/// fotos del documento.
class TravellerWizardView extends StatelessWidget {
  const TravellerWizardView({
    super.key,
    required this.booking,
    required this.onSubmitted,
  });

  final CheckinBookingData booking;

  /// El check-in se ha enviado correctamente
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TravellerWizardBloc(
        repository: getIt<TravellerRegisterRepository>(),
        checkinRepository: getIt<CheckinRepository>(),
      )..add(TravellerWizardStarted(booking)),
      child: _TravellerWizardBody(booking: booking, onSubmitted: onSubmitted),
    );
  }
}

class _TravellerWizardBody extends StatelessWidget {
  const _TravellerWizardBody({required this.booking, required this.onSubmitted});

  final CheckinBookingData booking;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TravellerWizardBloc, TravellerWizardState>(
      listenWhen: (previous, current) =>
          previous.errorCode != current.errorCode || previous.status != current.status,
      listener: (context, state) async {
        if (state.status == TravellerWizardStatus.submitted) {
          onSubmitted();
          return;
        }
        final code = state.errorCode;
        if (code != null && state.status == TravellerWizardStatus.ready) {
          final s = S.of(context);
          final bloc = context.read<TravellerWizardBloc>();
          await InfoDialog.error(
            context,
            title: s.guest_traveller_error_title,
            message: s.travellerErrorMessage(code),
          );
          bloc.add(const TravellerWizardErrorDismissed());
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case TravellerWizardStatus.loading:
          case TravellerWizardStatus.submitted:
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          case TravellerWizardStatus.failure:
            return _LoadFailedView(booking: booking);
          case TravellerWizardStatus.ready:
            return _WizardContent(state: state);
        }
      },
    );
  }
}

class _LoadFailedView extends StatelessWidget {
  const _LoadFailedView({required this.booking});

  final CheckinBookingData booking;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(s.guest_traveller_load_error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context
                  .read<TravellerWizardBloc>()
                  .add(TravellerWizardStarted(booking)),
              child: Text(s.guest_traveller_retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _WizardContent extends StatelessWidget {
  const _WizardContent({required this.state});

  final TravellerWizardState state;

  static const double _maxContentWidth = 720;

  @override
  Widget build(BuildContext context) {
    final index = state.selectedIndex.clamp(0, state.travellers.length - 1);

    final Widget body;
    switch (state.step) {
      case 0:
        body = IdentificationForm(
          key: ValueKey('identification-$index'),
          state: state,
          index: index,
        );
      case 1:
        body = ResidenceContactForm(
          key: ValueKey('residence-$index'),
          state: state,
          index: index,
        );
      default:
        body = ReviewSignatureStep(state: state);
    }

    return Column(
      children: [
        _StepHeader(step: state.step),
        if (state.isBusy)
          const LinearProgressIndicator(minHeight: 2, color: AppColors.gold)
        else
          const SizedBox(height: 2),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.step < 2) ...[
                      if (state.step == 0) ...[
                        Text(
                          S.of(context).guest_traveller_intro,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: AppColors.getTextSecondaryColor(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TravellerSelector(state: state),
                      const SizedBox(height: 20),
                    ],
                    body,
                  ],
                ),
              ),
            ),
          ),
        ),
        _NavigationBar(state: state),
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final titles = [
      s.guest_traveller_step_identification,
      s.guest_traveller_step_residence,
      s.guest_traveller_step_review,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: AppColors.getSurfaceColor(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _WizardContent._maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.guest_traveller_step_counter(step + 1, TravellerWizardState.stepCount),
                style: TextStyle(fontSize: 12, color: AppColors.getTextTertiaryColor(context)),
              ),
              const SizedBox(height: 2),
              Text(
                titles[step],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 0; i < TravellerWizardState.stepCount; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= step ? AppColors.gold : AppColors.getBorderColor(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationBar extends StatelessWidget {
  const _NavigationBar({required this.state});

  final TravellerWizardState state;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final bloc = context.read<TravellerWizardBloc>();
    final isLast = state.step == TravellerWizardState.stepCount - 1;
    final canSubmit = state.registerStatus?.isComplete ?? false;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(context),
        border: Border(top: BorderSide(color: AppColors.getBorderColor(context))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _WizardContent._maxContentWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLast && !canSubmit)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    s.guest_traveller_submit_pending,
                    style: const TextStyle(fontSize: 12, color: AppColors.warning),
                  ),
                ),
              Row(
                children: [
                  if (state.step > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: state.isBusy
                            ? null
                            : () => bloc.add(TravellerWizardStepRequested(state.step - 1)),
                        child: Text(s.guest_traveller_back),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: state.isBusy || (isLast && !canSubmit)
                          ? null
                          : () => bloc.add(
                                isLast
                                    ? const TravellerWizardSubmitRequested()
                                    : TravellerWizardStepRequested(state.step + 1),
                              ),
                      child: Text(isLast ? s.guest_traveller_submit : s.guest_traveller_next),
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
