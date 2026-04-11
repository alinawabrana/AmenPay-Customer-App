import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/services/api_service.dart';
import 'package:palmpay/utils/themes/text_theme.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';

import '../providers/payment_methods_refresh_provider.dart';

class EnrollPalmVeinScreen extends ConsumerStatefulWidget {
  final int paymentMethodId;
  final int? cardId;

  const EnrollPalmVeinScreen({
    super.key,
    required this.paymentMethodId,
    this.cardId,
  });

  @override
  ConsumerState<EnrollPalmVeinScreen> createState() =>
      _EnrollPalmVeinScreenState();
}

class _EnrollPalmVeinScreenState extends ConsumerState<EnrollPalmVeinScreen> {
  int _step = 1;

  bool _loadingSession = true;
  String? _sessionId;
  String? _qrData;
  String? _error;
  String _sessionStatus = 'created';
  Timer? _pollTimer;
  bool _notifiedEnrollment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initSession();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initSession() async {
    final l10n = AppLocalizations.of(context);
    if (widget.paymentMethodId <= 0) {
      setState(() {
        _loadingSession = false;
        _error = l10n.t('missing_payment_method');
      });
      return;
    }

    _pollTimer?.cancel();
    setState(() {
      _loadingSession = true;
      _sessionId = null;
      _qrData = null;
      _error = null;
      _sessionStatus = 'created';
      _step = 1;
    });

    try {
      final res = await ApiService.createPalmEnrollSession(
        paymentMethodId: widget.paymentMethodId,
      );
      final sessionId = res['session_id']?.toString();
      final qrData = res['qr_data']?.toString();
      if (sessionId == null ||
          sessionId.isEmpty ||
          qrData == null ||
          qrData.isEmpty) {
        throw Exception(l10n.t('invalid_enrollment_session_response'));
      }

      if (!mounted) return;
      setState(() {
        _sessionId = sessionId;
        _qrData = qrData;
        _sessionStatus = (res['status'] ?? 'created').toString().toLowerCase();
        _loadingSession = false;
      });

      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loadingSession = false;
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    final sessionId = _sessionId;
    if (sessionId == null) return;

    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final res = await ApiService.getPalmEnrollSessionStatus(
          sessionId: sessionId,
        );
        _handleSessionStatusResponse(res);
      } catch (_) {
        await _checkEnrollmentFallback();
      }
    });
  }

  void _handleSessionStatusResponse(Map<String, dynamic> res) {
    final status = (res['status'] ?? '').toString().toLowerCase();
    if (!mounted) return;

    if (status == 'enrolled') {
      _pollTimer?.cancel();
      _notifyEnrollmentComplete();
      setState(() {
        _sessionStatus = status;
        _error = null;
        _step = 3;
      });
      return;
    }

    if (status == 'failed') {
      _pollTimer?.cancel();
      final message =
          (res['message'] ??
                  res['error_code'] ??
                  AppLocalizations.of(context).t('qr_code_scan_failed'))
              .toString();
      setState(() {
        _sessionStatus = status;
        if (_step > 1) {
          _step = 2;
        }
        _error = message;
      });
      if (_step == 1) {
        _showScanFailedSnackBar(message);
      }
      return;
    }

    if (status == 'expired') {
      _pollTimer?.cancel();
      final message = AppLocalizations.of(
        context,
      ).t('qr_code_scan_failed_regenerate');
      setState(() {
        _sessionStatus = status;
        _error = message;
        if (_step > 1) {
          _step = 2;
        }
      });
      if (_step == 1) {
        _showScanFailedSnackBar(message);
      }
      return;
    }

    if (status.isNotEmpty) {
      setState(() {
        _sessionStatus = status;
        if (status == 'claimed' && _step < 2) {
          _step = 2;
        }
      });
    }
  }

  Future<void> _checkEnrollmentFallback() async {
    try {
      final res = await ApiService.getPalmEnrollMeStatus();
      if (!mounted) return;

      if (_isPalmEnrollmentConfirmed(res)) {
        _pollTimer?.cancel();
        _notifyEnrollmentComplete();
        setState(() {
          _sessionStatus = 'enrolled';
          _error = null;
          _step = 3;
        });
      }
    } catch (_) {
      // Keep waiting if both endpoints are temporarily unavailable.
    }
  }

  bool _isPalmEnrollmentConfirmed(Map<String, dynamic> res) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('PALM ENROLL → raw status: $res');
    }
    final status = (res['status'] ?? '').toString().toLowerCase();
    if (status == 'enrolled') {
      return true;
    }

    final byMethod = _extractEnrollmentByMethod(res);
    if (byMethod.isNotEmpty) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('PALM ENROLL → status map: $byMethod');
      }
      final byMethodId = byMethod[widget.paymentMethodId];
      if (byMethodId != null) return byMethodId;
      final cardId = widget.cardId;
      if (cardId != null && byMethod.containsKey(cardId)) {
        return byMethod[cardId] ?? false;
      }
      return false;
    }

    final candidates = [
      res['is_enrolled'],
      res['palm_vein_enrolled'],
      res['is_palm_enrolled'],
      res['palmEnrolled'],
      res['data'] is Map<String, dynamic>
          ? (res['data'] as Map<String, dynamic>)['is_enrolled']
          : null,
      res['data'] is Map<String, dynamic>
          ? (res['data'] as Map<String, dynamic>)['palm_vein_enrolled']
          : null,
      res['data'] is Map<String, dynamic>
          ? (res['data'] as Map<String, dynamic>)['is_palm_enrolled']
          : null,
      res['data'] is Map<String, dynamic>
          ? (res['data'] as Map<String, dynamic>)['palmEnrolled']
          : null,
    ];

    for (final value in candidates) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final lowered = value.toLowerCase().trim();
        if (lowered == 'true' || lowered == '1' || lowered == 'enrolled') {
          return true;
        }
        if (lowered == 'false' || lowered == '0') {
          return false;
        }
      }
    }

    return false;
  }

  void _notifyEnrollmentComplete() {
    if (_notifiedEnrollment) return;
    _notifiedEnrollment = true;
    ref.read(paymentMethodsRefreshProvider.notifier).state++;
  }

  Map<int, bool> _extractEnrollmentByMethod(Map<String, dynamic> res) {
    final map = <int, bool>{};
    final root = res['data'] is Map<String, dynamic>
        ? (res['data'] as Map<String, dynamic>)
        : res;

    final listCandidates = [
      root['payment_methods'],
      root['cards'],
      root['enrollments'],
      res['payment_methods'],
      res['cards'],
      res['enrollments'],
    ];

    for (final raw in listCandidates) {
      if (raw is! List) continue;
      for (final item in raw) {
        if (item is! Map<String, dynamic>) continue;
        final id = _readMethodId(item);
        final enrolled = _readEnrolledFlag(item);
        if (id != null && enrolled != null) {
          map[id] = enrolled;
        }
        final cardId = _coerceId(item['card_id'] ?? item['cardId']);
        if (cardId != null && enrolled != null) {
          map[cardId] = enrolled;
        }
      }
    }

    final enrolledIdsRaw = root['enrolled_methods'] ??
        root['enrolled_payment_methods'] ??
        root['enrolled_ids'];
    if (enrolledIdsRaw is List) {
      for (final v in enrolledIdsRaw) {
        if (v is Map<String, dynamic>) {
          final id = _readMethodId(v);
          if (id != null) {
            map[id] = _readEnrolledFlag(v) ?? true;
          }
          continue;
        }
        final id = _coerceId(v);
        if (id != null) {
          map[id] = true;
        }
      }
    }
    if (enrolledIdsRaw is Map) {
      for (final entry in enrolledIdsRaw.values) {
        if (entry is Map<String, dynamic>) {
          final id = _readMethodId(entry);
          if (id != null) {
            map[id] = _readEnrolledFlag(entry) ?? true;
          }
        } else {
          final id = _coerceId(entry);
          if (id != null) {
            map[id] = true;
          }
        }
      }
    }

    final notEnrolledIdsRaw =
        root['not_enrolled_methods'] ?? root['not_enrolled_ids'];
    if (notEnrolledIdsRaw is List) {
      for (final v in notEnrolledIdsRaw) {
        final id = _coerceId(v);
        if (id != null && !map.containsKey(id)) {
          map[id] = false;
        }
      }
    }

    return map;
  }

  int? _coerceId(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  int? _readMethodId(Map<String, dynamic> item) {
    return _coerceId(
      item['payment_method_id'] ??
          item['paymentMethodId'] ??
          item['payment_method'] ??
          item['method_id'] ??
          item['id'],
    );
  }

  bool? _readEnrolledFlag(Map<String, dynamic> item) {
    final candidates = [
      item['is_enrolled'],
      item['palm_vein_enrolled'],
      item['is_palm_enrolled'],
      item['palmEnrolled'],
      item['enrolled'],
      item['status'],
    ];

    for (final value in candidates) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final lowered = value.toLowerCase().trim();
        if (lowered == 'enrolled') return true;
        if (lowered == 'not_enrolled') return false;
        if (lowered == 'true' || lowered == '1') return true;
        if (lowered == 'false' || lowered == '0') return false;
      }
    }

    return null;
  }

  void _showScanFailedSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        title: Text(
          l10n.t('enroll_palm_vein'),
          style: ATextTheme.textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepIndicator(step: _step),
            const SizedBox(height: 24),
            Expanded(
              child: _step == 1
                  ? _StepOne(
                      loading: _loadingSession,
                      sessionStatus: _sessionStatus,
                      qrData: _qrData,
                      error: _error,
                      onRetry: _initSession,
                    )
                  : _step == 2
                  ? _StepTwo(
                      sessionStatus: _sessionStatus,
                      error: _error,
                      onRetry: _initSession,
                      onContinue: () => setState(() => _step = 3),
                    )
                  : _StepThree(
                      onDone: () {
                        context.pop();
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;

  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          children: [
            _StepCircle(number: 1, active: step >= 1, current: step == 1),
            Expanded(
              child: Container(
                height: 4,
                color: step >= 2
                    ? const Color(0xFF238EC2)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            _StepCircle(number: 2, active: step >= 2, current: step == 2),
            Expanded(
              child: Container(
                height: 4,
                color: step >= 3
                    ? const Color(0xFF238EC2)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            _StepCircle(number: 3, active: step >= 3, current: step == 3),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StepLabel(label: l10n.t('step_qr_code')),
            _StepLabel(label: l10n.t('step_scanning')),
            _StepLabel(label: l10n.t('step_complete')),
          ],
        ),
      ],
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String label;

  const _StepLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        letterSpacing: -0.5,
        color: const Color(0xFF4B5563),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int number;
  final bool active;
  final bool current;

  const _StepCircle({
    required this.number,
    required this.active,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final bg = current
        ? const Color(0xFF238EC2)
        : active
        ? const Color(0xFFEFF6FF)
        : const Color(0xFFF3F4F6);

    final fg = current
        ? Colors.white
        : active
        ? const Color(0xFF238EC2)
        : const Color(0xFF9CA3AF);

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: Text(
          number.toString(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _StepOne extends StatelessWidget {
  final VoidCallback onRetry;
  final bool loading;
  final String sessionStatus;
  final String? qrData;
  final String? error;

  const _StepOne({
    required this.onRetry,
    required this.loading,
    required this.sessionStatus,
    required this.qrData,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasError = error != null;
    final isWaiting = !loading && !hasError && sessionStatus == 'created';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                        : (qrData == null || qrData!.isEmpty)
                        ? const Icon(
                            Icons.qr_code,
                            size: 120,
                            color: Color(0xFF238EC2),
                          )
                        : QrImageView(
                            data: qrData!,
                            version: QrVersions.auto,
                            size: 170,
                          ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 16 / 12,
                      letterSpacing: -0.5,
                      color: const Color(0xFFB91C1C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  hasError ? error! : l10n.t('scan_qr_enrollment_instruction'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 23 / 14,
                    letterSpacing: -0.5,
                    color: hasError
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                if (loading || isWaiting)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (loading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Color(0xFF238EC2),
                          size: 18,
                        ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          loading
                              ? l10n.t('generating_qr_code_session')
                              : l10n.t('waiting_qr_scan_result'),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 16 / 12,
                                letterSpacing: -0.5,
                                color: const Color(0xFF238EC2),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (hasError)
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: loading ? null : onRetry,
              child: Text(l10n.t('regenerate_qr_code')),
            ),
          ),
        if (hasError) const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield, color: Color(0xFF238EC2), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.t('biometric_data_secure'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 16 / 12,
                  letterSpacing: -0.5,
                  color: const Color(0xFF4B5563),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepTwo extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onContinue;
  final String sessionStatus;
  final String? error;

  const _StepTwo({
    required this.onRetry,
    required this.onContinue,
    required this.sessionStatus,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasError = error != null;
    final isClaimed = sessionStatus == 'claimed';
    final statusText = hasError
        ? error!
        : isClaimed
        ? l10n.t('palm_scan_in_progress')
        : l10n.t('waiting_palm_scanner');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.t('step_2_of_3'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 20 / 14,
            letterSpacing: -0.5,
            color: const Color(0xFF238EC2),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF00AA44),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF238EC2),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  offset: Offset(0, 10),
                  blurRadius: 15,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF312E81),
                  ),
                  child: const Center(
                    child: Icon(Icons.pan_tool, color: Colors.white, size: 56),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.t('place_your_palm'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 28 / 18,
                    letterSpacing: -0.5,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.t('place_palm_instructions'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 23 / 14,
                    letterSpacing: -0.5,
                    color: const Color(0xFF4B5563),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: hasError
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: hasError
                        ? const Icon(
                            Icons.error_outline,
                            color: Color(0xFFB91C1C),
                            size: 36,
                          )
                        : const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation(
                                Color(0xFF238EC2),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: hasError
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      hasError ? error! : l10n.t('keep_hand_steady'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.5,
                        color: hasError
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF238EC2),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 16 / 12,
                    letterSpacing: -0.5,
                    color: hasError
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF4B5563),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: hasError ? onRetry : onContinue,
            child: Text(l10n.t('continue')),
          ),
        ),
      ],
    );
  }
}

class _StepThree extends StatelessWidget {
  final VoidCallback onDone;

  const _StepThree({required this.onDone});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00AA44),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.t('enrollment_complete'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 28 / 18,
                    letterSpacing: -0.5,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.t('palm_enrolled_success'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 23 / 14,
                    letterSpacing: -0.5,
                    color: const Color(0xFF4B5563),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: ElevatedButton(onPressed: onDone, child: Text(l10n.t('done'))),
        ),
      ],
    );
  }
}
