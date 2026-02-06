import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/services/api_service.dart';
import 'package:palmpay/utils/themes/text_theme.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';

class EnrollPalmVeinScreen extends StatefulWidget {
  const EnrollPalmVeinScreen({super.key});

  @override
  State<EnrollPalmVeinScreen> createState() => _EnrollPalmVeinScreenState();
}

class _EnrollPalmVeinScreenState extends State<EnrollPalmVeinScreen> {
  int _step = 1;

  bool _loadingSession = true;
  String? _sessionId;
  String? _qrData;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initSession() async {
    _pollTimer?.cancel();
    setState(() {
      _loadingSession = true;
      _sessionId = null;
      _qrData = null;
      _error = null;
      _step = 1;
    });

    try {
      final res = await ApiService.createPalmEnrollSession();
      final sessionId = res['session_id']?.toString();
      final qrData = res['qr_data']?.toString();
      if (sessionId == null ||
          sessionId.isEmpty ||
          qrData == null ||
          qrData.isEmpty) {
        throw Exception('Invalid enrollment session response');
      }

      if (!mounted) return;
      setState(() {
        _sessionId = sessionId;
        _qrData = qrData;
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
        final status = (res['status'] ?? '').toString().toLowerCase();
        if (!mounted) return;

        if (status == 'enrolled') {
          _pollTimer?.cancel();
          setState(() => _step = 3);
          return;
        }

        if (status == 'failed') {
          _pollTimer?.cancel();
          setState(() {
            _error =
                (res['message'] ?? res['error_code'] ?? 'Enrollment failed')
                    .toString();
          });
          return;
        }

        if (status == 'expired') {
          _pollTimer?.cancel();
          setState(() {
            _error = 'Session expired. Please regenerate QR.';
          });
          return;
        }

        if (status == 'claimed' && _step < 2) {
          setState(() => _step = 2);
        }
      } catch (_) {
        // Ignore transient polling failures.
      }
    });
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
        actions: [
          IconButton(
            onPressed: () async {
              final logDump = ApiService.getPalmEnrollmentLogDump();
              final text = [
                'Palm Vein Enrollment Logs',
                'step=$_step',
                'session_id=${_sessionId ?? '-'}',
                'error=${_error ?? '-'}',
                '',
                logDump.isEmpty ? 'No PALM ENROLL logs captured yet.' : logDump,
              ].join('\n');

              await Clipboard.setData(ClipboardData(text: text));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied enrollment logs')),
              );
            },
            icon: const Icon(Icons.copy_rounded, color: Color(0xFF333333)),
            tooltip: 'Copy logs',
          ),
        ],
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
                      qrData: _qrData,
                      error: _error,
                      onRetry: _initSession,
                      onNext: () => setState(() => _step = 2),
                    )
                  : _step == 2
                  ? _StepTwo(
                      error: _error,
                      onRetry: _initSession,
                      onNext: () => setState(() => _step = 3),
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
  final VoidCallback onNext;
  final VoidCallback onRetry;
  final bool loading;
  final String? qrData;
  final String? error;

  const _StepOne({
    required this.onNext,
    required this.onRetry,
    required this.loading,
    required this.qrData,
    required this.error,
  });

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
                        : QrImage(
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
                  l10n.t('scan_qr_enrollment_instruction'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 23 / 14,
                    letterSpacing: -0.5,
                    color: const Color(0xFF333333),
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
            onPressed: (loading || qrData == null) ? null : onNext,
            child: Text(l10n.t('i_scanned_qr_code')),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: loading ? null : onRetry,
          child: Text(l10n.t('continue')),
        ),
        const SizedBox(height: 16),
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
  final VoidCallback onNext;
  final VoidCallback onRetry;
  final String? error;

  const _StepTwo({required this.onNext, required this.onRetry, this.error});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.t('scanning_progress'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 16 / 12,
                          letterSpacing: -0.5,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                    Text(
                      '75%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 16 / 12,
                        letterSpacing: -0.5,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: 0.75,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF00AA44)),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      l10n.t('keep_hand_steady'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.5,
                        color: Color(0xFF238EC2),
                      ),
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onRetry,
                    child: Text(l10n.t('continue')),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: onNext,
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
