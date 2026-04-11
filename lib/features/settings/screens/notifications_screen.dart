import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/services/api_service.dart';
import 'package:palmpay/utils/themes/text_theme.dart';
import 'package:palmpay/features/settings/providers/notification_refresh_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _isLoading = true;
  String? _error;
  List<_AppNotification> _notifications = const [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getNotifications(),
        ApiService.getUnreadNotificationsCount(),
      ]);

      final notificationsJson = results[0];
      final unreadJson = results[1];
      final raw = notificationsJson['data'];
      final notifications = raw is List
          ? raw
                .whereType<Map<String, dynamic>>()
                .map(_AppNotification.fromJson)
                .toList()
          : <_AppNotification>[];

      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _unreadCount = (unreadJson['unread_count'] as num?)?.toInt() ??
            (notificationsJson['unread_count'] as num?)?.toInt() ??
            0;
        _isLoading = false;
      });
      ref.read(notificationRefreshProvider.notifier).state++;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(_AppNotification item) async {
    if (item.status == 'read') return;

    final previous = List<_AppNotification>.from(_notifications);
    final previousUnread = _unreadCount;

    setState(() {
      _notifications = _notifications
          .map((notification) => notification.id == item.id
              ? notification.copyWith(
                  status: 'read',
                  readAt: DateTime.now(),
                )
              : notification)
          .toList();
      _unreadCount = (_unreadCount - 1).clamp(0, 1 << 30);
    });

    try {
      await ApiService.markNotificationAsRead(item.id);
      ref.read(notificationRefreshProvider.notifier).state++;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notifications = previous;
        _unreadCount = previousUnread;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sectionedItems = _buildSections(_notifications);

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
          l10n.t('notifications'),
          style: ATextTheme.textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: _notifications.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        SizedBox(height: 120),
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 56,
                          color: Color(0xFF9CA3AF),
                        ),
                        SizedBox(height: 16),
                        Text(
                          l10n.t('notifications_none'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _UnreadCountBanner(count: _unreadCount);
                        }
                        final item = sectionedItems[index - 1];
                        if (item is String) {
                          return _NotificationSectionHeader(title: item);
                        }
                        return _NotificationTile(
                          item: item as _AppNotification,
                          onTap: () => _markAsRead(item),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: sectionedItems.length + 1,
                    ),
            ),
    );
  }
}

List<Object> _buildSections(List<_AppNotification> notifications) {
  final today = <_AppNotification>[];
  final yesterday = <_AppNotification>[];
  final earlier = <_AppNotification>[];
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final startOfYesterday = startOfToday.subtract(const Duration(days: 1));

  for (final notification in notifications) {
    if (!notification.timestamp.isBefore(startOfToday)) {
      today.add(notification);
    } else if (!notification.timestamp.isBefore(startOfYesterday)) {
      yesterday.add(notification);
    } else {
      earlier.add(notification);
    }
  }

  final items = <Object>[];
  if (today.isNotEmpty) {
    items.add('notifications_today');
    items.addAll(today);
  }
  if (yesterday.isNotEmpty) {
    items.add('notifications_yesterday');
    items.addAll(yesterday);
  }
  if (earlier.isNotEmpty) {
    items.add('notifications_earlier');
    items.addAll(earlier);
  }
  return items;
}

class _AppNotification {
  final int id;
  final String type;
  final String category;
  final String title;
  final String body;
  final DateTime timestamp;
  final IconData icon;
  final Color color;
  final Color tint;
  final String status;
  final String priority;
  final DateTime? readAt;

  const _AppNotification({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.icon,
    required this.color,
    required this.tint,
    required this.status,
    required this.priority,
    required this.readAt,
  });

  factory _AppNotification.fromJson(Map<String, dynamic> json) {
    final iconName = (json['icon']?.toString() ?? '').toLowerCase();
    final category = (json['category']?.toString() ?? '').toLowerCase();
    final type = (json['type']?.toString() ?? '').toLowerCase();
    final status = (json['status']?.toString() ?? '').toLowerCase();
    final priority = (json['priority']?.toString() ?? '').toLowerCase();
    final createdAt =
        DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
        DateTime.now();

    return _AppNotification(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: type,
      category: category,
      title: json['title']?.toString() ?? 'Notification',
      body: json['message']?.toString() ?? '',
      timestamp: createdAt,
      icon: _iconFor(iconName, category, type),
      color: _colorFor(iconName, category, type),
      tint: _tintFor(iconName, category, type),
      status: status,
      priority: priority,
      readAt: DateTime.tryParse(json['read_at']?.toString() ?? ''),
    );
  }

  _AppNotification copyWith({
    String? status,
    DateTime? readAt,
  }) {
    return _AppNotification(
      id: id,
      type: type,
      category: category,
      title: title,
      body: body,
      timestamp: timestamp,
      icon: icon,
      color: color,
      tint: tint,
      status: status ?? this.status,
      priority: priority,
      readAt: readAt ?? this.readAt,
    );
  }
}

IconData _iconFor(String icon, String category, String type) {
  if (icon == 'check_circle' || type.contains('completed')) {
    return Icons.check_circle_outline_rounded;
  }
  if (icon == 'credit_card' || category == 'payment_method') {
    return Icons.credit_card_rounded;
  }
  if (type.contains('failed')) return Icons.error_outline_rounded;
  return Icons.notifications_none_rounded;
}

Color _colorFor(String icon, String category, String type) {
  if (icon == 'check_circle' || type.contains('completed')) {
    return const Color(0xFF00AA44);
  }
  if (icon == 'credit_card' || category == 'payment_method') {
    return const Color(0xFF238EC2);
  }
  if (type.contains('failed')) return const Color(0xFFEF4444);
  return const Color(0xFF6B7280);
}

Color _tintFor(String icon, String category, String type) {
  if (icon == 'check_circle' || type.contains('completed')) {
    return const Color(0xFFF0FDF4);
  }
  if (icon == 'credit_card' || category == 'payment_method') {
    return const Color(0xFFEFF6FF);
  }
  if (type.contains('failed')) return const Color(0xFFFEE2E2);
  return const Color(0xFFF3F4F6);
}

class _UnreadCountBanner extends StatelessWidget {
  final int count;

  const _UnreadCountBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = count == 1
        ? l10n.t('notifications_unread_count_one')
        : l10n.tf('notifications_unread_count_other', {'count': '$count'});
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
              Icons.notifications_active_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.t('notifications_live_count'),
                  style: TextStyle(
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

class _NotificationSectionHeader extends StatelessWidget {
  final String title;

  const _NotificationSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Text(
        l10n.t(title),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final _AppNotification item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = item.status == 'unread';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFF8FBFF) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isUnread ? const Color(0xFFBFDBFE) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.tint,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF238EC2),
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          _formatRelativeTime(item.timestamp),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatRelativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('d MMM').format(time);
}
