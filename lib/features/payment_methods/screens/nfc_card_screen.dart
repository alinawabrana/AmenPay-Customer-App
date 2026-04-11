import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/app_routes.dart';
import 'package:palmpay/features/payment_methods/models/nfc_payment_method_status_model.dart';
import 'package:palmpay/features/payment_methods/providers/payment_methods_refresh_provider.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/services/api_service.dart';
import 'package:palmpay/utils/themes/text_theme.dart';
import 'package:palmpay/widgets/card_preview.dart';
import 'package:qr_flutter/qr_flutter.dart';

class NfcCardScreen extends ConsumerStatefulWidget {
  const NfcCardScreen({super.key});

  @override
  ConsumerState<NfcCardScreen> createState() => _NfcCardScreenState();
}

class _NfcCardScreenState extends ConsumerState<NfcCardScreen> {
  late Future<List<NfcPaymentMethodStatus>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();

    ref.listenManual<int>(paymentMethodsRefreshProvider, (previous, next) {
      setState(() {
        _future = _load();
      });
    });
  }

  Future<List<NfcPaymentMethodStatus>> _load() async {
    final results = await Future.wait([
      ApiService.getPaymentMethodsWithStatus(),
      ApiService.getDefaultPaymentMethodCheck(),
    ]);
    final response = results[0];
    final defaultJson = results[1];
    final defaultId = _extractDefaultPaymentMethodId(defaultJson);
    final raw = response['payment_methods'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(NfcPaymentMethodStatus.fromJson)
        .map((method) => method.copyWith(
              isDefault: defaultId != null && method.paymentMethodId == defaultId,
            ))
        .toList();
  }

  int? _extractDefaultPaymentMethodId(Map<String, dynamic> json) {
    final candidates = <dynamic>[
      json['payment_method_id'],
      json['id'],
      json['default_payment_method_id'],
      (json['data'] is Map<String, dynamic>)
          ? (json['data'] as Map<String, dynamic>)['payment_method_id']
          : null,
      (json['data'] is Map<String, dynamic>)
          ? (json['data'] as Map<String, dynamic>)['id']
          : null,
      (json['payment_method'] is Map<String, dynamic>)
          ? (json['payment_method'] as Map<String, dynamic>)['payment_method_id']
          : null,
      (json['payment_method'] is Map<String, dynamic>)
          ? (json['payment_method'] as Map<String, dynamic>)['id']
          : null,
    ];

    for (final value in candidates) {
      final parsed = _coerceId(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  int? _coerceId(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
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
      body: FutureBuilder<List<NfcPaymentMethodStatus>>(
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

          final methods = snapshot.data ?? const [];

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
                    (method) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _NfcMethodTile(
                        method: method,
                        onOpen: () async {
                          if (method.isNfcNotEnrolled) {
                            await context.push(
                              AppRoutes.paymentMethodsNfcEnrollPath,
                              extra: {'method': method},
                            );
                          } else {
                            await context.push(
                              '${AppRoutes.paymentMethodsNfcPath}/detail',
                              extra: {'method': method},
                            );
                          }
                          if (!context.mounted) return;
                          setState(() {
                            _future = _load();
                          });
                        },
                        onToggleDefault: (isDefault) async {
                          try {
                            final res =
                                await ApiService.toggleDefaultPaymentMethod(
                                  paymentMethodId: method.paymentMethodId,
                                  isDefault: isDefault,
                                );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  res['message']?.toString() ??
                                      l10n.t('default_payment_method_updated'),
                                ),
                              ),
                            );
                            ref
                                .read(paymentMethodsRefreshProvider.notifier)
                                .state++;
                            setState(() {
                              _future = _load();
                            });
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                ),
                                backgroundColor: const Color(0xFFB91C1C),
                              ),
                            );
                          }
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

class _NfcMethodTile extends StatelessWidget {
  final NfcPaymentMethodStatus method;
  final VoidCallback onOpen;
  final Future<void> Function(bool isDefault) onToggleDefault;

  const _NfcMethodTile({
    required this.method,
    required this.onOpen,
    required this.onToggleDefault,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statusLabel = method.isNfcActive
        ? l10n.t('active')
        : method.isNfcInactive
        ? l10n.t('inactive')
        : l10n.t('not_enrolled');
    final badgeColor = method.isNfcActive
        ? const Color(0xFF238EC2)
        : method.isNfcInactive
        ? const Color(0xFF9CA3AF)
        : const Color(0xFFB91C1C);
    final badgeBg = method.isNfcActive
        ? const Color(0xFFEFF6FF)
        : method.isNfcInactive
        ? const Color(0xFFF3F4F6)
        : const Color(0xFFFEF2F2);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.cardHolderName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method.cardNumber,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    if (method.isDefault) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFFDF5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.t('default_label'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF00AA44),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: method.isNfcNotEnrolled
                      ? ElevatedButton(
                          onPressed: onOpen,
                          child: Text(l10n.t('enroll_now')),
                        )
                      : OutlinedButton(
                          onPressed: onOpen,
                          child: Text(l10n.t('view_detail')),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.t('default_label'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Switch(
                    value: method.isDefault,
                    onChanged: (value) => onToggleDefault(value),
                    activeThumbColor: const Color(0xFF00AA44),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

class NfcCardDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> args;

  const NfcCardDetailScreen({super.key, required this.args});

  @override
  ConsumerState<NfcCardDetailScreen> createState() => _NfcCardDetailScreenState();
}

class _NfcCardDetailScreenState extends ConsumerState<NfcCardDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final method = widget.args['method'] as NfcPaymentMethodStatus;
    final holder = method.cardHolderName.toUpperCase();
    final isActive = method.isNfcActive;

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
              cardNumber: method.cardNumber,
              cardholderName: holder,
              expiryDate: method.expiryDate,
            ),
            const SizedBox(height: 24),
            _NfcInfoCard(method: method),
            const SizedBox(height: 24),
            _ActiveToggleCard(
              isActive: isActive,
              onChanged: _isLoading
                  ? (_) {}
                  : (val) async {
                      setState(() => _isLoading = true);
                      try {
                        await ApiService.toggleNfc(
                          paymentMethodId: method.paymentMethodId,
                          action: val ? 'activate' : 'deactivate',
                        );
                        if (!context.mounted) return;
                        ref.read(paymentMethodsRefreshProvider.notifier).state++;
                        context.pop();
                      } catch (e) {
                        if (!context.mounted) return;
                        setState(() => _isLoading = false);
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
          ],
        ),
      ),
    );
  }
}

class NfcEnrollScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> args;

  const NfcEnrollScreen({super.key, required this.args});

  @override
  ConsumerState<NfcEnrollScreen> createState() => _NfcEnrollScreenState();
}

class _NfcEnrollScreenState extends ConsumerState<NfcEnrollScreen> {
  int _step = 1;
  bool _isLoading = true;
  String? _error;
  String? _sessionId;
  Timer? _pollTimer;
  bool _isClaimed = false;

  NfcPaymentMethodStatus get _method =>
      widget.args['method'] as NfcPaymentMethodStatus;

  @override
  void initState() {
    super.initState();
    _createSession();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _createSession() async {
    try {
      final response = await ApiService.createNfcSession(
        paymentMethodId: _method.paymentMethodId,
      );
      if (!mounted) return;

      setState(() {
        _sessionId = response['session_id']?.toString();
        _isLoading = false;
      });

      if ((_sessionId ?? '').isNotEmpty) {
        _startPolling();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final sessionId = _sessionId;
      if (!mounted || sessionId == null || sessionId.isEmpty) return;

      try {
        final response = await ApiService.getNfcSessionStatus(
          sessionId: sessionId,
        );
        final status = (response['status'] ?? '').toString().toLowerCase();
        if (!mounted) return;

        if (status == 'created') {
          setState(() {
            _isClaimed = false;
          });
          return;
        }

        if (status == 'claimed') {
          setState(() {
            _isClaimed = true;
            _step = 2;
          });
          return;
        }

        if (status == 'completed') {
          _pollTimer?.cancel();
          ref.read(paymentMethodsRefreshProvider.notifier).state++;
          setState(() {
            _isClaimed = true;
            _step = 3;
          });
          return;
        }

        if (status == 'failed' || status == 'expired') {
          _pollTimer?.cancel();
          final message = response['last_error']?.toString().trim().isNotEmpty ==
                  true
              ? response['last_error'].toString()
              : response['message']?.toString() ??
                    'NFC enrollment ${status == 'expired' ? 'expired' : 'failed'}.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          context.pop();
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final qrData = _sessionId ?? '';

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
        title: Text(l10n.t('nfc_enroll_title'), style: ATextTheme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SimpleStepIndicator(step: _step),
            const SizedBox(height: 24),
            Expanded(
              child: _step == 1
                  ? _NfcStepOne(
                      qrData: qrData,
                      loading: _isLoading,
                      error: _error,
                      onContinue: () {
                        setState(() => _step = 2);
                      },
                    )
                  : _step == 2
                  ? _NfcStepTwo(isClaimed: _isClaimed)
                  : _NfcStepThree(
                      onDone: () => context.pop(),
                      title: l10n.t('enrollment_complete'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleStepIndicator extends StatelessWidget {
  final int step;

  const _SimpleStepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [l10n.t('nfc_step_qr'), l10n.t('nfc_step_scan'), l10n.t('done')];
    return Row(
      children: List.generate(labels.length * 2 - 1, (index) {
        if (index.isOdd) {
          final active = step > (index ~/ 2) + 1;
          return Expanded(
            child: Container(
              height: 4,
              color: active
                  ? const Color(0xFF238EC2)
                  : const Color(0xFFE5E7EB),
            ),
          );
        }
        final number = (index ~/ 2) + 1;
        final active = step >= number;
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF238EC2) : const Color(0xFFF3F4F6),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF9CA3AF),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }),
    );
  }
}

class _NfcStepOne extends StatelessWidget {
  final String qrData;
  final bool loading;
  final String? error;
  final VoidCallback onContinue;

  const _NfcStepOne({
    required this.qrData,
    required this.loading,
    required this.error,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.nfc_rounded,
                      color: Color(0xFF238EC2),
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).t('nfc_scan_qr_pos'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).t('nfc_pos_claims_session'),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF238EC2),
                      width: 2,
                    ),
                    color: const Color(0xFFEFF6FF),
                  ),
                  child: Center(
                    child: loading
                        ? const CircularProgressIndicator()
                        : qrData.isEmpty
                        ? const Icon(Icons.qr_code, size: 120)
                        : QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 170,
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      _NfcInstructionRow(
                        icon: Icons.qr_code_scanner_rounded,
                        text: AppLocalizations.of(context).t('nfc_step1_pos_scan'),
                      ),
                      SizedBox(height: 12),
                      _NfcInstructionRow(
                        icon: Icons.point_of_sale_rounded,
                        text: AppLocalizations.of(context).t('nfc_step2_keep_card'),
                      ),
                    ],
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFB91C1C)),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: loading || error != null ? null : onContinue,
            child: Text(AppLocalizations.of(context).t('nfc_i_scanned_qr')),
          ),
        ),
      ],
    );
  }
}

class _NfcStepTwo extends StatelessWidget {
  final bool isClaimed;

  const _NfcStepTwo({required this.isClaimed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEFF6FF),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF238EC2),
                    ),
                  ),
                ),
                Icon(
                  isClaimed ? Icons.contactless_rounded : Icons.point_of_sale_rounded,
                  size: 48,
                  color: const Color(0xFF238EC2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isClaimed
                ? AppLocalizations.of(context).t('nfc_scanning_card')
                : AppLocalizations.of(context).t('nfc_waiting_for_pos'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            isClaimed
                ? AppLocalizations.of(context).t('nfc_pos_claimed_waiting_scan')
                : AppLocalizations.of(context).t('nfc_waiting_pos_claim'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isClaimed ? Icons.nfc_rounded : Icons.qr_code_scanner_rounded,
                  color: const Color(0xFF238EC2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isClaimed
                        ? AppLocalizations.of(context).t('nfc_keep_card_steady')
                        : AppLocalizations.of(context).t('nfc_operator_scan_qr'),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NfcInstructionRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _NfcInstructionRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF238EC2), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }
}

class _NfcStepThree extends StatelessWidget {
  final VoidCallback onDone;
  final String title;

  const _NfcStepThree({required this.onDone, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 72, color: Color(0xFF00AA44)),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        SizedBox(
          width: 220,
          height: 56,
          child: ElevatedButton(
            onPressed: onDone,
            child: Text(AppLocalizations.of(context).t('done')),
          ),
        ),
      ],
    );
  }
}

class _NfcInfoCard extends StatelessWidget {
  final NfcPaymentMethodStatus method;

  const _NfcInfoCard({required this.method});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(title: 'Card Holder', value: method.cardHolderName),
          const SizedBox(height: 12),
          _InfoRow(title: 'Card Number', value: method.cardNumber),
          const SizedBox(height: 12),
          _InfoRow(
            title: AppLocalizations.of(context).t('nfc_status_label'),
            value: method.nfcStatus ??
                AppLocalizations.of(context).t('not_enrolled'),
          ),
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
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyMedium)),
        const SizedBox(width: 12),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
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
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isActive ? l10n.t('nfc_active') : l10n.t('nfc_inactive')),
                const SizedBox(height: 2),
                Text(l10n.t('toggle_contactless_payments')),
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
