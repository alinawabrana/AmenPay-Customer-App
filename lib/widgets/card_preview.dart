import 'package:flutter/material.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/utils/card_type_detector.dart';

/// Card preview widget showing card details
class CardPreview extends StatelessWidget {
  final String cardNumber;
  final String cardholderName;
  final String expiryDate;

  const CardPreview({
    super.key,
    this.cardNumber = '•••• •••• •••• ••••',
    this.cardholderName = '',
    this.expiryDate = 'MM/YY',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final effectiveCardholderName = cardholderName.isEmpty
        ? l10n.t('card_preview_name_placeholder')
        : cardholderName;
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0066CC), Color(0xFF1E40AF)],
          stops: [0.0, 0.7071],
        ),
        borderRadius: BorderRadius.circular(12),
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
          // Card icon
          SizedBox(
            width: 33,
            height: 26,
            child: Icon(Icons.credit_card, size: 33, color: Colors.white),
          ),
          // 37px vertical spacing
          const SizedBox(height: 37),
          // Card number row with card type icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Card number
              Expanded(
                child: Text(
                  cardNumber,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    height: 1.0, // 100% line height
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
              ),
              // Card type badge
              Builder(
                builder: (context) {
                  final cardType = CardTypeDetector.detectCardType(cardNumber);

                  if (cardType != CardType.unknown) {
                    final cardTypeName = CardTypeDetector.getCardTypeName(
                      cardType,
                    );
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        cardTypeName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          // 18px vertical spacing
          const Spacer(),
          // Cardholder name and expiry date row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Cardholder name column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('cardholder_name_label'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.0, // 100% line height
                      letterSpacing: -0.5,
                      color: Color(0xFFBFDBFE),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    effectiveCardholderName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.0, // 100% line height
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
              // Expires column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.t('expires_label'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.0, // 100% line height
                      letterSpacing: -0.5,
                      color: Color(0xFFBFDBFE),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    expiryDate,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.0, // 100% line height
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
