import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../bloc/traveller_wizard_bloc.dart';
import '../bloc/traveller_wizard_event.dart';
import '../bloc/traveller_wizard_state.dart';

/// Fichas para elegir qué huésped se está rellenando
class TravellerSelector extends StatelessWidget {
  const TravellerSelector({super.key, required this.state});

  final TravellerWizardState state;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final bloc = context.read<TravellerWizardBloc>();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < state.travellers.length; i++)
          _TravellerChip(
            label: state.travellers[i].fullName.isEmpty
                ? s.guest_traveller_guest_n(i + 1)
                : state.travellers[i].fullName,
            isPrimary: state.travellers[i].isPrimary,
            primaryLabel: s.guest_traveller_primary_badge,
            isSelected: i == state.selectedIndex,
            hasErrors: state.showErrors && state.hasErrorsAt(i),
            onTap: () => bloc.add(TravellerWizardTravellerSelected(i)),
            onRemove: state.travellers[i].id == null && state.travellers.length > 1
                ? () => bloc.add(TravellerWizardTravellerRemoved(i))
                : null,
            removeTooltip: s.guest_traveller_remove_guest,
          ),
        if (state.canAddTraveller)
          ActionChip(
            avatar: const Icon(Icons.person_add_alt_1, size: 18, color: AppColors.gold),
            label: Text(s.guest_traveller_add_guest),
            onPressed: () => bloc.add(const TravellerWizardTravellerAdded()),
          ),
      ],
    );
  }
}

class _TravellerChip extends StatelessWidget {
  const _TravellerChip({
    required this.label,
    required this.isPrimary,
    required this.primaryLabel,
    required this.isSelected,
    required this.hasErrors,
    required this.onTap,
    required this.removeTooltip,
    this.onRemove,
  });

  final String label;
  final bool isPrimary;
  final String primaryLabel;
  final bool isSelected;
  final bool hasErrors;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final String removeTooltip;

  @override
  Widget build(BuildContext context) {
    final chip = InputChip(
      selected: isSelected,
      showCheckmark: false,
      selectedColor: AppColors.goldWithAlpha20,
      side: BorderSide(
        color: hasErrors
            ? AppColors.error
            : isSelected
                ? AppColors.gold
                : AppColors.getBorderColor(context),
      ),
      avatar: Icon(
        hasErrors ? Icons.error_outline : Icons.person_outline,
        size: 18,
        color: hasErrors ? AppColors.error : AppColors.gold,
      ),
      label: Text(isPrimary ? '$label · $primaryLabel' : label),
      onPressed: onTap,
      onDeleted: onRemove,
      deleteButtonTooltipMessage: removeTooltip,
    );
    return chip;
  }
}
