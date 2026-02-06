import 'package:flutter/material.dart';

/// A secured badge/chip widget with shadow effects
class SecuredBadge extends StatelessWidget {
  const SecuredBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50), // 50% radius (fully rounded/pill-shaped)
        boxShadow: [
          // box-shadow: 0px 4px 6px 0px #0000001A
          BoxShadow(
            color: const Color(0xFF000000).withAlpha(26), // #0000001A
            offset: const Offset(0, 4),
            blurRadius: 6,
            spreadRadius: 0,
          ),
          // box-shadow: 0px 2px 4px 0px #0000001A
          BoxShadow(
            color: const Color(0xFF000000).withAlpha(26), // #0000001A
            offset: const Offset(0, 2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Shield icon with gradient fill - using Icons.shield for now
          // TODO: Replace with custom half-filled shield icon from Figma when available
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF00AA44).withAlpha(179), // Lighter green on left
                  const Color(0xFF00AA44), // Darker green on right
                ],
              ).createShader(bounds);
            },
            child: const Icon(
              Icons.shield,
              size: 16,
              color: Colors.white, // This will be masked by the gradient
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Secured',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF333333), // Dark gray text
            ),
          ),
        ],
      ),
    );
  }
}

