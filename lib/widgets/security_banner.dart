import 'package:flutter/material.dart';

/// Security banner widget with shield icon and message
class SecurityBanner extends StatelessWidget {
  const SecurityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 77.5,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.shield,
            size: 20,
            color: const Color(0xFF238EC2).withAlpha(128),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Your card will be securely tokenized for your protection',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.0, // 100% line height
                letterSpacing: -0.5,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
