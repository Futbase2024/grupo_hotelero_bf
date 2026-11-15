import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/traveller_entity.dart';
import '../../domain/validators/traveller_form_rules.dart';
import '../bloc/traveller_wizard_bloc.dart';
import '../bloc/traveller_wizard_event.dart';
import '../bloc/traveller_wizard_state.dart';
import '../traveller_l10n.dart';
import 'country_picker_field.dart';
import 'traveller_form_widgets.dart';
import 'traveller_text_field.dart';

/// Pantalla 2: domicilio habitual y contacto del huésped seleccionado.
/// Los menores indican su adulto responsable y el parentesco.
class ResidenceContactForm extends StatelessWidget {
  const ResidenceContactForm({super.key, required this.state, required this.index});

  final TravellerWizardState state;
  final int index;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final traveller = state.travellers[index];
    final checkin = state.effectiveCheckinDate;
    final errors = state.showErrors
        ? TravellerFormRules.residenceAndContact(traveller, checkin, state.travellers)
        : const <String, TravellerFieldError>{};
    final age = traveller.ageOn(checkin);
    final isMinor = age != null && age < TravellerFormRules.adultAge;
    final bloc = context.read<TravellerWizardBloc>();

    void update(TravellerEntity changed) =>
        bloc.add(TravellerWizardTravellerChanged(index, changed));
    String? err(String field) => s.fieldErrorText(errors[field]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isMinor) ...[
          _MinorSection(
            state: state,
            traveller: traveller,
            responsibleError: err(TravellerField.responsible),
            relationshipError: err(TravellerField.relationship),
            onChanged: update,
          ),
          const SizedBox(height: 24),
        ],
        TravellerSectionLabel(s.guest_traveller_residence_section),
        if (isMinor) ...[
          const SizedBox(height: 4),
          Text(
            s.guest_traveller_residence_inherited_note,
            style: TextStyle(fontSize: 12, color: AppColors.getTextTertiaryColor(context)),
          ),
        ],
        const SizedBox(height: 8),
        TravellerTextField(
          label: s.guest_traveller_address,
          value: traveller.residenceAddress,
          errorText: err(TravellerField.residenceAddress),
          textCapitalization: TextCapitalization.characters,
          autofillHints: const [AutofillHints.fullStreetAddress],
          onChanged: (v) => update(traveller.copyWith(residenceAddress: v)),
        ),
        const SizedBox(height: 12),
        TravellerFieldRow(
          children: [
            TravellerTextField(
              label: s.guest_traveller_city,
              value: traveller.residenceCity,
              errorText: err(TravellerField.residenceCity),
              textCapitalization: TextCapitalization.characters,
              autofillHints: const [AutofillHints.addressCity],
              onChanged: (v) => update(traveller.copyWith(residenceCity: v)),
            ),
            TravellerTextField(
              label: s.guest_traveller_postal_code,
              value: traveller.residencePostalCode,
              textCapitalization: TextCapitalization.characters,
              autofillHints: const [AutofillHints.postalCode],
              onChanged: (v) => update(traveller.copyWith(residencePostalCode: v)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CountryPickerField(
          label: s.guest_traveller_country,
          value: traveller.residenceCountry,
          errorText: err(TravellerField.residenceCountry),
          onChanged: (code) => update(traveller.copyWith(residenceCountry: code)),
        ),
        const SizedBox(height: 24),
        TravellerSectionLabel(s.guest_traveller_contact_section),
        if (!isMinor) ...[
          const SizedBox(height: 4),
          Text(
            s.guest_traveller_contact_note,
            style: TextStyle(
              fontSize: 12,
              color: errors.containsKey(TravellerField.contact)
                  ? AppColors.error
                  : AppColors.getTextTertiaryColor(context),
            ),
          ),
        ],
        const SizedBox(height: 8),
        TravellerFieldRow(
          children: [
            TravellerTextField(
              label: s.guest_traveller_mobile,
              value: traveller.mobile,
              errorText: err(TravellerField.mobile),
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              onChanged: (v) => update(traveller.copyWith(mobile: v)),
            ),
            TravellerTextField(
              label: s.guest_traveller_landline,
              value: traveller.landline,
              errorText: err(TravellerField.landline),
              keyboardType: TextInputType.phone,
              onChanged: (v) => update(traveller.copyWith(landline: v)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TravellerTextField(
          label: s.guest_traveller_email,
          value: traveller.email,
          errorText: err(TravellerField.email),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.done,
          onChanged: (v) => update(traveller.copyWith(email: v)),
        ),
      ],
    );
  }
}

class _MinorSection extends StatelessWidget {
  const _MinorSection({
    required this.state,
    required this.traveller,
    required this.onChanged,
    this.responsibleError,
    this.relationshipError,
  });

  final TravellerWizardState state;
  final TravellerEntity traveller;
  final ValueChanged<TravellerEntity> onChanged;
  final String? responsibleError;
  final String? relationshipError;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final adults = TravellerFormRules.possibleResponsibles(
      state.travellers,
      state.effectiveCheckinDate,
    );
    final selectedId = adults.any((a) => a.id == traveller.responsibleGuestId)
        ? traveller.responsibleGuestId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TravellerSectionLabel(s.guest_traveller_minor_section),
        const SizedBox(height: 8),
        if (adults.isEmpty)
          TravellerNotice(
            icon: Icons.info_outline,
            color: AppColors.info,
            text: s.guest_traveller_no_adults,
          )
        else
          DropdownButtonFormField<String>(
            initialValue: selectedId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: s.guest_traveller_responsible,
              errorText: responsibleError,
            ),
            items: [
              for (final adult in adults)
                DropdownMenuItem(value: adult.id, child: Text(adult.fullName)),
            ],
            onChanged: (id) => onChanged(traveller.copyWith(responsibleGuestId: id)),
          ),
        const SizedBox(height: 12),
        DropdownButtonFormField<TravellerRelationship>(
          initialValue: traveller.relationship,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: s.guest_traveller_relationship,
            errorText: relationshipError,
          ),
          items: [
            for (final relationship in TravellerRelationship.values)
              DropdownMenuItem(
                value: relationship,
                child: Text(s.relationshipLabel(relationship)),
              ),
          ],
          onChanged: (value) => onChanged(traveller.copyWith(relationship: value)),
        ),
      ],
    );
  }
}
