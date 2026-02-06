import 'package:flutter/material.dart';

/// Card type enumeration
enum CardType {
  visa,
  mastercard,
  americanExpress,
  discover,
  dinersClub,
  jcb,
  unknown,
}

/// Utility class for detecting credit card types from card numbers
class CardTypeDetector {
  /// Detect card type from card number (first few digits)
  static CardType detectCardType(String cardNumber) {
    // Remove spaces and non-digits
    String digitsOnly = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (digitsOnly.isEmpty) {
      return CardType.unknown;
    }

    // Get first 6 digits (BIN - Bank Identification Number)
    int firstDigit = int.tryParse(digitsOnly[0]) ?? 0;
    int firstTwoDigits = digitsOnly.length >= 2
        ? int.tryParse(digitsOnly.substring(0, 2)) ?? 0
        : 0;
    int firstThreeDigits = digitsOnly.length >= 3
        ? int.tryParse(digitsOnly.substring(0, 3)) ?? 0
        : 0;
    int firstFourDigits = digitsOnly.length >= 4
        ? int.tryParse(digitsOnly.substring(0, 4)) ?? 0
        : 0;
    int firstSixDigits = digitsOnly.length >= 6
        ? int.tryParse(digitsOnly.substring(0, 6)) ?? 0
        : 0;

    // Visa: starts with 4
    if (firstDigit == 4) {
      return CardType.visa;
    }

    // Mastercard: starts with 51-55 or 2221-2720
    if (firstTwoDigits >= 51 && firstTwoDigits <= 55) {
      return CardType.mastercard;
    }
    if (firstFourDigits >= 2221 && firstFourDigits <= 2720) {
      return CardType.mastercard;
    }

    // American Express: starts with 34 or 37
    if (firstTwoDigits == 34 || firstTwoDigits == 37) {
      return CardType.americanExpress;
    }

    // Discover: starts with 6011, 622126-622925, 644-649, or 65
    if (firstFourDigits == 6011) {
      return CardType.discover;
    }
    if (firstSixDigits >= 622126 && firstSixDigits <= 622925) {
      return CardType.discover;
    }
    if (firstThreeDigits >= 644 && firstThreeDigits <= 649) {
      return CardType.discover;
    }
    if (firstTwoDigits == 65) {
      return CardType.discover;
    }

    // Diners Club: starts with 300-305, 36, or 38
    if (firstThreeDigits >= 300 && firstThreeDigits <= 305) {
      return CardType.dinersClub;
    }
    if (firstTwoDigits == 36 || firstTwoDigits == 38) {
      return CardType.dinersClub;
    }

    // JCB: starts with 3528-3589
    if (firstFourDigits >= 3528 && firstFourDigits <= 3589) {
      return CardType.jcb;
    }

    return CardType.unknown;
  }

  /// Get card type name as string
  static String getCardTypeName(CardType cardType) {
    switch (cardType) {
      case CardType.visa:
        return 'Visa';
      case CardType.mastercard:
        return 'Mastercard';
      case CardType.americanExpress:
        return 'American Express';
      case CardType.discover:
        return 'Discover';
      case CardType.dinersClub:
        return 'Diners Club';
      case CardType.jcb:
        return 'JCB';
      case CardType.unknown:
        return '';
    }
  }

  /// Get card type icon (using Material Icons for now)
  /// TODO: Replace with custom card type icons if available
  static IconData? getCardTypeIcon(CardType cardType) {
    switch (cardType) {
      case CardType.visa:
        return Icons.credit_card; // TODO: Use Visa icon
      case CardType.mastercard:
        return Icons.credit_card; // TODO: Use Mastercard icon
      case CardType.americanExpress:
        return Icons.credit_card; // TODO: Use Amex icon
      case CardType.discover:
        return Icons.credit_card; // TODO: Use Discover icon
      case CardType.dinersClub:
        return Icons.credit_card; // TODO: Use Diners Club icon
      case CardType.jcb:
        return Icons.credit_card; // TODO: Use JCB icon
      case CardType.unknown:
        return null;
    }
  }
}

