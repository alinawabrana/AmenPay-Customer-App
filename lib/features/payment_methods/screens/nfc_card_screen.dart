import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/app_routes.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/services/api_service.dart';
import 'package:palmpay/utils/themes/text_theme.dart';
import 'package:palmpay/widgets/card_preview.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palmpay/features/payment_methods/providers/payment_methods_refresh_provider.dart';

import '../../authentication/models/profile/user_model.dart';
import '../../home/models/QR Code/payment_method_model.dart';

class NfcCardScreen extends StatefulWidget {
  const NfcCardScreen({super.key});

  @override
  State<NfcCardScreen> createState() => _NfcCardScreenState();
}

class _NfcCardScreenState extends State<NfcCardScreen> {
  late Future<_NfcData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_NfcData> _load() async {
    final results = await Future.wait([
      ApiService.getUserDetails(),
      ApiService.getPaymentMethods(),
    ]);

    final user = results[0] as UserModel;
    final paymentMethodsJson = results[1] as Map<String, dynamic>;

    final paymentResponse = PaymentMethodsResponse.fromJson(paymentMethodsJson);

    final methods = paymentResponse.paymentMethods;

    final nfcStatuses = <int, bool>{};
    await Future.wait(
      methods.map((m) async {
        try {
          final res = await ApiService.getNfcStatus(paymentMethodId: m.id);
          nfcStatuses[m.id] = _parseNfcStatus(res);
        } catch (_) {
          // keep fallback
        }
      }),
    );

    return _NfcData(user: user, methods: methods, nfcStatuses: nfcStatuses);
  }

  bool _parseNfcStatus(Map<String, dynamic> json) {
    final dynamic inner = json['data'];
    final Map<String, dynamic>? dataMap = inner is Map<String, dynamic>
        ? inner
        : null;

    dynamic v = json['NFC_status'];
    v ??= json['nfc_status'];
    v ??= dataMap?['NFC_status'] ?? dataMap?['nfc_status'];

    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return s == '1' || s == 'true' || s == 'active' || s == 'enabled';
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                onPressed: () => context.pop(),
                icon: SizedBox(
                  width: 17,
                  height: 15,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Icon(
                      Icons.arrow_back,
                      color: const Color(0xFF333333),
                      textDirection: Directionality.of(context),
                    ),
                  ),
                ),
              )
            : null,
        title: Text(l10n.t('nfc_card'), style: ATextTheme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: FutureBuilder<_NfcData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final user = data.user;
          final methods = data.methods;
          final nfcStatuses = data.nfcStatuses;

          return SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(AppRoutes.addCardPath),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.t('add_payment_method')),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.t('select_a_card'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 24 / 16,
                    letterSpacing: -0.5,
                    color: const Color(0xFF333333),
                  ),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 12),
                if (methods.isEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 24, 0, 0),
                    child: Text(
                      l10n.t('no_payment_methods_found'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  ...methods.map(
                    (m) => Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: 12),
                      child: _NfcCardTile(
                        method: m,
                        nfcActive: nfcStatuses[m.id],
                        onTap: () async {
                          await context.push(
                            '${AppRoutes.paymentMethodsNfcPath}/detail',
                            extra: <String, dynamic>{'user': user, 'method': m},
                          );
                          if (!context.mounted) return;
                          setState(() {
                            _future = _load();
                          });
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NfcCardTile extends StatelessWidget {
  final PaymentMethod method;
  final bool? nfcActive;
  final VoidCallback onTap;

  const _NfcCardTile({
    required this.method,
    required this.nfcActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isActive = nfcActive ?? (method.status.toLowerCase() == 'active');
    final masked = _maskForList(method.cardNumber);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              offset: Offset(0, 1),
              blurRadius: 2,
              spreadRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.credit_card,
                color: Color(0xFF238EC2),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    masked,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 20 / 14,
                      letterSpacing: -0.5,
                      color: const Color(0xFF333333),
                    ),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.expiryDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 16 / 12,
                      letterSpacing: -0.5,
                      color: const Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 6),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? const Color(0xFF238EC2)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isActive
                        ? l10n.t('active_status')
                        : l10n.t('inactive_status'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 16 / 12,
                      letterSpacing: -0.5,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _maskForList(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '•••• •••• •••• ••••';
    final last4 = digits.length >= 4
        ? digits.substring(digits.length - 4)
        : digits;
    return '•••• •••• •••• $last4';
  }
}

class _AccountInfoCard extends StatelessWidget {
  final String accountName;
  final String cardNumber;

  const _AccountInfoCard({required this.accountName, required this.cardNumber});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 1),
            blurRadius: 2,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('account_information'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(height: 28 / 18),
          ),
          const SizedBox(height: 16),
          _InfoRow(title: l10n.t('account_name'), value: accountName),
          const SizedBox(height: 12),
          _InfoRow(title: l10n.t('bank_card_number'), value: cardNumber),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 20 / 14,
      letterSpacing: -0.5,
      color: const Color(0xFF4B5563),
    );

    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 20 / 14,
      letterSpacing: -0.5,
      color: const Color(0xFF333333),
    );

    return Row(
      children: [
        Expanded(
          child: Text(title, style: titleStyle, textAlign: TextAlign.start),
        ),
        const SizedBox(width: 12),
        Text(value, style: valueStyle, textAlign: TextAlign.start),
      ],
    );
  }
}

class _ActiveToggleCard extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const _ActiveToggleCard({required this.isActive, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 1),
            blurRadius: 2,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? l10n.t('nfc_active') : l10n.t('nfc_inactive'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 20 / 14,
                    letterSpacing: -0.5,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.t('toggle_contactless_payments'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 16 / 12,
                    letterSpacing: -0.5,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF238EC2),
          ),
        ],
      ),
    );
  }
}

