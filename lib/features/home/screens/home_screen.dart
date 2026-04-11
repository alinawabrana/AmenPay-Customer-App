import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:palmpay/app_routes.dart';
import 'package:palmpay/features/payment_methods/models/nfc_payment_method_status_model.dart';
import 'package:palmpay/features/payment_methods/providers/payment_methods_refresh_provider.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/widgets/custom_app_bar.dart';
import 'package:palmpay/widgets/payment_method_card.dart';
import 'package:palmpay/widgets/quick_action_button.dart';
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
  List<_HomeTransaction> _transactions = const [];
  bool _isLoading = true;
  _NfcBadgeState _nfcBadge = _NfcBadgeState.notEnrolled;
  bool _isPalmEnrolled = false;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();

    ref.listenManual<int>(profileRefreshProvider, (previous, next) {
      _fetchUserDetails();
    });
    ref.listenManual<int>(paymentMethodsRefreshProvider, (previous, next) {
      _fetchUserDetails();
    });
  }

  Future<void> _fetchUserDetails() async {
    try {
      final results = await Future.wait([
        ApiService.getUserDetails(),
        ApiService.getPaymentMethodsWithStatus(),
        ApiService.getUserCards(),
        ApiService.getPalmEnrollMeStatus(),
      ]);

      final user = results[0] as UserModel;
      final paymentMethodsJson = results[1] as Map<String, dynamic>;
      final userCardsJson = results[2] as Map<String, dynamic>;
      final palmEnrollJson = results[3] as Map<String, dynamic>;

      final transactionsJson = await ApiService.getCustomerTransactions(
        customerId: user.id,
      );
      final transactions = _parseTransactions(transactionsJson);
      final methodsRaw = paymentMethodsJson['payment_methods'];
      final methods = methodsRaw is List
          ? methodsRaw
                .whereType<Map<String, dynamic>>()
                .map(NfcPaymentMethodStatus.fromJson)
                .toList()
          : <NfcPaymentMethodStatus>[];

      if (!mounted) return;
      setState(() {
        _user = user;
        _transactions = transactions;
        _nfcBadge = _deriveNfcBadge(methods);
        _isPalmEnrolled = _parseIsPalmEnrolled(
          methods,
          palmEnrollJson,
          userCardsJson,
        );
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error fetching user details: $e');
    }
  }

  List<_HomeTransaction> _parseTransactions(Map<String, dynamic> json) {
    final raw = json['transactions'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(_HomeTransaction.fromJson)
        .toList();
  }

  _NfcBadgeState _deriveNfcBadge(List<NfcPaymentMethodStatus> methods) {
    if (methods.any((m) => m.isNfcActive)) return _NfcBadgeState.active;
    if (methods.any((m) => m.isNfcEnrolledKnown)) {
      return _NfcBadgeState.inactive;
    }
    return _NfcBadgeState.notEnrolled;
  }

  bool _parseIsPalmEnrolled(
    List<NfcPaymentMethodStatus> methods,
    Map<String, dynamic> palmEnrollJson,
    Map<String, dynamic> userCardsJson,
  ) {
    if (methods.any((m) => m.palmEnrolled)) return true;

    final palmData = palmEnrollJson['data'] is Map<String, dynamic>
        ? (palmEnrollJson['data'] as Map<String, dynamic>)
        : palmEnrollJson;

    final enrolledList = palmData['enrolled_methods'] ??
        palmData['enrolled_payment_methods'] ??
        palmData['enrolled_ids'];
    if (enrolledList is List && enrolledList.isNotEmpty) return true;
    if (enrolledList is Map && enrolledList.isNotEmpty) return true;

    final enrolledCount = palmData['enrolled_count'];
    if (enrolledCount is num && enrolledCount > 0) return true;

    final candidates = [
      palmEnrollJson['is_enrolled'],
      palmEnrollJson['palm_vein_enrolled'],
      palmEnrollJson['is_palm_enrolled'],
      palmEnrollJson['palmEnrolled'],
      userCardsJson['palm_vein_enrolled'],
      userCardsJson['is_palm_enrolled'],
      userCardsJson['palmEnrolled'],
    ];

    for (final value in candidates) {
      if (value is bool) return value;
      if (value is String) {
        final lowered = value.toLowerCase();
        if (lowered == 'true') return true;
        if (lowered == 'false') return false;
      }
      if (value is num) {
        if (value == 1) return true;
        if (value == 0) return false;
      }
    }

    return false;
  }

  void _openHistoryScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _TransactionHistoryScreen(
          transactions: _transactions,
        ),
      ),
    );
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
                    icon: Icons.pan_tool,
                    label: l10n.t('palm_vein'),
                    backgroundColor: const Color(0xFF00AA44),
                    onTap: () {
                      context.push(AppRoutes.paymentMethodsPalmPath);
                    },
                  ),
                  QuickActionButton(
                    icon: Icons.qr_code,
                    label: l10n.t('qr_code'),
                    backgroundColor: const Color(0xFF238EC2),
                    onTap: () => context.push(AppRoutes.paymentMethodsQrPath),
                  ),
                  QuickActionButton(
                    icon: Icons.access_time,
                    label: l10n.t('history'),
                    backgroundColor: const Color(0xFFFF8800),
                    onTap: _openHistoryScreen,
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
                  onPressed: _openHistoryScreen,
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
                    color: const Color(0x00000000).withAlpha(13),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: _transactions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      child: Center(
                        child: Text(
                          l10n.t('recent_transactions'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < _transactions.length && i < 4; i++) ...[
                          TransactionItem(
                            title: _transactions[i].title,
                            date: _transactions[i].formattedDate,
                            amount: _transactions[i].formattedAmount,
                            icon: _transactions[i].icon,
                            iconColor: _transactions[i].iconColor,
                            iconBackgroundColor:
                                _transactions[i].iconBackgroundColor,
                            isPositive: _transactions[i].isPositive,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => _TransactionDetailScreen(
                                    transaction: _transactions[i],
                                  ),
                                ),
                              );
                            },
                          ),
                          if (i < _transactions.length - 1 && i < 3)
                            const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        ],
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
              badgeText: _isPalmEnrolled
                  ? l10n.t('enrolled')
                  : l10n.t('not_enrolled'),
              badgeColor: _isPalmEnrolled
                  ? const Color(0xFF00AA44)
                  : const Color(0xFF9CA3AF),
              onTap: () => context.push(AppRoutes.paymentMethodsPalmPath),
            ),
            const SizedBox(height: 12),
            PaymentMethodCard(
              title: l10n.t('nfc_card'),
              subtitle: l10n.t('contactless_payment'),
              icon: Icons.credit_card,
              iconColor: Color(0xFF238EC2),
              iconBackgroundColor: Color(0xFFEFF6FF),
              badgeText: switch (_nfcBadge) {
                _NfcBadgeState.active => l10n.t('active'),
                _NfcBadgeState.inactive => l10n.t('inactive'),
                _NfcBadgeState.notEnrolled => l10n.t('not_enrolled'),
              },
              badgeColor: switch (_nfcBadge) {
                _NfcBadgeState.active => const Color(0xFF238EC2),
                _NfcBadgeState.inactive => const Color(0xFF9CA3AF),
                _NfcBadgeState.notEnrolled => const Color(0xFF9CA3AF),
              },
              onTap: () => context.push(AppRoutes.paymentMethodsNfcPath),
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
              onTap: () => context.push(AppRoutes.paymentMethodsQrPath),
            ),
            // Bottom padding
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HomeTransaction {
  final int id;
  final String title;
  final String formattedDate;
  final String formattedAmount;
  final String rawAmount;
  final String status;
  final String cardNumber;
  final String cardHolderName;
  final String paymentMethodId;
  final String moyasarId;
  final String createdAtIso;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final bool isPositive;

  const _HomeTransaction({
    required this.id,
    required this.title,
    required this.formattedDate,
    required this.formattedAmount,
    required this.rawAmount,
    required this.status,
    required this.cardNumber,
    required this.cardHolderName,
    required this.paymentMethodId,
    required this.moyasarId,
    required this.createdAtIso,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.isPositive,
  });

  factory _HomeTransaction.fromJson(Map<String, dynamic> json) {
    final amountRaw = json['amount']?.toString() ?? '0';
    final amount = double.tryParse(amountRaw) ?? 0;
    final status = (json['status']?.toString() ?? '').toLowerCase();
    final cardHolder = json['card_holder_name']?.toString().trim();
    final cardNumber = json['card_number']?.toString().trim() ?? '';
    final createdAtRaw = json['created_at']?.toString();
    final createdAt =
        createdAtRaw != null ? DateTime.tryParse(createdAtRaw)?.toLocal() : null;

    final isPositive =
        status == 'completed' || status == 'success' || status == 'initiated';
    final formatter = DateFormat('MMM d, h:mm a');
    final formattedDate = createdAt != null
        ? formatter.format(createdAt)
        : 'Unknown date';

    return _HomeTransaction(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: _buildTitle(cardHolder, cardNumber),
      formattedDate: formattedDate,
      formattedAmount:
          '${isPositive ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
      rawAmount: amountRaw,
      status: status,
      cardNumber: cardNumber,
      cardHolderName: cardHolder ?? '',
      paymentMethodId: json['payment_method_id']?.toString() ?? '',
      moyasarId: json['moyasar_id']?.toString() ?? '',
      createdAtIso: createdAtRaw ?? '',
      icon: _iconForStatus(status),
      iconColor: _iconColorForStatus(status),
      iconBackgroundColor: _iconBgForStatus(status),
      isPositive: isPositive,
    );
  }

  static String _buildTitle(String? cardHolder, String cardNumber) {
    if (cardHolder != null && cardHolder.isNotEmpty) {
      return cardHolder;
    }
    if (cardNumber.isNotEmpty) {
      return cardNumber;
    }
    return 'Transaction';
  }

  static IconData _iconForStatus(String status) {
    switch (status) {
      case 'completed':
      case 'success':
      case 'initiated':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.receipt_long;
    }
  }

  static Color _iconColorForStatus(String status) {
    switch (status) {
      case 'completed':
      case 'success':
      case 'initiated':
        return const Color(0xFF00AA44);
      case 'pending':
        return const Color(0xFFFF8800);
      default:
        return const Color(0xFF6B7280);
    }
  }

  static Color _iconBgForStatus(String status) {
    switch (status) {
      case 'completed':
      case 'success':
      case 'initiated':
        return const Color(0xFFF0FDF4);
      case 'pending':
        return const Color(0xFFFFF7ED);
      default:
        return const Color(0xFFF3F4F6);
    }
  }
}

