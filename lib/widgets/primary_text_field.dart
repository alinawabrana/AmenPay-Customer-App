import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable primary text form field widget with theme styling
class PrimaryTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? textInputFormatter;

  const PrimaryTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLength,
    this.onChanged,
    this.textInputFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field label
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.0, // 100% line height
            letterSpacing: -0.5,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),

        // TextFormField(
        //   controller: controller,
        //   obscureText: obscureText,
        //   validator: validator,
        //   onChanged: onChanged,
        //   keyboardType: keyboardType,
        //   decoration: InputDecoration(
        //     hintText: hintText,
        //     hintStyle: TextStyle(),
        //   ),
        // ),

        // Text field
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          onChanged: onChanged,
          inputFormatters: textInputFormatter,
          decoration: InputDecoration(
            hintText: hintText,
            // hintStyle: TextStyle(),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF238EC2), width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            isDense: true, // makes the field more compact
          ),
        ),
      ],
    );
  }
}