class _NfcData {
  final UserModel user;
  final List<PaymentMethod> methods;
  final Map<int, bool> nfcStatuses;

  const _NfcData({
    required this.user,
    required this.methods,
    required this.nfcStatuses,
  });
}

class NfcCardDetailScreen extends StatefulWidget {
  final Map<String, dynamic> args;

  const NfcCardDetailScreen({super.key, required this.args});

  @override
  State<NfcCardDetailScreen> createState() => _NfcCardDetailScreenState();
}

class _NfcCardDetailScreenState extends State<NfcCardDetailScreen> {
  late bool _isActive;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final method = widget.args['method'] as PaymentMethod;
    _isActive = method.status.toLowerCase() == 'active';
    _fetchNfcStatus();
  }

  Future<void> _fetchNfcStatus() async {
    final method = widget.args['method'] as PaymentMethod;

    try {
      final res = await ApiService.getNfcStatus(paymentMethodId: method.id);
      final status = _parseNfcStatus(res);
      if (!mounted) return;
      setState(() {
        _isActive = status;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _parseNfcStatus(Map<String, dynamic> json) {
    final dynamic inner = json['data'];
    final Map<String, dynamic>? dataMap = inner is Map<String, dynamic>
        ? inner
        : null;

    dynamic v = json['NFC_status'];
    v ??= json['nfc_status'];
    v ??= dataMap?['NFC_status'] ?? dataMap?['nfc_status'];

    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return s == '1' || s == 'true' || s == 'active' || s == 'enabled';
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = widget.args['user'] as UserModel;
    final method = widget.args['method'] as PaymentMethod;

    final cardNumber = _formatCardNumber(method.cardNumber);
    final holder = (method.cardHolderName.isNotEmpty)
        ? method.cardHolderName.toUpperCase()
        : user.fullname.toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: SizedBox(
            width: 17,
            height: 15,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Icon(
                Icons.arrow_back,
                color: const Color(0xFF333333),
                textDirection: Directionality.of(context),
              ),
            ),
          ),
        ),
        title: Text(l10n.t('nfc_card'), style: ATextTheme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardPreview(
              cardNumber: cardNumber.isEmpty
                  ? '•••• •••• •••• ••••'
                  : '•••• •••• •••• $cardNumber',
              cardholderName: holder,
              expiryDate: method.expiryDate,
            ),
            const SizedBox(height: 24),
            _AccountInfoCard(
              accountName: user.fullname,
              cardNumber: _mask(method.cardNumber),
            ),
            const SizedBox(height: 24),
            _ActiveToggleCard(
              isActive: _isActive,
              onChanged: _isLoading
                  ? (_) {}
                  : (val) async {
                      final prev = _isActive;
                      setState(() {
                        _isActive = val;
                        _isLoading = true;
                      });

                      try {
                        await ApiService.updateNfcStatus(
                          paymentMethodId: method.id,
                          isEnabled: val,
                        );
                        if (!context.mounted) return;
                        ProviderScope.containerOf(
                          context,
                        ).read(paymentMethodsRefreshProvider.notifier).state++;
                        setState(() {
                          _isLoading = false;
                        });
                      } catch (e) {
                        if (!context.mounted) return;
                        setState(() {
                          _isActive = prev;
                          _isLoading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceAll('Exception: ', ''),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.addCardPath),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.t('add_payment_method')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCardNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  String _mask(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    final last4 = digits.length >= 4
        ? digits.substring(digits.length - 4)
        : digits;
    return '**** $last4';
  }
}
