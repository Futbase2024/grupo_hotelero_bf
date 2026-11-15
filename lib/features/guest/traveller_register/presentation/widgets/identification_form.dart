import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../checkin/domain/entities/guest_entity.dart';
import '../../../checkin/presentation/widgets/document_upload_sheet.dart';
import '../../domain/entities/traveller_entity.dart';
import '../../domain/validators/traveller_form_rules.dart';
import '../bloc/traveller_wizard_bloc.dart';
import '../bloc/traveller_wizard_event.dart';
import '../bloc/traveller_wizard_state.dart';
import '../traveller_l10n.dart';
import 'country_picker_field.dart';
import 'traveller_form_widgets.dart';
import 'traveller_text_field.dart';

/// Pantalla 1: identificación del huésped seleccionado
class IdentificationForm extends StatelessWidget {
  const IdentificationForm({super.key, required this.state, required this.index});

  final TravellerWizardState state;
  final int index;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final traveller = state.travellers[index];
    final checkin = state.effectiveCheckinDate;
    final errors = state.showErrors
        ? TravellerFormRules.identification(traveller, checkin)
        : const <String, TravellerFieldError>{};
    final age = traveller.ageOn(checkin);
    final isMinor = age != null && age < TravellerFormRules.adultAge;
    final type = traveller.documentType;
    final bloc = context.read<TravellerWizardBloc>();

