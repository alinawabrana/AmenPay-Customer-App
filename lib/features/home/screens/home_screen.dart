import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/app_routes.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/widgets/custom_app_bar.dart';
import 'package:palmpay/widgets/payment_method_card.dart';
import 'package:palmpay/widgets/quick_action_button.dart';
import 'package:palmpay/widgets/total_balance_card.dart';
import 'package:palmpay/widgets/transaction_item.dart';

import 'package:palmpay/features/settings/providers/profile_refresh_provider.dart';

import '../../../services/api_service.dart';
import '../../authentication/models/profile/user_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();

    ref.listenManual<int>(profileRefreshProvider, (previous, next) {
      _fetchUserDetails();
    });
  }

  Future<void> _fetchUserDetails() async {
    try {
      final user = await ApiService.getUserDetails();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      _isLoading = false;
      debugPrint('Error fetching user details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Text(
              _isLoading
                  ? l10n.t('welcome_back_loading')
                  : '${l10n.t('welcome_back')}, ${_user?.fullname ?? ''}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 32 / 24,
                letterSpacing: -0.5,
                color: Color(0xFF333333),
              ),
            ),
            // 4px spacing
            const SizedBox(height: 4),
            Text(
              l10n.t('manage_finances_securely'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
                letterSpacing: -0.5,
                color: Color(0xFF6B7280),
              ),
            ),
            // 16px spacing
            const SizedBox(height: 16),
            // Total Balance Card
            const TotalBalanceCard(),
            // 24px spacing
            const SizedBox(height: 24),
            // Quick Actions section
            Text(
              l10n.t('quick_action'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 24 / 16,
                letterSpacing: -0.5,
                color: Color(0xFF333333),
              ),
            ),
            // 16px spacing
            const SizedBox(height: 16),
            // Quick action buttons row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  QuickActionButton(
                    icon: Icons.send,
                    label: l10n.t('pay_now'),
                    backgroundColor: const Color(0xFF238EC2),
                    onTap: () {
                      // TODO: Navigate to pay now
                    },
                  ),
                  QuickActionButton(
                    icon: Icons.qr_code,
                    label: l10n.t('qr_code'),
                    backgroundColor: const Color(0xFF00AA44),
                    onTap: () => context.push(AppRoutes.paymentMethodsQrPath),
                  ),
                  QuickActionButton(
                    icon: Icons.access_time,
                    label: l10n.t('history'),
                    backgroundColor: const Color(0xFFFF8800),
                    onTap: () {
                      // TODO: Navigate to history
                    },
                  ),
                ],
              ),
            ),
            // 24px spacing
            const SizedBox(height: 24),
            // Recent Transactions section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.t('recent_transactions'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 24 / 16,
                    letterSpacing: -0.5,
                    color: Color(0xFF333333),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to all transactions
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.t('see_all'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF238EC2),
                    ),
                  ),
                ),
              ],
            ),
            // 26px spacing
            const SizedBox(height: 26),
            // Recent transactions card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x00000000).withAlpha(13), // #0000000D
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  TransactionItem(
                    title: 'Starbucks Coffee',
                    date: 'Today, 9:42 AM',
                    amount: '-\$5.50',
                    icon: Icons.local_cafe,
                    iconColor: const Color(0xFF238EC2),
                    iconBackgroundColor: const Color(0xFFEFF6FF),
                    isPositive: false,
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  TransactionItem(
                    title: 'Salary Deposit',
                    date: 'Yesterday, 2:15 PM',
                    amount: '+\$3,200.00',
                    icon: Icons.arrow_downward,
                    iconColor: const Color(0xFF00AA44),
                    iconBackgroundColor: const Color(0xFFF0FDF4),
                    isPositive: true,
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  TransactionItem(
                    title: 'Amazon Purchase',
                    date: 'Dec 28, 4:30 PM',
                    amount: '-\$89.99',
                    icon: Icons.shopping_cart,
                    iconColor: const Color(0xFFFF8800),
                    iconBackgroundColor: const Color(0xFFFFF7ED),
                    isPositive: false,
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  TransactionItem(
                    title: 'Uber Eats',
                    date: 'Dec 27, 7:20 PM',
                    amount: '-\$24.50',
                    icon: Icons.restaurant,
                    iconColor: const Color(0xFF9333EA),
                    iconBackgroundColor: const Color(0xFFFAF5FF),
                    isPositive: false,
                  ),
                ],
              ),
            ),
            // 24px spacing
            const SizedBox(height: 24),
            // Payment Methods section
            Text(
              l10n.t('payment_method_section_title'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 24 / 16,
                letterSpacing: -0.5,
                color: Color(0xFF333333),
              ),
            ),
            // 16px spacing
            const SizedBox(height: 16),
            // Payment method cards
            PaymentMethodCard(
              title: l10n.t('palm_vein'),
              subtitle: l10n.t('biometric_payment'),
              icon: Icons.pan_tool,
              iconColor: Color(0xFF00AA44),
              iconBackgroundColor: Color(0xFFF0FDF4),
              badgeText: l10n.t('enrolled'),
              badgeColor: Color(0xFF00AA44),
            ),
            const SizedBox(height: 12),
            PaymentMethodCard(
              title: l10n.t('nfc_card'),
              subtitle: l10n.t('contactless_payment'),
              icon: Icons.credit_card,
              iconColor: Color(0xFF238EC2),
              iconBackgroundColor: Color(0xFFEFF6FF),
              badgeText: l10n.t('inactive'),
              badgeColor: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 12),
            PaymentMethodCard(
              title: l10n.t('qr_code'),
              subtitle: l10n.t('scan_to_pay'),
              icon: Icons.qr_code,
              iconColor: Color(0xFFFF8800),
              iconBackgroundColor: Color(0xFFFFF7ED),
              badgeColor: Color(0xFFFF8800),
              badgeText: l10n.t('available'),
            ),
            // Bottom padding
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
