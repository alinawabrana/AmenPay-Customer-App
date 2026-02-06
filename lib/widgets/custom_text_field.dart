import 'package:flutter/material.dart';

/// A custom text field widget with icon and specific styling
class CustomTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final ValueChanged<bool>? onVisibilityToggle;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.onVisibilityToggle,
    this.controller,
    this.validator,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field label
        Text(
          label,
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.0, // 100% line height
            letterSpacing: -0.5,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        // Text field with icon
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          onChanged: onChanged,
          textAlign: TextAlign.start,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 24 / 16,
              letterSpacing: -0.5,
              color: Color(0xFFADAEBC),
            ),
            suffixIcon: obscureText && onVisibilityToggle != null
                ? SizedBox(
                    width: 14,
                    height: 16,
                    child: IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        size: 14,
                        color: const Color(0xFF9CA3AF),
                      ),
                      onPressed: () => onVisibilityToggle!(!obscureText),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  )
                : SizedBox(
                    width: 14,
                    height: 16,
                    child: Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
                  ),
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
            contentPadding: const EdgeInsetsDirectional.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