    void update(TravellerEntity changed) =>
        bloc.add(TravellerWizardTravellerChanged(index, changed));
    String? err(String field) => s.fieldErrorText(errors[field]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (traveller.isLegacy) ...[
          TravellerNotice(
            icon: Icons.edit_note,
            color: AppColors.warning,
            text: s.guest_traveller_legacy_notice,
          ),
          const SizedBox(height: 16),
        ],
        TravellerSectionLabel(s.guest_traveller_document_type),
        const SizedBox(height: 8),
        TravellerChoiceGroup<TravellerDocumentType>(
          values: TravellerDocumentType.values,
          selected: type,
          labelOf: s.documentTypeLabel,
          errorText: err(TravellerField.documentType),
          onSelected: (value) => update(traveller.copyWith(documentType: value)),
        ),
        const SizedBox(height: 16),
        TravellerTextField(
          label: s.guest_traveller_first_name,
          value: traveller.firstName,
          errorText: err(TravellerField.firstName),
          textCapitalization: TextCapitalization.characters,
          autofillHints: const [AutofillHints.givenName],
          onChanged: (v) => update(traveller.copyWith(firstName: v)),
        ),
        const SizedBox(height: 12),
        TravellerFieldRow(
          children: [
            TravellerTextField(
              label: s.guest_traveller_last_name_1,
              value: traveller.lastName1,
              errorText: err(TravellerField.lastName1),
              textCapitalization: TextCapitalization.characters,
              autofillHints: const [AutofillHints.familyName],
              onChanged: (v) => update(traveller.copyWith(lastName1: v)),
            ),
            TravellerTextField(
              label: s.guest_traveller_last_name_2,
              value: traveller.lastName2,
              textCapitalization: TextCapitalization.characters,
              onChanged: (v) => update(traveller.copyWith(lastName2: v)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TravellerSectionLabel(s.guest_traveller_sex),
        const SizedBox(height: 8),
        TravellerChoiceGroup<TravellerSex>(
          values: TravellerSex.values,
          selected: traveller.sex,
          labelOf: s.sexLabel,
          errorText: err(TravellerField.sex),
          onSelected: (value) => update(traveller.copyWith(sex: value)),
        ),
        const SizedBox(height: 16),
        TravellerFieldRow(
          children: [
            _BirthDateField(
              value: traveller.birthDate,
              lastDate: checkin,
              errorText: err(TravellerField.birthDate),
              helperText: age == null ? null : s.guest_traveller_age_on_checkin(age),
              onChanged: (date) => update(traveller.copyWith(birthDate: date)),
            ),
            CountryPickerField(
              label: s.guest_traveller_nationality,
              value: traveller.nationality,
              errorText: err(TravellerField.nationality),
              onChanged: (code) => update(traveller.copyWith(nationality: code)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TravellerFieldRow(
          children: [
            TravellerTextField(
              label: s.guest_traveller_document_number,
              value: traveller.documentNumber,
              errorText: err(TravellerField.documentNumber),
              helperText: isMinor ? s.guest_traveller_document_optional_minor : null,
              textCapitalization: TextCapitalization.characters,
              onChanged: (v) => update(traveller.copyWith(documentNumber: v)),
            ),
            if (type != null && type.hasSupportNumber)
              TravellerTextField(
                label: s.guest_traveller_support_number,
                value: traveller.supportNumber,
                errorText: err(TravellerField.supportNumber),
                helperText: type == TravellerDocumentType.dni
                    ? s.guest_traveller_support_help_dni
                    : s.guest_traveller_support_help_nie,
                textCapitalization: TextCapitalization.characters,
                onChanged: (v) => update(traveller.copyWith(supportNumber: v)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _DocumentPhotoButton(state: state, index: index),
      ],
    );
  }
}

class _BirthDateField extends StatelessWidget {
  const _BirthDateField({
    required this.value,
    required this.lastDate,
    required this.onChanged,
    this.errorText,
    this.helperText,
  });

  final DateTime? value;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = value;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime(lastDate.year - 30),
          firstDate: DateTime(1900),
          lastDate: lastDate,
          initialEntryMode: DatePickerEntryMode.calendarOnly,
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: S.of(context).guest_traveller_birth_date,
          errorText: errorText,
          helperText: helperText,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
        ),
        isEmpty: date == null,
        child: date == null ? null : Text(DateFormat.yMd(locale).format(date)),
      ),
    );
  }
}

/// Foto del documento con el sistema existente (marca COPIA + borrado
/// automático). Es opcional: no sustituye a los datos del formulario.
class _DocumentPhotoButton extends StatelessWidget {
  const _DocumentPhotoButton({required this.state, required this.index});

  final TravellerWizardState state;
  final int index;

  static DocumentType _toPhotoType(TravellerDocumentType? type) {
    switch (type) {
      case TravellerDocumentType.nie:
        return DocumentType.nie;
      case TravellerDocumentType.passport:
        return DocumentType.passport;
      case TravellerDocumentType.other:
        return DocumentType.other;
      case TravellerDocumentType.dni:
      case null:
        return DocumentType.dni;
    }
  }

  static TravellerDocumentType _fromPhotoType(DocumentType type) {
    switch (type) {
      case DocumentType.dni:
        return TravellerDocumentType.dni;
      case DocumentType.nie:
        return TravellerDocumentType.nie;
      case DocumentType.passport:
        return TravellerDocumentType.passport;
      case DocumentType.other:
        return TravellerDocumentType.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final traveller = state.travellers[index];
    final hasPhoto = traveller.id != null && state.guestIdsWithPhotos.contains(traveller.id);
    final bloc = context.read<TravellerWizardBloc>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: state.isBusy
              ? null
              : () => DocumentUploadSheet.show(
                    context: context,
                    guest: GuestEntity(
                      id: traveller.id,
                      fullName: traveller.fullName,
                      type: GuestType.adult,
                      documentType: _toPhotoType(traveller.documentType),
                      documentNumber: traveller.documentNumber,
                    ),
                    onConfirm: (type, number, front, back) => bloc.add(
                      TravellerWizardDocumentPhotosAdded(
                        index: index,
                        documentType: _fromPhotoType(type),
                        documentNumber: number,
                        frontBytes: front,
                        backBytes: back,
                      ),
                    ),
                  ),
          icon: Icon(
            hasPhoto ? Icons.check_circle : Icons.photo_camera_outlined,
            color: hasPhoto ? AppColors.success : AppColors.gold,
          ),
          label: Text(
            hasPhoto ? s.guest_traveller_photo_added : s.guest_traveller_photo_button,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.guest_traveller_photo_note,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.getTextTertiaryColor(context)),
        ),
      ],
    );
  }
}
