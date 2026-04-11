import 'package:flutter/material.dart';

/// Transaction item widget for recent transactions list
class TransactionItem extends StatelessWidget {
  final String title;
  final String date;
  final String amount;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final bool isPositive;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.title,
    required this.date,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.isPositive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
            ),
            // 4px spacing
            const SizedBox(width: 4),
            // Title and date column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 20 / 14,
                      letterSpacing: -0.5,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              amount,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 20 / 14,
                letterSpacing: -0.5,
                color: isPositive
                    ? const Color(0xFF00AA44)
                    : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
