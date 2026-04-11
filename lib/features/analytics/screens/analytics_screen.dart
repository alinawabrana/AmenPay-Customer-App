import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:palmpay/features/authentication/models/profile/user_model.dart';
import 'package:palmpay/features/payment_methods/models/nfc_payment_method_status_model.dart';
import 'package:palmpay/features/payment_methods/providers/payment_methods_refresh_provider.dart';
import 'package:palmpay/features/settings/providers/profile_refresh_provider.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/services/api_service.dart';
import 'package:palmpay/widgets/custom_app_bar.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  bool _isLoading = true;
  String? _error;
  _AnalyticsData? _data;
  _AnalyticsRange _selectedRange = _AnalyticsRange.sevenDays;

  @override
  void initState() {
    super.initState();
    _load();
    ref.listenManual<int>(profileRefreshProvider, (previous, next) => _load());
    ref.listenManual<int>(
      paymentMethodsRefreshProvider,
      (previous, next) => _load(),
    );
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await ApiService.getUserDetails();
      final results = await Future.wait([
        ApiService.getCustomerTransactions(customerId: user.id),
        ApiService.getPaymentMethodsWithStatus(),
        ApiService.getPalmEnrollMeStatus(),
      ]);

      final transactionsJson = results[0];
      final paymentMethodsJson = results[1];
      final palmStatusJson = results[2];

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
        _data = _AnalyticsData(
          user: user,
          transactions: transactions,
          methods: methods,
          palmEnrolled: _parseIsPalmEnrolled(palmStatusJson),
        );
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<_AnalyticsTransaction> _parseTransactions(Map<String, dynamic> json) {
    final raw = json['transactions'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(_AnalyticsTransaction.fromJson)
        .toList();
  }

  bool _parseIsPalmEnrolled(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final enrolled = data['enrolled_methods'];
    if (enrolled is List && enrolled.isNotEmpty) return true;
    if (enrolled is Map && enrolled.isNotEmpty) return true;
    final enrolledCount = data['enrolled_count'];
    return enrolledCount is num && enrolledCount > 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7FAFC),
        appBar: CustomAppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7FAFC),
        appBar: const CustomAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final filteredData = _data!.filtered(_selectedRange);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: const CustomAppBar(),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
                  Text(
                    l10n.t('analytics_title'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.tf('analytics_subtitle', {'name': _data!.user.fullname}),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _RangeSelector(
                    selected: _selectedRange,
                    onChanged: (range) {
                      setState(() {
                        _selectedRange = range;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _RangeSummaryBanner(
                    label: filteredData.rangeLabel,
                    caption: filteredData.localizedRangeSummary(l10n),
                  ),
                  const SizedBox(height: 20),
                  _OverviewGrid(data: filteredData, l10n: l10n),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: l10n.t('analytics_payment_activity'),
                    subtitle: l10n.t(filteredData.rangeSubtitle),
                    child: SizedBox(
                      height: 220,
                      child: _VolumeLineChart(
                        transactions: filteredData.transactions,
                        range: _selectedRange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _SectionCard(
                          title: l10n.t('analytics_status_mix'),
                          subtitle: l10n.t(filteredData.mixSubtitle),
                          child: SizedBox(
                            height: 220,
                            child: _StatusPieChart(
                              transactions: filteredData.transactions,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SectionCard(
                          title: l10n.t('analytics_method_readiness'),
                          subtitle: l10n.t('analytics_live_backend_enrollment'),
                          child: _MethodReadiness(data: _data!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: l10n.t('analytics_volume_snapshot'),
                    subtitle: l10n.t(filteredData.barSubtitle),
                    child: SizedBox(
                      height: 220,
                      child: _RecentBarChart(
                        transactions: filteredData.transactions,
                        range: _selectedRange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AnalyticsData {
  final UserModel user;
  final List<_AnalyticsTransaction> transactions;
  final List<NfcPaymentMethodStatus> methods;
  final bool palmEnrolled;

  const _AnalyticsData({
    required this.user,
    required this.transactions,
    required this.methods,
    required this.palmEnrolled,
  });

  double get totalProcessedAmount => transactions.fold(
    0,
    (sum, tx) => sum + (tx.isSuccessful ? tx.amount : 0),
  );

  int get completedCount => transactions.where((tx) => tx.isSuccessful).length;
  int get pendingCount => transactions.where((tx) => tx.isPending).length;
  int get failedCount => transactions.where((tx) => tx.isFailed).length;
  int get activeNfcCount => methods.where((m) => m.isNfcActive).length;
  int get inactiveNfcCount => methods.where((m) => m.isNfcInactive).length;
  int get qrReadyCount => methods.where((m) => (m.qrCode ?? '').isNotEmpty).length;

  double get completionRate {
    if (transactions.isEmpty) return 0;
    return (completedCount / transactions.length) * 100;
  }

  _AnalyticsData filtered(_AnalyticsRange range) {
    if (range == _AnalyticsRange.allTime) return this;
    final now = DateTime.now();
    final days = switch (range) {
      _AnalyticsRange.sevenDays => 7,
      _AnalyticsRange.thirtyDays => 30,
      _AnalyticsRange.allTime => 0,
    };
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    return _AnalyticsData(
      user: user,
      transactions: transactions
          .where((tx) => tx.createdAt != null && !tx.createdAt!.isBefore(cutoff))
          .toList(),
      methods: methods,
      palmEnrolled: palmEnrolled,
    );
  }

  String get rangeSubtitle => switch (transactions.isEmpty) {
    true => 'analytics_no_payment_activity',
    false => 'analytics_transaction_volume_range',
  };

  String get mixSubtitle => switch (transactions.isEmpty) {
    true => 'analytics_no_statuses',
    false => 'analytics_completed_vs_pending_failed',
  };

  String get barSubtitle => switch (transactions.isEmpty) {
    true => 'analytics_no_daily_totals',
    false => 'analytics_daily_totals_range',
  };

  String get rangeLabel {
    if (transactions.isEmpty) return 'analytics_no_data_selected_range';
    final sorted = [...transactions]..sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aTime.compareTo(bTime);
    });
    final start = sorted.first.createdAt!;
    final end = sorted.last.createdAt!;
    final formatter = DateFormat('d MMM yyyy');
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  String get rangeSummary {
    if (transactions.isEmpty) return 'analytics_switch_filter';
    return 'analytics_transactions_in_window:${transactions.length}';
  }

  String localizedRangeSummary(AppLocalizations l10n) {
    if (transactions.isEmpty) return l10n.t('analytics_switch_filter');
    return l10n.tf(
      'analytics_transactions_in_window',
      {'count': '${transactions.length}'},
    );
  }
}

enum _AnalyticsRange { sevenDays, thirtyDays, allTime }

class _AnalyticsTransaction {
  final double amount;
  final String status;
  final DateTime? createdAt;

  const _AnalyticsTransaction({
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  bool get isCompleted => status == 'completed' || status == 'success';
  bool get isSuccessful =>
      status == 'completed' || status == 'success' || status == 'initiated';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed' || status == 'declined';

  factory _AnalyticsTransaction.fromJson(Map<String, dynamic> json) {
    return _AnalyticsTransaction(
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      status: (json['status']?.toString() ?? '').toLowerCase(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')
          ?.toLocal(),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  final _AnalyticsData data;
  final AppLocalizations l10n;

  const _OverviewGrid({required this.data, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.05,
      children: [
        _MetricTile(
          title: l10n.t('analytics_processed'),
          value: '\$${data.totalProcessedAmount.toStringAsFixed(2)}',
          caption: l10n.tf(
            'analytics_successful_or_initiated',
            {'count': '${data.completedCount}'},
          ),
          icon: Icons.payments_rounded,
          accent: const Color(0xFF0F9D58),
          tint: const Color(0xFFE8F7EE),
        ),
        _MetricTile(
          title: l10n.t('analytics_success_rate'),
          value: '${data.completionRate.toStringAsFixed(0)}%',
          caption: l10n.t('analytics_initiated_counted_success'),
          icon: Icons.auto_graph_rounded,
          accent: const Color(0xFF2563EB),
          tint: const Color(0xFFEFF6FF),
        ),
        _MetricTile(
          title: l10n.t('analytics_nfc_active'),
          value: '${data.activeNfcCount}',
          caption: '${data.inactiveNfcCount} inactive enrolled',
          icon: Icons.contactless_rounded,
          accent: const Color(0xFF7C3AED),
          tint: const Color(0xFFF5F3FF),
        ),
        _MetricTile(
          title: l10n.t('analytics_palm_ready'),
          value: data.palmEnrolled ? l10n.t('enrolled') : l10n.t('not_enrolled'),
          caption: l10n.tf(
            'analytics_qr_enabled_methods',
            {'count': '${data.qrReadyCount}'},
          ),
          icon: Icons.pan_tool_rounded,
          accent: const Color(0xFFEA580C),
          tint: const Color(0xFFFFF7ED),
        ),
      ],
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final _AnalyticsRange selected;
  final ValueChanged<_AnalyticsRange> onChanged;

  const _RangeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _RangeChip(
          label: AppLocalizations.of(context).t('analytics_seven_days'),
          selected: selected == _AnalyticsRange.sevenDays,
          onTap: () => onChanged(_AnalyticsRange.sevenDays),
        ),
        _RangeChip(
          label: AppLocalizations.of(context).t('analytics_thirty_days'),
          selected: selected == _AnalyticsRange.thirtyDays,
          onTap: () => onChanged(_AnalyticsRange.thirtyDays),
        ),
        _RangeChip(
          label: AppLocalizations.of(context).t('analytics_all_time'),
          selected: selected == _AnalyticsRange.allTime,
          onTap: () => onChanged(_AnalyticsRange.allTime),
        ),
      ],
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}

class _RangeSummaryBanner extends StatelessWidget {
  final String label;
  final String caption;

  const _RangeSummaryBanner({required this.label, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF1F2937),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  caption,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFFD1D5DB),
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

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color accent;
  final Color tint;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.accent,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Icon(icon, color: accent),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: Color(0xFF9CA3AF),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _VolumeLineChart extends StatelessWidget {
  final List<_AnalyticsTransaction> transactions;
  final _AnalyticsRange range;

  const _VolumeLineChart({required this.transactions, required this.range});

  @override
  Widget build(BuildContext context) {
    final days = _buildBuckets(range);

    final values = days.map((day) {
      return transactions
          .where((tx) => tx.createdAt != null && _isInBucket(tx.createdAt!, day, range))
          .fold<double>(0, (sum, tx) => sum + tx.amount);
    }).toList();

    final maxY = values.isEmpty ? 10.0 : math.max(values.reduce(math.max), 10);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY * 1.2,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: Color(0xFFE5E7EB), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) => Text(
                '\$${value.toInt()}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= days.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _bucketLabel(days[index], range, compact: true),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              values.length,
              (index) => FlSpot(index.toDouble(), values[index]),
            ),
            isCurved: true,
            barWidth: 4,
            color: const Color(0xFF238EC2),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF238EC2).withAlpha(70),
                  const Color(0xFF238EC2).withAlpha(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: const Color(0xFF238EC2),
                strokeColor: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPieChart extends StatelessWidget {
  final List<_AnalyticsTransaction> transactions;

  const _StatusPieChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final completed = transactions.where((tx) => tx.isSuccessful).length.toDouble();
    final pending = transactions.where((tx) => tx.isPending).length.toDouble();
    final failed = transactions.where((tx) => tx.isFailed).length.toDouble();
    final total = completed + pending + failed;

    if (total == 0) {
      return Center(child: Text(l10n.t('analytics_no_transaction_data')));
    }

    final sections = [
      _PieConfig(l10n.t('analytics_success'), completed, const Color(0xFF00AA44)),
      _PieConfig(l10n.t('analytics_pending'), pending, const Color(0xFFFF8800)),
      _PieConfig(l10n.t('analytics_failed'), failed, const Color(0xFFEF4444)),
    ].where((section) => section.value > 0).toList();

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 34,
              sections: sections
                  .map(
                    (section) => PieChartSectionData(
                      value: section.value,
                      color: section.color,
                      radius: 48,
                      title: '${((section.value / total) * 100).round()}%',
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: sections
              .map(
                (section) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: section.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      section.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _PieConfig {
  final String label;
  final double value;
  final Color color;

  const _PieConfig(this.label, this.value, this.color);
}

class _MethodReadiness extends StatelessWidget {
  final _AnalyticsData data;

  const _MethodReadiness({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalMethods = data.methods.isEmpty ? 1 : data.methods.length;
    final activeNfc = data.activeNfcCount / totalMethods;
    final qrReady = data.qrReadyCount / totalMethods;
    final palmReady = data.palmEnrolled ? 1.0 : 0.0;

    return Column(
      children: [
        _ReadinessRow(
          label: l10n.t('analytics_palm_vein_label'),
          value: data.palmEnrolled
              ? l10n.t('analytics_palm_enrolled_value')
              : l10n.t('analytics_palm_not_enrolled_value'),
          progress: palmReady,
          color: const Color(0xFF00AA44),
        ),
        const SizedBox(height: 18),
        _ReadinessRow(
          label: l10n.t('analytics_nfc_card_label'),
          value: l10n.tf('analytics_nfc_active_value', {
            'count': '${data.activeNfcCount}',
          }),
          progress: activeNfc,
          color: const Color(0xFF238EC2),
        ),
        const SizedBox(height: 18),
        _ReadinessRow(
          label: l10n.t('analytics_qr_code_label'),
          value: l10n.tf('analytics_qr_ready_value', {
            'count': '${data.qrReadyCount}',
          }),
          progress: qrReady,
          color: const Color(0xFFFF8800),
        ),
      ],
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _ReadinessRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: progress.clamp(0, 1),
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _RecentBarChart extends StatelessWidget {
  final List<_AnalyticsTransaction> transactions;
  final _AnalyticsRange range;

  const _RecentBarChart({required this.transactions, required this.range});

  @override
  Widget build(BuildContext context) {
    final days = _buildBarBuckets(range);
    final totals = days.map((day) {
      return transactions
          .where((tx) => tx.createdAt != null && _isInBarBucket(tx.createdAt!, day, range))
          .fold<double>(0, (sum, tx) => sum + tx.amount);
    }).toList();
    final maxY = totals.isEmpty ? 10.0 : math.max(totals.reduce(math.max), 10);

    return BarChart(
      BarChartData(
        maxY: maxY * 1.25,
        minY: 0,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: Color(0xFFE5E7EB), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) => Text(
                '\$${value.toInt()}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= days.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _bucketLabel(days[index], range, compact: false),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(
          totals.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: totals[index],
                width: 22,
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color(0xFF00AA44), Color(0xFF238EC2)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _isInBucket(DateTime value, DateTime bucketStart, _AnalyticsRange range) {
  if (range == _AnalyticsRange.sevenDays) {
    return _isSameDay(value, bucketStart);
  }

  if (range == _AnalyticsRange.thirtyDays) {
    final bucketEnd = bucketStart.add(const Duration(days: 5));
    return !value.isBefore(bucketStart) && value.isBefore(bucketEnd);
  }

  final nextMonth = DateTime(bucketStart.year, bucketStart.month + 1, 1);
  return !value.isBefore(bucketStart) && value.isBefore(nextMonth);
}

bool _isInBarBucket(DateTime value, DateTime bucketStart, _AnalyticsRange range) {
  if (range == _AnalyticsRange.allTime) {
    final nextMonth = DateTime(bucketStart.year, bucketStart.month + 1, 1);
    return !value.isBefore(bucketStart) && value.isBefore(nextMonth);
  }

  if (range == _AnalyticsRange.thirtyDays) {
    final bucketEnd = bucketStart.add(const Duration(days: 5));
    return !value.isBefore(bucketStart) && value.isBefore(bucketEnd);
  }

  return _isSameDay(value, bucketStart);
}

String _bucketLabel(DateTime day, _AnalyticsRange range, {required bool compact}) {
  if (range == _AnalyticsRange.sevenDays) {
    return compact ? DateFormat('E').format(day) : DateFormat('d MMM').format(day);
  }

  if (range == _AnalyticsRange.thirtyDays) {
    return compact ? DateFormat('d MMM').format(day) : DateFormat('d MMM').format(day);
  }

  return compact ? DateFormat('MMM').format(day) : DateFormat('MMM').format(day);
}

List<DateTime> _buildBuckets(_AnalyticsRange range) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final count = switch (range) {
    _AnalyticsRange.sevenDays => 7,
    _AnalyticsRange.thirtyDays => 6,
    _AnalyticsRange.allTime => 8,
  };

  if (range == _AnalyticsRange.sevenDays) {
    return List.generate(
      count,
      (index) => today.subtract(Duration(days: count - 1 - index)),
    );
  }

  if (range == _AnalyticsRange.thirtyDays) {
    return List.generate(
      count,
      (index) => today.subtract(Duration(days: (count - 1 - index) * 5)),
    );
  }

  return List.generate(
    count,
    (index) => DateTime(today.year, today.month - (count - 1 - index), 1),
  );
}

List<DateTime> _buildBarBuckets(_AnalyticsRange range) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return switch (range) {
    _AnalyticsRange.sevenDays => List.generate(
      5,
      (index) => today.subtract(Duration(days: 4 - index)),
    ),
    _AnalyticsRange.thirtyDays => List.generate(
      6,
      (index) => today.subtract(Duration(days: (5 - index) * 5)),
    ),
    _AnalyticsRange.allTime => List.generate(
      6,
      (index) => DateTime(today.year, today.month - (5 - index), 1),
    ),
  };
}
