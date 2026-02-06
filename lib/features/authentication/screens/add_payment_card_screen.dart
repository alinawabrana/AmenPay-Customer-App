import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palmpay/features/authentication/providers/create_account_provider.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/widgets/card_preview.dart';
import 'package:palmpay/widgets/primary_text_field.dart';
import 'package:palmpay/widgets/security_banner.dart';
import 'package:palmpay/widgets/security_note.dart';

class AddPaymentCardScreen extends ConsumerStatefulWidget {
  const AddPaymentCardScreen({super.key});

  @override
  ConsumerState<AddPaymentCardScreen> createState() =>
      _AddPaymentCardScreenState();
}

class _AddPaymentCardScreenState extends ConsumerState<AddPaymentCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardholderNameController = TextEditingController();

  String _formattedCardNumber = '•••• •••• •••• ••••';
  String _formattedExpiryDate = 'MM/YY';
  String _cardholderName = 'YOUR NAME';

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_updateCardNumber);
    _expiryDateController.addListener(_updateExpiryDate);
    _cardholderNameController.addListener(_updateCardholderName);
  }

  void _updateCardNumber() {
    String text = _cardNumberController.text.replaceAll(' ', '');
    setState(() {
      if (text.isEmpty) {
        _formattedCardNumber = '•••• •••• •••• ••••';
      } else {
        // Format: Show actual digits as user types, fill rest with dots
        String formatted = '';
        for (int i = 0; i < 16; i++) {
          if (i > 0 && i % 4 == 0) formatted += ' ';
          if (i < text.length) {
            formatted += text[i];
          } else {
            formatted += '•';
          }
        }
        _formattedCardNumber = formatted;
        // Card type is automatically detected in CardPreview widget
      }
    });
  }

  void _updateExpiryDate() {
    setState(() {
      if (_expiryDateController.text.isEmpty) {
        _formattedExpiryDate = 'MM/YY';
      } else {
        _formattedExpiryDate = _expiryDateController.text;
      }
    });
  }

  void _updateCardholderName() {
    setState(() {
      if (_cardholderNameController.text.isEmpty) {
        _cardholderName = 'YOUR NAME';
      } else {
        _cardholderName = _cardholderNameController.text.toUpperCase();
      }
    });
  }

  @override
  void dispose() {
    _cardNumberController.removeListener(_updateCardNumber);
    _expiryDateController.removeListener(_updateExpiryDate);
    _cardholderNameController.removeListener(_updateCardholderName);
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    super.dispose();
  }

  String _formatExpiryDate(String value) {
    value = value.replaceAll('/', '');
    if (value.length >= 2) {
      return '${value.substring(0, 2)}/${value.substring(2)}';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(createAccountProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back arrow and title
                Row(
                  children: [
                    SizedBox(
                      width: 15,
                      height: 13,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          size: 15,
                          color: const Color(0xFF333333),
                          textDirection: Directionality.of(context),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          l10n.t('add_payment_card_title'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1.0, // 100% line height
                            letterSpacing: -0.5,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15), // Balance the back button
                  ],
                ),

                // 26px vertical spacing
                const SizedBox(height: 26),

                // Security banner
                const SecurityBanner(),

                // 32px vertical spacing
                const SizedBox(height: 32),

                // Card preview
                CardPreview(
                  cardNumber: _formattedCardNumber,
                  cardholderName: _cardholderName,
                  expiryDate: _formattedExpiryDate,
                ),

                // 32px vertical spacing
                const SizedBox(height: 32),

                // Card Number field
                PrimaryTextField(
                  label: l10n.t('card_number'),
                  hintText: '1234 5678 9012 3456',
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  maxLength: 19,
                  prefixIcon: Icon(
                    Icons.credit_card,
                    size: 14,
                    color: const Color(0xFF9CA3AF),
                  ),
                  suffixIcon: Icon(
                    Icons.lock,
                    size: 14,
                    color: const Color(0xFF00AA44),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.t('please_enter_card_number');
                    }
                    if (value.replaceAll(' ', '').length < 16) {
                      return l10n.t('card_number_must_be_16_digits');
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Format card number as user types (only digits, max 16)
                    String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (digitsOnly.length > 16) {
                      digitsOnly = digitsOnly.substring(0, 16);
                    }
                    String formatted = '';
                    for (int i = 0; i < digitsOnly.length; i++) {
                      if (i > 0 && i % 4 == 0) formatted += ' ';
                      formatted += digitsOnly[i];
                    }
                    if (formatted != value) {
                      _cardNumberController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                  },
                ),

                // 20px spacing
                const SizedBox(height: 20),

                // Expiry Date and CVV in same row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: PrimaryTextField(
                        label: l10n.t('expiry_date'),
                        hintText: 'MM/YY',
                        controller: _expiryDateController,
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        textInputFormatter: [
                          FilteringTextInputFormatter.digitsOnly,
                          ExpiryDateInputFormatter(), // <-- new
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.t('required');
                          }
                          if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                            return l10n.t('invalid_format');
                          }

                          // Parse month and year
                          final parts = value.split('/');
                          final month = int.tryParse(parts[0]);
                          final year = int.tryParse(parts[1]);

                          if (month == null ||
                              year == null ||
                              month < 1 ||
                              month > 12) {
                            return l10n.t('invalid_date');
                          }

                          // Convert YY to full year (assume 2000-2099)
                          final fullYear = 2000 + year;
                          final now = DateTime.now();

                          // Expiry is the last day of the month
                          final expiryDate = DateTime(fullYear, month + 1, 0);

                          if (expiryDate.isBefore(now)) {
                            return l10n.t('card_expired');
                          }

                          return null;
                        },
                        onChanged: (value) {
                          // Format expiry date as user types
                          final formatted = _formatExpiryDate(value);
                          if (formatted != value) {
                            _expiryDateController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                offset: formatted.length,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PrimaryTextField(
                        label: l10n.t('cvv'),
                        hintText: '123',
                        controller: _cvvController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 3,
                        suffixIcon: Icon(
                          Icons.lock,
                          size: 14,
                          color: const Color(0xFF00AA44),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.t('required');
                          }
                          if (value.length < 3) {
                            return l10n.t('invalid');
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                // 20px spacing
                const SizedBox(height: 20),

                // Cardholder Name field
                PrimaryTextField(
                  label: l10n.t('cardholder_name_label'),
                  hintText: 'John Doe',
                  controller: _cardholderNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.t('please_enter_cardholder_name');
                    }
                    return null;
                  },
                ),

                // 20px vertical spacing
                const SizedBox(height: 20),

                // Security note
                const SecurityNote(),

                // 20px vertical spacing
                const SizedBox(height: 20),

                // Add Card button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Get card details from controllers
                        final cardNumber = _cardNumberController.text
                            .replaceAll(' ', '');
                        final expiryDate = _expiryDateController.text;
                        final cvv = _cvvController.text;
                        final cardholderName = _cardholderNameController.text;

                        notifier.addCard(
                          context,
                          cardNumber: cardNumber,
                          expiryDate: expiryDate,
                          cvv: cvv,
                          cardholderName: cardholderName,
                        );
                      }
                    },
                    child: Text(l10n.t('add_card')),
                  ),
                ),

                // Bottom padding
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll('/', '');

    if (text.length > 4) {
      text = text.substring(0, 4); // max 4 digits: MMYY
    }

    // Block months > 12
    if (text.isNotEmpty) {
      final firstDigit = int.tryParse(text[0]) ?? 0;
      if (firstDigit > 1) {
        text = '1'; // First digit cannot be >1
      }
    }
    if (text.length >= 2) {
      final month = int.tryParse(text.substring(0, 2)) ?? 0;
      if (month > 12) {
        text = text.substring(0, 1); // remove second digit
      }
    }

    // Add slash automatically after 2 digits
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2) formatted += '/';
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
