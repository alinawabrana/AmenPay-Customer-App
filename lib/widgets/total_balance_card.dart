import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Total balance card widget with gradient background
class TotalBalanceCard extends StatelessWidget {
  final String balance;
  final VoidCallback? onAddFunds;
  final VoidCallback? onViewDetails;

  const TotalBalanceCard({
    super.key,
    this.balance = '\$12,458.50',
    this.onAddFunds,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      height: 188,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0066CC), Color(0xFF1D4ED8)],
          stops: [0.0, 0.7071],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0x00000000).withAlpha(26), // #0000001A
            offset: const Offset(0, 10),
            blurRadius: 15,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0x00000000).withAlpha(26), // #0000001A
            offset: const Offset(0, 4),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Balance label
          Text(
            l10n.t('total_balance'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
          // 8px spacing
          const SizedBox(height: 8),
          // Balance amount
          Text(
            balance,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              height: 40 / 36,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
          // 24px spacing
          const Spacer(),
          // Buttons row
          Row(
            children: [
              // Add Fund button
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0x00000000,
                        ).withAlpha(26), // #0000001A
                        offset: const Offset(0, 4),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: const Color(
                          0x00000000,
                        ).withAlpha(26), // #0000001A
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: onAddFunds,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF238EC2),
                      padding: EdgeInsets.zero,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          size: 11.38,
                          color: const Color(0xFF238EC2),
                        ),
                        const SizedBox(width: 2.5),
                        Text(
                          l10n.t('add_fund'),
                          style: const TextStyle(
                            color: Color(0xFF238EC2),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.0, // 100% line height
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 12px spacing
              const SizedBox(width: 12),
              // View Detail button
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(77),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: TextButton(
                    onPressed: onViewDetails,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      l10n.t('view_detail'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.0, // 100% line height
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
