import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/countries.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/traveller_entity.dart';
import '../../domain/entities/traveller_register_status.dart';
import '../../domain/validators/traveller_form_rules.dart';
import '../bloc/traveller_wizard_bloc.dart';
import '../bloc/traveller_wizard_event.dart';
import '../bloc/traveller_wizard_state.dart';
import '../traveller_l10n.dart';
import 'signature_pad.dart';
import 'traveller_form_widgets.dart';

/// Pantalla 3: resumen de cada huésped, protección de datos y firma del
/// parte de entrada (una por huésped de 14 años o más)
class ReviewSignatureStep extends StatelessWidget {
  const ReviewSignatureStep({super.key, required this.state});

  final TravellerWizardState state;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.guest_traveller_review_intro,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: AppColors.getTextSecondaryColor(context),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < state.travellers.length; i++) ...[
          _TravellerReviewCard(state: state, index: i),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        const _PrivacyCard(),
      ],
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final textStyle = TextStyle(
      fontSize: 12,
      height: 1.45,
      color: AppColors.getTextSecondaryColor(context),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 18, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(
                s.guest_traveller_privacy_title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(s.guest_traveller_privacy_body, style: textStyle),
          const SizedBox(height: 8),
          Text(s.guest_traveller_signature_meaning, style: textStyle),
        ],
      ),
    );
  }
}

class _TravellerReviewCard extends StatelessWidget {
  const _TravellerReviewCard({required this.state, required this.index});

  final TravellerWizardState state;
  final int index;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final traveller = state.travellers[index];
    final status = traveller.id == null ? null : state.registerStatus?.guest(traveller.id!);
    final age = traveller.ageOn(state.effectiveCheckinDate);
    final blocking = status?.issues.where((i) => i.isBlocking).toList() ?? const [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (status?.isDone ?? false)
              ? AppColors.success
              : AppColors.getBorderColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  traveller.fullName.isEmpty
                      ? s.guest_traveller_guest_n(index + 1)
                      : traveller.fullName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
              ),
              if (age != null)
                Text(
                  s.guest_traveller_age_on_checkin(age),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextTertiaryColor(context),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _TravellerSummary(traveller: traveller),
          if (blocking.isNotEmpty) ...[
            const SizedBox(height: 12),
            _IssuesBox(issues: blocking, index: index),
          ],
          const SizedBox(height: 12),
          _SignatureArea(state: state, traveller: traveller, status: status),
        ],
      ),
    );
  }
}

class _TravellerSummary extends StatelessWidget {
  const _TravellerSummary({required this.traveller});

  final TravellerEntity traveller;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final type = traveller.documentType;
    final birth = traveller.birthDate;

    final lines = <String>[
      if (type != null && traveller.documentNumber.isNotEmpty)
        '${s.documentTypeLabel(type)} ${traveller.documentNumber}',
      if (birth != null) '${s.guest_traveller_birth_date}: ${DateFormat.yMd(locale).format(birth)}',
      if (traveller.nationality != null)
        '${s.guest_traveller_nationality}: '
            '${countryByAlpha3(traveller.nationality)?.nameFor(language) ?? traveller.nationality}',
      if (traveller.residenceAddress.isNotEmpty)
        [
          traveller.residenceAddress,
          traveller.residenceCity,
          countryByAlpha3(traveller.residenceCountry)?.nameFor(language) ?? '',
        ].where((part) => part.isNotEmpty).join(', '),
      [traveller.mobile, traveller.landline, traveller.email]
          .where((part) => part.isNotEmpty)
          .join(' · '),
    ].where((line) => line.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              line,
              style: TextStyle(fontSize: 13, color: AppColors.getTextSecondaryColor(context)),
            ),
          ),
      ],
    );
  }
}

class _IssuesBox extends StatelessWidget {
  const _IssuesBox({required this.issues, required this.index});

  final List<TravellerIssue> issues;
  final int index;

