import "package:flutter/material.dart";
import "package:flutter/services.dart";

class FormTextInput extends StatelessWidget {
  final List<String? Function(String value)> extraValidators;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? initialValue;
  final bool readOnly;
  final bool obscure;
  final String? title;
  final int? minLines;
  final int? maxLength;
  final bool outlined;
  final int? maxLines;
  final bool capitalize;
  final bool required;
  final bool autocorrect;
  final void Function()? onTap;
  final Widget? trailing;
  final InputBorder? border;
  final List<TextInputFormatter>? formatters;
  final bool autofocus;

  const FormTextInput({
    super.key,
    this.border,
    this.controller,
    this.autofocus = false,
    this.title,
    this.obscure = false,
    this.readOnly = false,
    this.extraValidators = const [],
    this.keyboardType = TextInputType.text,
    this.initialValue,
    this.minLines,
    this.capitalize = false,
    this.maxLength,
    this.formatters,
    this.maxLines = 1,
    this.outlined = true,
    this.trailing,
    this.onTap,
    this.autocorrect = true,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    autofocus: autofocus,
    controller: controller,
    keyboardType: keyboardType,
    readOnly: readOnly,
    minLines: minLines,
    maxLines: maxLines,
    maxLength: maxLength,
    inputFormatters: formatters,
    textCapitalization: capitalize
        ? TextCapitalization.sentences
        : TextCapitalization.none,
    initialValue: initialValue,
    autocorrect: autocorrect,
    obscureText: obscure,
    onTap: onTap,
    decoration: InputDecoration(
      labelText: title,
      border: border ?? (outlined ? null : const UnderlineInputBorder()),
      suffixIcon: trailing,
    ),
    validator: (value) {
      if ((value?.isEmpty ?? true) && required) {
        return "This field is required";
      }

      for (final validator in extraValidators) {
        final reason = validator(value!);
        if (reason != null) return reason;
      }

      return null;
    },
  );
}
