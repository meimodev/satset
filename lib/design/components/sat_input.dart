import 'package:flutter/material.dart';
import '../colors.dart';

class SatInput extends StatelessWidget {
  const SatInput({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 16,
        height: 1.5,
        color: AppColors.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: AppColors.primaryOverride)
            : null,
      ),
    );
  }
}