  static const _identificationFields = {
    TravellerField.firstName,
    TravellerField.lastName1,
    TravellerField.sex,
    TravellerField.birthDate,
    TravellerField.nationality,
    TravellerField.documentType,
    TravellerField.documentNumber,
    TravellerField.supportNumber,
    'register_format',
  };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fields = issues.map((i) => s.fieldLabel(i.field)).toSet().join(', ');
    final step = issues.any((i) => _identificationFields.contains(i.field)) ? 0 : 1;
    final bloc = context.read<TravellerWizardBloc>();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${s.guest_traveller_issues_title} $fields',
              style: const TextStyle(fontSize: 13, color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () {
              bloc
                ..add(TravellerWizardStepRequested(step))
                ..add(TravellerWizardTravellerSelected(index));
            },
            child: Text(s.guest_traveller_edit),
          ),
        ],
      ),
    );
  }
}

class _SignatureArea extends StatelessWidget {
  const _SignatureArea({
    required this.state,
    required this.traveller,
    required this.status,
  });

  final TravellerWizardState state;
  final TravellerEntity traveller;
  final TravellerGuestStatus? status;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final current = status;
    if (current == null) return const SizedBox.shrink();

    if (!current.needsOwnSignature) {
      final responsible = _findById(traveller.responsibleGuestId);
      return _StatusLine(
        icon: current.coveredByResponsible ? Icons.check_circle : Icons.schedule,
        color: current.coveredByResponsible ? AppColors.success : AppColors.warning,
        text: current.coveredByResponsible && responsible != null
            ? s.guest_traveller_covered_by(responsible.fullName)
            : s.guest_traveller_pending_responsible_signature,
      );
    }

    if (current.signed) {
      return _StatusLine(
        icon: Icons.verified,
        color: AppColors.success,
        text: s.guest_traveller_signed,
      );
    }

    if (!current.canSign) return const SizedBox.shrink();

    final minors = state.travellers.where((t) {
      final age = t.ageOn(state.effectiveCheckinDate);
      return t.responsibleGuestId == traveller.id &&
          age != null &&
          age < TravellerFormRules.ownSignatureAge;
    }).map((t) => t.fullName).toList();

    return _SignatureBox(
      guestId: traveller.id!,
      isBusy: state.isBusy,
      minorsText: minors.isEmpty ? null : s.guest_traveller_minors_in_form(minors.join(', ')),
    );
  }

  TravellerEntity? _findById(String? id) {
    if (id == null) return null;
    for (final t in state.travellers) {
      if (t.id == id) return t;
    }
    return null;
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _SignatureBox extends StatefulWidget {
  const _SignatureBox({
    required this.guestId,
    required this.isBusy,
    this.minorsText,
  });

  final String guestId;
  final bool isBusy;
  final String? minorsText;

  @override
  State<_SignatureBox> createState() => _SignatureBoxState();
}

class _SignatureBoxState extends State<_SignatureBox> {
  String? _svg;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final svg = _svg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TravellerSectionLabel(s.guest_traveller_sign_title),
        if (widget.minorsText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.minorsText!,
            style: TextStyle(fontSize: 12, color: AppColors.getTextTertiaryColor(context)),
          ),
        ],
        const SizedBox(height: 8),
        SignaturePad(
          hint: s.guest_traveller_sign_hint,
          clearLabel: s.guest_traveller_clear,
          enabled: !widget.isBusy,
          onChanged: (value) => setState(() => _svg = value),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: svg == null || widget.isBusy
              ? null
              : () => context.read<TravellerWizardBloc>().add(
                    TravellerWizardSignatureSubmitted(
                      guestId: widget.guestId,
                      signatureSvg: svg,
                    ),
                  ),
          icon: const Icon(Icons.draw_outlined),
          label: Text(s.guest_traveller_sign_button),
        ),
      ],
    );
  }
}
