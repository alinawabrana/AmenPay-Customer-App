import 'package:flutter/material.dart';

/// Password strength indicator with 4 progress bars
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  int _calculateStrength() {
    if (password.isEmpty) return 0;
    
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[a-zA-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    
    return strength;
  }

  Color _getBarColor(int index, int strength) {
    if (index < strength) {
      switch (strength) {
        case 1:
          return Colors.red;
        case 2:
          return Colors.orange;
        case 3:
          return Colors.yellow;
        case 4:
          return Colors.green;
        default:
          return const Color(0xFFE5E7EB);
      }
    }
    return const Color(0xFFE5E7EB);
  }

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4 progress bars
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(
                  right: index < 3 ? 4 : 0,
                ),
                decoration: BoxDecoration(
                  color: _getBarColor(index, strength),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        // Requirement text
        const Text(
          'Password must be at least 8 characters with letters and numbers',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 16 / 12,
            letterSpacing: -0.5,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}


