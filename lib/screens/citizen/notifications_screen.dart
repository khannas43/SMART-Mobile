import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../i18n/app_locale.dart';
import '../../services/api_error_util.dart';
import '../../services/notification_service.dart';
import '../../widgets/data_screen_states.dart';

/// Citizen notifications list — mirrors `/citizen/citizen-notification`.
class CitizenNotificationsScreen extends StatefulWidget {
  const CitizenNotificationsScreen({super.key});

  @override
  State<CitizenNotificationsScreen> createState() =>
      _CitizenNotificationsScreenState();
}

class _CitizenNotificationsScreenState extends State<CitizenNotificationsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = const [];
  int _page = 1;
  int _total = 0;
  bool _loadingMore = false;

  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final nextPage = reset ? 1 : _page + 1;
      final result = await NotificationService.instance.fetchNotifications(
        page: nextPage,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _page = nextPage;
        _total = result.total;
        _rows = reset ? result.rows : [..._rows, ...result.rows];
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiErrorUtil.friendlyMessage(e);
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  IconData _channelIcon(String? channel) {
    switch ((channel ?? '').toUpperCase()) {
      case 'SMS':
        return Icons.sms_outlined;
      case 'EMAIL':
        return Icons.email_outlined;
      case 'WHATSAPP':
        return Icons.chat_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _channelColor(String? channel) {
    switch ((channel ?? '').toUpperCase()) {
      case 'SMS':
        return Colors.blue.shade600;
      case 'EMAIL':
        return Colors.red.shade600;
      case 'WHATSAPP':
        return Colors.green.shade600;
      default:
        return kMuted;
    }
  }

  String _pick(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      for (final entry in row.entries) {
        if (entry.key.toLowerCase() == key.toLowerCase()) {
          final text = entry.value?.toString().trim();
          if (text != null && text.isNotEmpty) return text;
        }
      }
    }
    return '';
  }

  String _formatTs(String raw) {
    if (raw.isEmpty) return '—';
    final asNum = num.tryParse(raw);
    if (asNum != null) {
      final ms = asNum > 1000000000000 ? asNum.toInt() : (asNum * 1000).toInt();
      final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    final hasMore = _rows.length < _total;

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      color: kCitizenOrange,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.l('Notifications', 'सूचनाएं'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: kText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l(
              'Recent messages sent to you',
              'आपको भेजे गए हाल के संदेश',
            ),
            style: const TextStyle(fontSize: 13, color: kMuted),
          ),
          const Divider(height: 24),
          if (_loading)
            DataScreenStates.loading()
          else if (_error != null)
            DataScreenStates.error(
              context: context,
              message: _error!,
              onRetry: () => _load(reset: true),
            )
          else if (_rows.isEmpty)
            DataScreenStates.empty(
              message: context.l(
                'No notifications found.',
                'कोई सूचना नहीं मिली।',
              ),
            )
          else ...[
            for (final row in _rows)
              _NotificationCard(
                channel: _pick(row, const ['notificationServiceName']),
                message: _pick(row, const ['notificationMessage']),
                when: _formatTs(
                  _pick(row, const ['notificationTimeStamp']),
                ),
                mobile: _pick(row, const ['notificationHofMobile']),
                icon: _channelIcon(
                  _pick(row, const ['notificationServiceName']),
                ),
                color: _channelColor(
                  _pick(row, const ['notificationServiceName']),
                ),
              ),
            if (hasMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: _loadingMore
                      ? const CircularProgressIndicator(color: kCitizenOrange)
                      : TextButton(
                          onPressed: () => _load(reset: false),
                          child: Text(
                            context.l('Load more', 'और लोड करें'),
                          ),
                        ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.channel,
    required this.message,
    required this.when,
    required this.mobile,
    required this.icon,
    required this.color,
  });

  final String channel;
  final String message;
  final String when;
  final String mobile;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (channel.isNotEmpty)
                    Text(
                      channel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    message.isEmpty ? '—' : message,
                    style: const TextStyle(fontSize: 14, color: kText),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: kMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          when,
                          style: const TextStyle(fontSize: 12, color: kMuted),
                        ),
                      ),
                      if (mobile.isNotEmpty) ...[
                        const Icon(Icons.phone_android, size: 14, color: kMuted),
                        const SizedBox(width: 4),
                        Text(
                          mobile,
                          style: const TextStyle(fontSize: 12, color: kMuted),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
