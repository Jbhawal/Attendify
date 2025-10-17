import 'package:flutter/material.dart';

/// Reusable text field that supports marking required fields and showing inline errors.
class AttendifyTextField extends StatelessWidget {
  const AttendifyTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.textCapitalization,
    this.isRequired = false,
    this.showError = false,
    this.errorText,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final TextCapitalization? textCapitalization;
  final bool isRequired;
  final bool showError;
  final String? errorText;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final labelWidget = Row(mainAxisSize: MainAxisSize.min, children: [Text(label), if (isRequired) const Text(' *', style: TextStyle(color: Colors.red))]);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      textCapitalization: textCapitalization ?? TextCapitalization.sentences,
      decoration: InputDecoration(
        label: labelWidget,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        errorText: showError ? (errorText ?? 'Required') : null,
      ),
    );
  }
}
