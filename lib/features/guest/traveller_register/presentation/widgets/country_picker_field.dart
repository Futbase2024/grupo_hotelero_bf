import 'package:flutter/material.dart';

import '../../../../../core/constants/countries.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

/// Campo de país (guarda el código ISO alfa-3) con buscador
class CountryPickerField extends StatelessWidget {
  const CountryPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final String label;

  /// Código alfa-3 seleccionado
  final String? value;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final country = countryByAlpha3(value);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final selected = await _CountryPickerSheet.show(context, title: label);
        if (selected != null) onChanged(selected);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        isEmpty: country == null,
        child: country == null ? null : Text(country.nameFor(language)),
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.title});

  final String title;

  static Future<String?> show(BuildContext context, {required String title}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getCardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CountryPickerSheet(title: title),
    );
  }

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  /// España primero: es la nacionalidad más frecuente
  static const String _pinned = 'ESP';

  String _query = '';

  static String _fold(String value) {
    const from = 'áàäâãåéèëêíìïîóòöôõúùüûñçÁÀÄÂÃÅÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇ';
    const to = 'aaaaaaeeeeiiiiooooouuuuncAAAAAAEEEEIIIIOOOOOUUUUNC';
    final buffer = StringBuffer();
    for (final char in value.split('')) {
      final i = from.indexOf(char);
      buffer.write(i >= 0 ? to[i] : char);
    }
    return buffer.toString().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final query = _fold(_query.trim());

    final countries = kCountries.where((c) {
      if (query.isEmpty) return true;
      return c.alpha3.toLowerCase() == query ||
          c.allNames.any((name) => _fold(name).contains(query));
    }).toList()
      ..sort((a, b) {
        if (a.alpha3 == _pinned) return -1;
        if (b.alpha3 == _pinned) return 1;
        return _fold(a.nameFor(language)).compareTo(_fold(b.nameFor(language)));
      });

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: S.of(context).guest_traveller_country_search,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: countries.length,
                  itemBuilder: (context, index) {
                    final country = countries[index];
                    return ListTile(
                      title: Text(country.nameFor(language)),
                      trailing: Text(
                        country.alpha3,
                        style: TextStyle(color: AppColors.getTextTertiaryColor(context)),
                      ),
                      onTap: () => Navigator.of(context).pop(country.alpha3),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
