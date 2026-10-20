import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';

/// Buscador de la lista de conversaciones.
///
/// Filtra en local sobre lo que ya está en memoria, así que no necesita
/// debounce: cada pulsación se refleja al instante.
class ConversationsSearchField extends StatefulWidget {
  const ConversationsSearchField({
    super.key,
    required this.onChanged,
    this.initialValue = '',
  });

  final ValueChanged<String> onChanged;
  final String initialValue;

  @override
  State<ConversationsSearchField> createState() =>
      _ConversationsSearchFieldState();
}

class _ConversationsSearchFieldState extends State<ConversationsSearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    widget.onChanged(_controller.text);
  }

  void _clear() {
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing16,
        AppTheme.spacing8,
        AppTheme.spacing16,
        AppTheme.spacing12,
      ),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        style: TextStyle(color: AppColors.getTextPrimaryColor(context)),
        decoration: InputDecoration(
          hintText: S.of(context).admin_chat_search_hint,
          hintStyle: const TextStyle(color: AppColors.gray500),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.gray500,
            size: 20,
          ),
          suffixIcon: _hasText
              ? IconButton(
                  onPressed: _clear,
                  tooltip: S.of(context).common_cancel,
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.gray500,
                    size: 20,
                  ),
                )
              : null,
          filled: true,
          fillColor: AppColors.whiteWithAlpha05,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing16,
            vertical: AppTheme.spacing12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            borderSide: BorderSide(color: AppColors.whiteWithAlpha10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            borderSide: const BorderSide(color: AppColors.gold),
          ),
        ),
      ),
    );
  }
}