enum _NfcBadgeState { active, inactive, notEnrolled }

class _TransactionHistoryScreen extends StatelessWidget {
  final List<_HomeTransaction> transactions;

  const _TransactionHistoryScreen({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
        ),
        title: Text(
          l10n.t('history'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        centerTitle: true,
      ),
      body: transactions.isEmpty
          ? Center(
              child: Text(
                l10n.t('recent_transactions'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: transactions.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TransactionItem(
                    title: transaction.title,
                    date: transaction.formattedDate,
                    amount: transaction.formattedAmount,
                    icon: transaction.icon,
                    iconColor: transaction.iconColor,
                    iconBackgroundColor: transaction.iconBackgroundColor,
                    isPositive: transaction.isPositive,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              _TransactionDetailScreen(transaction: transaction),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _TransactionDetailScreen extends StatelessWidget {
  final _HomeTransaction transaction;

  const _TransactionDetailScreen({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
        ),
        title: Text(
          l10n.t('view_detail'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(title: 'Transaction ID', value: transaction.id.toString()),
              const SizedBox(height: 14),
              _DetailRow(title: 'Card Holder', value: transaction.cardHolderName),
              const SizedBox(height: 14),
              _DetailRow(title: 'Card Number', value: transaction.cardNumber),
              const SizedBox(height: 14),
              _DetailRow(title: 'Amount', value: transaction.formattedAmount),
              const SizedBox(height: 14),
              _DetailRow(title: 'Status', value: transaction.status),
              const SizedBox(height: 14),
              _DetailRow(
                title: l10n.t('payment_method_id_label'),
                value: transaction.paymentMethodId,
              ),
              const SizedBox(height: 14),
              _DetailRow(title: 'Created At', value: transaction.formattedDate),
              if (transaction.moyasarId.isNotEmpty) ...[
                const SizedBox(height: 14),
                _DetailRow(title: 'Moyasar ID', value: transaction.moyasarId),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String title;
  final String value;

  const _DetailRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }
}
