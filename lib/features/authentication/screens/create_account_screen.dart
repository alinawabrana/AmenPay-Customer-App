import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palmpay/features/authentication/providers/create_account_provider.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/widgets/custom_text_field.dart';
import 'package:palmpay/widgets/password_strength_indicator.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createAccountProvider);
    final notifier = ref.read(createAccountProvider.notifier);
    final l10n = AppLocalizations.of(context);

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
                          l10n.t('create_account'),
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

                // Form fields
                CustomTextField(
                  label: l10n.t('full_name'),
                  hintText: l10n.t('enter_your_full_name'),
                  icon: Icons.person,
                  controller: _fullNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.t('please_enter_full_name');
                    }
                    return null;
                  },
                ),

                // 20px spacing
                const SizedBox(height: 20),

                CustomTextField(
                  label: l10n.t('email_address'),
                  hintText: l10n.t('enter_your_email'),
                  icon: Icons.email,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.t('please_enter_email');
                    }
                    if (!value.contains('@')) {
                      return l10n.t('please_enter_valid_email');
                    }
                    return null;
                  },
                ),

                // 20px spacing
                const SizedBox(height: 20),

                CustomTextField(
                  label: l10n.t('phone_number'),
                  hintText: l10n.t('enter_your_phone_number'),
                  icon: Icons.phone,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.t('please_enter_phone_number');
                    }
                    return null;
                  },
                ),

                // 20px spacing
                const SizedBox(height: 20),

                CustomTextField(
                  label: l10n.t('password'),
                  hintText: l10n.t('create_a_password'),
                  icon: Icons.lock,
                  obscureText: !state.isPasswordVisible,
                  controller: _passwordController,
                  onVisibilityToggle: (isVisible) {
                    notifier.togglePasswordVisibility();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.t('please_enter_password');
                    }
                    if (value.length < 8) {
                      return l10n.t('password_min_length');
                    }
                    return null;
                  },
                ),

                // Password strength indicator
                const SizedBox(height: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _passwordController,
                  builder: (context, value, child) {
                    return PasswordStrengthIndicator(password: value.text);
                  },
                ),

                // 20px spacing
                const SizedBox(height: 20),

                CustomTextField(
                  label: l10n.t('confirm_password'),
                  hintText: l10n.t('confirm_password'),
                  icon: Icons.lock,
                  obscureText: !state.isConfirmPasswordVisible,
                  controller: _confirmPasswordController,
                  onVisibilityToggle: (isVisible) {
                    notifier.toggleConfirmPasswordVisibility();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.t('please_confirm_password');
                    }
                    if (value != _passwordController.text) {
                      return l10n.t('passwords_do_not_match');
                    }
                    return null;
                  },
                ),

                // 24px vertical spacing
                const SizedBox(height: 24),

                // Terms and Conditions checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: Checkbox(
                        value: state.agreeToTerms,
                        onChanged: (value) {
                          notifier.toggleAgreeToTerms();
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(
                          color: Color(0xFF000000),
                          width: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 20 / 14,
                            letterSpacing: -0.5,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(text: l10n.t('i_agree_to_the')),
                            TextSpan(
                              text: l10n.t('terms_and_conditions'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 20 / 14,
                                letterSpacing: -0.5,
                                color: Color(0xFF238EC2),
                              ),
                              recognizer: null, // TODO: Add tap recognizer
                            ),
                            TextSpan(text: l10n.t('and')),
                            TextSpan(
                              text: l10n.t('privacy_policy'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 20 / 14,
                                letterSpacing: -0.5,
                                color: Color(0xFF238EC2),
                              ),
                              recognizer: null, // TODO: Add tap recognizer
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // 24px vertical spacing
                const SizedBox(height: 24),

                // Create Account button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate() &&
                          state.agreeToTerms) {
                        // Save form data to provider
                        notifier.updateFullName(_fullNameController.text);
                        notifier.updateEmail(_emailController.text);
                        notifier.updatePhoneNumber(_phoneController.text);
                        notifier.updatePassword(_passwordController.text);
                        notifier.updateConfirmPassword(
                          _confirmPasswordController.text,
                        );
                        // Navigate to step 2
                        notifier.createAccount(context);
                      } else if (!state.agreeToTerms) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.t('please_agree_terms'))),
                        );
                      }
                    },
                    child: Text(l10n.t('create_account')),
                  ),
                ),

                // 24px vertical spacing
                const SizedBox(height: 24),

                // Already have an account section
                Center(
                  child: Column(
                    children: [
                      Text(
                        l10n.t('already_have_account'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 20 / 14,
                          letterSpacing: -0.5,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          notifier.navigateToSignIn(context);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.t('sign_in'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.0, // 100% line height
                            letterSpacing: -0.5,
                            color: Color(0xFF238EC2),
                          ),
                        ),
                      ),
                    ],
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
