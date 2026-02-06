import 'package:flutter/material.dart';

/// Security note widget with lock icon
class SecurityNote extends StatelessWidget {
  const SecurityNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 71,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 16,
            child: Icon(
              Icons.lock,
              size: 14,
              color: const Color(0xFF00AA44),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Your card number is never stored. Only secure tokens.',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.0, // 100% line height
                letterSpacing: -0.5,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

