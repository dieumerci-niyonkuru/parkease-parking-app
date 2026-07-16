import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Capture which notifications were unread when the screen opened, so we can
  // keep highlighting them as "new" for this visit even after we clear the
  // unread badge by marking everything read.
  late final Set<String> _newIds;

  @override void initState() {
    super.initState();
    _newIds = NotificationService.notifications.where((n) => !n.isRead).map((n) => n.id).toSet();
    NotificationService.markAllRead();
  }

  Future<void> _confirmClearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear all notifications?'),
        content: const Text('This removes every notification from your list. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('CANCEL', style: AppTheme.label.copyWith(color: AppTheme.textMuted))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('CLEAR ALL', style: AppTheme.label.copyWith(color: AppTheme.danger, fontWeight: FontWeight.w900))),
        ],
      ),
    );
    if (ok == true) {
      NotificationService.clearAll();
      if (mounted) setState(() {});
    }
  }

  @override Widget build(BuildContext context) {
    final notifs = NotificationService.notifications;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        title: Text('Notifications', style: AppTheme.heading4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context)),
        actions: [
          if (notifs.isNotEmpty)
            TextButton.icon(
              onPressed: _confirmClearAll,
              icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: AppTheme.danger),
              label: Text('Clear', style: AppTheme.body.copyWith(color: AppTheme.danger, fontWeight: FontWeight.w700))),
        ],
      ),
      body: notifs.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.notifications_off_outlined, color: AppTheme.primary, size: 44),
            ),
            const SizedBox(height: 18),
            Text('You\'re all caught up', style: AppTheme.heading4.copyWith(color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Text('Payment confirmations, receipts and reminders will appear here.',
              textAlign: TextAlign.center, style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted)),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            itemBuilder: (_, i) {
              final n = notifs[i];
              return Dismissible(
                key: ValueKey(n.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24, bottom: 10),
                  decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                ),
                onDismissed: (_) {
                  NotificationService.remove(n.id);
                  setState(() {});
                },
                child: _NotifCard(notif: n, isNew: _newIds.contains(n.id))
                  .animate().fadeIn(delay: Duration(milliseconds: i * 40)).slideX(begin: -0.03),
              );
            },
          ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  final bool isNew;
  const _NotifCard({required this.notif, this.isNew = false});

  Color get _color => switch (notif.type) {
    NotificationType.payment  => AppTheme.success,
    NotificationType.reminder => AppTheme.warning,
    NotificationType.alert    => AppTheme.danger,
    NotificationType.system   => AppTheme.primary,
  };

  IconData get _icon => switch (notif.type) {
    NotificationType.payment  => Icons.check_circle_rounded,
    NotificationType.reminder => Icons.access_time_rounded,
    NotificationType.alert    => Icons.warning_rounded,
    NotificationType.system   => Icons.info_rounded,
  };

  // Friendly relative time: "Just now", "5m ago", "2h ago", "Yesterday", date.
  String get _timeLabel {
    final diff = DateTime.now().difference(notif.time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM · HH:mm').format(notif.time);
  }

  @override Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNew ? _color.withValues(alpha: 0.05) : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isNew ? _color.withValues(alpha: 0.25) : AppTheme.border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(_icon, color: _color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(notif.title,
              style: AppTheme.body.copyWith(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w700))),
            if (isNew)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(6)),
                child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
          ]),
          const SizedBox(height: 4),
          Text(notif.body, style: AppTheme.bodySmall),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.access_time_rounded, size: 11, color: AppTheme.textHint),
            const SizedBox(width: 4),
            Text(_timeLabel, style: AppTheme.label),
          ]),
        ])),
      ]),
    );
  }
}
