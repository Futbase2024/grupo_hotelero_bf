import 'package:flutter/material.dart';

/// Campo de texto controlado por el BLoC: muestra [value] y avisa de cada
/// cambio. Si el valor cambia desde fuera (p. ej. el servidor lo normaliza a
/// mayúsculas) se actualiza sin perder el foco.
class TravellerTextField extends StatefulWidget {
  const TravellerTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.helperText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.textInputAction = TextInputAction.next,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final String? helperText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;

  @override
  State<TravellerTextField> createState() => _TravellerTextFieldState();
}

class _TravellerTextFieldState extends State<TravellerTextField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(TravellerTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        helperText: widget.helperText,
        helperMaxLines: 3,
        errorMaxLines: 2,
      ),
    );
  }
}
